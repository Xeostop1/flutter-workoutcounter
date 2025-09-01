import 'package:flutter_tts/flutter_tts.dart';

class TtsRepository {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true;
  String language = 'ko-KR';

  TtsRepository() {
    _tts.setLanguage(language);
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0); // **** 음색(피치) 기본값 설정
  }

  Future<void> speak(String text) async {
    if (!enabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakCount(int n) => speak('$n');
  Future<void> speakRest(int seconds) => speak('휴식 $seconds 초');
  Future<void> stop() => _tts.stop();
}
