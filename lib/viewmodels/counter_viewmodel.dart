import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import '../repositories/tts_repository.dart';
import 'records_viewmodel.dart';

class CounterViewModel extends ChangeNotifier {
  final TtsRepository _tts;
  final RecordsViewModel _records;

  // ✅ TTS on/off
  bool ttsOn = true;
  void setTts(bool v) { ttsOn = v; notifyListeners(); }

  Routine? routine;

  // 진행 상태
  int setNow = 1;      // 현재 세트 (1부터)
  int repNow = 0;      // 현재 세트에서 완료한 반복 수
  double _repFrac = 0; // 현재 반복의 진행도 0~1 (애니메이션용)

  bool isRunning = false;
  bool isResting = false;
  Timer? _timer;

  CounterViewModel(this._tts, this._records);

  // 기본값
  int get defaultSets => 2;
  int get defaultReps => 10;
  int get restSeconds => 10;
  int get repSeconds => routine?.primary.repSeconds ?? 2;
  int get totalSets  => routine?.primary.sets ?? defaultSets;
  int get repsPerSet => routine?.primary.reps ?? defaultReps;

  // ✅ 링에 그릴 0~1 진행도 (세트 내 전체 진행)
  double get progress => (repsPerSet == 0) ? 0 : (repNow + _repFrac) / repsPerSet;

  void attachRoutine(Routine r) { routine = r; reset(); }

  void startPause() => isRunning ? _pause() : _start();

  void _start() {
    if (isResting) return;
    isRunning = true;
    _startProgressTimer();
    notifyListeners();
  }

  void _pause() {
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    isResting = false;
    repNow = 0;
    setNow = 1;
    _repFrac = 0;
    notifyListeners();
    _tts.stop();
  }

  void reset() => stop();

  void _startProgressTimer() {
    _timer?.cancel();

    // 부드러운 애니메이션: 1회 반복을 20스텝으로 쪼갬
    const stepCount = 20;
    final step = 1 / stepCount;
    final intervalMs = (repSeconds * 1000 / stepCount).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      // 현재 반복 진행
      _repFrac += step;

      // 한 반복 끝
      if (_repFrac >= 1.0) {
        _repFrac = 0;
        repNow++;
        if (ttsOn) _tts.speakCount(repNow);
      }

      // 세트 끝
      if (repNow >= repsPerSet) {
        t.cancel();
        isRunning = false;
        _repFrac = 0;
        repNow = 0;

        if (setNow >= totalSets) {
          _finishWorkout();
        } else {
          _startRest();
        }
      }
      notifyListeners(); // 💡 진행 상황 갱신
    });
  }

  void _startRest() async {
    isResting = true;
    notifyListeners();

    if (ttsOn) await _tts.speakRest(restSeconds);

    int left = restSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      left--;
      if (left <= 0) {
        t.cancel();
        isResting = false;
        setNow++;       // 다음 세트로
        startPause();   // 자동 시작 (원하면 버튼으로 바꿔도 됨)
      }
      notifyListeners();
    });
  }

  void _finishWorkout() {
    final r = routine;
    if (r != null) {
      _records.addRecord(
        WorkoutRecord(
          date: DateTime.now(),
          routineId: r.id,
          routineTitle: r.title,
          totalReps: totalSets * repsPerSet,
        ),
      );
    }
    stop();
  }
}
