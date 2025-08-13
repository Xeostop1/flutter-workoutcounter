import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final StorageService storage;
  bool ttsOn = true;
  String? voiceId;

  SettingsViewModel(this.storage);

  Future<void> load() async {
    ttsOn = await storage.getBool(StorageService.ttsOnKey, def: true);
    voiceId = await storage.getString(StorageService.voiceKey);
    notifyListeners();
  }

  Future<void> toggleTts(bool v) async {
    ttsOn = v;
    await storage.setBool(StorageService.ttsOnKey, v);
    notifyListeners();
  }

  Future<void> setVoice(String? id) async {
    voiceId = id;
    if (id != null) await storage.setString(StorageService.voiceKey, id);
    notifyListeners();
  }
}
