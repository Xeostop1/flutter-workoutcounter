import 'dart:async';

import 'package:counter_01/models/system_voice.dart';
import 'package:counter_01/models/trainer_voice.dart';
import 'dart:io';
import 'package:counter_01/theme/app_theme.dart';
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
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
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

  testWidgets(
    'slow native speech stays synchronized across rest and next set',
    (tester) async {
      final counter = await _pumpCounter(tester, const Size(375, 812));
      counter.attachRoutine(
        const Routine(
          id: 'native-busy',
          title: '긴 발화',
          categoryId: 'free',
          items: [
            Exercise(id: 'squat', name: '스쿼트', sets: 2, reps: 1, repSeconds: 1),
          ],
        ),
      );
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('음성 켜기'));
      await tester.pumpAndSettle();
      final spoken = <String>[];
      final completions = <Completer<int>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
            call,
          ) async {
            if (call.method != 'speak') return 1;
            if (completions.any((entry) => !entry.isCompleted)) return 0;
            final args = call.arguments;
            spoken.add(args is Map ? args['text'] as String : args as String);
            final completion = Completer<int>();
            completions.add(completion);
            return completion.future;
          });
      counter.startPause();
      await tester.pump();
      await tester.pump();
      expect(spoken, ['시작! 하나!']);
      await tester.pump(const Duration(seconds: 3));
      expect(counter.repNow, 0);
      expect(counter.isRunning, isTrue);
      completions.last.complete(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(spoken.last, '좋아요, 한 세트 끝!');
      await tester.pump(const Duration(seconds: 3));
      expect(counter.isResting, isFalse);
      completions.last.complete(1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(counter.isResting, isTrue);
      expect(spoken.last, '휴식! 1!');
      await tester.pump(const Duration(seconds: 2));
      expect(counter.restLeftSeconds, 3);
      for (final expected in ['2!', '3!', '시작! 하나!']) {
        completions.last.complete(1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(spoken.last, expected);
      }
      expect(spoken, [
        '시작! 하나!',
        '좋아요, 한 세트 끝!',
        '휴식! 1!',
        '2!',
        '3!',
        '시작! 하나!',
      ]);
      expect(counter.setNow, 2);
      expect(counter.isRunning, isTrue);
      counter.startPause();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      counter.reset();
      // The native engine is allowed to omit its cancel callback.
      completions.last.complete(0);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('sporkle/screen_awake'),
          (_) async => null,
        );
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
    expect(tester.getTopLeft(find.byType(GradientCircularCounter)).dy, 216);
    expect(tester.getTopLeft(find.bySemanticsLabel('운동 시작')).dy, 528);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'ready');
  });

  testWidgets('운동 전환 후 완료 표시와 진행 화면을 표시한다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    counter.exerciseDone[0] = true;
    counter.selectExercise(1);
    counter.startPause();
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    final ring = tester.getRect(
      find.ancestor(of: find.text('1'), matching: find.byType(SizedBox)).first,
    );
    expect(ring.top, 216);
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

  testWidgets('운동 진행률이 굵은 그라데이션 원에 연결되고 음소거 상태를 표시한다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    expect(find.bySemanticsLabel('음성 켜기'), findsOneWidget);
    counter.startPause();
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    final ring = tester.widget<GradientCircularCounter>(
      find.byType(GradientCircularCounter),
    );
    expect(ring.thickness, 30);
    expect(ring.progress, greaterThan(0));
    expect(ring.progress, counter.progress);
    expect(find.bySemanticsLabel('음성 켜기'), findsOneWidget);
    counter.startPause();
    await tester.pumpAndSettle();
    await _preview(tester, 'progress');
  });

  testWidgets('음성 버튼으로 전체 설정을 켜고 세션을 다시 음소거할 수 있다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    await tester.tap(find.bySemanticsLabel('음성 켜기'));
    await tester.pumpAndSettle();
    final auth = tester.element(find.byType(CounterPage)).read<AuthViewModel>();
    expect(auth.voiceCountingEnabled, isTrue);
    expect(counter.ttsOn, isTrue);
    expect(find.bySemanticsLabel('음성 끄기'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('음성 끄기'));
    await tester.pumpAndSettle();
    expect(counter.ttsOn, isFalse);
    expect(find.bySemanticsLabel('음성 켜기'), findsOneWidget);
  });

  testWidgets('3세트 15회는 각 세트 1부터 15까지 표시하고 모두 읽는다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    final spoken = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'speak') {
            final args = call.arguments;
            spoken.add(args is Map ? args['text'] as String : args as String);
          }
          return 1;
        });
    counter.attachRoutine(
      const Routine(
        id: 'three',
        title: '세트 검사',
        categoryId: 'free',
        items: [
          Exercise(id: 'squat', name: '스쿼트', sets: 3, reps: 15, repSeconds: 3),
        ],
      ),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('음성 켜기'));
    await tester.pumpAndSettle();
    spoken.clear();
    counter.startPause();
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('/ 15회'), findsOneWidget);
    expect(find.text('45'), findsNothing);
    expect(spoken, ['시작! 하나!']);
    counter.startPause();
    await tester.pump(const Duration(seconds: 5));
    expect(counter.currentRep, 1);
    expect(counter.totalRepsDoneSoFar, 0);
    expect(find.bySemanticsLabel('계속하기'), findsOneWidget);
    counter.startPause();
    await tester.pump();
    expect(spoken, ['시작! 하나!']);
    for (var set = 1; set <= 3; set++) {
      expect(find.text('$set / 3 세트'), findsOneWidget);
      for (var rep = 1; rep <= 15; rep++) {
        if (rep > 1) await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(counter.currentRep, rep);
        expect(counter.repNow, rep - 1);
        expect(find.text('$rep'), findsOneWidget);
        expect(
          spoken,
          isNotEmpty,
          reason:
              'set=$set rep=$rep voice=${counter.ttsOn} auth=${tester.element(find.byType(CounterPage)).read<AuthViewModel>().voiceCountingEnabled}',
        );
        expect(spoken.last, '${rep == 1 ? '시작! ' : ''}${koreanCount(rep)}!');
      }
      // The fifteenth repetition still gets its full exercise interval.
      await tester.pump(const Duration(seconds: 3));
      expect(counter.repNow, 15);
      if (set < 3) {
        await tester.pump(const Duration(seconds: 1));
        final restRing = tester.widget<GradientCircularCounter>(
          find.byType(GradientCircularCounter),
        );
        expect(restRing.gradient3, const Color(0xFF22C55E));
        expect(find.text('휴식'), findsOneWidget);
        expect(spoken.last, '휴식! 1!');
        expect(counter.restLeftSeconds, 3);
        counter.setTts(true);
        await tester.pump();
        expect(spoken.where((text) => text == '휴식! 1!').length, set);
        await tester.pump(const Duration(seconds: 1));
        expect(spoken.last, '2!');
        await tester.pump(const Duration(milliseconds: 250));
        await _preview(tester, 'rest');
        await tester.pump(const Duration(milliseconds: 1750));
        await tester.pump();
        expect(counter.repNow, 0);
      }
    }
    expect(spoken, [
      for (var set = 0; set < 3; set++) ...[
        for (var rep = 1; rep <= 15; rep++)
          '${rep == 1 ? '시작! ' : ''}${koreanCount(rep)}!',
        '좋아요, 한 세트 끝!',
        if (set < 2) ...['휴식! 1!', '2!', '3!'],
      ],
    ]);
    await tester.pumpWidget(const SizedBox());
    counter.reset();
  });

  testWidgets('폭 320인 작은 화면에서도 버튼이 넘치지 않는다', (tester) async {
    await _pumpCounter(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('1초 휴식과 다음 운동 시작은 한 번씩 읽고 초기화하면 다시 시작을 읽는다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(375, 812));
    final spoken = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'speak') {
            final args = call.arguments;
            spoken.add(args is Map ? args['text'] as String : args as String);
          }
          return 1;
        });
    counter.attachRoutine(
      const Routine(
        id: 'short-rest',
        title: '전환 검사',
        categoryId: 'free',
        items: [
          Exercise(id: 'squat', name: '스쿼트', sets: 1, reps: 1, repSeconds: 1),
          Exercise(id: 'lunge', name: '런지', sets: 2, reps: 2, repSeconds: 1),
        ],
      ),
    );
    counter.setRestSeconds(1);
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('음성 켜기'));
    await tester.pumpAndSettle();
    spoken.clear();
    counter.startPause();
    await tester.pump();
    expect(counter.isRunning, isTrue);
    expect(counter.ttsOn, isTrue);
    expect(
      tester
          .element(find.byType(CounterPage))
          .read<AuthViewModel>()
          .voiceCountingEnabled,
      isTrue,
    );
    expect(spoken, ['시작! 하나!']);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(counter.isResting, isTrue);
    expect(spoken.last, '휴식! 1!');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(counter.exerciseIndex, 1);
    expect(spoken, ['시작! 하나!', '좋아요, 한 세트 끝!', '휴식! 1!', '시작! 하나!']);
    counter.setTts(false);
    await tester.pump(const Duration(seconds: 4));
    expect(spoken.length, 4);
    counter.reset();
    counter.setTts(true);
    counter.startPause();
    await tester.pump();
    expect(spoken.last, '시작! 하나!');
    expect(spoken.length, 5);
    await tester.pumpWidget(const SizedBox());
    counter.reset();
  });

  testWidgets('진행 화면에서도 작은 화면은 스크롤할 수 있다', (tester) async {
    final counter = await _pumpCounter(tester, const Size(320, 568));
    counter.selectExercise(1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('런지'));
    expect(find.text('런지').hitTestable(), findsOneWidget);
  });

  testWidgets('운동·휴식 동안만 화면을 유지하고 일시정지·백그라운드·화면 종료 시 해제한다', (tester) async {
    final calls = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('sporkle/screen_awake'), (
          call,
        ) async {
          expect(call.method, 'setEnabled');
          calls.add(call.arguments as bool);
          return null;
        });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final counter = await _pumpCounter(tester, const Size(375, 812));
    expect(calls, [false]);
    counter.attachRoutine(
      const Routine(
        id: 'screen',
        title: '화면 유지',
        categoryId: 'free',
        items: [
          Exercise(id: 'squat', name: '스쿼트', sets: 2, reps: 1, repSeconds: 1),
        ],
      ),
    );
    counter.startPause();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, [
      false,
      true,
    ]); // Per-tick notifications don't spam the platform.
    counter.startPause();
    await tester.pump();
    expect(calls.last, false);
    counter.startPause();
    await tester.pump(const Duration(seconds: 1));
    expect(counter.isWaitingForNextSet, isTrue);
    expect(calls.last, true);
    await tester.pump(const Duration(seconds: 1));
    expect(counter.isResting, isTrue);
    expect(calls.last, true);
    final beforeBackground = calls.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls.last, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls.skip(beforeBackground), [false, true]);
    counter.pauseForEdit();
    await tester.pump();
    expect(calls.last, false);
    counter.startPause();
    await tester.pump();
    expect(calls.last, true);
    counter.reset();
    await tester.pump();
    expect(calls.last, false);
    counter.startPause();
    await tester.pump();
    expect(calls.last, true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls.last, false);
    counter.reset();
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
        theme: AppTheme.dark,
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
  TrainerVoice? get trainerVoice => null;
  @override
  String? get systemVoiceId => null;
  @override
  int get restSeconds => 3;
  bool _voice = false;
  @override
  bool get voiceCountingEnabled => _voice;
  @override
  double get voicePitch => 1;
  @override
  Future<void> setVoiceCountingEnabled(bool enabled) async {
    _voice = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  @override
  bool ttsEnabledOf(String id) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
