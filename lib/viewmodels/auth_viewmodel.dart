// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo);
  final AuthRepository _repo;

  // --- Auth state ---
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  // --- Onboarding state ---
  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  // --- Profile (UI에서 읽음) ---
  String? _displayName;
  String? get displayName => _displayName;

  String? _photoUrl; // ✅ RecordsPage에서 읽는 필드
  String? get photoUrl => _photoUrl;

  // --- User preference (예: 주간 목표) ---
  int? _weeklyTarget;
  int? get weeklyTarget => _weeklyTarget;

  // ====== Actions ======

  // 로그인(테스트용 더미 구현: 레포 실제 메서드가 없더라도 컴파일되도록 처리)
  Future<void> signInWithGoogle() async {
    _signedIn = true;
    _displayName ??= '스포클 사용자';
    // _photoUrl 에 네트워크 이미지 URL을 저장해도 됨. 없으면 null 유지(아바타 위젯에서 처리).
    notifyListeners();
  }

  Future<void> signInWithApple() async {
    _signedIn = true;
    _displayName ??= '스포클 사용자';
    notifyListeners();
  }

  Future<void> signOut() async {
    _signedIn = false;
    notifyListeners();
  }

  // 온보딩 완료/미완료 설정
  void setOnboardingDone(bool value) {
    _onboardingDone = value;
    notifyListeners();
  }

  // 주간 목표 저장(온보딩 3단계 등에서 호출)
  void setWeeklyTarget(int? value) {
    _weeklyTarget = value;
    notifyListeners();
  }

  // 프로필 업데이트(원하면 로그인 직후나 설정 화면에서 호출)
  void updateProfile({String? name, String? photoUrl}) {
    if (name != null) _displayName = name;
    if (photoUrl != null) _photoUrl = photoUrl;
    notifyListeners();
  }

  /// 계정 삭제(현재는 더미 구현: 앱 상태 초기화 + 로그아웃)
  Future<void> deleteAccount() async {
    // 실제 구현이 생기면 여기서 _repo.deleteAccount() 등을 호출하세요.
    _signedIn = false;
    _onboardingDone = false;
    _displayName = null;
    _photoUrl = null;
    _weeklyTarget = null;
    notifyListeners();
  }
}
