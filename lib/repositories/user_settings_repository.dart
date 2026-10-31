import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'guest_store.dart';

String systemVoiceSettingsKey(TargetPlatform? platform) => switch (platform) {
  TargetPlatform.android => 'androidSystemVoiceId',
  TargetPlatform.iOS => 'iosSystemVoiceId',
  _ => 'systemVoiceId',
};

class UserSettingsRepository {
  UserSettingsRepository({FirebaseFirestore? firestore, GuestStore? guestStore})
    : _db = firestore,
      _guests = guestStore;

  final FirebaseFirestore? _db;
  final GuestStore? _guests;

  CollectionReference<Map<String, dynamic>> get _users =>
      (_db ?? FirebaseFirestore.instance).collection('users');

  Future<Map<String, dynamic>?> load(String uid) async {
    if (uid == GuestStore.uid && _guests != null) return _guests.settings();
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  Future<void> update(
    String uid, {
    bool? onboardingDone,
    int? weeklyTarget,
    bool? homeTutorialDone,
    bool? voiceCountingEnabled,
    double? voicePitch,
    String? trainerVoiceId,
    String? systemVoiceId,
    TargetPlatform? systemVoicePlatform,
    int? restSeconds,
    String? name,
  }) async {
    final data = <String, Object?>{};

    if (onboardingDone != null) {
      data['onboardingDone'] = onboardingDone;
    }
    if (weeklyTarget != null) {
      data['weeklyTarget'] = weeklyTarget;
    }
    if (homeTutorialDone != null) {
      data['homeTutorialDone'] = homeTutorialDone;
    }
    if (voiceCountingEnabled != null) {
      data['voiceCountingEnabled'] = voiceCountingEnabled;
    }
    if (voicePitch != null) {
      data['voicePitch'] = voicePitch;
    }
    if (trainerVoiceId != null) data['trainerVoiceId'] = trainerVoiceId;
    if (systemVoiceId != null) {
      data[systemVoiceSettingsKey(systemVoicePlatform)] = systemVoiceId;
    }
    if (restSeconds != null) {
      data['restSeconds'] = restSeconds;
    }
    if (name != null) {
      data['name'] = name;
    }
    if (data.isEmpty) return;

    if (uid == GuestStore.uid && _guests != null) {
      await _guests.updateSettings(data);
      return;
    }

    await _users.doc(uid).set(data, SetOptions(merge: true));
  }
}
