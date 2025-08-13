class WorkoutRecord {
  final String id; // routineId + timestamp
  final String routineId;
  final String routineName;
  final DateTime date; // 완료 시각
  final int doneSets;
  final int doneRepsTotal; // 전체 수행 횟수

  WorkoutRecord({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.doneSets,
    required this.doneRepsTotal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'routineName': routineName,
    'date': date.toIso8601String(),
    'doneSets': doneSets,
    'doneRepsTotal': doneRepsTotal,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) => WorkoutRecord(
    id: j['id'],
    routineId: j['routineId'],
    routineName: j['routineName'],
    date: DateTime.parse(j['date']),
    doneSets: j['doneSets'],
    doneRepsTotal: j['doneRepsTotal'],
  );
}
