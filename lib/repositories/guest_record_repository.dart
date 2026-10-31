import '../models/workout_record.dart';
import 'guest_store.dart';
import 'record_repository.dart';

class GuestRecordRepository implements RecordRepository {
  GuestRecordRepository(
    this.remote,
    this.guests, {
    required this.currentUid,
    this.currentScope,
  });
  final RecordRepository remote;
  final GuestStore guests;
  final String? Function() currentUid;
  final Object? Function()? currentScope;

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async {
    if (uid == GuestStore.uid) return guests.records();
    final pending = uid == null
        ? <WorkoutRecord>[]
        : await guests.records(accountUid: uid);
    List<WorkoutRecord> cloud;
    try {
      cloud = await remote.loadAll(uid: uid);
    } catch (_) {
      if (pending.isEmpty) rethrow;
      return pending;
    }
    return {
      for (final r in pending) workoutRecordKey(r): r,
      for (final r in cloud) workoutRecordKey(r): r,
    }.values.toList();
  }

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    if (uid == GuestStore.uid) {
      final scope = currentScope?.call();
      await guests.saveRecord(
        record,
        isCurrent: () => currentUid() == uid && currentScope?.call() == scope,
      );
    } else {
      await remote.save(record, uid: uid);
    }
  }
}
