import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/pages/records/record_page.dart';
import 'package:counter_01/pages/records/sections/calendar_section.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/widgets/bottom_nav_shell.dart';
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
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
  });

  for (final size in [const Size(360, 640), const Size(375, 812)]) {
    for (final month in [2, 10, 8]) {
      testWidgets('$size $month월 빈 기록은 달력 추가 버튼까지 스크롤 없이 보인다', (tester) async {
        await _pump(tester, size: size, selected: DateTime(2026, month, 1));
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        expect(scroll.maxScrollExtent, 0);
        expect(
          tester.getBottomLeft(find.byType(CalendarSection)).dy,
          lessThan(
            tester
                .getTopLeft(find.byKey(const ValueKey('empty-day-records')))
                .dy,
          ),
        );
        expect(find.text('이번 주 목표'), findsNothing);
        expect(find.text('기록 추가').hitTestable(), findsOneWidget);
        expect(
          tester
              .getBottomLeft(find.byKey(const ValueKey('empty-day-records')))
              .dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
        );
        final grid = tester.widget<GridView>(find.byType(GridView));
        expect(
          tester.getSize(find.byType(GridView)).width,
          lessThanOrEqualTo(308),
        );
        expect(
          grid.childrenDelegate.estimatedChildCount,
          {2: 28, 10: 35, 8: 42}[month],
        );
        expect(
          tester
              .getSize(find.byKey(ValueKey<DateTime>(DateTime(2026, month, 1))))
              .height,
          greaterThanOrEqualTo(44),
        );
        expect(tester.takeException(), isNull);
        if (month == 8) await _preview(tester, 'empty-${size.width.toInt()}');
      });
    }
  }

  testWidgets('다른 달로 넘겨도 기록 표시와 날짜 선택을 유지한다', (tester) async {
    final records = _Records();
    await records.addRecord(
      WorkoutRecord(
        date: DateTime(2026, 12, 15),
        routineId: 'walk',
        routineTitle: '산책 기록',
        totalReps: 10,
      ),
    );
    await _pump(tester, records: records, selected: DateTime(2026, 10, 1));
    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
    final day = DateTime(2026, 12, 15);
    expect(find.byKey(ValueKey('workout-stamp-$day')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey<DateTime>(day)));
    await tester.pumpAndSettle();
    expect(records.selectedDay, day);
    expect(find.text('산책 기록'), findsOneWidget);
    await _preview(tester, 'selected-record');
    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
    expect(find.text('2027.01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘이 선택된 채 다른 달을 보다가 오늘을 누르면 돌아온다', (tester) async {
    final now = DateTime.now();
    final records = await _pump(tester, selected: now);
    await tester.tap(find.byTooltip('이전 달'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();
    expect(
      find.text('${now.year}.${now.month.toString().padLeft(2, '0')}'),
      findsOneWidget,
    );
    expect(records.selectedDay, DateTime(now.year, now.month, now.day));
  });

  testWidgets('실제 운동만 불꽃 도장을 찍고 같은 날 여러 운동도 하나로 표시한다', (tester) async {
    final records = _Records();
    final day = DateTime(2026, 8, 18);
    for (var i = 0; i < 2; i++) {
      await records.addRecord(
        WorkoutRecord(
          date: day.add(Duration(seconds: i)),
          routineId: 'workout-$i',
          routineTitle: '운동',
          totalReps: 10,
        ),
      );
    }
    await records.addRecord(
      WorkoutRecord.memo(date: DateTime(2026, 8, 19), title: '메모만 있는 날'),
    );
    await records.addRecord(
      WorkoutRecord(
        date: DateTime(2026, 8, 20),
        routineId: 'zero',
        routineTitle: '진행하지 않은 운동',
        totalReps: 0,
      ),
    );
    await _pump(tester, records: records, selected: day);
    final stamp = find.byKey(ValueKey('workout-stamp-$day'));
    expect(stamp, findsOneWidget);
    expect(
      (tester.widget<Image>(stamp).image as AssetImage).assetName,
      'assets/images/fire_cal.png',
    );
    expect(
      find.byKey(ValueKey('workout-stamp-${DateTime(2026, 8, 19)}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('workout-stamp-${DateTime(2026, 8, 20)}')),
      findsNothing,
    );
    expect(find.byKey(ValueKey('calendar-selection-$day')), findsOneWidget);
    await _preview(tester, 'flame-stamps');
  });

  testWidgets('오늘 회색 네모는 다른 날짜 선택 뒤에도 유지되고 운동 도장과 함께 보인다', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final records = _Records();
    await _pump(tester, records: records, selected: today);
    final todayMarker = find.byKey(ValueKey('calendar-today-$today'));
    expect(todayMarker, findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: todayMarker, matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, const Color(0xFF777777));
    expect(find.byKey(ValueKey('workout-stamp-$today')), findsNothing);
    final other = today.day == 1
        ? DateTime(today.year, today.month, 2)
        : DateTime(today.year, today.month, today.day - 1);
    await tester.tap(find.byKey(ValueKey<DateTime>(other)));
    await tester.pumpAndSettle();
    expect(todayMarker, findsOneWidget);
    expect(find.byKey(ValueKey('calendar-selection-$other')), findsOneWidget);
    await records.addRecord(
      WorkoutRecord(
        date: other,
        routineId: 'other',
        routineTitle: '선택한 날 운동',
        totalReps: 5,
      ),
    );
    await tester.pumpAndSettle();
    await _preview(tester, 'workout-and-today');
    await records.addRecord(
      WorkoutRecord(
        date: today,
        routineId: 'today',
        routineTitle: '오늘 운동',
        totalReps: 10,
      ),
    );
    await tester.pumpAndSettle();
    expect(todayMarker, findsOneWidget);
    expect(find.byKey(ValueKey('workout-stamp-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('calendar-selection-$today')), findsNothing);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'today-and-workout');
  });

  testWidgets('운동 기록 화면에는 주간 목표 대신 날짜별 내역만 표시한다', (tester) async {
    final records = _Records();
    for (var i = 0; i < 2; i++) {
      await records.addRecord(
        WorkoutRecord(
          date: DateTime.now().add(Duration(seconds: i)),
          routineId: '$i',
          routineTitle: '운동 $i',
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
        routineTitle: '시작 전 종료',
        totalReps: 0,
      ),
    );
    await _pump(tester, records: records);
    expect(find.text('이번 주 목표'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('운동 0'), findsOneWidget);
  });

  testWidgets('빈 날짜에서 기록 추가 후 수정해도 같은 날짜의 기록 하나만 남는다', (tester) async {
    final day = DateTime(2026, 10, 12);
    final records = await _pump(
      tester,
      selected: day,
      size: const Size(375, 812),
    );
    await tester.tap(find.text('기록 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '아침 산책');
    await tester.enterText(find.byType(TextField).last, '20분');
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    expect(records.recordsOn(day).length, 1);
    expect(find.text('아침 산책'), findsOneWidget);
    await tester.tap(find.byTooltip('기록 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '저녁 산책');
    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    expect(records.recordsOn(day).single.routineTitle, '저녁 산책');
    expect(find.text('아침 산책'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final populated in [false, true]) {
    testWidgets('320x568 글자 2배에서도 내용이 넘치지 않고 스크롤로 접근된다 $populated', (
      tester,
    ) async {
      final records = _Records();
      final day = DateTime(2026, 8, 1);
      if (populated) {
        await records.addRecord(
          WorkoutRecord.memo(
            date: day,
            title: '매우 긴 운동 기록 제목도 줄바꿈하여 읽을 수 있습니다',
            memo: '산책과 스트레칭을 꾸준히 진행했습니다.',
          ),
        );
      }
      await _pump(
        tester,
        records: records,
        selected: day,
        size: const Size(320, 568),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      final target = populated ? find.byTooltip('기록 수정') : find.text('기록 추가');
      await tester.scrollUntilVisible(
        target,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'large-text-$populated');
    });
  }

  testWidgets('로딩과 읽기 실패 재시도 화면을 유지한다', (tester) async {
    final records = _Records()..loading = true;
    await _pump(tester, records: records, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    records.loading = false;
    records.error = StateError('offline');
    records.refresh();
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(records.retried, isTrue);
    expect(find.text('기록 추가'), findsOneWidget);
  });
}

Future<_Records> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double scale = 1,
  DateTime? selected,
  _Records? records,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  records ??= _Records();
  records.selectDay(selected ?? DateTime.now());
  final auth = _Auth();
  addTearDown(auth.dispose);
  addTearDown(records.dispose);
  final router = GoRouter(
    initialLocation: '/records',
    routes: [
      ShellRoute(
        builder: (_, __, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/records', builder: (_, __) => const RecordsPage()),
          for (final path in ['/home', '/routines', '/settings'])
            GoRoute(path: path, builder: (_, __) => const Scaffold()),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<RecordsViewModel>.value(value: records),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(
              top: size.width == 375 ? 44 : 24,
              bottom: size.width == 375 ? 34 : 24,
            ),
            textScaler: TextScaler.linear(scale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('records-preview'),
            child: child,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.runAsync(
      () async => precacheImage(
        const AssetImage('assets/images/fire_cal.png'),
        tester.element(find.byType(RecordsPage)),
      ),
    );
    await tester.pumpAndSettle();
  }
  return records;
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('RECORDS_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('records-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/records-previews').create(recursive: true);
    await File(
      'build/records-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _Auth extends ChangeNotifier implements AuthViewModel {
  @override
  int get weeklyTarget => 4;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Records extends RecordsViewModel {
  _Records() : super(InMemoryRecordRepository());
  bool loading = false;
  Object? error;
  bool retried = false;
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
