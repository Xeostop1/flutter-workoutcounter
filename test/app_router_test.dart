import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/app_router.dart';

void main() {
  test('로그인 전에도 법률 문서를 열 수 있다', () {
    expect(
      redirectForAuth(
        authReady: true,
        signedIn: false,
        onboardingDone: false,
        location: '/legal/privacy',
      ),
      isNull,
    );
    expect(
      redirectForAuth(
        authReady: true,
        signedIn: false,
        onboardingDone: false,
        location: '/home',
      ),
      '/login',
    );
  });

  test('인증 복원이 끝날 때까지 랜딩 화면을 유지한다', () {
    expect(
      redirectForAuth(
        authReady: false,
        signedIn: false,
        onboardingDone: false,
        location: '/home',
      ),
      '/landing',
    );
    expect(
      redirectForAuth(
        authReady: false,
        signedIn: false,
        onboardingDone: false,
        location: '/landing',
      ),
      isNull,
    );
  });
}
