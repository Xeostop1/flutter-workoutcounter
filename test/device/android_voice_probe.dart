// Device-only diagnostic entry point. No Firebase initialization or auth bypass.
import 'dart:convert';
import 'dart:io';

import 'package:counter_01/models/system_voice.dart';
import 'package:counter_01/services/tts_service.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/widgets/system_voice_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(theme: AppTheme.dark, home: const _VoiceProbe()));
}

class _VoiceProbe extends StatefulWidget {
  const _VoiceProbe();

  @override
  State<_VoiceProbe> createState() => _VoiceProbeState();
}

class _VoiceProbeState extends State<_VoiceProbe> {
  final _engine = FlutterTts();
  late final _service = TtsService.forTesting(_engine, isAndroid: true);
  late final Future<List<SystemVoice>> _voices;
  final _report = <String, dynamic>{};
  int _started = 0;
  int _completed = 0;
  String _status = '실제 Android TTS 엔진을 점검하고 있습니다.';

  @override
  void initState() {
    super.initState();
    _engine.setStartHandler(() => _started++);
    _engine.setCompletionHandler(() => _completed++);
    _engine.setErrorHandler((message) => _log('engine_error', message));
    _voices = _loadAndCheck();
  }

  void _log(String name, dynamic value) {
    _report[name] = value;
    debugPrint('ANDROID_VOICE_PROBE ${jsonEncode({name: value})}');
  }

  Future<void> _waitForCompletion(int expected) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_completed >= expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Native speech completion callback was not received');
  }

  Future<List<SystemVoice>> _loadAndCheck() async {
    try {
      final voices = await _service.systemVoices().timeout(
        const Duration(seconds: 45),
      );
      _log('engine', await _engine.getDefaultEngine);
      _log('voices', [
        for (final voice in voices)
          {
            'id': voice.id,
            'locale': voice.locale,
            'quality': voice.quality,
            'network_required': voice.networkRequired,
          },
      ]);
      if (voices.isEmpty) {
        throw StateError('No Korean voices provided by engine');
      }

      final local = voices.where((v) => !v.networkRequired).firstOrNull;
      final selected = local ?? voices.first;
      await _service.preview(selected).timeout(const Duration(seconds: 45));
      await _waitForCompletion(1);
      _log('preview', {'voice': selected.id, 'completed': _completed});
      final beforeStarted = _started;
      final beforeCompleted = _completed;
      for (var rep = 1; rep <= 3; rep++) {
        await _service
            .count(rep, totalReps: 3, force: true)
            .timeout(const Duration(seconds: 30));
        await _waitForCompletion(beforeCompleted + rep);
      }
      final starts = _started - beforeStarted;
      final completions = _completed - beforeCompleted;
      _log('counter', {'starts': starts, 'completions': completions});
      if (starts != 3 || completions != 3) {
        throw StateError('Three counter utterances did not complete');
      }

      await _engine.setVoice(selected.native);
      await _engine.awaitSynthCompletion(true);
      final directory = await getApplicationDocumentsDirectory();
      final sample = File('${directory.path}/android-korean-voice.wav');
      final result = await _engine
          .synthesizeToFile('하나! 둘! 셋! 좋아요. 한 세트 끝!', sample.path, true)
          .timeout(const Duration(seconds: 45));
      final bytes = await sample.length();
      if (result != 1 || bytes <= 44) {
        throw StateError('No valid synthesized audio sample: $result / $bytes');
      }
      _log('sample', {'path': sample.path, 'bytes': bytes});
      _log('passed', true);
      await File(
        '${directory.path}/android-voice-report.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(_report));
      if (mounted) {
        setState(() => _status = '한국어 음성 ${voices.length}개 · 미리듣기/카운트 합성 완료');
      }
      return voices;
    } catch (error) {
      _log('failed', '$error');
      if (mounted) setState(() => _status = '점검 실패: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Android 음성 점검 (테스트 전용)')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status),
            const Text('운영 Firebase에 연결하거나 사용자 데이터를 저장하지 않습니다.'),
            const SizedBox(height: 20),
            SystemVoicePicker(
              selected: null,
              load: () => _voices,
              preview: _service.preview,
              onApply: (voice) {
                _log('picker_selected', voice.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('기기 음성 선택 확인: ${voice.name}')),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
