import 'dart:io';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

enum TtsVerbosity { quiet, normal, detailed }

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _inited = false;
  bool _binding = false; // 중복 바인딩 방지
  bool _readyBound = false; // 엔진 바인딩 되었는지 (대략적 플래그)

  // 간격 읽기 정책
  TtsVerbosity _mode = TtsVerbosity.normal;
  TtsVerbosity get mode => _mode;
  void setMode(TtsVerbosity m) => _mode = m;

  // 컨텍스트 없을 때 쓸 기본 피치
  double _fallbackPitch = 1.0;
  double get fallbackPitch => _fallbackPitch;
  void setFallbackPitch(double p) => _fallbackPitch = p.clamp(0.5, 2.0);

  Future<void> _ensureInitAndBind({
    String language = 'ko-KR',
    double rate = 0.45,
  }) async {
    if (_binding) {
      // 다른 호출이 바인딩 중이면 잠깐 대기
      for (int i = 0; i < 10 && !_inited; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }
    _binding = true;
    try {
      if (!_inited) {
        await _tts.setLanguage(language);
        await _tts.setSpeechRate(rate);
        await _tts.setVolume(1.0);
        // 발화 완료 콜백을 기다리도록 (안드로이드에서 안정성 ↑)
        await _tts.awaitSpeakCompletion(true);
        // 큐 모드: FLUSH (이전 발화를 자동으로 끊고 새로 재생)
        // 0: QUEUE_FLUSH, 1: QUEUE_ADD
        await _tts.setQueueMode(0);
        _inited = true;
      }

      // Android: Google TTS 엔진이 있으면 선택(없으면 기본 유지)
      if (Platform.isAndroid) {
        try {
          final engines = await _tts.getEngines; // [{name: ..., label: ...}]
          final google = engines.firstWhere(
            (e) => (e['name'] as String).contains('google'),
            orElse: () => <String, String>{},
          );
          if (google.isNotEmpty) {
            await _tts.setEngine(google['name'] as String);
          }
        } catch (_) {
          // 엔진 조회 실패해도 무시
        }
      }

      // getVoices 호출이 바인딩 트리거에 도움이 됨
      try {
        await _tts.getVoices;
      } catch (_) {}

      _readyBound = true;
    } finally {
      _binding = false;
    }
  }

  /// 사전 워밍업용(화면 진입 시 한 번 호출하면 첫 발화 실패 방지에 도움)
  Future<void> warmUp() => _ensureInitAndBind();

  Future<void> speak(
    String text, {
    BuildContext? context,
    double? overridePitch,
    bool force = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    bool enabled = false;
    double pitch = _fallbackPitch;

    if (context != null) {
      final auth = context.read<AuthViewModel>();
      enabled = auth.voiceCountingEnabled;
      pitch = auth.voicePitch; // 남성=0.90, 여성=1.10
    }

    await _ensureInitAndBind();
    if (!enabled && !force) return;

    pitch = (overridePitch ?? pitch).clamp(0.5, 2.0);

    // 발화: 큐 플러시 모드 사용 → stop() 없이도 이전 발화 중단
    Future<void> doSpeak() async {
      await _tts.setPitch(pitch); // ✅ 발화 직전 피치 적용
      await _tts.speak(trimmed);
    }

    try {
      await doSpeak();
    } catch (_) {
      // 바인딩 타이밍 문제로 실패할 수 있어 짧게 재시도
      await Future.delayed(const Duration(milliseconds: 150));
      await _ensureInitAndBind();
      await doSpeak();
    }
  }

  Future<void> count(
    int rep, {
    int? totalReps,
    TtsVerbosity? mode,
    BuildContext? context,
    double? overridePitch,
    bool force = false,
  }) async {
    if (totalReps == null) {
      await speak(
        rep.toString(),
        context: context,
        overridePitch: overridePitch,
        force: force,
      );
      return;
    }
    final m = mode ?? _mode;
    if (shouldSpeakRep(rep: rep, totalReps: totalReps, mode: m)) {
      await speak(
        rep.toString(),
        context: context,
        overridePitch: overridePitch,
        force: force,
      );
    }
  }

  // stop()은 바인딩 전에는 실패 로그를 내므로, 필요할 때만 사용
  Future<void> stop() async {
    if (!_readyBound) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

bool shouldSpeakRep({
  required int rep, // 1-based
  required int totalReps,
  required TtsVerbosity mode,
}) {
  if (rep > totalReps - 5) return true; // 마지막 5회 모두
  if (rep <= 5) return true; // 시작 1~5회 모두
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
