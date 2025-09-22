import '../models/workout_record.dart';

class StorageRepository {
  final Map<DateTime, List<WorkoutRecord>> _byDate = {};

  List<WorkoutRecord> getByDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _byDate[d]?.toList() ?? [];
  }

  void addRecord(WorkoutRecord r) {
    final d = DateTime(r.date.year, r.date.month, r.date.day);
    _byDate.putIfAbsent(d, () => []);
    _byDate[d]!.add(r);
  }

  bool hasAnyOn(DateTime day) => getByDate(day).isNotEmpty;
}
