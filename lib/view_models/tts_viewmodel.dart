import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_settings.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TtsViewModel {
  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;


  void setEnabled(bool on) {
    _isEnabled = on;                   // *** 외부에서 on/off 설정 가능 ***
  }
  // 설정 모델 사용
  TtsSettings _settings = TtsSettings(
    isEnabled: false,
    voiceGender: VoiceGender.female,
  );

  TtsSettings get settings => _settings;

  // 숫자 텍스트 리스트 (1~100)
  List<String> numberWords = [];

  // SharedPreferences 저장 키 이름
  static const String _keyIsEnabled = 'tts_is_enabled';
  static const String _keyVoiceGender = 'tts_voice_gender';

  // 초기 TTS 설정
  Future<void> initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await loadNumberWordsFromJson(); // *** JSON 불러오기 추가
    await _tts.awaitSpeakCompletion(true);
  }

  // 말하기
  Future<void> speak(String text) async {
    if (!_settings.isEnabled) return; // TTS 꺼져 있으면 종료
    print('[TTS] speak: $text');
    _tts.speak(text); // *** await 제거: 비동기 호출로 UI 지연 방지 ***
  }

  // 멈추기
  Future<void> stop() async {
    await _tts.stop();
  }

  // 설정 불러오기
  Future<TtsSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyIsEnabled) ?? false;
    final genderString = prefs.getString(_keyVoiceGender) ?? 'female';

    _settings = TtsSettings(
      isEnabled: isEnabled,
      voiceGender:
      genderString == 'female' ? VoiceGender.female : VoiceGender.male,
    );

    await _applySettings();
    return _settings;
  }

  // 설정 저장하기
  Future<void> saveSettings({
    required bool isFemale,
    required bool isOn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsEnabled, isOn);
    await prefs.setString(_keyVoiceGender, isFemale ? 'female' : 'male');

    _settings = TtsSettings(
      isEnabled: isOn,
      voiceGender: isFemale ? VoiceGender.female : VoiceGender.male,
    );

    await _applySettings();
  }

  // 설정 적용
  Future<void> _applySettings() async {
    if (!_settings.isEnabled) return;
    print('[TTS] applySettings - language: en-US');
    await _tts.setLanguage('en-US');
  }

  // 사용 가능한 음성 목록 출력 디버깅용
  Future<void> printAvailableVoices() async {
    final voices = await _tts.getVoices;
    print('[TTS] 기기에서 사용 가능한 음성 목록:');
    for (var voice in voices) {
      print(voice);
    }
  }

  // *** JSON에서 숫자 단어 목록 불러오기
  Future<void> loadNumberWordsFromJson() async {
    final String jsonString = await rootBundle.loadString(
        'assets/number_words.json'); // *** 파일 로드
    final List<dynamic> jsonList = json.decode(jsonString); // *** JSON 파싱
    numberWords = jsonList.cast<String>(); // *** String 리스트로 변환
    print('[TTS] 불러온 숫자 단어 수: ${numberWords.length}');
  }


  // Future<void> speakCountSequence(
  //     int repeatCount, {
  //       int delayMillis = 1000,
  //       void Function(int count)? onCount,
  //     }) async {
  //   if (!_settings.isEnabled) {
  //     print('[TTS] 비활성화 상태로 스피킹 생략');
  //     return;
  //   }
  //
  //   print('[TTS] 세트 카운트 시작: 1~$repeatCount');
  //
  //   for (int i = 0; i < repeatCount; i++) {
  //     final count = i + 1;
  //     final word = numberWords[i];
  //     print('[TTS] [$count] → $word');
  //
  //     // ✅ 콜백으로 화면 업데이트
  //     if (onCount != null) onCount(count);
  //
  //     _tts.speak(word);
  //     await Future.delayed(Duration(milliseconds: delayMillis));
  //   }
  //
  //   print('[TTS] 세트 카운트 종료');
  // }

  // Future<void> speakCountSequence({
  //   required int total,
  //   required void Function(int count) onCount,
  //   int delayMillis = 0,                // ← UI 전환 추가 지연(ms)
  // }) async {
  //   for (var i = 1; i <= total; i++) {
  //     await _tts.speak(numberWords[i - 1]);
  //     onCount(i);
  //     if (delayMillis > 0) {
  //       await Future.delayed(Duration(milliseconds: delayMillis));
  //     }
  //   }
  // }
  Future<void> speakCountSequence({
    required int total,
    required void Function(int count) onCount,
    int delayMillis = 0,
  }) async {
    for (var i = 1; i <= total; i++) {
      if (_isEnabled) {
        await _tts.speak(numberWords[i - 1]);  // *** isEnabled 체크 ***
      }
      onCount(i);
      if (delayMillis > 0) {
        await Future.delayed(Duration(milliseconds: delayMillis));
      }
    }
  }



}
