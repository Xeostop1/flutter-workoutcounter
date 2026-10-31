import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import 'records_viewmodel.dart';

class CounterViewModel extends ChangeNotifier {
  CounterViewModel(this._records);

  final RecordsViewModel _records;

  static const _defaultExercise = Exercise(
    id: 'NA',
    name: '운동',
    reps: 10,
    sets: 2,
    repSeconds: 2,
  );

  static const Duration _lastRepHold = Duration(seconds: 1);

  // 현재 루틴 상태
  Routine? routine;
  int exerciseIndex = 0;
  List<bool> exerciseDone = const [];
  List<int> _exerciseReps = [];

  // 카운터 상태
  int setNow = 1;
  int repNow = 0;
  bool isRunning = false;
  bool isResting = false;
  bool workoutCompleted = false;
  bool workoutEndedEarly = false;
  bool isSavingWorkout = false;
  bool workoutSaveFailed = false;
  double progress = 0.0; // 0~1

  // 휴식 상태
  int restSec = 3;
  int restLeftSeconds = 0;

  // TTS 상태
  bool ttsOn = true;

  Timer? _timer;
  Timer? _holdTimer;
  WorkoutRecord? _pendingWorkoutRecord;
  String? _pendingWorkoutUid;
  String? _accountUid;
  int _accountGeneration = 0;
  bool _pendingEarlyExit = false;
  double _withinRep = 0.0;
  bool _setStarted = false;
  Future<void>? _pendingSpeech;

  bool get hasPendingWorkout => _pendingWorkoutRecord != null;
  bool get setStarted => _setStarted;
  bool get isWaitingForNextSet => _holdTimer?.isActive ?? false;

  // The configured interval is a minimum; don't advance past an unfinished cue.
  void waitForSpeech(Future<void> speech) {
    _pendingSpeech = speech;
    void release() {
      if (identical(_pendingSpeech, speech)) _pendingSpeech = null;
    }

    speech.then((_) => release(), onError: (Object _) => release());
  }

  void bindAccount(String? uid) {
    if (_accountUid == uid) return;
    _accountUid = uid;
    _accountGeneration++;
    _cancelAllTimers();
    _resetCounterState();
    routine = null;
    exerciseIndex = 0;
    exerciseDone = const [];
    _exerciseReps = [];
    _pendingWorkoutRecord = null;
    _pendingWorkoutUid = null;
    isSavingWorkout = false;
    workoutSaveFailed = false;
    workoutCompleted = false;
    workoutEndedEarly = false;
    notifyListeners();
  }

  Exercise get current {
    final r = routine;
    if (r == null || r.items.isEmpty) return _defaultExercise;
    if (exerciseIndex < 0 || exerciseIndex >= r.items.length) {
      return r.items.first;
    }
    return r.items[exerciseIndex];
  }

  int get repSeconds => _safePositive(current.repSeconds, 2);
  int get totalSets => _safePositive(current.sets, 2);
  int get repsPerSet => _safePositive(current.reps, 10);
  int get restSeconds => restSec;
  // Cue the current repetition at its start; record it only after its interval.
  int get currentRep => (repNow + 1).clamp(1, repsPerSet);
  int get setSecondsLeft => ((repsPerSet - repNow - _withinRep) * repSeconds)
      .ceil()
      .clamp(0, repsPerSet * repSeconds)
      .toInt();

  bool get inProgress =>
      _setStarted ||
      isRunning ||
      isResting ||
      repNow > 0 ||
      setNow > 1 ||
      progress > 0 ||
      totalRepsDoneSoFar > 0 ||
      exerciseIndex > 0;

  int get totalRepsDoneSoFar =>
      _exerciseReps.fold(0, (sum, reps) => sum + reps);

  void attachRoutine(Routine r) {
    if (hasPendingWorkout) return;
    _cancelAllTimers();
    _resetCounterState();
    workoutCompleted = false;
    workoutEndedEarly = false;
    isSavingWorkout = false;
    workoutSaveFailed = false;
    _pendingWorkoutRecord = null;
    routine = r;
    exerciseIndex = 0;
    exerciseDone = List<bool>.filled(r.items.length, false);
    _exerciseReps = List<int>.filled(r.items.length, 0);
    notifyListeners();
  }

