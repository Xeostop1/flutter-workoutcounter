import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final StorageService storage;

  AuthViewModel({required this.storage});

  bool firstOpen = true;
  bool onboardingSkippedDevice = false;

  // ✅ 디폴트는 false지만, fakeSignIn()으로 true로 바꿔 사용
  bool isLoggedIn = false;

  Future<void> bootstrap() async {
    final already = await storage.getFirstOpenDone();
    if (!already) {
      await storage.setFirstOpenDone();
      firstOpen = true;
    } else {
      firstOpen = false;
    }
    onboardingSkippedDevice = await storage.getOnboardingSkipped();
    notifyListeners();
  }

  Future<void> skipOnboarding() async {
    onboardingSkippedDevice = true;
    await storage.setOnboardingSkipped(true);
    notifyListeners();
  }

  // 🔹 여기가 추가: 로그인 구현 전 임시용 가짜 로그인
  Future<void> fakeSignIn() async {
    isLoggedIn = true;
    notifyListeners();
  }

  // (참고) 나중에 실제 구현 시
  // Future<void> signInWithGoogle() async { ... }
  // Future<void> signInWithApple() async { ... }
  // Future<void> logout() async { ... }
}
