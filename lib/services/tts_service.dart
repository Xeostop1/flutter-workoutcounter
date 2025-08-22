import 'package:flutter_tts/flutter_tts.dart';

enum TtsVerbosity { quiet, normal, detailed }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  Future<void> init({
    String language = 'ko-KR',
    double rate = 0.45,
    double pitch = 1.02,
  }) async {
    if (_inited) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    _inited = true;
  }

  Future<void> speak(String text) async {
    if (!_inited) await init();
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}

/// --- 숫자 읽기 규칙(세트 100 / 횟수 200 고려) ---
bool shouldSpeakRep({
  required int rep, // 1-based
  required int totalReps, // ex) 200
  required TtsVerbosity mode,
}) {
  if (rep > totalReps - 5) return true; // 마지막 5회는 모두
  if (rep <= 5) return true; // 시작 1~5회는 모두
  switch (mode) {
    case TtsVerbosity.quiet:
      final q1 = (totalReps * 0.25).round();
      final q2 = (totalReps * 0.50).round();
      final q3 = (totalReps * 0.75).round();
      return rep == q1 || rep == q2 || rep == q3;
    case TtsVerbosity.normal:
      final step = totalReps >= 80 ? 10 : 5;
      return rep % step == 0;
    case TtsVerbosity.detailed:
      return rep % 3 == 0;
  }
}

bool isHalfway(int rep, int totalReps) => rep == (totalReps / 2).round();
