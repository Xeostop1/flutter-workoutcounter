class Exercise {
  final String id; // UUID
  final String name;
  final int sets;
  final int reps;
  final int repSeconds; // 1회당 걸리는 초
  final bool isTransient; // *** 저장하지 않는 임시 객체 여부

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.repSeconds,
    this.isTransient = false, // ***
  });

  // *** 액션시트나 임시 프리셋용으로 쉽게 만드는 팩토리
  factory Exercise.adHoc({
    required String name,
    int sets = 3,
    int reps = 12,
    int repSeconds = 3,
    bool isTransient = true,
  }) {
    // *** 외부 의존 없이 임시 id 생성(프로덕션에선 uuid 패키지 권장)
    final tmpId = 'adhoc_${DateTime.now().millisecondsSinceEpoch}';
    return Exercise(
      id: tmpId,
      name: name,
      sets: sets,
      reps: reps,
      repSeconds: repSeconds,
      isTransient: isTransient,
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    int? repSeconds,
    bool? isTransient, // ***
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      repSeconds: repSeconds ?? this.repSeconds,
      isTransient: isTransient ?? this.isTransient, // ***
    );
  }

  // *** 총 운동 예상 시간(초): 세트 × 횟수 × 1회 시간
  int get totalSeconds => sets * reps * repSeconds; // ***

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'repSeconds': repSeconds,
    'isTransient': isTransient, // ***
  };

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
    id: m['id'] as String,
    name: m['name'] as String,
    sets: m['sets'] as int,
    reps: m['reps'] as int,
    repSeconds: m['repSeconds'] as int,
    isTransient: (m['isTransient'] as bool?) ?? false, // ***
  );
}
