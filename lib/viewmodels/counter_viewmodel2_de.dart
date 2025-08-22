import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import '../services/tts_service.dart';

/// 카운터가 어떤 상태인지 나타내는 간단한 단계
enum CounterPhase { idle, rep, rest, done }

class CounterViewModel extends ChangeNotifier {
  final TtsService tts;
  final Future<void> Function(WorkoutRecord record)? onFinished;

  // ✅ 기본 루틴을 하드코딩-> 나중에 객체로 받는걸로 변경
  Routine _routine = Routine(
    // id: const Uuid().v4(),
    id: "1234",
    name: '스쿼트',
    sets: 2,
    reps: 2,
    secPerRep: 2.0,
    restSec: 10,
  );

  CounterViewModel({required this.tts, this.onFinished, bool voiceOn = true})
    : _voiceOn = voiceOn;

  CounterPhase _phase = CounterPhase.idle;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _voiceOn;

  int _currentSet = 1;
  int _currentRep = 0;

  DateTime? _startedAt;
  DateTime? _finishedAt;

  // === 읽기 전용 ===
  Routine get routine => _routine;
  String get routineName => _routine.name;
  int get totalSets => _routine.sets;
  int get repsPerSet => _routine.reps;
  double get secPerRep => _routine.secPerRep;
  int get restSec => _routine.restSec;

  CounterPhase get phase => _phase;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get voiceOn => _voiceOn;

  int get currentSet => _currentSet;
  int get currentRep => _currentRep;
  int get leftReps => (repsPerSet - _currentRep).clamp(0, repsPerSet);

  bool get isRest => _phase == CounterPhase.rest;

  double get currentDurationSeconds =>
      _phase == CounterPhase.rest ? restSec.toDouble() : secPerRep;

  int get sessionSeconds {
    if (_startedAt == null) return 0;
    final end = _finishedAt ?? DateTime.now();
    return end.difference(_startedAt!).inSeconds;
  }

  // === 루틴 교체 ===
  void updateRoutine(Routine newRoutine) {
    _routine = newRoutine;
    _resetProgress();
    _phase = CounterPhase.rep;
    notifyListeners();
  }

  // === 컨트롤 ===
  Future<void> start() async {
    if (_phase == CounterPhase.done) _resetProgress();
    _isPlaying = true;
    _isPaused = false;
    _startedAt ??= DateTime.now();
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _isPaused = true;
    notifyListeners();
  }

  Future<void> resetCurrentSet() async {
    _currentRep = 0;
    _phase = CounterPhase.rep;
    notifyListeners();
  }

  void toggleVoice() {
    _voiceOn = !_voiceOn;
    notifyListeners();
  }

  // === 애니메이션 1회 끝날 때마다 호출 ===
  Future<CounterPhase> onTickEnd() async {
    if (!_isPlaying || _isPaused) return _phase;

    if (_phase == CounterPhase.rest) {
      _phase = CounterPhase.rep;
      _currentRep = 0;
      if (_voiceOn) await tts.speak('${_currentSet}세트 시작');
      notifyListeners();
      return _phase;
    }

    _currentRep += 1;
    if (_voiceOn) await tts.count(_currentRep);

    if (_currentRep < repsPerSet) {
      notifyListeners();
      return _phase;
    }

    final isLastSet = _currentSet >= totalSets;
    if (isLastSet) {
      _phase = CounterPhase.done;
      _isPlaying = false;
      _isPaused = false;
      _finishedAt = DateTime.now();

      final record = WorkoutRecord(
        id: '${_routine.id}_${_finishedAt!.millisecondsSinceEpoch}',
        routineId: _routine.id,
        routineName: _routine.name,
        date: _finishedAt!,
        doneSets: totalSets,
        doneRepsTotal: totalSets * repsPerSet,
        durationSec: sessionSeconds,
      );
      if (onFinished != null) {
        await onFinished!(record);
      }

      notifyListeners();
      return _phase;
    }

    _currentSet += 1;
    _currentRep = 0;

    if (restSec > 0) {
      _phase = CounterPhase.rest;
    } else {
      _phase = CounterPhase.rep;
    }

    notifyListeners();
    return _phase;
  }

  void _resetProgress() {
    _phase = CounterPhase.rep;
    _isPlaying = false;
    _isPaused = false;
    _currentSet = 1;
    _currentRep = 0;
    _startedAt = null;
    _finishedAt = null;
  }
}
