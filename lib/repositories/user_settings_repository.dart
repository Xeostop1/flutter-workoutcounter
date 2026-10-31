import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsRepository {
  UserSettingsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<Map<String, dynamic>?> load(String uid) async {
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
    if (restSeconds != null) {
      data['restSeconds'] = restSeconds;
    }
    if (name != null) {
      data['name'] = name;
    }
    if (data.isEmpty) return;

    await _users.doc(uid).set(data, SetOptions(merge: true));
  }
}
