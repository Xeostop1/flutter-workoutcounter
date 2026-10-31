import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/pages/counter/counter_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:counter_01/widgets/gradient_circular_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _routine = Routine(
  id: 'preview',
  title: '자유 운동',
  categoryId: 'free',
  items: [
    Exercise(id: 'squat', name: '스쿼트', sets: 1, reps: 10, repSeconds: 2),
    Exercise(id: 'lunge', name: '런지', sets: 1, reps: 10, repSeconds: 2),
    Exercise(id: 'pushup', name: '푸시업', sets: 1, reps: 10, repSeconds: 2),
    Exercise(id: 'crunch', name: '크런치', sets: 1, reps: 10, repSeconds: 2),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
      font.addFont(
        rootBundle.load('assets/fonts/Pretendard/Pretendard-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });

  testWidgets('참고 이미지 크기의 준비 화면을 표시한다', (tester) async {
    await _pumpCounter(tester, const Size(375, 812));
    expect(find.text('자유 운동'), findsOneWidget);
    expect(find.byTooltip('운동 설정 수정'), findsOneWidget);
    expect(find.byType(GradientCircularCounter), findsOneWidget);
    expect(tester.getTopLeft(find.byType(GradientCircularCounter)).dy, 239);
    expect(tester.getTopLeft(find.bySemanticsLabel('운동 시작')).dy, 506);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'ready');
  });

  testWidgets('운동 전환 후 완료 표시와 진행 화면을 표시한다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    counter.exerciseDone[0] = true;
    counter.selectExercise(1);
    counter.startPause();
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
    final ring = tester.getRect(
      find.ancestor(of: find.text('20'), matching: find.byType(SizedBox)).first,
    );
    expect(ring.top, 239);
    expect(find.bySemanticsLabel('스쿼트 완료'), findsOneWidget);
    expect(find.bySemanticsLabel('일시정지'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'active');
    await tester.tap(find.bySemanticsLabel('일시정지'));
    await tester.pump();
    expect(counter.isRunning, isFalse);
    expect(find.bySemanticsLabel('계속하기'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('계속하기'));
    expect(counter.isRunning, isTrue);
    counter.startPause();
    await tester.pump();
  });

  testWidgets('폭 320인 작은 화면에서도 버튼이 넘치지 않는다', (tester) async {
    await _pumpCounter(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('진행 화면에서도 작은 화면은 스크롤할 수 있다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(320, 568));
    counter.selectExercise(1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('런지'));
    expect(find.text('런지').hitTestable(), findsOneWidget);
  });
}

Future<CounterViewModel> _pumpCounter(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final records = RecordsViewModel(InMemoryRecordRepository());
  final counter = CounterViewModel(records);
  final auth = _Auth();
  final routines = _Routines();
  addTearDown(records.dispose);
  addTearDown(counter.dispose);
  addTearDown(auth.dispose);
  addTearDown(routines.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CounterViewModel>.value(value: counter),
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<RoutinesViewModel>.value(value: routines),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Pretendard'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 44, bottom: 34)),
          child: RepaintBoundary(key: const ValueKey('preview'), child: child),
        ),
        home: const CounterPage(routine: _routine),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Image decoding uses real I/O, outside the widget test's fake clock.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(CounterPage));
    for (final asset in [
      'assets/images/btn_Initialization.png',
      'assets/images/btn_play.png',
      'assets/images/btn_pause.png',
      'assets/images/btn_sound-on.png',
      'assets/images/btn_sound-off.png',
      'assets/images/stamp_done.png',
      'assets/icons/icon-edit.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
  return counter;
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('COUNTER_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('preview')),
  );
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/counter-previews').create(recursive: true);
      await File(
        'build/counter-previews/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }
}

class _Auth extends ChangeNotifier implements AuthViewModel {
  @override
  int get restSeconds => 3;
  @override
  bool get voiceCountingEnabled => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  @override
  bool ttsEnabledOf(String id) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
