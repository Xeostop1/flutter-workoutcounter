import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/routine.dart';
import '../models/workout_record.dart';
import 'guest_store.dart';
import 'record_repository.dart';

class GuestMigration {
  GuestMigration(
    this.store, {
    required this.writeRecord,
    required this.writeRoutine,
  });
  final GuestStore store;
  final Future<void> Function(String, WorkoutRecord) writeRecord;
  final Future<void> Function(String, Routine) writeRoutine;
  final Map<String, Future<void>> _running = {};
  final Set<String> _paused = {};
  bool isAllowed(String uid) => !_paused.contains(uid);

  Future<void> pause(String uid) async {
    _paused.add(uid);
    try {
      await _running[uid];
    } catch (_) {
      /* The local queue remains retryable. */
    }
  }

  void resume(String uid) => _paused.remove(uid);

  Future<void> retry(String uid, {required bool Function() isCurrent}) {
    if (!isAllowed(uid)) return Future.error(StateError('계정 데이터 처리가 중지되었습니다.'));
    final running = _running[uid];
    if (running != null) return running;
    late final Future<void> task;
    task = _retry(uid, isCurrent: () => isAllowed(uid) && isCurrent())
        .whenComplete(() {
          if (identical(_running[uid], task)) _running.remove(uid);
        });
    _running[uid] = task;
    return task;
  }

  Future<void> _retry(String uid, {required bool Function() isCurrent}) async {
    void check() {
      if (!isCurrent()) throw StateError('계정이 변경되었습니다.');
    }

    check();
    await store.claim(uid, isCurrent: isCurrent);
    Object? failure;
    for (final routine in await store.routines(accountUid: uid)) {
      check();
      try {
        await writeRoutine(uid, routine);
        await store.acknowledge(uid, 'routines', routine.id);
      } catch (error) {
        failure = error;
      }
    }
    for (final record in await store.records(accountUid: uid)) {
      check();
      try {
        await writeRecord(uid, record);
        await store.acknowledge(uid, 'records', workoutRecordKey(record));
      } catch (error) {
        failure = error;
      }
    }
    check();
    if (failure != null) throw failure;
  }
}

/// Never overwrite an existing account document, even after an interrupted
/// upload whose server acknowledgement was lost.
class FirestoreGuestImporter {
  FirestoreGuestImporter({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    bool Function(String)? isCurrent,
  }) : _db = db ?? FirebaseFirestore.instance,
       _isCurrent = isCurrent,
       _auth = auth ?? FirebaseAuth.instance;
  final bool Function(String)? _isCurrent;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> _insert(
    String uid,
    String collection,
    String key,
    Map<String, dynamic> data,
  ) async {
    void check() {
      if (_auth.currentUser?.uid != uid || _isCurrent?.call(uid) == false) {
        throw StateError('계정이 변경되었습니다.');
      }
    }

    check();
    final document = _db
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(key);
    await _db.runTransaction((transaction) async {
      check();
      final existing = await transaction.get(document);
      check();
      if (!existing.exists) transaction.set(document, data);
    });
  }

  Future<void> record(String uid, WorkoutRecord record) => _insert(
    uid,
    'workoutRecords',
    workoutRecordKey(record),
    {...record.toJson(), 'date': Timestamp.fromDate(record.date)},
  );

  Future<void> routine(String uid, Routine routine) =>
      _insert(uid, 'routines', routine.id, {
        ...routine.toMap(),
        'ownerUid': uid,
        'createdAt': Timestamp.fromDate(routine.createdAt ?? DateTime.now()),
        'updatedAt': Timestamp.fromDate(routine.updatedAt ?? DateTime.now()),
      });
}
