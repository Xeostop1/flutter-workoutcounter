import 'dart:async';
import 'package:counter_01/models/workout_settings.dart';
import 'package:flutter/material.dart';
import '../models/voice_gender.dart';
import '../view_models/tts_viewmodel.dart';

class WorkoutViewModel extends ChangeNotifier {
  int _currentSet = 1;
  int _currentCount = 1;
  bool _isPaused = false;
  bool _isRunning = false;
  bool _isResting = false;
  Timer? _timer;
  double _progress = 0.0;

  // 마지막 운동 세트/횟수 기억용
  Map<String, int>? lastWorkout;

  WorkoutSettings settings = WorkoutSettings(
    routineId: '001',
    totalSets: 3,
    repeatCount: 10,
    breakTime: Duration(seconds: 10),
    isCountdownOn: true,
    voiceGender: VoiceGender.female,
  );

  // ✅ getter
  int get currentSet => _currentSet;
  int get currentCount => _currentCount;
  bool get isPaused => _isPaused;
  bool get isRunning => _isRunning;
  bool get isResting => _isResting;
  double get progress => _progress;

  // ✅ setter/helper
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void startResting() {
    _isResting = true;
    _progress = 0.0;
    notifyListeners();
  }

  void nextSet() {
    _currentSet++;
    _currentCount = 1;
    _isResting = false;
    _progress = 0.0;
    notifyListeners();
  }

  void stopWorkout() {
    _timer?.cancel();
    _isPaused = false;
    _isRunning = false;
    _isResting = false;
    _currentSet = 1;
    _currentCount = 1;
    _progress = 0.0;
    notifyListeners();
  }

  // ✅ 총 세트 수 업데이트
  void updateTotalSet(int newValue) {
    settings = settings.copyWith(totalSets: newValue);
    // 👇 여기 추가
    lastWorkout = {
      'sets': newValue,
      'reps': settings.repeatCount,
    };
    print("🛠️ 세트 변경 → 마지막 운동 정보 업데이트됨: $lastWorkout");
    notifyListeners();
  }

// ✅ 반복 횟수 업데이트
  void updateRepeatCount(int newValue) {
    settings = settings.copyWith(repeatCount: newValue);
    // 👇 여기 추가
    lastWorkout = {
      'sets': settings.totalSets,
      'reps': newValue,
    };
    print("🛠️ 반복 변경 → 마지막 운동 정보 업데이트됨: $lastWorkout");
    notifyListeners();
  }

  void increaseRepeatCount() {
    settings = settings.copyWith(repeatCount: settings.repeatCount + 1);
    notifyListeners();
  }

  void increaseTotalSet() {
    settings = settings.copyWith(totalSets: settings.totalSets + 1);
    notifyListeners();
  }

  // ✅ 리셋
  void resetWorkout({
    bool isLoggedIn = false,
    Map<String, dynamic>? lastWorkout,
  }) {
    print("🔄 [리셋 시작] 로그인 여부: $isLoggedIn");
    print("📝 전달받은 마지막 운동 정보: $lastWorkout");

    // 전달받은 마지막 운동 정보 저장
    if (isLoggedIn && lastWorkout != null) {
      this.lastWorkout = {
        'sets': lastWorkout['sets'] ?? 2,
        'reps': lastWorkout['reps'] ?? 10,
      };
      print("✅ 새로운 마지막 운동 정보 저장됨: ${this.lastWorkout}");
    }

    // 저장된 마지막 운동 정보 사용
    final sets = this.lastWorkout?['sets'] ?? 2;
    final reps = this.lastWorkout?['reps'] ?? 10;
    print("🎯 리셋에 사용될 값 → 세트: $sets, 반복: $reps");

    settings = settings.copyWith(
      totalSets: sets,
      repeatCount: reps,
    );

    _currentSet = 1;
    _currentCount = 1;
    _isPaused = false;
    _isRunning = false;
    _isResting = false;
    _progress = 0.0;
    _timer?.cancel();

    print("✅ 리셋 완료. 현재 세트: $_currentSet, 반복: $_currentCount, 진행률: $_progress");
    notifyListeners();
  }

  void startTimer({
    required TtsViewModel ttsViewModel,
    required VoidCallback onStartRest,
    required VoidCallback onComplete,
  }) {
    _isRunning = true;
    _isPaused = false;
    _isResting = false;
    _progress = 0.0;
    notifyListeners();

    final totalCount = settings.repeatCount;
    const tick = Duration(seconds: 1);

    _timer?.cancel();
    _timer = Timer.periodic(tick, (timer) {
      if (_isPaused) return;

      _progress = _currentCount / totalCount;
      notifyListeners();

      if (_currentCount >= totalCount) {
        if (_currentSet >= settings.totalSets) {
          timer.cancel();
          onComplete();
          stopWorkout();
        } else {
          onStartRest();
        }
      } else {
        ttsViewModel.speak("$_currentCount");
        _currentCount++;
      }
    });
  }
}
