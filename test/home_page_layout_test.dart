import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/user_profile.dart';
import 'package:counter_01/pages/home/home_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:counter_01/viewmodels/streak_viewmodel.dart';
import 'package:counter_01/widgets/bottom_nav_shell.dart';
import 'package:counter_01/widgets/home/buddy_header.dart';
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
    expect(find.text('Day 100'), findsOneWidget);
    expect(find.text('저장된 루틴'), findsOneWidget);
    expect(tester.getTopLeft(find.byType(BuddyHeader)).dy, 115);
    expect(tester.getTopLeft(find.byType(FilledButton)).dy, 257);
    expect(tester.getSize(find.byType(FilledButton)).height, 60);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'single');
  });

  testWidgets('여러 루틴을 넘겨도 자유 운동 버튼은 목록 위에 있다', (tester) async {
    await _pumpHome(tester, count: 6);
    await _preview(tester, 'multiple');
    expect(
      tester.getTopLeft(find.text('루틴 없이 운동하기')).dy,
      lessThan(tester.getTopLeft(find.text('저장된 루틴')).dy),
    );
    await tester.drag(find.byType(PageView), const Offset(-375, 0));
    await tester.pumpAndSettle();
    expect(find.text('어깨'), findsOneWidget);
    expect(find.text('하체'), findsNothing);
    await _preview(tester, 'second-page');
  });

  testWidgets('루틴이 없어도 등록 안내와 운동 시작 버튼을 표시한다', (tester) async {
    await _pumpHome(tester, count: 0);
    expect(find.text('루틴이 비어있어요!'), findsOneWidget);
    expect(find.text('루틴 없이 운동하기'), findsOneWidget);
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
    await tester.ensureVisible(find.text('루틴 없이 운동하기'));
    expect(find.text('루틴 없이 운동하기').hitTestable(), findsOneWidget);
  });

  testWidgets('루틴 재생은 선택한 루틴으로 카운터를 연다', (tester) async {
    final counter = await _pumpHome(tester, count: 1);
    await tester.tap(find.byTooltip('하체 시작'));
    await tester.pumpAndSettle();
    expect(find.text('운동 카운터 화면'), findsOneWidget);
    expect(counter.routine?.id, '0');
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
      await tester.ensureVisible(find.text('루틴 없이 운동하기'));
      expect(find.text('루틴 없이 운동하기').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('하단 메뉴로 기록 화면에 이동한다', (tester) async {
    await _pumpHome(tester, count: 1, bottomInset: 34);
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('기록 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 진입 튜토리얼의 강조 표시가 운동 버튼에 맞는다', (tester) async {
    await _pumpHome(tester, count: 0, tutorialDone: false);
    expect(find.textContaining('반가워요!'), findsOneWidget);
    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();
    final label = find.text('루틴 없이 운동하기');
    expect(label, findsNWidgets(2));
    final highlight = find
        .ancestor(of: label.last, matching: find.byType(Container))
        .first;
    expect(
      tester.getRect(highlight),
      tester.getRect(find.byType(FilledButton)),
    );
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
  bool tutorialDone = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final records = RecordsViewModel(InMemoryRecordRepository());
  final counter = CounterViewModel(records);
  final auth = _Auth(nickname, tutorialDone);
  final routines = _Routines(_routines(count));
  final streak = _Streak();
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
      GoRoute(
        path: '/buddy',
        builder: (_, __) => const Scaffold(body: Text('불씨 방')),
      ),
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
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Pretendard'),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(top: 44, bottom: bottomInset),
            textScaler: TextScaler.linear(textScale),
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
      'assets/images/flame_stage_0.png',
      'assets/images/play_icon.png',
      for (final name in ['home', 'records', 'routines', 'settings'])
        for (final state in ['on', 'off'])
          'assets/icons/nav_${name}_$state.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
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
  final bool homeTutorialDone;
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Streak extends StreakViewModel {
  @override
  int get day => 100;
  @override
  int get flameStage => 0;
}
