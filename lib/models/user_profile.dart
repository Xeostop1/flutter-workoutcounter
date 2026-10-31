// lib/models/user_profile.dart

/// 앱의 계정/개인 설정을 모두 품는 사용자 프로필 모델.
/// (원격 DB/로컬 스토리지 양쪽 동기화 대상)
class UserProfile {
  final String uid;

  /// 표시 이름 / 이메일 / 아바타
  final String? name;
  final String? email;
  final String? photoUrl;

  /// 온보딩 완료 여부
  final bool onboardingDone;

  /// 주간 목표(옵션)
  final int? weeklyTarget;
  final bool homeTutorialDone;

  // =========================
  // 🔊 보이스 카운팅(TTS) 설정
  // =========================

  /// TTS 카운팅 사용 여부
  final bool voiceCountingEnabled;

  /// TTS 피치(저음~고음). FlutterTTS 권장 범위: 0.5 ~ 2.0
  final double voicePitch;
  final int restSeconds;

  const UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.onboardingDone = false,
    this.weeklyTarget,
    this.homeTutorialDone = false,
    this.voiceCountingEnabled = false,
    this.voicePitch = 1.0,
    this.restSeconds = 3,
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    bool? onboardingDone,
    int? weeklyTarget,
    bool? homeTutorialDone,
    bool? voiceCountingEnabled,
    double? voicePitch,
    int? restSeconds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      homeTutorialDone: homeTutorialDone ?? this.homeTutorialDone,
      voiceCountingEnabled: voiceCountingEnabled ?? this.voiceCountingEnabled,
      voicePitch: voicePitch ?? this.voicePitch,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'onboardingDone': onboardingDone,
    'weeklyTarget': weeklyTarget,
    'homeTutorialDone': homeTutorialDone,
    'voiceCountingEnabled': voiceCountingEnabled,
    'voicePitch': voicePitch,
    'restSeconds': restSeconds,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    name: json['name'] as String?,
    email: json['email'] as String?,
    photoUrl: json['photoUrl'] as String?,
    onboardingDone: (json['onboardingDone'] as bool?) ?? false,
    weeklyTarget: json['weeklyTarget'] as int?,
    homeTutorialDone: (json['homeTutorialDone'] as bool?) ?? false,
    voiceCountingEnabled: (json['voiceCountingEnabled'] as bool?) ?? false,
    voicePitch: (json['voicePitch'] as num?)?.toDouble() ?? 1.0,
    restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 3,
  );
}
