import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/pages/home/character_room_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/streak_viewmodel.dart';
import 'package:counter_01/widgets/flame_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Pretendard')..addFont(
          rootBundle.load('assets/fonts/Pretendard/Pretendard-Regular.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final size in [const Size(360, 640), const Size(375, 812)]) {
    testWidgets('$size 현재 불씨와 목표 및 펼침 버튼을 한 화면에 표시한다', (tester) async {
      await _pump(tester, size: size);
      expect(find.text('나의 불씨'), findsOneWidget);
      expect(find.text('불씨 방'), findsNothing);
      expect(find.text('Day 0'), findsOneWidget);
      expect(find.text('Day 8'), findsNothing);
      expect(find.text('0 / 3회'), findsOneWidget);
      expect(find.text('성장 과정 보기').hitTestable(), findsOneWidget);
      expect(find.byKey(const ValueKey('flame-growth-list')), findsNothing);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .maxScrollExtent,
        0,
      );
      expect(
        tester
            .widget<FlameAvatar>(
              find.byKey(const ValueKey('room-current-flame')),
            )
            .stage,
        0,
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'collapsed-${size.width.toInt()}');
    });
  }

  testWidgets('애니메이션의 마지막 배치가 끝난 뒤 성장 목록 전체를 자동으로 보여준다', (tester) async {
    await _pump(tester, reduced: false);
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pump();
    await tester.pump(); // Start the size-animation ticker before the slow frame.
    // Jump over the final animation frame, as on a busy physical device.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(); // Start the scroll-animation ticker after final layout.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final viewport = tester.getRect(
      find.byKey(const ValueKey('character-room-scroll')),
    );
    final list = find.byKey(const ValueKey('flame-growth-list'));
    expect(
      tester.getRect(list).bottom,
      lessThanOrEqualTo(viewport.bottom + .5),
    );
    expect(
      find.byKey(const ValueKey('growth-stage-0')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _preview(tester, 'expanded-animated-360');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('화살표는 같은 화면에서 가로 목록을 펼치고 끝까지 넘겨도 실제 성장과 기록은 바뀌지 않는다', (
    tester,
  ) async {
    final records = _Records();
    final streak = _Streak(10, 3);
    await _pump(
      tester,
      records: records,
      streak: streak,
      size: const Size(375, 812),
    );
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pumpAndSettle();
    await _loadImages(tester);
    final list = find.byKey(const ValueKey('flame-growth-list'));
    expect(tester.widget<ListView>(list).scrollDirection, Axis.horizontal);
    expect(
      tester.widget<ListView>(list).childrenDelegate.estimatedChildCount,
      13,
    );
    expect(find.text('현재'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('growth-stage-3')).hitTestable(),
      findsOneWidget,
    );
    final marker = tester.widget<Container>(
      find.byKey(const ValueKey('growth-stage-3')),
    );
    expect(
      ((marker.decoration as BoxDecoration).border! as Border).top.color,
      const Color(0xFFFF895E),
    );
    await _preview(tester, 'expanded-375');
    await tester.drag(list, const Offset(-1800, 0));
    await tester.pumpAndSettle();
    await _loadImages(tester);
    expect(
      find.byKey(const ValueKey('growth-stage-10')).hitTestable(),
      findsOneWidget,
    );
    await _preview(tester, 'last-stages');
    await tester.drag(list, const Offset(1800, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('growth-stage--2')).hitTestable(),
      findsOneWidget,
    );
    expect(streak.day, 10);
    expect(streak.flameStage, 3);
    expect(records.totalCount, 0);
    expect(
      tester
          .widget<FlameAvatar>(find.byKey(const ValueKey('room-current-flame')))
          .stage,
      3,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('toggle-growth')));
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pumpAndSettle();
    expect(list, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('주간 목표는 실제 설정과 이번 주 운동만 계산한다', (tester) async {
    final records = _Records();
    for (var i = 0; i < 2; i++) {
      await records.addRecord(
        WorkoutRecord(
          date: DateTime.now().add(Duration(seconds: i)),
          routineId: '$i',
          routineTitle: '운동',
          totalReps: 10,
        ),
      );
    }
    await records.addRecord(
      WorkoutRecord.memo(date: DateTime.now(), title: '메모'),
    );
    await records.addRecord(
      WorkoutRecord(
        date: DateTime.now(),
        routineId: 'zero',
        routineTitle: '미진행',
        totalReps: 0,
      ),
    );
    await records.addRecord(
      WorkoutRecord(
        date: DateTime.now().subtract(const Duration(days: 14)),
        routineId: 'past',
        routineTitle: '지난 운동',
        totalReps: 10,
      ),
    );
    final auth = _Auth();
    await _pump(tester, records: records, auth: auth);
    expect(find.text('2 / 3회'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(2 / 3, .0001),
    );
    auth.target = 5;
    auth.refresh();
    await tester.pumpAndSettle();
    expect(find.text('2 / 5회'), findsOneWidget);
    expect(find.text('주 5회 운동하기'), findsOneWidget);
  });

  testWidgets('목표를 초과해도 실제 횟수는 보이고 진행 막대만 100퍼센트로 제한한다', (tester) async {
    final records = _Records();
    for (var i = 0; i < 4; i++) {
      await records.addRecord(
        WorkoutRecord(
          date: DateTime.now().add(Duration(seconds: i)),
          routineId: '$i',
          routineTitle: '운동',
          totalReps: 1,
        ),
      );
    }
    await _pump(tester, records: records);
    expect(find.text('4 / 3회'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('목표 로딩과 기록 오류를 0회로 숨기지 않고 재시도한다', (tester) async {
    final records = _Records()..loading = true;
    await _pump(tester, records: records, settle: false);
    expect(find.text('— / 3회'), findsOneWidget);
    expect(find.text('0 / 3회'), findsNothing);
    records.loading = false;
    records.error = StateError('offline');
    records.refresh();
    await tester.pumpAndSettle();
    expect(find.text('운동 기록을 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(records.retried, isTrue);
    expect(find.text('0 / 3회'), findsOneWidget);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform 320x568 두 배 글자에서도 스크롤로 펼치고 접을 수 있다', (tester) async {
      await _pump(
        tester,
        size: const Size(320, 568),
        scale: 2,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('toggle-growth')));
      await tester.tap(find.byKey(const ValueKey('toggle-growth')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('growth-stage-0')).hitTestable(),
        findsOneWidget,
      );
      await _preview(tester, 'large-text-${platform.name}');
      await tester.ensureVisible(find.byKey(const ValueKey('toggle-growth')));
      await tester.tap(find.byKey(const ValueKey('toggle-growth')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flame-growth-list')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('확장 애니메이션 중 닫거나 화면을 떠나도 스크롤 콜백이 남지 않는다', (tester) async {
    await _pump(tester, reduced: false);
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('flame-growth-list')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('toggle-growth')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byTooltip('돌아가기'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('홈 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double scale = 1,
  bool reduced = true,
  bool settle = true,
  TargetPlatform platform = TargetPlatform.android,
  _Records? records,
  _Auth? auth,
  _Streak? streak,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  records ??= _Records();
  auth ??= _Auth();
  streak ??= _Streak(0, 0);
  for (final notifier in [records, auth, streak]) {
    addTearDown(notifier.dispose);
  }
  final router = GoRouter(
    initialLocation: '/buddy',
    routes: [
      GoRoute(path: '/buddy', builder: (_, __) => const CharacterRoomPage()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('홈 화면')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordsViewModel>.value(value: records),
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<StreakViewModel>.value(value: streak),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark.copyWith(platform: platform),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(
              top: size.width == 375 ? 44 : 24,
              bottom: size.width == 375 ? 34 : 24,
            ),
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: RepaintBoundary(
            key: const ValueKey('room-preview'),
            child: child,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    if (reduced) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _loadImages(tester, settle: reduced);
  }
}

Future<void> _loadImages(WidgetTester tester, {bool settle = true}) async {
  final context = tester.element(find.byType(CharacterRoomPage));
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('ROOM_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('room-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/room-previews').create(recursive: true);
    await File(
      'build/room-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _Auth extends ChangeNotifier implements AuthViewModel {
  int target = 3;
  @override
  int get weeklyTarget => target;
  @override
  bool get settingsLoaded => true;
  void refresh() => notifyListeners();
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

class _Records extends RecordsViewModel {
  _Records() : super(InMemoryRecordRepository());
  bool loading = false, retried = false;
  Object? error;
  @override
  bool get isLoading => loading;
  @override
  Object? get loadError => error;
  void refresh() => notifyListeners();
  @override
  Future<void> reload() async {
    retried = true;
    error = null;
    notifyListeners();
  }
}
