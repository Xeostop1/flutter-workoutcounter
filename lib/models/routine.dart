import 'exercise.dart';

class Routine {
  final String id; // UUID
  final String title;
  final String categoryId; // 카테고리 UUID (FK)
  final List<Exercise> items;

  const Routine({
    required this.id,
    required this.title,
    required this.categoryId,
    this.items = const [],
  });

  // 대표 운동(없을 때 기본값)
  Exercise get primary => items.isNotEmpty
      ? items.first
      : const Exercise(
          id: 'EMPTY',
          name: '운동',
          sets: 2,
          reps: 10,
          repSeconds: 2,
        );

  Routine copyWith({
    String? id,
    String? title,
    String? categoryId,
    List<Exercise>? items,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'categoryId': categoryId,
    'items': items.map((e) => e.toMap()).toList(),
  };

  factory Routine.fromMap(Map<String, dynamic> m) => Routine(
    id: m['id'] as String,
    title: m['title'] as String,
    categoryId: m['categoryId'] as String,
    items: (m['items'] as List<dynamic>? ?? const [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .toList(),
  );
}
