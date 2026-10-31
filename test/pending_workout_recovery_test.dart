import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/pending_workout_store.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late PendingWorkoutStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('workout_recovery_test_');
    store = PendingWorkoutStore(directory: () async => directory);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('서버 저장 전에 파일을 남기고 재시작 후 같은 ID로 복구한다', () async {
    final remote = _RemoteRecords()..offline = true;
    remote.beforeSave = () async {
      expect((await store.load('a')).single.toJson(), _record.toJson());
    };
    final first = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('a');
    await _settle(first);
    await expectLater(first.addRecord(_record), throwsStateError);
    expect(first.records, isEmpty);
    expect(first.pendingCount, 1);
    first.dispose();

    remote.offline = false;
    final restartedStore = PendingWorkoutStore(
      directory: () async => directory,
    );
    final restarted = RecordsViewModel(remote, pendingWorkouts: restartedStore)
      ..bindAccount('a');
    addTearDown(restarted.dispose);
    await _settle(restarted);

    expect(restarted.records.single.toJson(), _record.toJson());
    expect(
      remote.attempts
          .map((attempt) => workoutRecordKey(attempt.record))
          .toSet(),
      {workoutRecordKey(_record)},
    );
    expect(await restartedStore.load('a'), isEmpty);
    expect(restarted.pendingCount, 0);
  });

  test('디스크 날짜에 시간대를 포함하여 복구 후에도 동일한 기록 ID를 유지한다', () async {
    await store.save('a', _record);
    final files = await directory
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.endsWith('.json'))
        .toList();
    final json =
        jsonDecode(await (files.single as File).readAsString())
            as Map<String, dynamic>;
    final storedDate = DateTime.parse(json['date'] as String);
    expect(storedDate.isUtc, isTrue);
    expect(
      storedDate.microsecondsSinceEpoch,
      _record.date.microsecondsSinceEpoch,
    );
    final restarted = PendingWorkoutStore(directory: () async => directory);
    expect(
      workoutRecordKey((await restarted.load('a')).single),
      workoutRecordKey(_record),
    );
  });

  test('서버 성공 직후 종료되어도 재전송으로 기록이 중복되지 않는다', () async {
    final remote = _RemoteRecords();
    await store.save('a', _record);
    await remote.save(_record, uid: 'a');
    final records = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _settle(records);

    expect(remote.data['a'], hasLength(1));
    expect(records.records, hasLength(1));
    expect(await store.load('a'), isEmpty);
  });

  test('재실행 후에도 오프라인이면 파일을 유지하고 수동 재시도로 복구한다', () async {
    final remote = _RemoteRecords()..offline = true;
    await store.save('a', _record);
    final records = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _settle(records);

    expect(records.recoveryFailed, isTrue);
    expect(records.pendingCount, 1);
    expect(await store.load('a'), hasLength(1));
    remote.offline = false;
    await records.retryPendingRecords();
    expect(records.recoveryFailed, isFalse);
    expect(records.records, hasLength(1));
    expect(await store.load('a'), isEmpty);
  });

  test('다른 계정은 대기 기록을 읽거나 전송하지 않는다', () async {
    final remote = _RemoteRecords();
    await store.save('a', _record);
    final records = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('b');
    addTearDown(records.dispose);
    await _settle(records);
    expect(records.pendingCount, 0);
    expect(remote.attempts, isEmpty);
    expect(await store.load('a'), hasLength(1));

    records.bindAccount('a');
    await _settle(records);
    expect(remote.attempts.single.uid, 'a');
    expect(records.records, hasLength(1));
  });

  test('복구 전송 중 계정이 바뀌어도 새 계정 목록에 반영하지 않는다', () async {
    final saving = Completer<void>();
    final remote = _RemoteRecords()..block = saving;
    await store.save('a', _record);
    final records = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _until(() => remote.attempts.isNotEmpty);
    records.bindAccount('b');
    await _settle(records);
    saving.complete();
    await _until(() => remote.data['a']?.isNotEmpty ?? false);
    await _until(() => !records.recovering);

    expect(records.accountUid, 'b');
    expect(records.records, isEmpty);
    expect(remote.data['b'] ?? {}, isEmpty);
    await store.load('a'); // 이전 계정 파일 정리가 끝날 때까지 기다린다.
  });

  test('같은 기록의 동시 저장은 한 번만 전송한다', () async {
    final saving = Completer<void>();
    final remote = _RemoteRecords()..block = saving;
    final records = RecordsViewModel(remote, pendingWorkouts: store)
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _settle(records);
    final first = records.addRecord(_record);
    final second = records.addRecord(_record);
    await _until(() => remote.attempts.isNotEmpty);
    saving.complete();
    await Future.wait([first, second]);

    expect(remote.attempts, hasLength(1));
    expect(records.records, hasLength(1));
  });

  test('로컬 파일 저장 실패 시 서버 전송이나 완료 처리를 하지 않는다', () async {
    final remote = _RemoteRecords();
    final records = RecordsViewModel(remote, pendingWorkouts: _BrokenStore())
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _settle(records);
    await expectLater(
      records.addRecord(_record),
      throwsA(isA<FileSystemException>()),
    );
    expect(remote.attempts, isEmpty);
    expect(records.records, isEmpty);
  });

  test('서버 성공 후 로컬 정리가 실패해도 같은 기록을 다시 저장한다', () async {
    final remote = _RemoteRecords();
    final failingStore = _CleanupFailureStore(directory: () async => directory);
    final records = RecordsViewModel(remote, pendingWorkouts: failingStore)
      ..bindAccount('a');
    addTearDown(records.dispose);
    await _settle(records);
    await expectLater(
      records.addRecord(_record),
      throwsA(isA<FileSystemException>()),
    );
    expect(remote.data['a'], hasLength(1));
    expect(await store.load('a'), hasLength(1));
    failingStore.fail = false;
    await records.retryPendingRecords();
    expect(remote.data['a'], hasLength(1));
    expect(records.records, hasLength(1));
    expect(await store.load('a'), isEmpty);
  });

  test('여러 기록을 개별 파일로 보관하고 탈퇴 계정의 파일만 지운다', () async {
    await Future.wait([
      store.save('a', _record),
      store.save('a', _record.copyWith(date: DateTime(2026, 10, 27))),
      store.save('b', _record),
    ]);
    expect(await store.load('a'), hasLength(2));
    await store.clear('a');
    expect(await store.load('a'), isEmpty);
    expect(await store.load('b'), hasLength(1));
    await expectLater(store.save('a', _record), throwsStateError);
  });
}

