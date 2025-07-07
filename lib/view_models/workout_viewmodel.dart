// ChangeNotifier 상속: 상태가 바뀌면 화면에 알리는 flutter 기능
import 'package:counter_01/models/workout_settings.dart';
import 'package:flutter/material.dart';
import '../models/voice_gender.dart';

//상태 저장용 변수
//게터
// 값을 바꾸는 함수
// 상태변화 화면 전달 함수
class WorkoutViewModel{
  WorkoutSettings settings = WorkoutSettings(
    routineId: '001',
    totalSets: 3,
    repeatCount: 10,
    breakTime: Duration(seconds: 10),
    isCountdownOn: true,
    voiceGender: VoiceGender.female,
  );


  // 총 세트 수 업데이트 함수 ***
  void updateTotalSet(int newValue) {
    settings = settings.copyWith(totalSets: newValue);
  }


  // 반복 횟수 증가
void increaseRepeatCount(){
  settings = settings.copyWith(
    repeatCount: settings.repeatCount+1,
  );
}
//총 세트 증가
void increaseTotalset(){
  settings = settings.copyWith(
    totalSets: settings.totalSets +1,
  );
}

//업데이트 반복카운터
void updateRepeatCount(int newValue) {
    settings = settings.copyWith(repeatCount: newValue);
  }

  //리셋
void resetSettings(){
  settings = WorkoutSettings(
    routineId: '001',
    totalSets: 3,
    repeatCount: 10,
    breakTime: Duration(seconds: 10),
    isCountdownOn: true,
    voiceGender: VoiceGender.female,
  );
}


}



