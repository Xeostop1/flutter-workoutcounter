import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/pages/routines/routine_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:counter_01/widgets/bottom_nav_shell.dart';
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
    title: ['하체', '등', '버피', '어깨', '자유 운동'][index % 5],
    categoryId: 'test',
    favorite: index % 5 < 3,
    updatedAt: DateTime(2025, 6, [19, 17, 1, 19, 17][index % 5]),
    items: List.generate(
      [5, 5, 2, 3, 1][index % 5],
      (item) => Exercise(
        id: '$item',
        name: ['스쿼트', '데드리프트', '버피테스트', '사레레', '러닝'][index % 5],
        sets: 1,
        reps: 10,
        repSeconds: 2,
      ),
    ),
  ),
);

Routine get _single => _routines(
  2,
).last.copyWith(favorite: false, items: [_routines(2).last.items.first]);

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

  testWidgets('빈 목록은 안내와 루틴 추가 버튼을 표시한다', (tester) async {
    await _pumpPage(tester, _Routines([]));
    expect(find.text('루틴을 등록하고\n운동을 시작 해보세요'), findsOneWidget);
    final bubble = find
        .ancestor(
          of: find.text('루틴을 등록하고\n운동을 시작 해보세요'),
          matching: find.byType(CustomPaint),
        )
        .first;
    expect(tester.getRect(bubble), const Rect.fromLTWH(73, 366, 229, 107));
    final addButton = find
        .ancestor(of: find.byIcon(Icons.add), matching: find.byType(SizedBox))
        .first;
    expect(tester.getRect(addButton), const Rect.fromLTWH(279, 636, 72, 72));
    expect(tester.takeException(), isNull);
    await _preview(tester, 'empty');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('루틴 등록 화면'), findsOneWidget);
  });

  testWidgets('루틴 1개는 최신순과 제목 운동 날짜를 표시한다', (tester) async {
    await _pumpPage(tester, _Routines([_single]));
    expect(find.text('최신순'), findsOneWidget);
    expect(find.text('데드리프트'), findsOneWidget);
    expect(find.text('25.06.17'), findsOneWidget);
    expect(tester.getTopLeft(find.text('등')), const Offset(64, 114));
    expect(tester.takeException(), isNull);
    await _preview(tester, 'single');
  });

  testWidgets('여러 루틴은 즐겨찾기와 구분선을 표시한다', (tester) async {
    await _pumpPage(tester, _Routines(_routines(5)));
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.byType(Divider), findsNWidgets(4));
    expect(find.text('최신순'), findsNothing);
    expect(tester.getTopLeft(find.text('하체')), const Offset(64, 82));
    expect(tester.takeException(), isNull);
    await _preview(tester, 'multiple');
  });

  testWidgets('즐겨찾기 변경 결과를 목록에 반영한다', (tester) async {
    final routines = _Routines([_single]);
    await _pumpPage(tester, routines);
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(routines.toggled, _single.id);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.star_rounded)).color,
      const Color(0xFFFF6633),
    );
  });

  testWidgets('즐겨찾기 저장 실패 시 기존 상태와 오류 안내를 유지한다', (tester) async {
    final routines = _Routines([_single])..failFavorite = true;
    await _pumpPage(tester, routines);
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(routines.items.single.favorite, isFalse);
    expect(find.text('즐겨찾기를 저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
  });

  testWidgets('제목을 누르면 해당 루틴 수정 화면을 연다', (tester) async {
    await _pumpPage(tester, _Routines([_single]));
    await tester.tap(find.text('등'));
    await tester.pumpAndSettle();
    expect(find.text('루틴 수정 1'), findsOneWidget);
  });

  testWidgets('마지막 루틴의 수정 버튼은 추가 버튼에 가려지지 않는다', (tester) async {
    final items = _routines(12);
    items[11] = items[11].copyWith(title: '마지막 루틴');
    await _pumpPage(tester, _Routines(items));
    await tester.fling(find.byType(ListView), const Offset(0, -4000), 10000);
    await tester.pumpAndSettle();
    final edit = find.byTooltip('마지막 루틴 수정');
    final add = find
        .ancestor(of: find.byIcon(Icons.add), matching: find.byType(SizedBox))
        .first;
    expect(tester.getRect(edit).bottom, lessThan(tester.getRect(add).top));
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('루틴 수정 11'), findsOneWidget);
  });

  testWidgets('로딩 중에는 빈 목록이나 추가 버튼을 표시하지 않는다', (tester) async {
    await _pumpPage(tester, _Routines([])..loading = true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.textContaining('루틴을 등록하고'), findsNothing);
  });

  testWidgets('불러오기 실패 시 다시 시도할 수 있다', (tester) async {
    final routines = _Routines([])..error = StateError('오프라인');
    await _pumpPage(tester, routines);
    expect(find.byIcon(Icons.add), findsNothing);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(routines.retried, isTrue);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  for (final count in [0, 10]) {
    testWidgets('작은 화면과 큰 글씨에서도 루틴 $count개가 넘치지 않는다', (tester) async {
      final items = _routines(count);
      if (items.isNotEmpty) {
        items[0] = items[0].copyWith(title: '아주 긴 루틴 이름도 화면 안에 표시');
      }
      await _pumpPage(
        tester,
        _Routines(items),
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add).hitTestable(), findsOneWidget);
      await _preview(tester, 'small-$count');
    });
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  _Routines routines, {
  Size size = const Size(375, 812),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final records = RecordsViewModel(InMemoryRecordRepository());
  addTearDown(records.dispose);
  addTearDown(routines.dispose);
  final router = GoRouter(
    initialLocation: '/routines',
    routes: [
      ShellRoute(
        builder: (_, __, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/routines', builder: (_, __) => const RoutinePage()),
        ],
      ),
      GoRoute(
        path: '/routines/create',
        builder: (_, __) => const Scaffold(body: Text('루틴 등록 화면')),
      ),
      GoRoute(
        path: '/routines/edit/:id',
        builder: (_, state) =>
            Scaffold(body: Text('루틴 수정 ${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RoutinesViewModel>.value(value: routines),
        ChangeNotifierProvider<RecordsViewModel>.value(value: records),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Pretendard'),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 44),
            textScaler: TextScaler.linear(textScale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('routine-preview'),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    final context = tester.element(find.byType(RoutinePage));
    for (final asset in [
      'assets/images/routine_mascot.png',
      for (final name in ['home', 'settings'])
        for (final state in ['on', 'off'])
          'assets/icons/nav_${name}_$state.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pump();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('ROUTINE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('routine-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/routine-previews').create(recursive: true);
    await File(
      'build/routine-previews/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  _Routines(this.items);
  @override
  List<Routine> items;
  bool loading = false;
  Object? error;
  bool failFavorite = false;
  String? toggled;
  bool retried = false;
  @override
  bool get isLoading => loading;
  @override
  Object? get loadError => error;
  @override
  void retryLoad() {
    retried = true;
    error = null;
    notifyListeners();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    if (failFavorite) throw StateError('저장 실패');
    toggled = id;
    items = items
        .map((r) => r.id == id ? r.copyWith(favorite: !r.favorite) : r)
        .toList();
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
