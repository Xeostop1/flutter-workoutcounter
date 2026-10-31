import 'package:counter_01/models/trainer_voice.dart';
import 'package:counter_01/models/user_profile.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:counter_01/pages/onboarding/onboarding_page.dart';
import 'package:counter_01/pages/settings/settings_page.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Auth extends ChangeNotifier implements AuthViewModel {
  @override
  UserProfile? get user => null;
  @override
  TrainerVoice? get trainerVoice => null;
  @override
  String? get systemVoiceId => null;
  @override
  int get restSeconds => 30;
  @override
  bool get voiceCountingEnabled => true;
  @override
  double get voicePitch => 1;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final weight in ['Regular']) {
      await (FontLoader('Pretendard')..addFont(
            rootBundle.load('assets/fonts/Pretendard/Pretendard-$weight.ttf'),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (_) async => {
            'appName': 'SPORKLE',
            'packageName': 'counter_01',
            'version': '1.0.0',
            'buildNumber': '2',
          },
        );
  });
  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    bool compact = false,
  }) async {
    tester.view
      ..physicalSize = compact ? const Size(320, 568) : const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _Auth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: page,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(compact ? 1.5 : 1)),
            child: RepaintBoundary(key: const ValueKey('design'), child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('IOS_PREVIEWS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('design')),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage();
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ios-design-previews').create(recursive: true);
      await File(
        'build/ios-design-previews/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
  }

  testWidgets('설정 화면은 큰 글씨에서도 스크롤로 모든 항목에 접근한다', (tester) async {
    await pump(tester, const SettingsPage(), compact: true);
    await tester.scrollUntilVisible(find.text('회원탈퇴'), 150);
    await tester.pumpAndSettle();
    expect(find.text('회원탈퇴').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('설정 디자인 미리보기', (tester) async {
    await pump(tester, const SettingsPage());
    expect(tester.takeException(), isNull);
    await preview(tester, 'settings');
  });
  testWidgets('첫 설정은 작은 화면의 큰 글씨와 키보드에서도 진행 버튼이 보인다', (tester) async {
    await pump(tester, const OnboardingPage(), compact: true);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    tester.view.viewInsets = const FakeViewPadding(bottom: 216);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), '3');
    await tester.pumpAndSettle();
    expect(find.text('다음').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('첫 설정 디자인 미리보기', (tester) async {
    await pump(tester, const OnboardingPage());
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/charactor_first.png'),
        tester.element(find.byType(OnboardingPage)),
      );
    });
    await tester.pumpAndSettle();
    await preview(tester, 'onboarding');
  });
}
