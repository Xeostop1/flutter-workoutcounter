import '../models/workout_record.dart';

/// 기록 저장소 인터페이스 (나중에 DB로 교체할 때 이 인터페이스만 맞추면 됩니다)
abstract class RecordRepository {
  /// 모든 기록 불러오기
  Future<List<WorkoutRecord>> loadAll();

  /// 기록 1건 저장
  Future<void> save(WorkoutRecord record);
}

/// 간단한 인메모리 구현 (앱을 종료하면 사라짐)
class InMemoryRecordRepository implements RecordRepository {
  final List<WorkoutRecord> _data = [];

  @override
  Future<List<WorkoutRecord>> loadAll() async {
    // DB가 아니므로 바로 반환
    return List.unmodifiable(_data);
  }

  @override
  Future<void> save(WorkoutRecord record) async {
    _data.add(record);
  }
}
