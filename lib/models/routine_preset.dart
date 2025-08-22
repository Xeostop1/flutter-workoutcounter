class RoutinePreset {
  final String id; // 기록 저장/완료 표시용 키
  final String name; // 표시명 (예: 스쿼트)
  final int sets;
  final int reps;
  final double secPerRep;
  final int restSec;

  RoutinePreset({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.secPerRep = 2.0,
    this.restSec = 10,
  });
}
