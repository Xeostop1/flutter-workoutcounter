// Device-only verification: production counter and native TTS, in-memory records.
// No Firebase initialization, authentication bypass, or production data writes.
import 'dart:convert';
import 'dart:io';

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/pages/counter/counter_page.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/services/tts_service.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/counter_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TtsService.instance.warmUp();
  final directory = await getApplicationDocumentsDirectory();
  runApp(_CounterVoiceProbe(directory));
}

class _CounterVoiceProbe extends StatefulWidget {
  const _CounterVoiceProbe(this.directory);
  final Directory directory;
  @override
  State<_CounterVoiceProbe> createState() => _CounterVoiceProbeState();
}

class _CounterVoiceProbeState extends State<_CounterVoiceProbe> {
  final _records = RecordsViewModel(InMemoryRecordRepository());
  late final _counter = CounterViewModel(_records);
  final _auth = _ProbeAuth();
  final _routines = _ProbeRoutines();
  final _clock = Stopwatch()..start();
  final _events = <Map<String, dynamic>>[];
  late final _engine = _ObservedTts(_event);
  late final GoRouter _router;
  int _seconds = 2;
  String _lastState = '';
  String _status = '동일한 운동 화면 · 실제 Android TTS · 기록은 메모리에만 저장';

  void _event(String kind, Object? detail) {
    final event = {
      'ms': _clock.elapsedMilliseconds,
      'kind': kind,
      'detail': detail,
    };
    _events.add(event);
    debugPrint('COUNTER_VOICE_PROBE ${jsonEncode(event)}');
  }

  @override
  void initState() {
    super.initState();
    // Observe native callbacks without replacing the production speech service.
    _engine;
    _counter.addListener(_observeCounter);
    _router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => _home()),
        GoRoute(
          path: '/counter',
          builder: (_, __) => CounterPage(
            routine: Routine(
              id: 'voice-probe-$_seconds',
              title: '음성 검사 · $_seconds초 간격',
              categoryId: Routine.freeCategoryId,
              items: [
                Exercise(
                  id: 'squat',
                  name: '스쿼트',
                  sets: 2,
                  reps: 3,
                  repSeconds: _seconds,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _observeCounter() {
    final key =
        '${_counter.isRunning}:${_counter.isResting}:${_counter.setNow}:'
        '${_counter.currentRep}:${_counter.restLeftSeconds}:${_counter.workoutCompleted}';
    if (key == _lastState) return;
    _lastState = key;
    _event('counter', {
      'running': _counter.isRunning,
      'resting': _counter.isResting,
      'set': _counter.setNow,
      'rep': _counter.currentRep,
      'rest_left': _counter.restLeftSeconds,
      'completed': _counter.workoutCompleted,
    });
    if (_counter.workoutCompleted) _saveReport();
  }

  Future<void> _saveReport() async {
    // Wait for the final native callback and the page's normal completion route.
    await Future<void>.delayed(const Duration(seconds: 3));
    final file = File('${widget.directory.path}/counter-voice-$_seconds.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'rep_seconds': _seconds,
        'rest_seconds': 3,
        'engine': await _engine.getDefaultEngine,
        'record_count': _records.records.length,
        'total_reps': _records.records.lastOrNull?.totalReps,
        'events': _events,
      }),
    );
    if (mounted) setState(() => _status = '$_seconds초 간격 검사 완료 · ${file.path}');
  }

  void _open(int seconds) {
    _seconds = seconds;
    _events.clear();
    _lastState = '';
    _clock.reset();
    _router.go('/counter');
  }

  Widget _home() => Scaffold(
    appBar: AppBar(title: const Text('테스트 전용 · 실제 운동/TTS 검사')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status),
          const Text('Firebase 미연결 · 로그인/실제 운동 기록 변경 없음'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _open(2),
            child: const Text('2초 간격 검사'),
          ),
          FilledButton(
            onPressed: () => _open(1),
            child: const Text('1초 간격 검사'),
          ),
          FilledButton(
            onPressed: () => _open(10),
            child: const Text('화면 유지 검사 · 10초 간격'),
          ),
          const Text('운동 화면의 시작 버튼을 누르면 3회 × 2세트, 휴식 3초를 실행합니다.'),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<CounterViewModel>.value(value: _counter),
      ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
      ChangeNotifierProvider<RoutinesViewModel>.value(value: _routines),
    ],
    child: MaterialApp.router(theme: AppTheme.dark, routerConfig: _router),
  );

  @override
  void dispose() {
    _router.dispose();
    _counter.dispose();
    _records.dispose();
    _auth.dispose();
    _routines.dispose();
    super.dispose();
  }
}

class _ObservedTts extends FlutterTts {
  _ObservedTts(this.record);
  final void Function(String, Object?) record;
  @override
  Future<dynamic> platformCallHandler(MethodCall call) async {
    record(call.method, call.arguments);
    return super.platformCallHandler(call);
  }
}

class _ProbeAuth extends ChangeNotifier implements AuthViewModel {
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

class _ProbeRoutines extends ChangeNotifier implements RoutinesViewModel {
  @override
  bool ttsEnabledOf(String id) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