  void selectExercise(int index) {
    if (hasPendingWorkout) return;
    final r = routine;
    if (r == null) return;
    if (index < 0 || index >= r.items.length) return;
    if (index == exerciseIndex || exerciseDone[index]) return;

    _cancelAllTimers();
    _resetCounterState();
    exerciseIndex = index;
    _restoreExerciseProgress();
    notifyListeners();
  }

  void setRestSeconds(int seconds) {
    final next = seconds.clamp(1, 600).toInt();
    if (restSec == next) return;
    restSec = next;
    notifyListeners();
  }

  void setTts(bool enabled) {
    if (ttsOn == enabled) return;
    ttsOn = enabled;
    if (!enabled) _pendingSpeech = null;
    notifyListeners();
  }

  void pauseForEdit() {
    if (hasPendingWorkout) return;
    _cancelAllTimers();
    isRunning = false;
    isResting = false;
    restLeftSeconds = 0;
    _withinRep = 0.0;

    _restoreExerciseProgress();
    notifyListeners();
  }

  void updateCurrentExercise(Exercise updated) {
    if (hasPendingWorkout) return;
    final r = routine;
    if (r == null || r.items.isEmpty) return;
    if (exerciseIndex < 0 || exerciseIndex >= r.items.length) return;

    final nextItems = List<Exercise>.from(r.items);
    nextItems[exerciseIndex] = updated;
    routine = r.copyWith(items: nextItems);

    // 짧은 한국어 주석: 수정 시 카운터는 멈춤
    _cancelAllTimers();
    isRunning = false;
    isResting = false;
    restLeftSeconds = 0;

    _withinRep = 0.0;
    _restoreExerciseProgress();

    notifyListeners();
  }

  void startPause() {
    if (hasPendingWorkout) return;
    isRunning ? _pause() : _start();
  }

  void stop() {
    if (hasPendingWorkout) return;
    _cancelAllTimers();
    if (exerciseIndex >= 0 && exerciseIndex < _exerciseReps.length) {
      _exerciseReps[exerciseIndex] = 0;
      exerciseDone[exerciseIndex] = false;
    }
    _resetCounterState();
    workoutCompleted = false;
    workoutEndedEarly = false;
    isSavingWorkout = false;
    workoutSaveFailed = false;
    _pendingWorkoutRecord = null;
    notifyListeners();
  }

  void reset() => stop();

  void consumeWorkoutCompletion() {
    if (!workoutCompleted) return;
    workoutCompleted = false;
    notifyListeners();
  }

  Future<void> retryWorkoutSave() => _savePendingWorkout();

  Future<bool> finishNowAndRecord() async {
    if (workoutEndedEarly) return true;
    if (hasPendingWorkout) return false;
    final r = routine;
    final totalReps = totalRepsDoneSoFar;
    if (r != null && totalReps > 0) {
      _cancelAllTimers();
      _pendingEarlyExit = true;
      _pendingWorkoutUid = _records.accountUid;
      _pendingWorkoutRecord = WorkoutRecord(
        date: DateTime.now(),
        routineId: r.id,
        routineTitle: r.title,
        totalReps: totalReps,
        exercises: List.unmodifiable(r.items),
      );
      _resetCounterState();
      await _savePendingWorkout();
      return workoutEndedEarly;
    }
    stop();
    return true;
  }

  void _start() {
    if (isResting || isRunning || (_holdTimer?.isActive ?? false)) return;
    if (routine == null || routine!.items.isEmpty) return;
    if (_exerciseReps[exerciseIndex] >= totalSets * repsPerSet) {
      _finishExercise();
      return;
    }
    _startProgressTimer();
  }

  void _pause() {
    isRunning = false;
    _cancelTickTimer();
    notifyListeners();
  }

  void _startProgressTimer() {
    _cancelAllTimers();

    const stepCount = 20;
    final intervalMs = (repSeconds * 1000 / stepCount)
        .round()
        .clamp(16, 1000000)
        .toInt();

    _withinRep = 0.0;
    isRunning = true;
    _setStarted = true;
    notifyListeners();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!isRunning || isResting) {
        timer.cancel();
        return;
      }

      _withinRep = (_withinRep + 1 / stepCount).clamp(0.0, 1.0);
      progress = ((repNow + _withinRep) / repsPerSet).clamp(0.0, 1.0);

