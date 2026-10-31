import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/workout_record.dart';

abstract class RecordRepository {
  Future<List<WorkoutRecord>> loadAll({String? uid});
  Future<void> save(WorkoutRecord record, {String? uid});
}

class InMemoryRecordRepository implements RecordRepository {
  final List<WorkoutRecord> _data = [];

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async =>
      List.unmodifiable(_data);

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    final index = _data.indexWhere(
      (item) => workoutRecordKey(item) == workoutRecordKey(record),
    );
    if (index == -1) {
      _data.add(record);
    } else {
      _data[index] = record;
    }
  }
}

class FirestoreRecordRepository implements RecordRepository {
  FirestoreRecordRepository({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('workoutRecords');

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async {
    final ownerUid = uid ?? _auth.currentUser?.uid;
    if (ownerUid == null) return [];

    final snapshot = await _collection(
      ownerUid,
    ).orderBy('date', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final date = data['date'];
      return WorkoutRecord.fromJson({
        ...data,
        if (date is Timestamp) 'date': date.toDate().toIso8601String(),
      });
    }).toList();
  }

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('운동 기록 저장에는 로그인이 필요합니다.');
    if (uid != null && user.uid != uid) {
      throw StateError('운동 기록 저장 중 로그인 계정이 변경되었습니다.');
    }

    await _collection(user.uid).doc(workoutRecordKey(record)).set({
      ...record.toJson(),
      'date': Timestamp.fromDate(record.date),
    });
  }
}

String workoutRecordKey(WorkoutRecord record) =>
    '${record.date.microsecondsSinceEpoch}_${record.routineId}';
