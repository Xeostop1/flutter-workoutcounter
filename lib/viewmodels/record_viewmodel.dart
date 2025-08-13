import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';
import '../repositories/record_repository.dart';

class RecordViewModel extends ChangeNotifier {
  final RecordRepository repo;
  List<WorkoutRecord> records = [];

  RecordViewModel(this.repo);

  Future<void> load() async {
    records = await repo.load();
    notifyListeners();
  }

  Future<void> add(WorkoutRecord r) async {
    records = [...records, r];
    await repo.saveAll(records);
    notifyListeners();
  }

  List<WorkoutRecord> byDate(DateTime day) {
    final ymd = DateTime(day.year, day.month, day.day);
    return records.where((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return d == ymd;
    }).toList();
  }

  bool didWorkout(DateTime day) => byDate(day).isNotEmpty;
}
