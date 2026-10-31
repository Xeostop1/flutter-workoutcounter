import 'dart:async';

import 'package:counter_01/pages/auth/login_page.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/user_settings_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/Pretendard/Pretendard-$weight.ttf'),
      );
    }
    await font.load();
  });
  testWidgets('로그인 제목의 크기 차이와 Google 우선 순서를 유지한다', (tester) async {
    await _pumpLogin(tester, _LoginRepository());
    final intro = tester.widget<Text>(find.text('마음 속 작은 불씨를 살려'));
    final headline = tester.widget<Text>(find.text('건강한 운동습관 만들기'));
    final hint = tester.widget<Text>(find.text('로그인 없이 시작하거나 계정으로 로그인해주세요'));
    expect(intro.style!.fontSize, 16);
    expect(headline.style!.fontSize, greaterThan(23.5));
    expect(hint.style!.fontSize, 12);
    expect(
      tester.getTopLeft(find.text('Google 로그인')).dy,
      lessThan(tester.getTopLeft(find.text('Apple 로그인')).dy),
    );
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(375, 740),
    const Size(375, 812),
    const Size(430, 932),
  ]) {
    testWidgets('$size: 기본 글자는 스크롤 없이 로그인 버튼을 모두 표시한다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpLogin(tester, _LoginRepository(), revealGoogle: false);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, 0);
      final artwork = tester.getSize(find.byKey(const ValueKey('login-flame')));
      final minimumWidth = size.width == 320
          ? 144.0
          : size.height < 700
          ? 232.0
          : 300.0;
      expect(artwork.width, greaterThanOrEqualTo(minimumWidth));
      expect(artwork.width, lessThanOrEqualTo(size.width - 32));
      expect(artwork.height, closeTo(artwork.width * 5 / 6, 0.01));
      for (final label in ['Apple 로그인', 'Google 로그인']) {
        expect(find.text(label).hitTestable(), findsOneWidget);
        final rect = tester.getRect(find.widgetWithText(ElevatedButton, label));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 34));
      }
      expect(find.text('로그인 없이 시작하기').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('LOGIN_UI_PREVIEWS')) {
        await expectLater(
          find.byKey(const ValueKey('login-preview')),
          matchesGoldenFile(
            '../verification/guest-mode-20261031/login-${size.width.toInt()}x${size.height.toInt()}.png',
          ),
        );
      }
    });
  }
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$platform: 작은 화면, 글자 $scale배에서 플랫폼별 로그인 표시', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        try {
          await _pumpLogin(tester, _LoginRepository(), textScale: scale);
          expect(find.text('Apple 로그인'), findsOneWidget);
          expect(find.text('Google 로그인'), findsOneWidget);
          expect(find.byType(ElevatedButton), findsNWidgets(2));
          await tester.ensureVisible(find.text('Google 로그인'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform: Apple 로그인 중 Google 중복 요청을 막고 취소 후 재시도한다', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final repository = _LoginRepository();
        await _pumpLogin(tester, repository);
        await tester.ensureVisible(find.text('Apple 로그인'));
        await tester.tap(find.text('Apple 로그인'));
        await tester.tap(find.text('Google 로그인'));
        await tester.pump();
        expect(repository.appleCalls, 1);
        expect(repository.googleCalls, 0);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester
              .widgetList<ElevatedButton>(find.byType(ElevatedButton))
              .every((button) => button.onPressed == null),
          isTrue,
        );
        repository.request.complete();
        await tester.pumpAndSettle();
        repository.request = Completer<void>();
        await tester.ensureVisible(find.text('Google 로그인'));
        await tester.tap(find.text('Google 로그인'));
        expect(repository.googleCalls, 1);
        repository.request.complete();
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('$platform: Apple 로그인 실패 후 두 로그인 버튼을 복구한다', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final repository = _LoginRepository();
        await _pumpLogin(tester, repository);
        await tester.ensureVisible(find.text('Apple 로그인'));
        await tester.tap(find.text('Apple 로그인'));
        repository.request.completeError(StateError('test failure'));
        await tester.pumpAndSettle();
        expect(find.text('애플 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
        expect(
          tester
              .widgetList<ElevatedButton>(find.byType(ElevatedButton))
              .every((button) => button.onPressed != null),
          isTrue,
        );
        expect(repository.appleCalls, 1);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  for (final entry in {
    'operation-not-allowed': 'Apple 로그인 설정을 확인해야 해요. 운영자에게 문의해주세요.',
    'invalid-oauth-client-id': 'Apple 로그인 설정을 확인해야 해요. 운영자에게 문의해주세요.',
    'account-exists-with-different-credential':
        '다른 로그인 방식으로 가입된 계정이에요. 기존 로그인 방법을 사용해주세요.',
    'network-request-failed': '네트워크 연결을 확인한 뒤 Apple 로그인을 다시 시도해주세요.',
  }.entries) {
    testWidgets('Apple ${entry.key} 오류를 구체적으로 안내한다', (tester) async {
      final repository = _LoginRepository();
      await _pumpLogin(tester, repository);
      await tester.ensureVisible(find.text('Apple 로그인'));
      await tester.tap(find.text('Apple 로그인'));
      repository.request.completeError(FirebaseAuthException(code: entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Google 로그인 중 중복 요청을 막고 취소 후 다시 시도한다', (tester) async {
    final repository = _LoginRepository();
    await _pumpLogin(tester, repository);
    await tester.tap(find.text('Google 로그인'));
    await tester.tap(find.text('Google 로그인'));
    await tester.pump();
    expect(repository.googleCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Google 로그인'),
          )
          .onPressed,
      isNull,
    );

    // 실제 Google 저장소는 계정 선택 취소 시 정상 반환한다.
    repository.request.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    repository.request = Completer<void>();
    await tester.tap(find.text('Google 로그인'));
    expect(repository.googleCalls, 2);
    repository.request.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Google 로그인 실패를 안내하고 재시도 버튼을 활성화한다', (tester) async {
    final repository = _LoginRepository();
    await _pumpLogin(tester, repository);
    await tester.tap(find.text('Google 로그인'));
    repository.request.completeError(StateError('test failure'));
    await tester.pumpAndSettle();
    expect(find.text('구글 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Google 로그인'),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google 로그인 대기 중 화면이 닫혀도 setState 오류가 없다', (tester) async {
    final repository = _LoginRepository();
    await _pumpLogin(tester, repository);
    await tester.tap(find.text('Google 로그인'));
    await tester.pumpWidget(const SizedBox.shrink());
    repository.request.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLogin(
  WidgetTester tester,
  _LoginRepository repository, {
  double textScale = 1,
  bool revealGoogle = true,
}) async {
  final viewModel = AuthViewModel(repository, settingsRepo: _UnusedSettings());
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
            disableAnimations: true,
          ),
          child: RepaintBoundary(
            key: const ValueKey('login-preview'),
            child: child!,
          ),
        ),
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(LoginPage));
    await precacheImage(
      const AssetImage('assets/images/login_flame_still.png'),
      context,
    );
  });
  await tester.pumpAndSettle();
  if (revealGoogle) {
    await tester.ensureVisible(find.text('Google 로그인'));
    await tester.pumpAndSettle();
  }
}

class _LoginRepository implements AuthRepository {
  int googleCalls = 0;
  int appleCalls = 0;
  Completer<void> request = Completer<void>();

  @override
  Future<void> signInWithApple() {
    appleCalls++;
    return request.future;
  }

  @override
  Future<void> signInWithGoogle() {
    googleCalls++;
    return request.future;
  }

  @override
  Stream<AppUser?> userChanges() => const Stream.empty();

  @override
  AppUser? currentUser() => null;

  @override
  bool onboardingDone = false;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class _UnusedSettings implements UserSettingsRepository {
  @override
  Future<Map<String, dynamic>?> load(String uid) async => null;

  @override
  Future<void> update(
    String uid, {
    bool? onboardingDone,
    int? weeklyTarget,
    bool? homeTutorialDone,
    bool? voiceCountingEnabled,
    double? voicePitch,
    String? trainerVoiceId,
    String? systemVoiceId,
    TargetPlatform? systemVoicePlatform,
    int? restSeconds,
    String? name,
  }) async {}
}
