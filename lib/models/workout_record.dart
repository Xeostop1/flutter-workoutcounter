import 'exercise.dart';

/// 기록 종류: 일반 운동 기록 / 메모(수동 입력)
enum RecordKind { workout, memo }

class WorkoutRecord {
  final DateTime date;
  final String routineId;
  final String routineTitle;
  final int totalReps;
  final List<Exercise> exercises;

  // 메모/수동 기록을 위한 확장 필드
  final String? memo;
  final RecordKind kind;

  const WorkoutRecord({
    required this.date,
    required this.routineId,
    required this.routineTitle,
    required this.totalReps,
    this.exercises = const [],
    this.memo,
    this.kind = RecordKind.workout,
  });

  /// 메모 전용 routineId 고정값
  static const String manualRoutineId = '_manual';

  /// 메모 전용 팩토리
  factory WorkoutRecord.memo({
    required DateTime date,
    required String title,
    String? memo,
  }) {
    final now = DateTime.now();
    return WorkoutRecord(
      date: DateTime(
        date.year,
        date.month,
        date.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
      ),
      routineId: manualRoutineId,
      routineTitle: title,
      totalReps: 0,
      exercises: const [],
      memo: memo,
      kind: RecordKind.memo,
    );
  }

  /// 불변 객체 편의 복사
  WorkoutRecord copyWith({
    DateTime? date,
    String? routineId,
    String? routineTitle,
    int? totalReps,
    List<Exercise>? exercises,
    String? memo,
    RecordKind? kind,
  }) {
    return WorkoutRecord(
      date: date ?? this.date,
      routineId: routineId ?? this.routineId,
      routineTitle: routineTitle ?? this.routineTitle,
      totalReps: totalReps ?? this.totalReps,
      exercises: exercises ?? this.exercises,
      memo: memo ?? this.memo,
      kind: kind ?? this.kind,
    );
  }

  // (선택) 직렬화가 필요하면 사용
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'routineId': routineId,
    'routineTitle': routineTitle,
    'totalReps': totalReps,
    'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    'memo': memo,
    'kind': kind.name,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutRecord(
      date: DateTime.parse(json['date'] as String),
      routineId: json['routineId'] as String,
      routineTitle: json['routineTitle'] as String,
      totalReps: json['totalReps'] as int,
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((value) => Exercise.fromMap(value as Map<String, dynamic>))
          .toList(),
      memo: json['memo'] as String?,
      kind: _parseKind(json['kind'] as String?),
    );
  }

  static RecordKind _parseKind(String? raw) {
    if (raw == null) return RecordKind.workout;
    return raw == 'memo' ? RecordKind.memo : RecordKind.workout;
  }
}
