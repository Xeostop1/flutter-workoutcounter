import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/viewmodels/streak_viewmodel.dart';

void main() {
  test('같은 날의 운동은 한 번만 세고 메모는 제외한다', () {
    final today = DateTime(2026, 8, 17);
    final viewModel = StreakViewModel();

    viewModel.syncWorkoutRecords([
      _workout(today.add(const Duration(hours: 8))),
      _workout(today.add(const Duration(hours: 20))),
      _workout(today.subtract(const Duration(days: 1))),
      _workout(today.subtract(const Duration(days: 2)), totalReps: 0),
      WorkoutRecord.memo(date: today, title: '메모'),
    ], now: today);

    expect(viewModel.day, 2);
    expect(viewModel.flameStage, 0);
  });

  test('Firestore 기록으로 단계를 복원하고 쉰 날만큼 감소한다', () {
    final today = DateTime(2026, 8, 17);
    final records = List.generate(
      70,
      (index) => _workout(today.subtract(Duration(days: index))),
    );
    final viewModel = StreakViewModel();

    viewModel.syncWorkoutRecords(records, now: today);
    expect(viewModel.day, 70);
    expect(viewModel.flameStage, 10);

    viewModel.syncWorkoutRecords(
      records,
      now: today.add(const Duration(days: 3)),
    );
    expect(viewModel.day, 68);
    expect(viewModel.flameStage, 9);
  });
}

WorkoutRecord _workout(DateTime date, {int totalReps = 10}) => WorkoutRecord(
  date: date,
  routineId: 'routine',
  routineTitle: '운동',
  totalReps: totalReps,
);
