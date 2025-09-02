// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/foundation.dart';

/// 아주 단순한(in-memory) 인증/온보딩 상태 보관용 VM
/// - 실제 로그인 연동 전까지는 가짜 로그인으로 동작
class AuthViewModel extends ChangeNotifier {
  bool _signedIn;
  bool _onboardingDone;

  AuthViewModel({
    bool startSignedIn = false,
    bool startOnboardingDone = false,
  })  : _signedIn = startSignedIn,
        _onboardingDone = startOnboardingDone;

  /// 로그인 여부
  bool get signedIn => _signedIn;

  /// 온보딩 완료 여부 (← 이제 이 이름만 씀)
  bool get onboardingDone => _onboardingDone;

  // ---------- 온보딩 ----------
  void setOnboardingDone(bool v) {
    if (_onboardingDone == v) return;
    _onboardingDone = v;
    notifyListeners();
  }

  /// 편의 메서드 (기존 코드 호환)
  void skipOnboarding() => setOnboardingDone(true);

  // ---------- 로그인/로그아웃 (가짜 구현) ----------
  Future<void> signInWithGoogle() async {
    _signedIn = true;
    notifyListeners();
  }

  Future<void> signInWithApple() async {
    _signedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _signedIn = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // 실제에선 서버/스토리지 정리 로직 필요
    _signedIn = false;
    notifyListeners();
  }
}
