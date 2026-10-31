import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';

void main() {
  test('이번 주 운동 횟수는 월요일부터 일요일까지 운동 기록만 센다', () async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    await Future<void>.delayed(Duration.zero);

    for (final date in [
      DateTime(2026, 8, 9),
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 16),
    ]) {
      await records.addRecord(
        WorkoutRecord(
          date: date,
          routineId: 'routine',
          routineTitle: '운동',
          totalReps: 10,
        ),
      );
    }
    await records.addRecord(
      WorkoutRecord(
        date: DateTime(2026, 8, 12),
        routineId: 'empty-routine',
        routineTitle: '0회 운동',
        totalReps: 0,
      ),
    );
    await records.addManualRecord(date: DateTime(2026, 8, 12), title: '메모');

    expect(records.workoutsThisWeek(DateTime(2026, 8, 12)), 2);
  });

  test('계정이 바뀌면 이전 기록을 지우고 새 계정 기록을 불러온다', () async {
    final records = RecordsViewModel(_AccountRecordRepository());

    records.bindAccount('user-a');
    await Future<void>.delayed(Duration.zero);
    expect(
      records.recordsOn(DateTime(2026, 8, 10)).single.routineTitle,
      'A 운동',
    );

    records.bindAccount(null);
    expect(records.totalCount, 0);

    records.bindAccount('user-b');
    await Future<void>.delayed(Duration.zero);
    expect(
      records.recordsOn(DateTime(2026, 8, 10)).single.routineTitle,
      'B 운동',
    );
  });

  test('초기 로딩 중 저장한 기록은 유실되거나 중복되지 않는다', () async {
    final repository = _DelayedRecordRepository();
    final records = RecordsViewModel(repository)..bindAccount('user');
    await pumpEventQueue();

    final syncedDuringLoad = _record('동기화된 새 운동', 11);
    final localDuringLoad = _record('로딩 중 새 운동', 12);
    await records.addRecord(syncedDuringLoad);
    await records.addRecord(localDuringLoad);

    repository.completeLoad([_record('기존 운동', 10), syncedDuringLoad]);
    await pumpEventQueue();

    expect(records.records.map((record) => record.routineTitle), {
      '기존 운동',
      '동기화된 새 운동',
      '로딩 중 새 운동',
    });
    expect(records.totalCount, 3);
  });

  test('기록 로딩 실패를 알리고 재시도한다', () async {
    final repository = _FailOnceLoadRepository();
    final records = RecordsViewModel(repository)..bindAccount('user');

    expect(records.isLoading, isTrue);
    await pumpEventQueue();
    expect(records.isLoading, isFalse);
    expect(records.loadError, isNotNull);

    await records.reload();

    expect(repository.attempts, 2);
    expect(records.loadError, isNull);
    expect(records.records.single.routineTitle, '복구된 운동');
  });

  test('계정 전환 중 완료된 수동 기록 추가를 새 계정에 넣지 않는다', () async {
    final repository = _DelayedSaveRecordRepository();
    final records = RecordsViewModel(repository)..bindAccount('user-a');
    await pumpEventQueue();

    final saving = records.addManualRecord(
      date: DateTime(2026, 8, 14),
      title: '추가 중인 기록',
    );
    records.bindAccount('user-b');
    await pumpEventQueue();
    repository.completeSave();
    await saving;

    expect(records.records.single.routineTitle, 'B 기록');
  });

  test('계정 전환 중 완료된 수동 기록 수정을 새 계정에 적용하지 않는다', () async {
    final repository = _DelayedSaveRecordRepository();
    final records = RecordsViewModel(repository)..bindAccount('user-a');
    await pumpEventQueue();

    final saving = records.updateManualRecord(
      records.records.single,
      title: '수정된 A 기록',
    );
    records.bindAccount('user-b');
    await pumpEventQueue();
    repository.completeSave();
    await saving;

    expect(records.records.single.routineTitle, 'B 기록');
  });
}

WorkoutRecord _record(String title, int day) => WorkoutRecord(
  date: DateTime(2026, 8, day),
  routineId: title,
  routineTitle: title,
  totalReps: 10,
);

class _AccountRecordRepository implements RecordRepository {
  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async => [
    WorkoutRecord(
      date: DateTime(2026, 8, 10),
      routineId: 'routine',
      routineTitle: uid == 'user-a' ? 'A 운동' : 'B 운동',
      totalReps: 10,
    ),
  ];

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {}
}

class _DelayedRecordRepository implements RecordRepository {
  final Completer<List<WorkoutRecord>> _load = Completer();

  void completeLoad(List<WorkoutRecord> records) => _load.complete(records);

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) => _load.future;

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {}
}

class _FailOnceLoadRepository implements RecordRepository {
  int attempts = 0;

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async {
    attempts++;
    if (attempts == 1) throw StateError('첫 로딩 실패');
    return [_record('복구된 운동', 13)];
  }

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {}
}

class _DelayedSaveRecordRepository implements RecordRepository {
  final Completer<void> _save = Completer<void>();

  void completeSave() => _save.complete();

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async => [
    WorkoutRecord(
      date: DateTime(2026, 8, 14),
      routineId: WorkoutRecord.manualRoutineId,
      routineTitle: uid == 'user-a' ? 'A 기록' : 'B 기록',
      totalReps: 0,
      kind: RecordKind.memo,
    ),
  ];

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) => _save.future;
}
