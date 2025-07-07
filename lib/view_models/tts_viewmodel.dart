import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_settings.dart';

class TtsViewModel {
  final FlutterTts _tts = FlutterTts();

  // 설정 모델
  TtsSettings _settings = TtsSettings(
    isEnabled: false,
    voiceGender: VoiceGender.female,
  );

  TtsSettings get settings => _settings;

  // 숫자 텍스트 리스트 (1~100)
  final List<String> numberWords = [
    for (int i = 1; i <= 100; i++)
      i == 100 ? 'One hundred' : _numberToWords(i),
  ];

  // SharedPreferences 키
  static const String _keyIsEnabled = 'tts_is_enabled';
  static const String _keyVoiceGender = 'tts_voice_gender';

  // 초기 TTS 설정
  Future<void> initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  // 말하기
  Future<void> speak(String text) async {
    if (!_settings.isEnabled) return;
    print('[TTS] speak: $text');
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
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
    // Android에서는 setVoice 미지원 가능성 있음
    // await _tts.setVoice({...});
  }

  // 사용 가능한 음성 목록 출력
  Future<void> printAvailableVoices() async {
    final voices = await _tts.getVoices;
    print('[TTS] 기기에서 사용 가능한 음성 목록:');
    for (var voice in voices) {
      print(voice);
    }
  }

  // 숫자 → 영어 단어 (1~99까지 지원, 100은 예외 처리)
  static String _numberToWords(int number) {
    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty',
      'Seventy', 'Eighty', 'Ninety'
    ];

    if (number < 20) return units[number];
    if (number < 100) {
      final ten = number ~/ 10;
      final unit = number % 10;
      return '$tens[ten]' + (unit > 0 ? '-${units[unit]}' : '');
    }
    return '';
  }



  Future<void> speakCountSequence(int repeatCount, {int delayMillis = 1000}) async {
    if (!_settings.isEnabled) {
      print('[TTS] 비활성화 상태로 스피킹 생략');
      return;
    }

    print('[TTS] 세트 카운트 시작: 1~$repeatCount');

    for (int i = 0; i < repeatCount; i++) {
      final word = numberWords[i];
      print('[TTS] [$i] → $word');

      await _tts.speak(word);
      await Future.delayed(Duration(milliseconds: delayMillis));
    }

    print('[TTS] 세트 카운트 종료');
  }

}
