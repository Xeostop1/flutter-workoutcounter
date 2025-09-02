import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';
import '../repositories/record_repository.dart';

class RecordsViewModel extends ChangeNotifier {
  final RecordRepository _repo;
  RecordsViewModel(this._repo) { _load(); }

  final List<WorkoutRecord> _records = [];

  Future<void> _load() async {
    final all = await _repo.loadAll();   // ✅ 레포에 존재
    _records..clear()..addAll(all);
    notifyListeners();
  }

  Future<void> addRecord(WorkoutRecord r) async {
    await _repo.save(r);                 // ✅ 레포에 존재
    _records.add(r);
    notifyListeners();
  }

  Iterable<DateTime> allDays() sync* {
    final seen = <String>{};
    for (final r in _records) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      final k = '${d.year}-${d.month}-${d.day}';
      if (seen.add(k)) yield d;
    }
  }

  bool hasAnyOn(DateTime day) =>
      _records.any((r) => _sameDay(r.date, day));

  List<WorkoutRecord> recordsOn(DateTime day) =>
      _records.where((r) => _sameDay(r.date, day)).toList();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