final _record = WorkoutRecord(
  date: DateTime(2026, 10, 28, 9, 30, 0, 123, 456),
  routineId: 'routine',
  routineTitle: '저장 대기 운동',
  totalReps: 3,
  exercises: const [
    Exercise(id: 'squat', name: '스쿼트', sets: 1, reps: 3, repSeconds: 1),
  ],
);

Future<void> _settle(RecordsViewModel records) =>
    _until(() => !records.recovering && !records.isLoading);

Future<void> _until(bool Function() condition) async {
  final elapsed = Stopwatch()..start();
  while (!condition()) {
    if (elapsed.elapsed > const Duration(seconds: 15)) {
      throw TimeoutException('기록 복구 작업이 완료되지 않았습니다.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _RemoteRecords implements RecordRepository {
  bool offline = false;
  Completer<void>? block;
  Future<void> Function()? beforeSave;
  final attempts = <({String uid, WorkoutRecord record})>[];
  final data = <String, Map<String, WorkoutRecord>>{};

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async =>
      data[uid]?.values.toList() ?? [];

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    if (uid == null) throw StateError('계정 없음');
    attempts.add((uid: uid, record: record));
    await beforeSave?.call();
    if (block != null) await block!.future;
    if (offline) throw StateError('오프라인');
    (data[uid] ??= {})[workoutRecordKey(record)] = record;
  }
}

class _BrokenStore extends PendingWorkoutStore {
  @override
  Future<List<WorkoutRecord>> load(String uid) async => [];

  @override
  Future<void> save(String uid, WorkoutRecord record) async =>
      throw const FileSystemException('디스크 쓰기 실패');
}

class _CleanupFailureStore extends PendingWorkoutStore {
  _CleanupFailureStore({required super.directory});
  bool fail = true;

  @override
  Future<void> remove(String uid, WorkoutRecord record) {
    if (fail) throw const FileSystemException('파일 정리 실패');
    return super.remove(uid, record);
  }
}
