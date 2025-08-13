import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';
import '../services/tts_service.dart';
import 'settings_viewmodel.dart';
import 'record_viewmodel.dart';

class CounterViewModel extends ChangeNotifier {
  final TtsService tts;
  final SettingsViewModel settings;
  final RecordViewModel records;

  // 현재 세션 설정
  Routine routine;

  // 진행 상태
  int currentSet = 1;
  int currentRep = 0;
  bool isRunning = false;
  bool isPaused = false;
  bool isResting = false;
  double progress = 0.0; // 0~1, 원형 표시용

  Timer? _tick;

  CounterViewModel({
    required this.tts,
    required this.settings,
    required this.records,
    Routine? initialRoutine,
  }) : routine =
           initialRoutine ??
           Routine(
             id: 'default',
             name: '스쿼트',
             sets: 3,
             reps: 15,
             secPerRep: 2.0,
           );

  void start() {
    if (isRunning && isPaused) {
      // 재개
      isPaused = false;
      _scheduleTick();
      notifyListeners();
      return;
    }
    reset();
    isRunning = true;
    _announce("시작");
    _scheduleTick();
    notifyListeners();
  }

  void _scheduleTick() {
    _tick?.cancel();
    _tick = Timer.periodic(
      Duration(milliseconds: (routine.secPerRep * 1000 / 20).round()),
      (t) {
        if (isPaused) return;
        // 20 step으로 부드럽게
        progress += 1 / 20 / routine.reps;
        if (progress >= (currentRep + 1) / routine.reps) {
          // 한 회 완료
          currentRep += 1;
          _announce("$currentRep");
        }
        if (currentRep >= routine.reps) {
          // 한 세트 완료
          if (currentSet >= routine.sets) {
            _finishAll();
          } else {
            _restThenNextSet();
          }
        }
        notifyListeners();
      },
    );
  }

  Future<void> _restThenNextSet() async {
    _tick?.cancel();
    isResting = true;
    _announce("휴식 시작");
    notifyListeners();

    for (int s = 10; s >= 1; s--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!isResting) break;
      if (s <= 3) _announce("$s");
    }
    if (!isResting) return;
    _announce("다음 세트");
    isResting = false;
    currentSet += 1;
    currentRep = 0;
    progress = 0.0;
    _scheduleTick();
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    isPaused = true;
    _tick?.cancel();
    _announce("일시정지");
    notifyListeners();
  }

  void stop() {
    _tick?.cancel();
    isRunning = false;
    isPaused = false;
    isResting = false;
    _announce("정지");
    notifyListeners();
  }

  void reset() {
    _tick?.cancel();
    currentSet = 1;
    currentRep = 0;
    progress = 0.0;
    isPaused = false;
    isResting = false;
    isRunning = false;
    notifyListeners();
  }

  Future<void> _finishAll() async {
    _tick?.cancel();
    isRunning = false;
    _announce("완료");
    await records.add(
      WorkoutRecord(
        id: "${routine.id}_${DateTime.now().millisecondsSinceEpoch}",
        routineId: routine.id,
        routineName: routine.name,
        date: DateTime.now(),
        doneSets: routine.sets,
        doneRepsTotal: routine.sets * routine.reps,
      ),
    );
    notifyListeners();
  }

  Future<void> _announce(String t) async {
    if (settings.ttsOn) {
      await tts.speak(t);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
