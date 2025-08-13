import '../models/workout_record.dart';
import '../services/storage_service.dart';

class RecordRepository {
  final StorageService storage;
  RecordRepository(this.storage);

  Future<List<WorkoutRecord>> load() async {
    final list = await storage.readList(StorageService.recordsKey);
    return list.map(WorkoutRecord.fromJson).toList();
  }

  Future<void> saveAll(List<WorkoutRecord> items) async => storage.writeList(
    StorageService.recordsKey,
    items.map((e) => e.toJson()).toList(),
  );
}
