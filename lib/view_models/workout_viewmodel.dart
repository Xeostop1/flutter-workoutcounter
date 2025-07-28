import 'dart:async';
import 'package:counter_01/models/workout_settings.dart';
import 'package:flutter/material.dart';
import '../models/voice_gender.dart';

class WorkoutViewModel extends ChangeNotifier {
  int _setCount = 2;
  int _repeatCount = 10;
  int _currentSet = 1;
  int _currentCount = 1;
  bool _isPaused = false;
  bool _isRunning = false;
  bool _isResting = false;
  Timer? _timer;

  WorkoutSettings settings = WorkoutSettings(
    routineId: '001',
    totalSets: 3,
    repeatCount: 10,
    breakTime: Duration(seconds: 10),
    isCountdownOn: true,
    voiceGender: VoiceGender.female,
  );

  // ✅ getter 추가 (상태 접근용)
  int get currentSet => _currentSet;
  int get currentCount => _currentCount;
  bool get isPaused => _isPaused;
  bool get isRunning => _isRunning;
  bool get isResting => _isResting;

  double get progress =>
      settings.repeatCount == 0 ? 0.0 : (_currentCount - 1) / settings.repeatCount;

  // 총 세트 수 업데이트
  void updateTotalSet(int newValue) {
    settings = settings.copyWith(totalSets: newValue);
    notifyListeners();
  }

  // 반복 횟수 업데이트
  void updateRepeatCount(int newValue) {
    settings = settings.copyWith(repeatCount: newValue);
    notifyListeners();
  }

  // 반복 횟수 증가
  void increaseRepeatCount() {
    settings = settings.copyWith(repeatCount: settings.repeatCount + 1);
    notifyListeners();
  }

  // 총 세트 수 증가
  void increaseTotalset() {
    settings = settings.copyWith(totalSets: settings.totalSets + 1);
    notifyListeners();
  }

  // *** 리셋 기능 ***
  void resetWorkout({bool isLoggedIn = false, Map<String, dynamic>? lastWorkout}) {
    if (isLoggedIn && lastWorkout != null) {
      _setCount = lastWorkout['sets'] ?? 2;
      _repeatCount = lastWorkout['reps'] ?? 10;
      settings = settings.copyWith(
        totalSets: _setCount,
        repeatCount: _repeatCount,
      );
    } else {
      _setCount = 2;
      _repeatCount = 10;
      settings = settings.copyWith(
        totalSets: 2,
        repeatCount: 10,
      );
    }
    _currentSet = 1;
    _currentCount = 1;
    _isPaused = false;
    _isRunning = false;
    _isResting = false;
    _timer?.cancel();
    notifyListeners();
  }
}
