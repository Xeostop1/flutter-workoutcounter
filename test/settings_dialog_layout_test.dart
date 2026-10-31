import 'package:counter_01/pages/settings/settings_page.dart';
import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/user_settings_repository.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'SPORKLE',
      packageName: 'test.sporkle',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final font = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/Pretendard/Pretendard-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('nickname cancel keeps input alive until dialog unmounts', (
    tester,
  ) async {
    final auth = _NicknameAuth();
    await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
    await tester.tap(find.text('닉네임 변경'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '저장하지 않음');
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(auth.savedNames, isEmpty);
    expect(auth.displayName, '게스트');
  });

  for (final dismissal in ['barrier', 'back']) {
    testWidgets('nickname $dismissal dismisses without saving or errors', (
      tester,
    ) async {
      final auth = _NicknameAuth();
      await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
      await tester.tap(find.text('닉네임 변경'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '저장하지 않음');
      if (dismissal == 'barrier') {
        await tester.tapAt(const Offset(4, 4));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.savedNames, isEmpty);
      expect(auth.displayName, '게스트');
    });
  }

  testWidgets('nickname save trims the name and saves exactly once', (
    tester,
  ) async {
    final auth = _NicknameAuth();
    await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
    await tester.tap(find.text('닉네임 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' 새 불씨 ');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(auth.savedNames, ['새 불씨']);
    expect(auth.displayName, '새 불씨');
  });

  testWidgets('nickname blank save keeps the dialog open without writing', (
    tester,
  ) async {
    final auth = _NicknameAuth();
    await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
    await tester.tap(find.text('닉네임 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(auth.savedNames, isEmpty);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nickname save failure keeps the old name and reports the error',
    (tester) async {
      final auth = _NicknameAuth()..failSave = true;
      await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
      await tester.tap(find.text('닉네임 변경'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '새 불씨');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('닉네임을 변경하지 못했습니다.'), findsOneWidget);
      expect(auth.displayName, '게스트');
      expect(auth.savedNames, ['새 불씨']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nickname repeated cancellation starts with the stored name', (
    tester,
  ) async {
    final auth = _NicknameAuth();
    await _pumpSettings(tester, const Size(360, 640), 1, auth: auth);
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(find.text('닉네임 변경'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '게스트',
      );
      await tester.enterText(find.byType(TextField), '초안 $attempt');
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(auth.savedNames, isEmpty);
  });

  for (final size in [const Size(320, 568), const Size(360, 640)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$size 글자 $scale배: 로그아웃 버튼은 한 줄이고 취소는 계정을 유지한다', (
        tester,
      ) async {
        final repository = await _pumpSettings(tester, size, scale);
        await tester.scrollUntilVisible(find.text('로그아웃'), 160);
        await tester.tap(find.text('로그아웃'));
        await tester.pumpAndSettle();
        final action = find.widgetWithText(FilledButton, '로그아웃');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: action, matching: find.text('로그아웃')),
        );
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 4),
        );
        expect(boxes.map((box) => box.top).toSet(), hasLength(1));
        expect(boxes.last.right, lessThanOrEqualTo(paragraph.size.width + 0.5));
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('LOGIN_UI_PREVIEWS')) {
          await expectLater(
            find.byKey(const ValueKey('settings-preview')),
            matchesGoldenFile(
              '../verification/login-ui-20261031/logout-${size.width.toInt()}-scale$scale.png',
            ),
          );
        }
        final cancel = find.widgetWithText(FilledButton, '취소');
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(repository.signOutCalls, 0);
        expect(repository.deleteCalls, 0);
      });
    }
  }

  testWidgets('확인을 눌렀을 때만 기존 로그아웃 동작을 호출한다', (tester) async {
    final repository = await _pumpSettings(tester, const Size(360, 640), 1);
    await tester.scrollUntilVisible(find.text('로그아웃'), 160);
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(repository.signOutCalls, 1);
    expect(repository.deleteCalls, 0);
  });

  testWidgets('같은 확인 창을 쓰는 회원탈퇴도 큰 글자에서 취소하면 삭제하지 않는다', (tester) async {
    final repository = await _pumpSettings(tester, const Size(320, 568), 2);
    await tester.scrollUntilVisible(find.text('회원탈퇴'), 160);
    await tester.ensureVisible(find.text('회원탈퇴'));
    await tester.pumpAndSettle();
    expect(find.text('회원탈퇴').hitTestable(), findsOneWidget);
    await tester.tap(find.text('회원탈퇴'));
    await tester.pumpAndSettle();
    final cancel = find.widgetWithText(FilledButton, '취소');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsNothing);
    expect(repository.deleteCalls, 0);
    expect(repository.signOutCalls, 0);
  });
}

Future<_AuthRepository> _pumpSettings(
  WidgetTester tester,
  Size size,
  double scale, {
  AuthViewModel? auth,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _AuthRepository();
  final viewModel =
      auth ?? AuthViewModel(repository, settingsRepo: _UnusedSettings());
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(
            key: const ValueKey('settings-preview'),
            child: child!,
          ),
        ),
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

class _AuthRepository extends Fake implements AuthRepository {
  int signOutCalls = 0;
  int deleteCalls = 0;
  @override
  Stream<AppUser?> userChanges() => const Stream.empty();
  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
  }
}

class _UnusedSettings extends Fake implements UserSettingsRepository {}

class _NicknameAuth extends AuthViewModel {
  _NicknameAuth() : super(_AuthRepository(), settingsRepo: _UnusedSettings());

  final savedNames = <String>[];
  String name = '게스트';
  bool failSave = false;
  @override
  String get displayName => name;
  @override
  Future<void> setDisplayName(String value) async {
    savedNames.add(value);
    if (failSave) throw StateError('Test save failure');
    name = value;
    notifyListeners();
  }
}
