import 'package:flutter/foundation.dart';

import '../models/workout_record.dart';

class StreakViewModel extends ChangeNotifier {
  int _day = 0;
  int get day => _day;

  int get flameStage => _stageFromDay(_day);

  void syncWorkoutRecords(Iterable<WorkoutRecord> records, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final workoutDays = records
        .where(
          (record) => record.kind == RecordKind.workout && record.totalReps > 0,
        )
        .map((record) => _dateOnly(record.date))
        .where((date) => !date.isAfter(today))
        .toSet();

    var nextDay = 0;
    if (workoutDays.isNotEmpty) {
      final lastWorkout = workoutDays.reduce(
        (latest, date) => date.isAfter(latest) ? date : latest,
      );
      final completedRestDays = (today.difference(lastWorkout).inDays - 1)
          .clamp(0, 1 << 30);
      nextDay = (workoutDays.length - completedRestDays)
          .clamp(-2, 1 << 30)
          .toInt();
    }

    if (_day == nextDay) return;
    _day = nextDay;
    notifyListeners();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _stageFromDay(int day) {
    if (day <= -2) return -2;
    if (day == -1) return -1;
    if (day <= 0) return 0;

    const thresholds = [1, 3, 5, 10, 15, 20, 30, 40, 50, 60, 70];

    var stage = 0;
    for (var i = 0; i < thresholds.length; i++) {
      if (day >= thresholds[i]) {
        stage = i;
      } else {
        break;
      }
    }
    return stage;
  }
}
