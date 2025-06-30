
enum VoiceGender {
  male,
  female,
}

//모델
class WorkoutSettings{
  final String routineId;
  int totalSets, repeatCount;
  Duration breakTime;
  bool isCountdownOn;
  VoiceGender voiceGender;

  WorkoutSettings({
    required this.routineId,
    required this.totalSets,
    required this.repeatCount,
    required this.breakTime,
    required this.isCountdownOn,
    required this.voiceGender,
  });

//  일부 정보만 업데이트 이 값들로 복사하되, 주어진 값으로 바꿔줘
  WorkoutSettings copyWith({
    int? totalSets,
    int? repeatCount,
    Duration? breakTime,
    bool? isCountdownOn,
    VoiceGender? voiceGender,
  }) {
    return WorkoutSettings(
      routineId: routineId,
      totalSets: totalSets ?? this.totalSets,
      repeatCount: repeatCount ?? this.repeatCount,
      breakTime: breakTime ?? this.breakTime,
      isCountdownOn: isCountdownOn ?? this.isCountdownOn,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }
}