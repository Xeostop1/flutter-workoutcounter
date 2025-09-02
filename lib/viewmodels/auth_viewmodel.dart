import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  bool isSignedIn = false;

  // 온보딩 완료 여부(간단 버전: 메모리 변수)
  bool onboardingDone = false;

  AuthViewModel(this._repo) {
    // 로그인 상태 스트림 구독
    _repo.authStateChanges().listen((v) {
      isSignedIn = v;
      notifyListeners();
    });
  }

  // === 로그인/로그아웃 ===
  Future<void> signInWithGoogle() async => _repo.signInWithGoogle();
  Future<void> signInWithApple() async => _repo.signInWithApple();
  Future<void> signOut() async => _repo.signOut();
  Future<void> deleteAccount() async => _repo.deleteAccount();

  // 온보딩 스킵/완료 표시 ===
  Future<void> skipOnboarding() async {
    onboardingDone = true;   // 지금은 메모리에만 저장
    notifyListeners();
  }

  bool get shouldShowOnboarding => !onboardingDone;
}
