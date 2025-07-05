import 'package:flutter/material.dart';
import '../models/tts_settings.dart';

class TtsSettingsPanel extends StatelessWidget {
  final TtsSettings settings;
  final Function(TtsSettings) onSettingsChanged;

  const TtsSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('TTS 사용'),
          value: settings.isEnabled,
          onChanged: (value) => onSettingsChanged(settings.copyWith(isEnabled: value)),
        ),
        ListTile(
          title: const Text('목소리 성별'),
          trailing: DropdownButton<VoiceGender>(
            value: settings.voiceGender,
            items: VoiceGender.values.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender == VoiceGender.female ? '여성' : '남성'),
              );
            }).toList(),
            onChanged: (gender) {
              if (gender != null) {
                onSettingsChanged(settings.copyWith(voiceGender: gender));
              }
            },
          ),
        ),
      ],
    );
  }
}
