import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';
import '../repositories/record_repository.dart';

class RecordsViewModel extends ChangeNotifier {
  final RecordRepository _repo;
  DateTime selectedDay = DateTime.now();

  RecordsViewModel(this._repo);

  List<WorkoutRecord> recordsOfSelected() => _repo.byDate(selectedDay);
  bool hasAnyOn(DateTime day) => _repo.hasAnyOn(day);
  void selectDay(DateTime day) { selectedDay = day; notifyListeners(); }
  void addRecord(WorkoutRecord r) { _repo.add(r); notifyListeners(); }
}
