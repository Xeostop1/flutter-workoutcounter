import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/system_voice.dart';
import '../services/tts_service.dart';
import 'sheets/app_sheet.dart';

Future<String?> showSystemVoicePicker(
  BuildContext context, {
  String? selected,
}) async {
  final tts = TtsService.instance;
  try {
    return await showAppSheet<String>(
      context,
      title: switch (defaultTargetPlatform) {
        TargetPlatform.android => '안드로이드 목소리',
        TargetPlatform.iOS => '아이폰 목소리',
        _ => '기기 목소리',
      },
      child: SystemVoicePicker(
        selected: selected,
        load: tts.systemVoices,
        preview: tts.preview,
        onApply: (voice) => Navigator.of(context).pop(voice.id),
      ),
    );
  } finally {
    await tts.stop();
  }
}

class SystemVoicePicker extends StatefulWidget {
  const SystemVoicePicker({
    super.key,
    required this.selected,
    required this.load,
    required this.preview,
    required this.onApply,
  });
  final String? selected;
  final Future<List<SystemVoice>> Function() load;
  final Future<void> Function(SystemVoice) preview;
  final ValueChanged<SystemVoice> onApply;
  @override
  State<SystemVoicePicker> createState() => _SystemVoicePickerState();
}

class _SystemVoicePickerState extends State<SystemVoicePicker> {
  static const automatic = SystemVoice(id: '', name: '자동 선택', locale: 'ko-KR');
  late Future<List<SystemVoice>> _voices;
  late String _selected;
  String? _playing;
  String? _error;
  @override
  void initState() {
    super.initState();
    _selected = widget.selected ?? '';
    _voices = widget.load();
  }

  Future<void> _preview(SystemVoice voice) async {
    if (_playing != null) return;
    setState(() {
      _playing = voice.id;
      _error = null;
    });
    try {
      await widget.preview(voice);
    } catch (_) {
      if (mounted) setState(() => _error = '미리듣기를 재생하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _playing = null);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SystemVoice>>(
    future: _voices,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            const Text('목소리를 불러오지 못했어요.'),
            TextButton(
              onPressed: () => setState(() => _voices = widget.load()),
              child: const Text('다시 시도'),
            ),
          ],
        );
      }
      final options = [automatic, ...?snapshot.data];
      final selected =
          options.where((v) => v.id == _selected).firstOrNull ?? automatic;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '무료로 사용할 수 있는 한국어 목소리예요.\n미리 듣고 마음에 드는 목소리를 골라 보세요.',
            style: TextStyle(color: Color(0xFF9B9EA8), height: 1.5),
          ),
          const SizedBox(height: 16),
          for (final voice in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFF272A30),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => setState(() => _selected = voice.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                voice.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              selected.id == voice.id
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected.id == voice.id
                                  ? const Color(0xFFFF784F)
                                  : const Color(0xFF9B9EA8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          voice.id.isEmpty
                              ? '설치된 목소리 중 좋은 품질로 선택'
                              : voice.detail,
                          style: const TextStyle(color: Color(0xFF9B9EA8)),
                        ),
                        TextButton.icon(
                          onPressed: _playing == null
                              ? () => _preview(voice)
                              : null,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: Text(
                            _playing == voice.id
                                ? '재생 중…'
                                : '${voice.name} 미리듣기',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Color(0xFFFFB783))),
          const Text(
            '이 기기의 음성 엔진에서 제공하는 목소리입니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9B9EA8)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _playing == null ? () => widget.onApply(selected) : null,
            child: const Text('이 목소리로 선택'),
          ),
        ],
      );
    },
  );
}
