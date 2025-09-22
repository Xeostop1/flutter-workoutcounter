import 'package:flutter/foundation.dart';
import '../repositories/tts_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final TtsRepository tts;
  SettingsViewModel(this.tts);
  bool get voiceEnabled => tts.enabled;
  void toggleVoice(bool v) { tts.enabled = v; notifyListeners(); }
  String get language => tts.language;
  void setLanguage(String lang) { tts.language = lang; notifyListeners(); }
}
