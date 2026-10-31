import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:counter_01/app_router.dart';
import 'package:counter_01/pages/auth/login_page.dart';
import 'package:counter_01/pages/onboarding/onboarding_page.dart';
import 'package:counter_01/pages/settings/settings_page.dart';
import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/guest_store.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sporkle_guest_widget_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'test',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('로그인 없이 시작 버튼은 실제 게스트 세션을 만들고 온보딩으로 이동한다', (tester) async {
    final store = GuestStore(directory: () async => directory);
    final auth = AuthViewModel(_Auth(), guestStore: store);
    addTearDown(auth.dispose);
    await _pump(tester, auth, '/login');
    await tester.ensureVisible(find.text('로그인 없이 시작하기'));
    await tester.tap(find.text('로그인 없이 시작하기'));
    for (var i = 0; i < 100 && !auth.authReady; i++) {
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      });
    }
    await tester.pumpAndSettle();
    expect(auth.isGuest, isTrue);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('게스트 설정은 탈퇴를 숨기고 로그인 화면으로 연결한다', (tester) async {
    final store = GuestStore(directory: () async => directory);
    final auth = AuthViewModel(_Auth(), guestStore: store);
    addTearDown(auth.dispose);
    await tester.runAsync(() async {
      await auth.continueAsGuest();
      await auth.completeOnboarding(weeklyTarget: 3);
    });
    await _pump(tester, auth, '/settings');
    expect(find.text('회원탈퇴'), findsNothing);
    expect(find.text('로그아웃'), findsNothing);
    final login = find.text('로그인하고 기록 보관하기');
    await tester.scrollUntilVisible(login, 150);
    await tester.ensureVisible(login);
    await tester.pumpAndSettle();
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Google 로그인'), findsOneWidget);
    expect(find.text('Apple 로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('게스트 저장소를 열지 못하면 안내하고 다시 선택할 수 있다', (tester) async {
    final auth = AuthViewModel(
      _Auth(),
      guestStore: GuestStore(
        directory: () async {
          throw FileSystemException('test disk failure');
        },
      ),
    );
    addTearDown(auth.dispose);
    await _pump(tester, auth, '/login');
    await tester.ensureVisible(find.text('로그인 없이 시작하기'));
    await tester.tap(find.text('로그인 없이 시작하기'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(auth.isGuest, isFalse);
    expect(find.text('게스트 시작에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '로그인 없이 시작하기'),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  AuthViewModel auth,
  String location,
) async {
  final router = GoRouter(
    initialLocation: location,
    refreshListenable: auth,
    redirect: (_, state) => redirectForAuth(
      authReady: auth.authReady || !auth.canUseApp,
      signedIn: auth.signedIn,
      isGuest: auth.isGuest,
      onboardingDone: auth.onboardingDone,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: auth,
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Auth extends Fake implements AuthRepository {
  @override
  bool onboardingDone = false;
  @override
  Stream<AppUser?> userChanges() => const Stream.empty();
  @override
  AppUser? currentUser() => null;
}
