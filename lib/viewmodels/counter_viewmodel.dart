// lib/viewmodels/counter_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import '../repositories/tts_repository.dart';
import 'records_viewmodel.dart';

class CounterViewModel extends ChangeNotifier {
  final TtsRepository _tts;
  final RecordsViewModel _records;

  CounterViewModel(this._tts, this._records);

  // ===== 루틴/운동 =====
  Routine? routine;
  int exerciseIndex = 0;
  List<bool> exerciseDone = const [];

  Exercise get current {
    final r = routine;
    if (r == null || r.items.isEmpty) {
      return const Exercise(id: 'NA', name: '운동', reps: 10, sets: 2, repSeconds: 2);
    }
    return r.items[exerciseIndex];
  }

  // ===== 카운터 상태 =====
  int setNow = 1;
  int repNow = 0;
  bool isRunning = false;
  bool isResting = false;
  double progress = 0.0; // 0~1
  Timer? _timer;

  // 1회 반복(1 rep)의 내부 진행도
  double _withinRep = 0.0;

  // 마지막 카운트 보여주는 홀드 시간
  final Duration lastRepHold = const Duration(seconds: 1);

  // ===== 파생값(현재 운동 기준) =====
  int get repSeconds => current.repSeconds <= 0 ? 2 : current.repSeconds;
  int get totalSets  => current.sets       <= 0 ? 2 : current.sets;
  int get repsPerSet => current.reps       <= 0 ? 10: current.reps;

  // ===== 휴식 설정/카운트다운 =====
  int restSec = 10;            // 사용자가 정하는 기본 휴식 초
  int restLeftSeconds = 0;     // 화면에 보여줄 남은 휴식 초
  int get restSeconds => restSec;  // ← 이 한 곳만 존재(중복 선언 금지)

  void setRestSeconds(int s) {
    restSec = s.clamp(1, 600);
    notifyListeners();
  }

  // ===== TTS 온/오프 =====
  bool ttsOn = true;
  void setTts(bool v) { ttsOn = v; notifyListeners(); }

  // ===== 진행 중 여부(뒤로가기 모달에서 사용) =====
  bool get inProgress =>
      isRunning || isResting || repNow > 0 || setNow > 1 || progress > 0 || exerciseIndex > 0;

  // 부분 기록 합계
  int get totalRepsDoneSoFar {
    final setsDone = isResting ? totalSets : (setNow - 1).clamp(0, totalSets);
    final repsNow  = isResting ? 0 : repNow;
    return setsDone * repsPerSet + repsNow;
  }

  // ===== 루틴 연결/운동 선택 =====
  void attachRoutine(Routine r) {
    routine = r;
    exerciseIndex = 0;
    exerciseDone = List<bool>.filled(r.items.length, false);
    reset();
  }

  void selectExercise(int i) {
    final r = routine;
    if (r == null) return;
    if (i < 0 || i >= r.items.length) return;
    stop();                // 진행 중이면 정지 후
    exerciseIndex = i;     // 현재 운동 변경
    notifyListeners();
  }

  // ===== 컨트롤 =====
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
    progress = 0;
    _withinRep = 0.0;
    restLeftSeconds = 0;
    _tts.stop();
    notifyListeners();
  }

  void reset() => stop();

  // ===== 타이머/진행 =====
  void _startProgressTimer() {
    _timer?.cancel();

    final reps = repsPerSet;
    final sec  = repSeconds;

    const stepCount = 20; // 1회 반복을 20스텝으로
    final intervalMs = (sec * 1000 / stepCount).round().clamp(16, 1000000);

    _withinRep = 0.0;
    isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (!isRunning || isResting) {
        t.cancel();
        return;
      }

      // 1) 이번 rep 진행
      _withinRep += 1 / stepCount;

      // 2) 링 진행도
      progress = ((repNow + _withinRep) / reps).clamp(0.0, 1.0);

      // 3) rep 완료 시
      if (_withinRep >= 1.0) {
        _withinRep = 0.0;
        repNow++;
        if (ttsOn) _tts.speakCount(repNow);

        // 세트의 모든 rep 완료
        if (repNow >= reps) {
          t.cancel();
          isRunning = false;
          progress = 1.0;     // 링 가득 표시
          notifyListeners();  // UI가 마지막 카운트(예: 10)를 그릴 기회

          // 마지막 카운트 1초 보여준 뒤 휴식/다음 단계
          Timer(lastRepHold, () {
            if (setNow >= totalSets) {
              _finishExercise();  // 다음 운동 or 전체 종료
            } else {
              progress = 0.0;
              repNow = 0;
              _startRest();       // 세트 사이 휴식
            }
          });
          return;
        }
      }

      notifyListeners();
    });
  }

  // ===== 휴식: TTS 없음, 화면 카운트다운 =====
  void _startRest() {
    isResting = true;
    restLeftSeconds = restSeconds;  // 시작값 세팅
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      restLeftSeconds = (restLeftSeconds - 1).clamp(0, 3600);
      notifyListeners();

      if (restLeftSeconds <= 0) {
        t.cancel();
        isResting = false;
        setNow++;
        startPause(); // 다음 세트 시작
      }
    });
  }

  // ===== 운동(Exercise) 완료 처리 =====
  void _finishExercise() {
    final r = routine;
    if (r == null) { stop(); return; }

    if (exerciseIndex >= 0 && exerciseIndex < exerciseDone.length) {
      exerciseDone[exerciseIndex] = true; // 완료 마킹
    }

    // 다음 운동이 있으면 이동
    if (exerciseIndex < r.items.length - 1) {
      exerciseIndex++;
      setNow = 1;
      repNow = 0;
      progress = 0;
      _startRest(); // 운동 간 짧은 휴식
      notifyListeners();
      return;
    }

    // 마지막 운동까지 완료 → 전체 종료
    _finishWorkout();
  }

  // ===== 전체 워크아웃 기록/종료 =====
  void _finishWorkout() {
    final r = routine;
    if (r != null) {
      _records.addRecord(WorkoutRecord(
        date: DateTime.now(),
        routineId: r.id,
        routineTitle: r.title,
        totalReps: totalSets * repsPerSet, // 필요 시 전체 운동 합산으로 변경
      ));
    }
    stop();
  }

  // ===== 뒤로가기 '네' 시: 부분 기록 후 종료 =====
  Future<void> finishNowAndRecord() async {
    final r = routine;
    if (r != null) {
      _records.addRecord(WorkoutRecord(
        date: DateTime.now(),
        routineId: r.id,
        routineTitle: r.title,
        totalReps: totalRepsDoneSoFar,
      ));
    }
    stop();
  }
}
