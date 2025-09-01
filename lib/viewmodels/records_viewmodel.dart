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

  // ✅ 공개 게터 추가: 페이지에서 사용할 수 있게
  Iterable<DateTime> allDays() => _repo.allDays();

  // (선택) 최초 기록일이 필요하면 이 헬퍼도 유용합니다.
  DateTime? firstRecordDay() {
    final list = allDays().toList()..sort();
    return list.isEmpty ? null : list.first;
  }
}
