import '../models/workout_record.dart';

abstract class RecordRepository {
  List<WorkoutRecord> byDate(DateTime day);
  void add(WorkoutRecord record);
  bool hasAnyOn(DateTime day);
  Iterable<DateTime> allDays();
}

// 메모리 저장소(나중에 Firestore로 교체)
class MemoryRecordRepository implements RecordRepository {
  final Map<DateTime, List<WorkoutRecord>> _byDate = {};
  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<WorkoutRecord> byDate(DateTime day) => _byDate[_key(day)]?.toList() ?? [];

  @override
  void add(WorkoutRecord record) {
    final k = _key(record.date);
    _byDate.putIfAbsent(k, () => []);
    _byDate[k]!.add(record);
  }

  @override
  bool hasAnyOn(DateTime day) => byDate(day).isNotEmpty;

  @override
  Iterable<DateTime> allDays() => _byDate.keys;
}
