import '../models/routine.dart';
import '../services/storage_service.dart';

class RoutineRepository {
  final StorageService storage;
  RoutineRepository(this.storage);

  Future<List<Routine>> load() async {
    final list = await storage.readList(StorageService.routinesKey);
    if (list.isEmpty) {
      // 초기 예시 데이터
      final seed = [
        Routine(id: 'lower', name: '하체', sets: 3, reps: 15, secPerRep: 2),
        Routine(id: 'back', name: '등', sets: 3, reps: 12, secPerRep: 2),
      ];
      await saveAll(seed);
      return seed;
    }
    return list.map(Routine.fromJson).toList();
  }

  Future<void> saveAll(List<Routine> items) async => storage.writeList(
    StorageService.routinesKey,
    items.map((e) => e.toJson()).toList(),
  );
}
