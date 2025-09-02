import 'exercise.dart';

class Routine {
  final String id;               // UUID
  final String title;
  final String categoryId;       // ✅ 카테고리 UUID (FK)
  final List<Exercise> items;

  const Routine({
    required this.id,
    required this.title,
    required this.categoryId,    // ← 반드시 UUID로 저장
    this.items = const [],
  });

  // 대표 운동(없을 때 기본값)
  Exercise get primary => items.isNotEmpty
      ? items.first
      : const Exercise(id: 'EMPTY', name: '운동', reps: 10, sets: 2, repSeconds: 2);
}
