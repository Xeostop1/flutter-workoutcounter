import '../services/storage_service.dart';
import '../models/workout_record.dart';

class RecordRepository {
  final StorageService storage;
  RecordRepository(this.storage);

  Future<List<WorkoutRecord>> loadAll() async {
    final raw = await storage.readList(StorageService.recordsKey);
    final list = raw.map(WorkoutRecord.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> add(WorkoutRecord rec) async {
    final raw = await storage.readList(StorageService.recordsKey);
    raw.add(rec.toJson());
    await storage.writeList(StorageService.recordsKey, raw);
  }

  Future<void> addAll(List<WorkoutRecord> items) async {
    final raw = await storage.readList(StorageService.recordsKey);
    raw.addAll(items.map((e) => e.toJson()));
    await storage.writeList(StorageService.recordsKey, raw);
  }

  Future<void> clear() async {
    await storage.writeList(StorageService.recordsKey, []);
  }
}
