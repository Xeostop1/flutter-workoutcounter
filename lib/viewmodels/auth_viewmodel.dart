import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// 앱 첫 실행/온보딩 스킵 상태를 관리하는 ViewModel.
/// - 지금은 소셜 로그인 전이므로 isLoggedIn은 항상 false.
/// - Firebase Auth 연동 후 로그인 로직만 채우면 됨.
class AuthViewModel extends ChangeNotifier {
  final StorageService storage;

  AuthViewModel({required this.storage});

  /// 첫 실행이면 true였다가 bootstrap/load 이후 false로 갱신됨.
  bool firstOpen = true;

  /// 이 디바이스에서 온보딩을 스킵했는지
  bool onboardingSkippedDevice = false;

  /// 로그인 상태(지금은 미구현이므로 false 유지)
  bool isLoggedIn = false;

  /// 앱 시작 시 호출(스플래시에서 1번 실행)
  Future<void> bootstrap() async {
    // 첫 실행 여부 체크
    final already = await storage.getFirstOpenDone();
    if (!already) {
      firstOpen = true;
      await storage.setFirstOpenDone(); // 이후부터는 false가 되도록 저장
    } else {
      firstOpen = false;
    }

    // 온보딩 스킵 여부 로드
    onboardingSkippedDevice = await storage.getOnboardingSkipped();

    notifyListeners();
  }

  /// main.dart 호환용: load() -> bootstrap()
  Future<void> load() => bootstrap();

  /// 온보딩 "건너뛰기" / "시작하기"에서 호출
  Future<void> skipOnboarding() async {
    onboardingSkippedDevice = true;
    await storage.setOnboardingSkipped(true);
    notifyListeners();
  }

  /// (선택) 디버그 편의를 위한 초기화: 온보딩 다시 보이게
  Future<void> resetOnboardingForDebug() async {
    onboardingSkippedDevice = false;
    await storage.setOnboardingSkipped(false);
    notifyListeners();
  }

  // === 추후 소셜 로그인 연동 시 확장 포인트 ===
  // Future<void> signInWithGoogle() async { ... }
  // Future<void> signInWithApple() async { ... }
  // Future<void> logout() async { ... }
}
