// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

enum TtsVerbosity { quiet, normal, detailed }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  // 기본 모드(필요하면 setter로 바꿔 사용)
  TtsVerbosity _mode = TtsVerbosity.normal;
  TtsVerbosity get mode => _mode;
  void setMode(TtsVerbosity m) => _mode = m;

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

  /// ✅ 숫자 읽기
  /// - totalReps/mode를 주면 규칙에 따라 "간격 읽기"
  /// - 안 주면 매회 읽기 (기존 VM의 tts.count(_currentRep)와 100% 호환)
  Future<void> count(int rep, {int? totalReps, TtsVerbosity? mode}) async {
    if (!_inited) await init();

    // 규칙 없이 그냥 매회 읽기
    if (totalReps == null) {
      await speak(rep.toString());
      return;
    }

    final m = mode ?? _mode;
    final say = shouldSpeakRep(rep: rep, totalReps: totalReps, mode: m);
    if (say) {
      await speak(rep.toString());
    }
  }

  Future<void> stop() async {
    await _tts.stop();
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
