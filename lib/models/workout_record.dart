class WorkoutRecord {
  final DateTime date;
  final String routineId;   // **** String으로 변경
  final String routineTitle;
  final int totalReps;

  WorkoutRecord({
    required this.date,
    required this.routineId,
    required this.routineTitle,
    required this.totalReps,
  });
}
