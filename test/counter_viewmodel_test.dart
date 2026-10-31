import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';

void main() {
  testWidgets('운동 횟수는 설정한 간격마다 한 번 증가한다', (tester) async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'routine',
          title: '테스트',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'exercise',
              name: '스쿼트',
              sets: 1,
              reps: 2,
              repSeconds: 1,
            ),
          ],
        ),
      );

    counter.setRestSeconds(0);
    expect(counter.restSeconds, 1);
    counter.setRestSeconds(3);

    counter.startPause();
    expect(counter.setSecondsLeft, 2);
    await tester.pump(const Duration(milliseconds: 1050));

    expect(counter.repNow, 1);
    expect(counter.setSecondsLeft, 1);

    await tester.pump(const Duration(seconds: 3));
    expect(counter.workoutCompleted, isTrue);
    expect(counter.workoutEndedEarly, isFalse);
    await tester.pump();
    expect(records.records.single.totalReps, 2);
    expect(
      records.recordsOn(DateTime.now()).single.exercises.single.name,
      '스쿼트',
    );

    counter.consumeWorkoutCompletion();
    expect(counter.workoutCompleted, isFalse);
    counter.dispose();
  });

  testWidgets('앞 운동을 건너뛰고 마지막 운동을 끝내면 완료한 횟수만 저장한다', (tester) async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'skipped-routine',
          title: '운동 건너뛰기',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'skipped',
              name: '스쿼트',
              sets: 2,
              reps: 10,
              repSeconds: 1,
            ),
            Exercise(
              id: 'completed',
              name: '푸시업',
              sets: 1,
              reps: 2,
              repSeconds: 1,
            ),
          ],
        ),
      )
      ..selectExercise(1)
      ..startPause();
    addTearDown(counter.dispose);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(counter.exerciseDone, [false, true]);
    expect(records.records.single.totalReps, 2);
    expect(counter.workoutCompleted, isFalse);
    expect(counter.workoutEndedEarly, isTrue);
  });

  testWidgets('운동을 바꿨다가 돌아와도 횟수를 이어가고 합계를 저장한다', (tester) async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'switch-routine',
          title: '운동 전환',
          categoryId: 'test',
          items: [
            Exercise(id: 'first', name: '스쿼트', sets: 2, reps: 2, repSeconds: 1),
            Exercise(
              id: 'second',
              name: '푸시업',
              sets: 1,
              reps: 2,
              repSeconds: 1,
            ),
          ],
        ),
      )
      ..startPause();
    addTearDown(counter.dispose);

    await tester.pump(const Duration(milliseconds: 1050));
    counter.selectExercise(0);
    expect(counter.repNow, 1);
    expect(counter.isRunning, isTrue);

    counter.selectExercise(1);
    expect(counter.totalRepsDoneSoFar, 1);
    counter.startPause();
    await tester.pump(const Duration(milliseconds: 1050));
    counter.selectExercise(0);

    expect(counter.repNow, 1);
    expect(counter.setNow, 1);
    expect(counter.totalRepsDoneSoFar, 2);
    expect(counter.isRunning, isFalse);
    counter.startPause();
    await tester.pump(const Duration(milliseconds: 1050));

    expect(await counter.finishNowAndRecord(), isTrue);
    expect(records.records.single.totalReps, 3);
  });

  for (final elapsedMs in [1050, 2100]) {
    testWidgets('세트 경계 ${elapsedMs}ms에 전환해도 다음 세트와 완료 합계를 유지한다', (
      tester,
    ) async {
      final records = RecordsViewModel(InMemoryRecordRepository());
      final counter = CounterViewModel(records)
        ..attachRoutine(
          const Routine(
            id: 'boundary-routine',
            title: '세트 경계 전환',
            categoryId: 'test',
            items: [
              Exercise(
                id: 'first',
                name: '스쿼트',
                sets: 2,
                reps: 1,
                repSeconds: 1,
              ),
              Exercise(
                id: 'second',
                name: '푸시업',
                sets: 1,
                reps: 1,
                repSeconds: 1,
              ),
            ],
          ),
        )
        ..setRestSeconds(1)
        ..startPause();
      addTearDown(counter.dispose);

      await tester.pump(Duration(milliseconds: elapsedMs));
      counter
        ..selectExercise(1)
        ..selectExercise(0);

      expect(counter.setNow, 2);
      expect(counter.repNow, 0);
      expect(counter.totalRepsDoneSoFar, 1);
      counter.startPause();
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();

      expect(counter.workoutCompleted, isTrue);
      expect(records.records.single.totalReps, 3);
    });
  }

  testWidgets('기록 저장 실패 시 완료 처리하지 않고 재시도한다', (tester) async {
    final repository = _FailOnceRecordRepository();
    final records = RecordsViewModel(repository);
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'retry-routine',
          title: '재시도 테스트',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'exercise',
              name: '스쿼트',
              sets: 1,
              reps: 1,
              repSeconds: 1,
            ),
          ],
        ),
      );

    counter.startPause();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(counter.workoutCompleted, isFalse);
    expect(counter.workoutSaveFailed, isTrue);
    expect(counter.hasPendingWorkout, isTrue);
    expect(records.recordsOn(DateTime.now()), isEmpty);

    await counter.retryWorkoutSave();

    expect(repository.attempts, 2);
    expect(counter.workoutCompleted, isTrue);
    expect(counter.workoutSaveFailed, isFalse);
    expect(counter.hasPendingWorkout, isFalse);
    expect(records.recordsOn(DateTime.now()), hasLength(1));
    counter.dispose();
  });

  testWidgets('중간 종료 저장 중 카운터를 멈추고 같은 기록으로 재시도한다', (tester) async {
    final firstSave = Completer<void>();
    final repository = _FailOnceRecordRepository(firstSave: firstSave);
    final records = RecordsViewModel(repository);
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'stop-routine',
          title: '중간 종료 테스트',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'exercise',
              name: '스쿼트',
              sets: 1,
              reps: 10,
              repSeconds: 1,
            ),
          ],
        ),
      )
      ..startPause();

    await tester.pump(const Duration(milliseconds: 1050));

    final saving = counter.finishNowAndRecord();
    expect(counter.isSavingWorkout, isTrue);
    expect(counter.isRunning, isFalse);
    expect(counter.hasPendingWorkout, isTrue);
    expect(await counter.finishNowAndRecord(), isFalse);
    counter
      ..startPause()
      ..reset()
      ..selectExercise(0);
    await tester.pump(const Duration(seconds: 15));
    expect(repository.attempts, 1);
    expect(counter.isRunning, isFalse);
    expect(counter.hasPendingWorkout, isTrue);

    firstSave.complete();
    await tester.pump();
    expect(await saving, isFalse);
    expect(records.records, isEmpty);
    expect(counter.workoutSaveFailed, isTrue);

    await counter.retryWorkoutSave();
    expect(repository.attempts, 2);
    expect(
      repository.attemptedRecords[0],
      same(repository.attemptedRecords[1]),
    );
    expect(counter.workoutEndedEarly, isTrue);
    expect(counter.workoutCompleted, isFalse);
    expect(counter.hasPendingWorkout, isFalse);
    expect(counter.isRunning, isFalse);
    expect(records.records, hasLength(1));
    expect(records.records.single.totalReps, 1);
    expect(await counter.finishNowAndRecord(), isTrue);
    expect(repository.attempts, 2);
    counter.dispose();
  });

  testWidgets('계정 전환 후 이전 저장 결과가 새 카운터를 완료시키지 않는다', (tester) async {
    final firstSave = Completer<void>();
    final records = RecordsViewModel(
      _FailOnceRecordRepository(firstSave: firstSave),
    )..bindAccount('a');
    final counter = CounterViewModel(records)
      ..bindAccount('a')
      ..attachRoutine(
        const Routine(
          id: 'account-switch',
          title: '계정 전환',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'squat',
              name: '스쿼트',
              sets: 1,
              reps: 10,
              repSeconds: 1,
            ),
          ],
        ),
      )
      ..startPause();
    addTearDown(counter.dispose);
    addTearDown(records.dispose);
    await tester.pump(const Duration(milliseconds: 1050));
    final saving = counter.finishNowAndRecord();
    records.bindAccount('b');
    counter.bindAccount('b');
    firstSave.complete();
    await tester.pump();
    await saving;

    expect(counter.hasPendingWorkout, isFalse);
    expect(counter.isSavingWorkout, isFalse);
    expect(counter.workoutSaveFailed, isFalse);
    expect(counter.workoutCompleted, isFalse);
    expect(counter.workoutEndedEarly, isFalse);
    expect(counter.routine, isNull);
    expect(records.records, isEmpty);
  });

  test('완료한 횟수가 없으면 중간 종료 기록을 만들지 않는다', () async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    final counter = CounterViewModel(records)
      ..attachRoutine(
        const Routine(
          id: 'empty-stop-routine',
          title: '0회 종료 테스트',
          categoryId: 'test',
          items: [
            Exercise(
              id: 'exercise',
              name: '스쿼트',
              sets: 1,
              reps: 10,
              repSeconds: 1,
            ),
          ],
        ),
      )
      ..startPause();

    expect(await counter.finishNowAndRecord(), isTrue);
    expect(records.records, isEmpty);
    expect(counter.isRunning, isFalse);
    counter.dispose();
  });

  testWidgets('세트와 운동 사이 휴식에서 진행 횟수와 다음 세트를 유지한다', (tester) async {
    final counter =
        CounterViewModel(RecordsViewModel(InMemoryRecordRepository()))
          ..attachRoutine(
            const Routine(
              id: 'multi-routine',
              title: '여러 운동',
              categoryId: 'test',
              items: [
                Exercise(
                  id: 'first',
                  name: '스쿼트',
                  sets: 2,
                  reps: 1,
                  repSeconds: 1,
                ),
                Exercise(
                  id: 'second',
                  name: '푸시업',
                  sets: 1,
                  reps: 1,
                  repSeconds: 1,
                ),
              ],
            ),
          )
          ..setRestSeconds(1)
          ..selectExercise(1);

    expect(counter.totalRepsDoneSoFar, 0);
    counter
      ..selectExercise(0)
      ..startPause();

    await tester.pump(const Duration(milliseconds: 2100));
    expect(counter.isResting, isTrue);
    expect(counter.totalRepsDoneSoFar, 1);

    await tester.pump(const Duration(milliseconds: 3200));
    expect(counter.exerciseIndex, 1);
    expect(counter.setNow, 1);
    expect(counter.totalRepsDoneSoFar, 2);
    counter.dispose();
  });
}

class _FailOnceRecordRepository implements RecordRepository {
  _FailOnceRecordRepository({this.firstSave});

  final Completer<void>? firstSave;
  int attempts = 0;
  final List<WorkoutRecord> attemptedRecords = [];
  final List<WorkoutRecord> _records = [];

  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async => _records;

  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    attempts++;
    attemptedRecords.add(record);
    if (attempts == 1) {
      if (firstSave != null) await firstSave!.future;
      throw StateError('첫 저장 실패');
    }
    _records.add(record);
  }
}
