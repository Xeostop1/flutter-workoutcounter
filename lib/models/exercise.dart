class Exercise {
  final String id;   //uuid 사용
  final String name;
  final int reps;
  final int sets;
  final int repSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.reps,
    required this.sets,
    required this.repSeconds,
  });
}
