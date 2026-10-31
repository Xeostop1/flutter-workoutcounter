import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/trainer_voice.dart';

/// Offline, pre-generated voice packs. No service credentials ship in the app.
class TrainerAudioService {
  TrainerAudioService({AssetBundle? bundle, MethodChannel? channel})
    : _bundle = bundle ?? rootBundle,
      _channel = channel ?? const MethodChannel('sporkle/trainer_audio');
  static final instance = TrainerAudioService();
  final AssetBundle _bundle;
  final MethodChannel _channel;
  final Map<TrainerVoice, int> _verified = {};
  int _generation = 0;

  String _base(TrainerVoice voice) => 'assets/audio/trainers/${voice.id}';
  String _countPath(TrainerVoice voice, int rep) =>
      '${_base(voice)}/${rep.toString().padLeft(3, '0')}.mp3';

  Future<int> requireVoice(TrainerVoice voice) async {
    final cached = _verified[voice];
    if (cached != null) return cached;
    final manifest =
        jsonDecode(
              await _bundle.loadString('assets/audio/trainers/manifest.json'),
            )
            as Map<String, dynamic>;
    final pack = (manifest['voices'] as Map<String, dynamic>)[voice.id];
    if (pack is! Map || pack['count'] is! int || pack['count'] < 15) {
      throw StateError('Voice pack is not available: ${voice.id}');
    }
    final count = pack['count'] as int;
    final assets = (await AssetManifest.loadFromAssetBundle(
      _bundle,
    )).listAssets().toSet();
    if (!assets.contains('${_base(voice)}/preview.mp3') ||
        List.generate(
          count,
          (index) => _countPath(voice, index + 1),
        ).any((path) => !assets.contains(path))) {
      throw StateError('Voice pack is incomplete: ${voice.id}');
    }
    _verified[voice] = count;
    return count;
  }

  Future<void> preview(TrainerVoice voice) async {
    final generation = ++_generation;
    await requireVoice(voice);
    if (generation != _generation) return;
    await _channel.invokeMethod<void>('play', {
      'asset': '${_base(voice)}/preview.mp3',
    });
  }

  Future<bool> count(TrainerVoice voice, int rep) async {
    final generation = ++_generation;
    final maxRep = await requireVoice(voice);
    if (generation != _generation) return true;
    if (rep < 1 || rep > maxRep) return false;
    await _channel.invokeMethod<void>('play', {
      'asset': _countPath(voice, rep),
    });
    return true;
  }

  Future<void> stop() async {
    ++_generation;
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Other platforms continue to use their existing TTS implementation.
    }
  }
}
