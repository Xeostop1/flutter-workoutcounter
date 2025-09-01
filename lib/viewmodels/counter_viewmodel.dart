import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import '../repositories/tts_repository.dart';
import 'records_viewmodel.dart';

class CounterViewModel extends ChangeNotifier {
  final TtsRepository _tts;
  final RecordsViewModel _records;

  Routine? routine;
  int setNow = 1;
  int repNow = 0;
  bool isRunning = false;
  bool isResting = false;
  double progress = 0.0; // 0~1
  Timer? _timer;

  CounterViewModel(this._tts, this._records);

  int get defaultSets => 2;
  int get defaultReps => 10;
  int get restSeconds => 10;
  int get repSeconds => routine?.primary.repSeconds ?? 2;
  int get totalSets => routine?.primary.sets ?? defaultSets;
  int get repsPerSet => routine?.primary.reps ?? defaultReps;

  void attachRoutine(Routine r) { routine = r; reset(); }

  void startPause() { isRunning ? _pause() : _start(); }

  void _start() {
    if (isResting) return;
    isRunning = true;
    _startProgressTimer();
    notifyListeners();
  }

  void _pause() { isRunning = false; _timer?.cancel(); notifyListeners(); }

  void stop() { _timer?.cancel(); isRunning=false; isResting=false; repNow=0; setNow=1; progress=0; notifyListeners(); _tts.stop(); }

  void reset() => stop();

  void _startProgressTimer() {
    _timer?.cancel();
    final stepCount = 20; // 부드러운 진행
    final intervalMs = (repSeconds * 1000 / stepCount).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      final step = 1 / stepCount;
      progress = (repNow + progress + step) / repsPerSet;

      if (progress >= (repNow + 1) / repsPerSet) {
        repNow++;
        _tts.speakCount(repNow);
      }

      if (repNow >= repsPerSet) {
        t.cancel();
        isRunning = false;
        progress = 0;
        repNow = 0;

        if (setNow >= totalSets) {
          _finishWorkout();
        } else {
          _startRest();
        }
      }
      notifyListeners();
    });
  }

  void _startRest() async {
    isResting = true;
    notifyListeners();
    await _tts.speakRest(restSeconds);
    int left = restSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      left--;
      if (left <= 0) {
        t.cancel();
        isResting = false;
        setNow++;
        startPause();
      }
    });
  }

  void _finishWorkout() {
    final r = routine;
    if (r != null) {
      _records.addRecord(WorkoutRecord(
        date: DateTime.now(),
        routineId: r.id,
        routineTitle: r.title,
        totalReps: totalSets * repsPerSet,
      ));
    }
    stop();
  }
}
