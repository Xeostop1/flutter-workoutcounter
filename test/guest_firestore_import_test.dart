// Local transaction doubles; production Firestore is never contacted.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/guest_migration.dart';
import 'package:counter_01/repositories/record_repository.dart';

void main() {
  final record = WorkoutRecord(
    date: DateTime(2026, 10, 31),
    routineId: 'guest_abc',
    routineTitle: '운동',
    totalReps: 5,
  );
  test('실제 importer는 UID 경로의 안정된 ID로 생성하고 이미 있는 문서는 보존한다', () async {
    final db = _Db();
    final auth = _Auth();
    final importer = FirestoreGuestImporter(db: db, auth: auth);
    final path = 'users/a/workoutRecords/${workoutRecordKey(record)}';
    await importer.record('a', record);
    expect(db.data[path]!['totalReps'], 5);
    db.data[path]!['routineTitle'] = '서버 수정';
    await importer.record('a', record);
    expect(db.data[path]!['routineTitle'], '서버 수정');
    expect(db.writes, 1);
    await importer.routine(
      'a',
      const Routine(
        id: 'guest_abc',
        title: '루틴',
        categoryId: 'FREE',
        ttsEnabled: false,
      ),
    );
    expect(db.data['users/a/routines/guest_abc']!['ownerUid'], 'a');
    expect(db.data['users/a/routines/guest_abc']!['ttsEnabled'], isFalse);
  });

  test('트랜잭션 조회 중 계정 전환 또는 탈퇴 시작이면 쓰기를 차단한다', () async {
    final db = _Db();
    final auth = _Auth();
    var allowed = true;
    final importer = FirestoreGuestImporter(
      db: db,
      auth: auth,
      isCurrent: (_) => allowed,
    );
    db.afterRead = () {
      auth.uid = 'b';
    };
    await expectLater(importer.record('a', record), throwsStateError);
    expect(db.writes, 0);
    auth.uid = 'a';
    db.afterRead = () {
      allowed = false;
    };
    await expectLater(importer.record('a', record), throwsStateError);
    expect(db.writes, 0);
  });
}

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  String uid = 'a';
  @override
  User get currentUser => _User(uid);
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.path);
  @override
  final String path;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Col('$path/$name');
}

class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Col(this.path);
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Doc('$path/$id');
}

class _Snapshot<T extends Object?> extends Fake implements DocumentSnapshot<T> {
  _Snapshot(this.exists);
  @override
  final bool exists;
}

class _Db extends Fake implements FirebaseFirestore {
  final data = <String, Map<String, dynamic>>{};
  int writes = 0;
  void Function()? afterRead;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Col(name);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => handler(_Transaction(this));
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Db db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> doc,
  ) async {
    final exists = db.data.containsKey(doc.path);
    db.afterRead?.call();
    return _Snapshot<T>(exists);
  }

  @override
  Transaction set<T>(DocumentReference<T> doc, T value, [SetOptions? options]) {
    db.writes++;
    db.data[doc.path] = Map<String, dynamic>.from(value as Map);
    return this;
  }
}
