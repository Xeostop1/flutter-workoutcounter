import 'dart:io';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/system_voice.dart';

enum TtsVerbosity { quiet, normal, detailed, everyRep }

class TtsService {
  TtsService._()
    : _tts = FlutterTts(),
      _isIOS = Platform.isIOS,
      _isAndroid = Platform.isAndroid;

  @visibleForTesting
  TtsService.forTesting(
    FlutterTts tts, {
    bool isIOS = false,
    bool isAndroid = false,
  }) : _tts = tts,
       _isIOS = isIOS,
       _isAndroid = isAndroid;
  static final TtsService instance = TtsService._();

  final FlutterTts _tts;
  final bool _isIOS;
  final bool _isAndroid;
  Future<void>? _initialization;
  int _speechGeneration = 0;
  Future<void> _speechTail = Future<void>.value();
  Completer<void> _speechCancelled = Completer<void>();
  String? _appliedVoice;
  bool _readyBound = false; // 엔진 바인딩 되었는지 (대략적 플래그)

  // 간격 읽기 정책
  TtsVerbosity _mode = TtsVerbosity.normal;
  TtsVerbosity get mode => _mode;
  void setMode(TtsVerbosity m) => _mode = m;

  // 컨텍스트 없을 때 쓸 기본 피치
  double _fallbackPitch = 1.0;
  double get fallbackPitch => _fallbackPitch;
  void setFallbackPitch(double p) => _fallbackPitch = p.clamp(0.5, 2.0);

  Future<void> _ensureInitAndBind() {
    if (_readyBound) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (_isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      // Queue mode is only implemented by the Android plugin.
      if (_isAndroid) await _tts.setQueueMode(0);
      _readyBound = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<List<SystemVoice>> systemVoices() async {
    await _ensureInitAndBind();
    final raw = await _tts.getVoices;
    if (raw is! List) return [];
    final byId = <String, SystemVoice>{};
    for (final item in raw.whereType<Map>()) {
      final locale = '${item['locale'] ?? ''}';
      final name = '${item['name'] ?? ''}';
      final id = '${item['identifier'] ?? name}';
      if (!locale.toLowerCase().startsWith('ko') ||
          name.isEmpty ||
          id.isEmpty) {
        continue;
      }
      byId[id] = SystemVoice(
        id: id,
        name: name,
        locale: locale,
        quality: '${item['quality'] ?? ''}',
        gender: '${item['gender'] ?? ''}',
        networkRequired: '${item['network_required'] ?? ''}' == '1',
      );
    }
    return byId.values.toList()..sort((a, b) {
      final rank = b.qualityRank.compareTo(a.qualityRank);
      return rank != 0 ? rank : a.name.compareTo(b.name);
    });
  }

  Future<void> _selectVoice(String? id) async {
    final key = id ?? '';
    if (_appliedVoice == key) return;
    final voices = await systemVoices();
    final voice =
        voices.where((voice) => voice.id == id).firstOrNull ??
        voices.firstOrNull;
    if (voice != null) {
      await _tts.setVoice(voice.native);
    } else if (_appliedVoice != null) {
      await _tts.setLanguage('ko-KR');
    }
    _appliedVoice = key;
  }

  Future<void> preview(SystemVoice voice) async {
    await stop();
    await speak('하나! 둘! 셋! 좋아요. 한 세트 끝!', force: true, voiceId: voice.id);
  }

  /// 사전 워밍업용(화면 진입 시 한 번 호출하면 첫 발화 실패 방지에 도움)
  Future<void> warmUp() => _ensureInitAndBind();

  Future<void> speak(
    String text, {
    BuildContext? context,
    double? overridePitch,
    bool force = false,
    String? voiceId,
  }) {
    final generation = _speechGeneration;
    final cancelled = _speechCancelled.future;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future<void>.value();

    bool enabled = false;
    double pitch = _fallbackPitch;

    if (context != null) {
      final auth = context.read<AuthViewModel>();
      enabled = auth.voiceCountingEnabled;
      voiceId ??= auth.systemVoiceId;
      pitch = 1.0; // Keep each installed voice’s natural timbre.
    }

    pitch = (overridePitch ?? pitch).clamp(0.5, 2.0);
    if (!enabled && !force) return Future<void>.value();
    // Android rejects overlapping flush requests with 0; serialize on completion.
    final speech = _speechTail.then((_) async {
      if (generation != _speechGeneration) return;
      await _ensureInitAndBind();
      if (generation != _speechGeneration) return;
      await _selectVoice(voiceId);
      if (generation != _speechGeneration) return;
      await _tts.setPitch(pitch);
      if (generation != _speechGeneration) return;
      try {
        final result = await Future.any<dynamic>([
          _tts.speak(trimmed),
          cancelled,
        ]).timeout(const Duration(seconds: 20));
        if (generation != _speechGeneration) return;
        if (result != 1) throw StateError('TTS did not complete: $result');
      } catch (_) {
        if (generation == _speechGeneration) await stop();
        rethrow;
      }
    });
    _speechTail = speech.catchError((Object _) {});
    return speech;
  }

  Future<void> count(
    int rep, {
    bool start = false,
    int? totalReps,
    TtsVerbosity? mode,
    BuildContext? context,
    double? overridePitch,
    bool force = false,
  }) async {
    if (totalReps == null) {
      await speak(
        '${start && rep == 1 ? '시작! ' : ''}${koreanCount(rep)}!',
        context: context,
        overridePitch: overridePitch,
        force: force,
      );
      return;
    }
    final m = mode ?? _mode;
    if (shouldSpeakRep(rep: rep, totalReps: totalReps, mode: m)) {
      await speak(
        '${start && rep == 1 ? '시작! ' : ''}${koreanCount(rep)}!',
        context: context,
        overridePitch: overridePitch,
        force: force,
      );
    }
  }

  Future<void> restCount(
    int elapsed, {
    BuildContext? context,
    bool force = false,
  }) {
    // Keep the opening cue and first number in one ordered utterance.
    return speak(
      '${elapsed == 1 ? '휴식! ' : ''}$elapsed!',
      context: context,
      force: force,
    );
  }

  // stop()은 바인딩 전에는 실패 로그를 내므로, 필요할 때만 사용
  Future<void> stop() async {
    ++_speechGeneration;
    _speechCancelled.complete();
    _speechCancelled = Completer<void>();
    _speechTail = Future<void>.value();
    if (!_readyBound) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() => stop();
}

bool shouldSpeakRep({
  required int rep, // 1-based
  required int totalReps,
  required TtsVerbosity mode,
}) {
  if (rep > totalReps - 5) return true; // 마지막 5회 모두
  if (rep <= 5) return true; // 시작 1~5회 모두
  switch (mode) {
    case TtsVerbosity.everyRep:
      return true;
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
