import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';
import '../repositories/record_repository.dart';

class RecordViewModel extends ChangeNotifier {
  final RecordRepository repo;
  RecordViewModel(this.repo);

  List<WorkoutRecord> _all = [];
  List<WorkoutRecord> get all => _all;

  Future<void> load() async {
    _all = await repo.loadAll();
    _all.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// 카운터 완료 시 호출
  Future<void> saveWorkout({
    required DateTime dateTime,
    required String routineId,
    required String routineName,
    required int sets,
    required int repsPerSet,
    required int durationSec,
  }) async {
    final id = '${routineId}_${dateTime.millisecondsSinceEpoch}';
    final rec = WorkoutRecord(
      id: id,
      routineId: routineId,
      routineName: routineName,
      date: dateTime,
      doneSets: sets,
      doneRepsTotal: sets * repsPerSet,
      durationSec: durationSec,
    );

    await repo.add(rec);
    _all.insert(0, rec);
    notifyListeners();
  }

  List<WorkoutRecord> byDate(DateTime d) {
    return _all.where((r) => _sameDay(r.date, d)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool didWorkout(DateTime d) => _all.any((r) => _sameDay(r.date, d));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isRoutineDoneOn(String routineId, DateTime day) {
    return _all.any(
      (r) =>
          r.routineId == routineId &&
          r.date.year == day.year &&
          r.date.month == day.month &&
          r.date.day == day.day,
    );
  }
}
