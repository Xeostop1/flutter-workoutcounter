import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';
import '../repositories/record_repository.dart';

class RecordsViewModel extends ChangeNotifier {
  final RecordRepository _repo;
  RecordsViewModel(this._repo) {
    _load();
  }

  final List<WorkoutRecord> _records = [];

  // ----- ⬇️ 달력/선택 상태 -----
  DateTime _selectedDay = _strip(DateTime.now());
  DateTime _focusedDay  = _strip(DateTime.now());

  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay  => _focusedDay;

  /// 달력에서 날짜 선택
  void selectDay(DateTime day) {
    _selectedDay = _strip(day);
    _focusedDay  = _selectedDay;
    notifyListeners();
  }

  /// 선택된 날짜의 기록 리스트
  List<WorkoutRecord> recordsOfSelected() => recordsOn(_selectedDay);
  // --------------------------------

  Future<void> _load() async {
    final all = await _repo.loadAll();
    _records
      ..clear()
      ..addAll(all);
    notifyListeners();
  }

  Future<void> addRecord(WorkoutRecord r) async {
    await _repo.save(r);
    _records.add(r);
    notifyListeners();
  }

  // 기록이 있는 모든 날짜(중복 제거)
  Iterable<DateTime> allDays() sync* {
    final seen = <String>{};
    for (final r in _records) {
      final d = _strip(r.date);
      final k = '${d.year}-${d.month}-${d.day}';
      if (seen.add(k)) yield d;
    }
  }

  bool hasAnyOn(DateTime day) =>
      _records.any((r) => _sameDay(r.date, day));

  List<WorkoutRecord> recordsOn(DateTime day) =>
      _records.where((r) => _sameDay(r.date, day)).toList();

  static DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
