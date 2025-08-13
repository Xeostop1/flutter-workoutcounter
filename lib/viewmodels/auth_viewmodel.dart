import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// 앱 첫 실행/온보딩 스킵 상태를 관리하는 최소 ViewModel.
/// - 지금은 소셜 로그인 연동 전이므로 isLoggedIn은 항상 false로 둔다.
/// - 나중에 Firebase Auth를 붙이면 isLoggedIn, signInWithGoogle/Apple만 구현하면 된다.
class AuthViewModel extends ChangeNotifier {
  final StorageService storage;

  AuthViewModel({required this.storage});

  /// (선택) 첫 실행 여부. 첫 실행이면 true였다가 bootstrap에서 false로 바뀜.
  bool firstOpen = true;

  /// 이 디바이스에서 온보딩을 스킵했는지 여부
  bool onboardingSkippedDevice = false;

  /// 로그인 상태(지금은 로그인 기능 미구현이므로 false로 유지)
  bool isLoggedIn = false;

  /// 앱 시작 시 호출. 스플래시에서 한 번 실행해주면 된다.
  Future<void> bootstrap() async {
    // firstOpen 플래그 갱신
    final already = await storage.getFirstOpenDone();
    if (!already) {
      await storage.setFirstOpenDone();
      firstOpen = true;
    } else {
      firstOpen = false;
    }

    // 온보딩 스킵 플래그 로드
    onboardingSkippedDevice = await storage.getOnboardingSkipped();

    notifyListeners();
  }

  /// 온보딩 "건너뛰기" 혹은 "시작하기" 버튼에서 호출.
  Future<void> skipOnboarding() async {
    onboardingSkippedDevice = true;
    await storage.setOnboardingSkipped(true);
    notifyListeners();
  }

  // === 추후 확장용: 소셜 로그인 연동 시 여기에 구현 ===
  // Future<void> signInWithGoogle() async { ... }
  // Future<void> signInWithApple() async { ... }
  // Future<void> logout() async { ... }
}
