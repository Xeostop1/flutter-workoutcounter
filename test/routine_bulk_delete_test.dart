// Test-only Firestore doubles; no live backend is used.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'owner';
}

class _Auth extends Fake implements FirebaseAuth {
  User? user = _User();
  @override
  User? get currentUser => user;
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

class _Batch extends Fake implements WriteBatch {
  _Batch(this.db);
  final _Db db;
  final List<String> paths = [];
  @override
  void delete(DocumentReference document) => paths.add(document.path);
  @override
  Future<void> commit() async {
    if (db.fail) throw StateError('offline');
    db.commits.add(paths);
    db.afterCommit?.call();
  }
}

class _Db extends Fake implements FirebaseFirestore {
  final List<List<String>> commits = [];
  bool fail = false;
  void Function()? afterCommit;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Col(name);
  @override
  WriteBatch batch() => _Batch(this);
}

void main() {
  test('확인한 계정의 루틴 경로만 배치로 삭제한다', () async {
    final db = _Db();
    final vm = RoutinesViewModel(db: db, auth: _Auth());
    addTearDown(vm.dispose);
    await vm.deleteRoutines({'a', 'b'}, ownerUid: 'owner');
    expect(db.commits.single, [
      'users/owner/routines/a',
      'users/owner/routines/b',
    ]);
  });
  test('계정 변경과 서버 실패는 성공으로 처리하지 않는다', () async {
    final db = _Db();
    final auth = _Auth();
    final vm = RoutinesViewModel(db: db, auth: auth);
    addTearDown(vm.dispose);
    await expectLater(
      vm.deleteRoutines({'a'}, ownerUid: 'other'),
      throwsStateError,
    );
    expect(db.commits, isEmpty);
    db.fail = true;
    await expectLater(
      vm.deleteRoutines({'a'}, ownerUid: 'owner'),
      throwsStateError,
    );
    expect(db.commits, isEmpty);
  });
  test('대량 삭제 중 로그아웃되면 다음 배치를 보내지 않는다', () async {
    final db = _Db();
    final auth = _Auth();
    db.afterCommit = () => auth.user = null;
    final vm = RoutinesViewModel(db: db, auth: auth);
    addTearDown(vm.dispose);
    await expectLater(
      vm.deleteRoutines({
        for (var i = 0; i < 401; i++) '$i',
      }, ownerUid: 'owner'),
      throwsStateError,
    );
    expect(db.commits.length, 1);
    expect(db.commits.single.length, 400);
  });
}
