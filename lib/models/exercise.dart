class Exercise {
  final String id; // UUID
  final String name;
  final int sets;
  final int reps;
  final int repSeconds; // 1회당 걸리는 초

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.repSeconds,
  });

  Exercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    int? repSeconds,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      repSeconds: repSeconds ?? this.repSeconds,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'repSeconds': repSeconds,
  };

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
    id: m['id'] as String,
    name: m['name'] as String,
    sets: m['sets'] as int,
    reps: m['reps'] as int,
    repSeconds: m['repSeconds'] as int,
  );
}