      if (_withinRep >= 1.0) {
        if (_pendingSpeech != null) return;
        _withinRep = 0.0;
        repNow++;
        _exerciseReps[exerciseIndex]++;

        if (repNow >= repsPerSet) {
          timer.cancel();
          isRunning = false;
          progress = 1.0;
          _holdTimer = Timer.periodic(_lastRepHold, (timer) {
            if (_pendingSpeech != null) return;
            timer.cancel();
            if (setNow >= totalSets) {
              _finishExercise();
            } else {
              repNow = 0;
              progress = 0.0;
              _startRest();
            }
          });
          notifyListeners();
          return;
        }
      }

      notifyListeners();
    });
  }

  void _startRest({bool advanceSet = true}) {
    _cancelAllTimers();

    isResting = true;
    restLeftSeconds = restSeconds;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isResting) {
        timer.cancel();
        return;
      }

      if (_pendingSpeech != null) return;

      restLeftSeconds = (restLeftSeconds - 1).clamp(0, 3600).toInt();
      notifyListeners();

      if (restLeftSeconds <= 0) {
        timer.cancel();
        isResting = false;
        if (advanceSet) setNow++;
        _start();
      }
    });
  }

  void _finishExercise() {
    final r = routine;
    if (r == null) {
      stop();
      return;
    }

    if (exerciseIndex >= 0 && exerciseIndex < exerciseDone.length) {
      exerciseDone[exerciseIndex] = true;
    }

    var nextIndex = exerciseIndex + 1;
    while (nextIndex < r.items.length && exerciseDone[nextIndex]) {
      nextIndex++;
    }
    if (nextIndex < r.items.length) {
      exerciseIndex = nextIndex;
      _resetCounterState();
      _restoreExerciseProgress();
      _startRest(advanceSet: false);
      notifyListeners();
      return;
    }

    unawaited(_finishWorkout());
  }

  Future<void> _finishWorkout() async {
    final r = routine;
    if (r == null) return;

    _cancelAllTimers();
    _resetCounterState();
    _pendingEarlyExit = exerciseDone.any((done) => !done);
    _pendingWorkoutUid = _records.accountUid;
    _pendingWorkoutRecord = WorkoutRecord(
      date: DateTime.now(),
      routineId: r.id,
      routineTitle: r.title,
      totalReps: totalRepsDoneSoFar,
      exercises: List.unmodifiable(r.items),
    );
    await _savePendingWorkout();
  }

  Future<void> _savePendingWorkout() async {
    final record = _pendingWorkoutRecord;
    if (record == null || isSavingWorkout) return;
    final generation = _accountGeneration;

    isSavingWorkout = true;
    workoutSaveFailed = false;
    notifyListeners();

    try {
      await _records.addRecord(record, accountUid: _pendingWorkoutUid);
      if (generation != _accountGeneration) return;
      _pendingWorkoutRecord = null;
      workoutEndedEarly = _pendingEarlyExit;
      workoutCompleted = !_pendingEarlyExit;
    } catch (_) {
      if (generation == _accountGeneration) workoutSaveFailed = true;
    } finally {
      if (generation == _accountGeneration) {
        isSavingWorkout = false;
        notifyListeners();
      }
    }
  }

  void _resetCounterState() {
    _setStarted = false;
    isRunning = false;
    isResting = false;
    setNow = 1;
    repNow = 0;
    progress = 0.0;
    _withinRep = 0.0;
    restLeftSeconds = 0;
  }

  void _restoreExerciseProgress() {
    if (exerciseIndex < 0 || exerciseIndex >= _exerciseReps.length) return;
    final reps = _exerciseReps[exerciseIndex];
    setNow = (reps ~/ repsPerSet + 1).clamp(1, totalSets).toInt();
    repNow = reps >= totalSets * repsPerSet ? repsPerSet : reps % repsPerSet;
    progress = (repNow / repsPerSet).clamp(0.0, 1.0);
    _setStarted = repNow > 0;
  }

  void _cancelTickTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _cancelAllTimers() {
    _pendingSpeech = null;
    _cancelTickTimer();
    _cancelHoldTimer();
  }

  int _safePositive(int value, int fallback) {
    if (value <= 0) return fallback;
    return value;
  }

  @override
  void dispose() {
    _accountGeneration++;
    _cancelAllTimers();
    super.dispose();
  }
}
