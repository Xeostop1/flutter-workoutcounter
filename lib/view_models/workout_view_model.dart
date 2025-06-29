// ChangeNotifier 상속: 상태가 바뀌면 화면에 알리는 flutter 기능
import 'package:flutter/material.dart';

//상태 저장용 변수
//게터
// 값을 바꾸는 함수
// 상태변화 화면 전달 함수

class WorkoutViewModel extends ChangeNotifier{
  //객체변수
  WorkoutSettings _settings = WorkoutSettings(
    routineId: '001',
    totalSets: 3,
    repeatCount: 10,
    breakTime: Duration(seconds: 30),
    isCountdownOn: true,
    voiceGender: VoiceGender.female,
  );
//getter
  WorkoutSettngs get setting => _settings;

  void updateRepeatCount(int value) {
    _settings = _settings.copyWith(repeatCount: value);
    notifyListeners(); // View에 "값 바뀜!"이라고 알려주는 것
  }



}
