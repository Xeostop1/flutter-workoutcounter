import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // === 기존 루틴/기록/설정 키 ===
  static const routinesKey = 'routines_v1';
  static const recordsKey = 'records_v1';
  static const ttsOnKey = 'tts_on';
  static const voiceKey = 'voice_id';

  // === 온보딩/첫 실행 키 ===
  static const firstOpenKey = 'first_open_done_v1';
  static const onboardingSkipKey = 'onboarding_skip_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ==== 리스트 저장/불러오기 ====
  Future<List<Map<String, dynamic>>> readList(String key) async {
    final p = await _prefs;
    final raw = p.getStringList(key) ?? [];
    return raw.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> list) async {
    final p = await _prefs;
    await p.setStringList(key, list.map((e) => json.encode(e)).toList());
  }

  // ==== Bool ====
  Future<void> setBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  Future<bool> getBool(String key, {bool def = false}) async {
    final p = await _prefs;
    return p.getBool(key) ?? def;
  }

  // ==== String ====
  Future<void> setString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await _prefs;
    return p.getString(key);
  }

  // ==== 온보딩/첫 실행 전용 ====
  Future<bool> getFirstOpenDone() async => getBool(firstOpenKey, def: false);
  Future<void> setFirstOpenDone() async => setBool(firstOpenKey, true);

  Future<bool> getOnboardingSkipped() async =>
      getBool(onboardingSkipKey, def: false);
  Future<void> setOnboardingSkipped(bool v) async =>
      setBool(onboardingSkipKey, v);
}
