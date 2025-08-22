import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

enum CounterPhase { rep, rest, done }

class CounterViewModel extends ChangeNotifier {
  // 기본값: 3세트 15회, 1회 2초, 휴식 10초
  String routineName;
  int totalSets;
  int repsPerSet;
  int restSeconds;
  double secondsPerRep;

  final TtsService tts;
  final TtsVerbosity verbosity;

  CounterViewModel({
    required this.tts,
    this.routineName = '스쿼트',
    this.totalSets = 3,
    this.repsPerSet = 15,
    this.restSeconds = 10,
    this.secondsPerRep = 2.0,
    this.verbosity = TtsVerbosity.normal,
  });

  int currentSet = 1; // 1-based
  int currentRep = 0; // 0-based
  bool isPlaying = false;
  bool isPaused = false;
  bool isRest = false;
  bool voiceOn = true;

  CounterPhase get phase {
    if (isRest) return CounterPhase.rest;
    if (currentSet > totalSets) return CounterPhase.done;
    return CounterPhase.rep;
  }

  double get currentDurationSeconds =>
      isRest ? restSeconds.toDouble() : secondsPerRep;
  int get leftReps => (repsPerSet - currentRep).clamp(0, repsPerSet);

  void toggleVoice() {
    voiceOn = !voiceOn;
    notifyListeners();
  }

  Future<void> _speak(String text) async {
    if (!voiceOn) return;
    await tts.speak(text);
  }

  /// 루틴을 선택했을 때 값 교체 + 초기화
  Future<void> applyRoutine({
    required String name,
    required int sets,
    required int reps,
    double? secPerRep,
    int? restSec,
  }) async {
    routineName = name;
    totalSets = sets;
    repsPerSet = reps;
    if (secPerRep != null) secondsPerRep = secPerRep;
    if (restSec != null) restSeconds = restSec;
    // 상태 초기화
    isPlaying = false;
    isPaused = false;
    isRest = false;
    currentSet = 1;
    currentRep = 0;
    notifyListeners();
    await _speak('$name, ${sets}세트 ${reps}회로 시작합니다');
  }

  Future<void> play() async {
    if (phase == CounterPhase.done) return;
    isPlaying = true;
    isPaused = false;
    notifyListeners();

    if (currentRep == 0 && !isRest) {
      await _speak("$currentSet세트 시작, 준비!");
    }
  }

  void pause() {
    isPaused = true;
    isPlaying = false;
    notifyListeners();
  }

  Future<void> stop() async {
    isPlaying = false;
    isPaused = false;
    isRest = false;
    currentSet = totalSets + 1; // done
    notifyListeners();
    await _speak("정지했어요.");
  }

  Future<void> resetSet() async {
    isPlaying = false;
    isPaused = false;
    isRest = false;
    currentRep = 0;
    notifyListeners();
    await _speak("리셋합니다.");
  }

  Future<void> resetAll() async {
    isPlaying = false;
    isPaused = false;
    isRest = false;
    currentSet = 1;
    currentRep = 0;
    notifyListeners();
  }

  /// 애니메이션 1라운드 완료 시 호출
  Future<CounterPhase> onTickComplete() async {
    if (phase == CounterPhase.rest) {
      isRest = false;
      currentSet += 1;
      currentRep = 0;
      if (currentSet <= totalSets) {
        await _speak("다음 ${currentSet}세트, 준비!");
        notifyListeners();
        return CounterPhase.rep;
      } else {
        await _speak("모든 세트 완료! 수고했어요.");
        isPlaying = false;
        notifyListeners();
        return CounterPhase.done;
      }
    }

    if (phase == CounterPhase.rep) {
      currentRep += 1;

      if (shouldSpeakRep(
        rep: currentRep,
        totalReps: repsPerSet,
        mode: verbosity,
      )) {
        await _speak("$currentRep");
      }
      if (isHalfway(currentRep, repsPerSet)) {
        // await _speak("절반 지났어요!");
        // -> 이걸 정말 쓸건지 확인하기!!!
      }

      if (currentRep >= repsPerSet) {
        await _speak("${currentSet}세트 완료, 잘했어요.");
        if (currentSet >= totalSets) {
          await _speak("모든 세트 완료! 수고했어요.");
          isPlaying = false;
          notifyListeners();
          return CounterPhase.done;
        } else {
          isRest = true;
          notifyListeners();
          await _speak("휴식 ${restSeconds}초 시작");
          return CounterPhase.rest;
        }
      } else {
        notifyListeners();
        return CounterPhase.rep;
      }
    }

    isPlaying = false;
    notifyListeners();
    return CounterPhase.done;
  }
}
