import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_settings.dart';

class TtsViewModel {
  final FlutterTts _tts = FlutterTts();

  TtsSettings _settings = TtsSettings(
    isEnabled: false,
    voiceGender: VoiceGender.female,
  );

  TtsSettings get settings => _settings;


  // ✅ SharedPreferences 키
  static const String _keyIsEnabled = 'tts_is_enabled';
  static const String _keyVoiceGender = 'tts_voice_gender';

  // ✅ 설정 불러오기
  Future<TtsSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyIsEnabled) ?? false;
    final genderString = prefs.getString(_keyVoiceGender) ?? 'female';

    _settings = TtsSettings(
      isEnabled: isEnabled,
      voiceGender: genderString == 'female'
          ? VoiceGender.female
          : VoiceGender.male,
    );

    await _applySettings();
    return _settings;
  }

  // ✅ 설정 저장
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

  // ✅ 설정 적용
  Future<void> _applySettings() async {
    if (!_settings.isEnabled) return;
    await _tts.setLanguage('en-US');
    await _tts.setVoice({
      "name": _settings.voiceGender == VoiceGender.female
          ? "en-US-language_female"
          : "en-US-language_male"
    });
  }

  // ✅ 음성 출력
  Future<void> speak(String text) async {
    if (!_settings.isEnabled) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
