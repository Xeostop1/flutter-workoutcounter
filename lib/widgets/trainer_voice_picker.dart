import 'package:flutter/material.dart';

import 'sheets/app_sheet.dart';
import '../models/trainer_voice.dart';
export '../models/trainer_voice.dart';

/// Connect only after both licensed voice packs and their previews are bundled.
/// Previewing a voice never persists the user's selection.
Future<TrainerVoice?> showTrainerVoicePicker(
  BuildContext context, {
  required TrainerVoice? selected,
  required Future<void> Function(TrainerVoice voice) preview,
  required Future<void> Function() stopPreview,
}) async {
  try {
    return await showAppSheet<TrainerVoice>(
      context,
      title: '트레이너 목소리',
      child: TrainerVoicePicker(
        initialSelection: selected,
        preview: preview,
        onApply: (voice) => Navigator.of(context).pop(voice),
      ),
    );
  } finally {
    await stopPreview();
  }
}

class TrainerVoicePicker extends StatefulWidget {
  const TrainerVoicePicker({
    super.key,
    required this.initialSelection,
    required this.preview,
    required this.onApply,
  });

  final TrainerVoice? initialSelection;
  final Future<void> Function(TrainerVoice voice) preview;
  final ValueChanged<TrainerVoice> onApply;

  @override
  State<TrainerVoicePicker> createState() => _TrainerVoicePickerState();
}

class _TrainerVoicePickerState extends State<TrainerVoicePicker> {
  TrainerVoice? _selected;
  TrainerVoice? _playing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
  }

  Future<void> _preview(TrainerVoice voice) async {
    if (_playing != null) return;
    setState(() {
      _playing = voice;
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '직접 듣고 운동에 맞는 목소리를 골라 보세요.',
          style: TextStyle(color: Color(0xFF9B9EA8)),
        ),
        const SizedBox(height: 20),
        for (final voice in TrainerVoice.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: const Color(0xFF272A30),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _selected = voice),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              voice.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _selected == voice
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _selected == voice
                                ? const Color(0xFFFF784F)
                                : const Color(0xFF9B9EA8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voice.description,
                        style: const TextStyle(color: Color(0xFF9B9EA8)),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _playing == null
                            ? () => _preview(voice)
                            : null,
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(
                          _playing == voice ? '재생 중…' : '${voice.label} 미리듣기',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFFB783))),
          const SizedBox(height: 12),
        ],
        const Text(
          'AI로 만든 음성이에요.',
          style: TextStyle(color: Color(0xFF9B9EA8), fontSize: 12),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _selected == null || _playing != null
              ? null
              : () => widget.onApply(_selected!),
          child: const Text('이 목소리로 선택'),
        ),
      ],
    );
  }
}
