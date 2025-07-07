import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tts_settings.dart';

class TtsViewModel {
  final FlutterTts _tts = FlutterTts();

  TtsSettings _settings = TtsSettings(
    isEnabled: false,
    voiceGender: VoiceGender.female, // ⚠️ 유지하지만 사용 X
  );

  TtsSettings get settings => _settings;

  static const String _keyIsEnabled = 't                                                                                                                                                                                               ts_is_enabled';
  static const String _keyVoiceGender = 'tts_voice_gender';

  Future<TtsSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyIsEnabled) ?? false;

    _settings = TtsSettings(
      isEnabled: isEnabled,
      voiceGender: VoiceGender.female, // ⚠️ 더 이상 의미 없음
    );

    await _applySettings();
    return _settings;
  }

  Future<void> saveSettings({
    required bool isFemale,
    required bool isOn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsEnabled, isOn);

    _settings = TtsSettings(
      isEnabled: isOn,
      voiceGender: VoiceGender.female, // ⚠️ 더 이상 의미 없음
    );

    await _applySettings();
  }

  Future<void> _applySettings() async {
    if (!_settings.isEnabled) return;

    await _tts.setLanguage('en-US');

    // ✅ 성별 voice 설정 제거
    // await _tts.setVoice(...) 제거
  }

  Future<void> speak(String text) async {
    if (!_settings.isEnabled) return;

    print('[TTS] speak: $text');
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // ✅ 디버깅용 음성 목록 출력
  Future<void> printAvailableVoices() async {
    final voices = await _tts.getVoices;
    print('[TTS] 사용 가능한 음성 목록:');
    for (var voice in voices) {
      print(voice);
    }
  }
}
