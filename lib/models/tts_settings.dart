enum VoiceGender { male, female }

class TtsSettings {
  final bool isEnabled;
  final VoiceGender voiceGender;

  TtsSettings({
    required this.isEnabled,
    required this.voiceGender,
  });

  // ✅ 추가된 getter: isFemale
  bool get isFemale => voiceGender == VoiceGender.female;

  // ✅ 추가된 getter: isOn (isEnabled 대체용)
  bool get isOn => isEnabled;

  TtsSettings copyWith({bool? isEnabled, VoiceGender? voiceGender}) {
    return TtsSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }
}
