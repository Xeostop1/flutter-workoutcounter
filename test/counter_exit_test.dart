import 'dart:async';
import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/pages/counter/counter_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Auth extends ChangeNotifier implements AuthViewModel {
  @override
  bool get voiceCountingEnabled => true;
  @override
  String? get systemVoiceId => null;
  @override
  int get restSeconds => 3;
  @override
  bool get homeTutorialDone => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  @override
  bool ttsEnabledOf(String id) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository extends InMemoryRecordRepository {
  bool fail = false;
  @override
  Future<void> save(WorkoutRecord record, {String? uid}) async {
    if (fail) throw StateError('offline');
    await super.save(record, uid: uid);
  }
}

const routine = Routine(
  id: 'free-exit',
  title: '자유 운동',
  categoryId: 'FREE',
  items: [Exercise(id: 'squat', name: '스쿼트', sets: 3, reps: 15, repSeconds: 2)],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Pretendard')..addFont(
          rootBundle.load('assets/fonts/Pretendard/Pretendard-Regular.ttf'),
        ))
        .load();
  });
  for (final scenario in ['saved', 'zero', 'retry']) {
    testWidgets('confirmed exit returns home despite stuck speech: $scenario', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final neverFinishes = Completer<int>();
      var spoken = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
            call,
          ) async {
            if (call.method == 'speak') {
              spoken++;
              // Complete one rep, then hang the next cue to exercise exit/save.
              if (scenario != 'zero' && spoken == 1) return 1;
              return neverFinishes.future;
            }
            if (call.method == 'getVoices') return [];
            return 1;
          });
      final repository = _Repository()..fail = scenario == 'retry';
      final records = RecordsViewModel(repository);
      final counter = CounterViewModel(records);
      final auth = _Auth();
      final routines = _Routines();
      final router = GoRouter(
        initialLocation: '/counter',
        routes: [
          GoRoute(
            path: '/counter',
            builder: (_, __) => const CounterPage(routine: routine),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('홈 화면')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CounterViewModel>.value(value: counter),
            ChangeNotifierProvider<AuthViewModel>.value(value: auth),
            ChangeNotifierProvider<RoutinesViewModel>.value(value: routines),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('운동 시작'));
      await tester.pump();
      expect(spoken, greaterThan(0));
      if (scenario != 'zero') await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('네'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (scenario == 'retry') {
        expect(find.text('홈 화면'), findsNothing);
        expect(counter.hasPendingWorkout, isTrue);
        repository.fail = false;
        await tester.tap(find.text('다시 저장하기'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.text('홈 화면'), findsOneWidget);
      expect(records.records.length, scenario == 'zero' ? 0 : 1);
      if (scenario != 'zero') expect(records.records.single.totalReps, 1);
      expect(counter.hasPendingWorkout, isFalse);
      await tester.pumpWidget(const SizedBox());
      neverFinishes.complete(1);
      await tester.pump();
      router.dispose();
      counter.dispose();
      records.dispose();
      auth.dispose();
      routines.dispose();
    });
  }
}
