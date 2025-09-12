class UserProfile {
  /// 인증 계정의 고유 ID (Firebase UID 등)
  final String uid;

  /// 표시 이름 / 이메일 / 아바타
  final String? name;
  final String? email;
  final String? photoUrl;

  /// 온보딩 완료 여부(앱 정책에 따라 로컬/원격에서 동기화 가능)
  final bool onboardingDone;

  /// 주간 목표(옵션)
  final int? weeklyTarget;

  const UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.onboardingDone = false,
    this.weeklyTarget,
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    bool? onboardingDone,
    int? weeklyTarget,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
    );
  }

  /// 로그아웃 상태 표현용
  static const empty = UserProfile(uid: '');

  bool get isEmpty => uid.isEmpty;
  bool get isNotEmpty => uid.isNotEmpty;
}
