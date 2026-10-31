import 'dart:io';
import 'package:counter_01/theme/app_theme.dart';
import 'dart:ui' as ui;

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/user_profile.dart';
import 'package:counter_01/pages/home/home_page.dart';
import 'package:counter_01/pages/home/character_room_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:counter_01/viewmodels/streak_viewmodel.dart';
import 'package:counter_01/widgets/bottom_nav_shell.dart';
import 'package:counter_01/widgets/home/buddy_header.dart';
import 'package:counter_01/widgets/flame_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

List<Routine> _routines(int count) => List.generate(
  count,
  (index) => Routine(
    id: '$index',
    title: ['하체', '등', '버피', '어깨', '가슴', '전신'][index],
    categoryId: 'test',
    items: List.generate(
      4,
      (item) => Exercise(
        id: '$item',
        name: ['스쿼트', '데드리프트', '버피테스트', '사레레', '체스트 프레스', '케이블 머신'][index],
        sets: 1,
        reps: 10,
        repSeconds: 2,
      ),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    final font = FontLoader('Pretendard');
    font.addFont(
      rootBundle.load('assets/fonts/Pretendard/Pretendard-Regular.ttf'),
    );
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('저장된 루틴이 하나인 홈 화면을 표시한다', (tester) async {
    await _pumpHome(tester, count: 1);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('저장된 루틴'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('저장된 루틴')).dy,
      greaterThan(tester.getBottomLeft(find.byType(BuddyHeader)).dy),
    );
    expect(
      tester.getTopLeft(find.byType(FilledButton)).dy,
      greaterThan(tester.getBottomLeft(find.byType(BuddyHeader)).dy),
    );
    expect(tester.getSize(find.byType(FilledButton)).height, 60);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'single');
  });

  testWidgets('여러 루틴을 넘겨도 바로 운동 시작은 목록 아래에 보인다', (tester) async {
    await _pumpHome(tester, count: 6);
    await _preview(tester, 'multiple');
    expect(
      tester.getTopLeft(find.text('바로 운동 시작')).dy,
      greaterThan(tester.getBottomLeft(find.byType(PageView)).dy),
    );
    expect(find.text('바로 운동 시작').hitTestable(), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-375, 0));
    await tester.pumpAndSettle();
    expect(find.text('어깨'), findsOneWidget);
    expect(find.text('하체'), findsNothing);
    await _preview(tester, 'second-page');
  });

  testWidgets('루틴이 없어도 등록 안내와 운동 시작 버튼을 표시한다', (tester) async {
    await _pumpHome(tester, count: 0);
    expect(find.text('루틴이 비어있어요!'), findsOneWidget);
    expect(find.text('바로 운동 시작'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'empty');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('루틴 목록 화면'), findsOneWidget);
  });

  testWidgets('작은 화면과 긴 이름에서도 레이아웃이 넘치지 않는다', (tester) async {
    await _pumpHome(
      tester,
      count: 6,
      size: const Size(320, 568),
      nickname: '열글자보다훨씬더긴사용자이름',
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('바로 운동 시작'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('바로 운동 시작').hitTestable(), findsOneWidget);
  });

  testWidgets('루틴 재생은 선택한 루틴으로 카운터를 연다', (tester) async {
    final counter = await _pumpHome(tester, count: 1);
    await tester.tap(find.byTooltip('하체 시작'));
    await tester.pumpAndSettle();
    expect(find.text('운동 카운터 화면'), findsOneWidget);
    expect(counter.routine?.id, '0');
  });

  testWidgets('바로 운동 시작은 기존 자유 운동 설정을 연다', (tester) async {
    await _pumpHome(tester, count: 1);
    await tester.tap(find.text('바로 운동 시작'));
    await tester.pumpAndSettle();
    expect(find.text('자유 운동 설정'), findsOneWidget);
    expect(find.text('루틴 없이 운동하기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('불씨를 누르면 기존 성장 화면으로 이동한다', (tester) async {
    await _pumpHome(tester, count: 0);
    await tester.tap(find.byType(BuddyHeader));
    await tester.pumpAndSettle();
    expect(find.byType(CharacterRoomPage), findsOneWidget);
    expect(find.text('나의 불씨'), findsOneWidget);
    expect(find.text('이번 주 목표'), findsOneWidget);
    expect(find.text('불씨 방'), findsNothing);
  });

  for (final size in [const Size(375, 812), const Size(360, 640)]) {
    testWidgets('$size 첫날 불씨와 루틴 3개 및 시작 버튼이 한 화면에 보인다', (tester) async {
      await _pumpHome(
        tester,
        count: 6,
        size: size,
        bottomInset: size.width == 375 ? 34 : 24,
        topInset: size.width == 375 ? 44 : 24,
      );
      expect(
        find.byKey(const ValueKey('home-first-day-ember')).hitTestable(),
        findsOneWidget,
      );
      for (final label in ['하체', '등', '버피', '바로 운동 시작']) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        tester.getBottomLeft(find.byType(FilledButton)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy - 8),
      );
      final background = button.style!.backgroundColor!.resolve({})!;
      final text = tester.widget<Text>(find.text('바로 운동 시작')).style!;
      expect(text.fontSize, greaterThanOrEqualTo(19));
      expect(text.fontWeight, FontWeight.w700);
      expect(
        (text.color!.computeLuminance() + .05) /
            (background.computeLuminance() + .05),
        greaterThanOrEqualTo(3),
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'first-day-${size.width.toInt()}');
    });
  }

  testWidgets('첫날 불씨 자산은 투명하고 실제 불씨 너비가 60픽셀 이상이다', (tester) async {
    await _pumpHome(tester, count: 0);
    final avatar = tester.widget<FlameAvatar>(
      find.byKey(const ValueKey('home-first-day-ember')),
    );
    final imageWidth = avatar.size * avatar.characterScale;
    await tester.runAsync(() async {
      final bytes = await rootBundle.load(FlameArtwork.asset(0));
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: 128,
      );
      final frame = await codec.getNextFrame();
      final pixels = (await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(pixels[3], 0);
      var left = frame.image.width;
      var right = 0;
      for (var y = 0; y < frame.image.height; y++) {
        for (var x = 0; x < frame.image.width; x++) {
          if (pixels[(y * frame.image.width + x) * 4 + 3] > 128) {
            if (x < left) left = x;
            if (x > right) right = x;
          }
        }
      }
      expect(
        (right - left + 1) / frame.image.width * imageWidth,
        inInclusiveRange(60, 85),
      );
      frame.image.dispose();
      codec.dispose();
    });
    expect(tester.takeException(), isNull);
  });

  for (final stage in FlameArtwork.stages.where((stage) => stage != 0)) {
    testWidgets('기존 성장 단계 $stage 이미지와 실제 Day 값을 유지한다', (tester) async {
      final day = stage < 0
          ? stage
          : const [1, 3, 5, 10, 15, 20, 30, 40, 50, 60, 100][stage];
      await _pumpHome(tester, count: 3, day: day, flameStage: stage);
      expect(find.text('Day $day'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-first-day-ember')), findsNothing);
      final path = FlameArtwork.asset(stage);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is ResizeImage &&
              (widget.image as ResizeImage).imageProvider is AssetImage &&
              ((widget.image as ResizeImage).imageProvider as AssetImage)
                      .assetName ==
                  path,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'growth-$stage');
    });
  }

  testWidgets('운동 전 Day 0을 임의로 Day 1로 바꾸지 않는다', (tester) async {
    await _pumpHome(tester, count: 0, day: 0);
    expect(find.text('Day 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-first-day-ember')), findsOneWidget);
    await _preview(tester, 'before-first-workout');
  });

  for (final count in [0, 6]) {
    testWidgets('글씨를 두 배로 키워도 루틴 $count개 화면이 넘치지 않는다', (tester) async {
      await _pumpHome(
        tester,
        count: count,
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('바로 운동 시작'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('바로 운동 시작'));
      await tester.pumpAndSettle();
      expect(find.text('바로 운동 시작').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('하단 메뉴로 기록 화면에 이동한다', (tester) async {
    await _pumpHome(tester, count: 1, bottomInset: 34);
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('기록 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 안내는 명시적인 버튼으로 자유 운동 설정까지 이동한다', (tester) async {
    await _pumpHome(tester, count: 0, tutorialDone: false);
    expect(find.text('반가워요!'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('가볍게 한 세트'), findsOneWidget);
    expect(find.text('바로 운동 시작').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 운동 후 루틴이 있어도 다음과 등록 버튼으로 안내를 끝낸다', (tester) async {
    await _pumpHome(
      tester,
      count: 1,
      tutorialDone: false,
      workoutCompleted: true,
      size: const Size(320, 568),
    );
    expect(find.text('다음').hitTestable(), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('루틴 등록하기').hitTestable(), findsOneWidget);
    await tester.tap(find.text('루틴 등록하기'));
    await tester.pumpAndSettle();
    expect(find.text('루틴 목록 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<CounterViewModel> _pumpHome(
  WidgetTester tester, {
  required int count,
  Size size = const Size(375, 812),
  String nickname = '나라',
  double textScale = 1,
  double bottomInset = 0,
  double topInset = 44,
  bool tutorialDone = true,
  bool workoutCompleted = false,
  int day = 1,
  int flameStage = 0,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final records = RecordsViewModel(InMemoryRecordRepository());
  final counter = CounterViewModel(records)
    ..workoutCompleted = workoutCompleted;
  final auth = _Auth(nickname, tutorialDone);
  final routines = _Routines(_routines(count));
  final streak = _Streak(day, flameStage);
  for (final notifier in [records, counter, auth, routines, streak]) {
    addTearDown(notifier.dispose);
  }
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (_, __, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/routines',
            builder: (_, __) => const Scaffold(body: Text('루틴 목록 화면')),
          ),
          GoRoute(
            path: '/records',
            builder: (_, __) => const Scaffold(body: Text('기록 화면')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const Scaffold(body: Text('설정 화면')),
          ),
        ],
      ),
      GoRoute(
        path: '/counter',
        builder: (_, __) => const Scaffold(body: Text('운동 카운터 화면')),
      ),
      GoRoute(path: '/buddy', builder: (_, __) => const CharacterRoomPage()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<CounterViewModel>.value(value: counter),
        ChangeNotifierProvider<RecordsViewModel>.value(value: records),
        ChangeNotifierProvider<RoutinesViewModel>.value(value: routines),
        ChangeNotifierProvider<StreakViewModel>.value(value: streak),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(
            key: const ValueKey('home-preview'),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(HomePage));
    for (final asset in [
      'assets/images/logo_sporkle.png',
      'assets/images/play_icon.png',
      for (final name in ['home', 'records', 'routines', 'settings'])
        for (final state in ['on', 'off'])
          'assets/icons/nav_${name}_$state.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
    for (final img in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(img.image, context);
    }
  });
  await tester.pumpAndSettle();
  return counter;
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('HOME_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('home-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/home-previews').create(recursive: true);
    await File(
      'build/home-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _Auth extends ChangeNotifier implements AuthViewModel {
  _Auth(this.nickname, this.homeTutorialDone);
  final String nickname;
  @override
  UserProfile get user => UserProfile(uid: 'preview', name: nickname);
  @override
  bool get signedIn => true;
  @override
  bool get settingsLoaded => true;
  @override
  bool homeTutorialDone;
  @override
  Future<void> markHomeTutorialDone() async {
    homeTutorialDone = true;
    notifyListeners();
  }

  @override
  int get weeklyTarget => 3;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  _Routines(this.items);
  @override
  final List<Routine> items;
  @override
  Object? get loadError => null;
  @override
  bool get isLoading => false;
  @override
  void clearSelectedRoutine() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Streak extends StreakViewModel {
  _Streak(this.day, this.flameStage);
  @override
  final int day;
  @override
  final int flameStage;
}
