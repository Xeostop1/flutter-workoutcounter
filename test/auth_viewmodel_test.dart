import 'package:counter_01/models/trainer_voice.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/user_settings_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';

void main() {
  test(
    'platform automatic voice remains empty instead of restoring legacy id',
    () async {
      final auth = _FakeAuthRepository();
      final settings = _DelayedSettingsRepository();
      final viewModel = AuthViewModel(
        auth,
        settingsRepo: settings,
        voicePlatform: TargetPlatform.android,
      );
      auth.emit(const AppUser(uid: 'auto-user'));
      settings.complete('auto-user', {
        'systemVoiceId': 'com.apple.old-voice',
        'androidSystemVoiceId': '',
      });
      await pumpEventQueue();
      expect(viewModel.systemVoiceId, '');
      viewModel.dispose();
      await auth.close();
    },
  );
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
      '$platform loads and saves only its own native voice preference',
      () async {
        final auth = _FakeAuthRepository();
        final settings = _DelayedSettingsRepository();
        final viewModel = AuthViewModel(
          auth,
          settingsRepo: settings,
          voicePlatform: platform,
        );
        auth.emit(const AppUser(uid: 'voice-user'));
        settings.complete('voice-user', {
          'systemVoiceId': 'legacy',
          'androidSystemVoiceId': 'ko-kr-android',
          'iosSystemVoiceId': 'com.apple.ko-voice',
        });
        await pumpEventQueue();
        expect(
          viewModel.systemVoiceId,
          platform == TargetPlatform.android
              ? 'ko-kr-android'
              : 'com.apple.ko-voice',
        );
        await viewModel.setSystemVoice('new-voice');
        expect(settings.savedVoicePlatform, platform);
        expect(settings.savedVoiceId, 'new-voice');
        expect(viewModel.user?.systemVoiceId, 'new-voice');
        await viewModel.setSystemVoice('');
        expect(settings.savedVoiceId, '');
        viewModel.dispose();
        await auth.close();
      },
    );
  }
  test(
    'legacy iPhone voice survives when no platform-specific choice exists',
    () async {
      final auth = _FakeAuthRepository();
      final settings = _DelayedSettingsRepository();
      final viewModel = AuthViewModel(
        auth,
        settingsRepo: settings,
        voicePlatform: TargetPlatform.iOS,
      );
      auth.emit(const AppUser(uid: 'legacy-user'));
      settings.complete('legacy-user', {
        'systemVoiceId': 'com.apple.old-voice',
      });
      await pumpEventQueue();
      expect(viewModel.systemVoiceId, 'com.apple.old-voice');
      viewModel.dispose();
      await auth.close();
    },
  );
  test('계정 전환 중 이전 설정 응답을 무시한다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user-a'));
    settings.complete('user-a', {
      'weeklyTarget': 7,
      'restSeconds': 60,
      'trainerVoiceId': 'male_trainer',
      'systemVoiceId': 'installed-ko-voice',
    });
    await pumpEventQueue();
    expect(viewModel.weeklyTarget, 7);
    expect(viewModel.trainerVoice, TrainerVoice.male);
    expect(viewModel.systemVoiceId, 'installed-ko-voice');

    auth.emit(const AppUser(uid: 'user-b'));
    expect(viewModel.authReady, isFalse);
    expect(viewModel.weeklyTarget, isNull);
    expect(viewModel.restSeconds, 3);
    expect(viewModel.trainerVoice, isNull);
    expect(viewModel.systemVoiceId, isNull);

    auth.emit(const AppUser(uid: 'user-c'));
    settings.complete('user-b', {'weeklyTarget': 6, 'restSeconds': 50});
    await pumpEventQueue();
    expect(viewModel.user?.uid, 'user-c');
    expect(viewModel.authReady, isFalse);
    expect(viewModel.weeklyTarget, isNull);

    settings.complete('user-c', {'weeklyTarget': 2, 'restSeconds': 10});
    await pumpEventQueue();
    expect(viewModel.authReady, isTrue);
    expect(viewModel.weeklyTarget, 2);
    expect(viewModel.restSeconds, 10);

    viewModel.dispose();
    await auth.close();
  });

  test('설정 저장 실패 시 이전 값으로 되돌리고 오류를 전달한다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user'));
    settings.complete('user', {});
    await pumpEventQueue();
    settings.updateError = StateError('저장 실패');

    await expectLater(
      viewModel.setVoiceCountingEnabled(true),
      throwsStateError,
    );
    expect(viewModel.voiceCountingEnabled, isFalse);

    await expectLater(viewModel.setVoicePitch(1.1), throwsStateError);
    expect(viewModel.voicePitch, 1.0);
    await expectLater(
      viewModel.setTrainerVoice(TrainerVoice.male),
      throwsStateError,
    );
    expect(viewModel.trainerVoice, isNull);
    await expectLater(viewModel.setSystemVoice('ko-test'), throwsStateError);
    expect(viewModel.systemVoiceId, isNull);
    settings.updateError = null;
    await viewModel.setSystemVoice('ko-test');
    expect(viewModel.systemVoiceId, 'ko-test');
    expect(viewModel.user?.systemVoiceId, 'ko-test');
    await viewModel.setTrainerVoice(TrainerVoice.female);
    expect(viewModel.trainerVoice, TrainerVoice.female);
    expect(viewModel.user?.trainerVoiceId, 'female_trainer');
    settings.updateError = StateError('저장 실패');

    await expectLater(viewModel.setRestSeconds(30), throwsStateError);
    expect(viewModel.restSeconds, 3);

    viewModel.dispose();
    await auth.close();
  });

  test('온보딩은 설정 저장이 성공한 뒤에만 완료된다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user'));
    settings.complete('user', {});
    await pumpEventQueue();
    settings.updateError = StateError('저장 실패');

    await expectLater(
      viewModel.completeOnboarding(weeklyTarget: 5),
      throwsStateError,
    );
    expect(viewModel.onboardingDone, isFalse);
    expect(viewModel.weeklyTarget, isNull);

    settings.updateError = null;
    await viewModel.completeOnboarding(weeklyTarget: 5);
    expect(viewModel.onboardingDone, isTrue);
    expect(viewModel.weeklyTarget, 5);

    viewModel.dispose();
    await auth.close();
  });

  test('홈 튜토리얼은 설정 저장이 성공한 뒤에만 완료된다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user'));
    settings.complete('user', {});
    await pumpEventQueue();
    settings.updateError = StateError('저장 실패');

    await expectLater(viewModel.markHomeTutorialDone(), throwsStateError);
    expect(viewModel.homeTutorialDone, isFalse);

    settings.updateError = null;
    await viewModel.markHomeTutorialDone();
    expect(viewModel.homeTutorialDone, isTrue);

    viewModel.dispose();
    await auth.close();
  });

  test('닉네임은 Firestore 저장이 성공한 뒤에만 변경된다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user', displayName: '기존 이름'));
    settings.complete('user', {'name': '기존 이름'});
    await pumpEventQueue();
    settings.updateError = StateError('저장 실패');

    await expectLater(viewModel.setDisplayName('새 이름'), throwsStateError);
    expect(viewModel.displayName, '기존 이름');

    settings.updateError = null;
    await viewModel.setDisplayName(' 새 이름 ');
    expect(settings.savedName, '새 이름');
    expect(viewModel.displayName, '새 이름');

    viewModel.dispose();
    await auth.close();
  });
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _users =
      StreamController<AppUser?>.broadcast(sync: true);
  AppUser? _currentUser;

  void emit(AppUser? user) {
    _currentUser = user;
    _users.add(user);
  }

  Future<void> close() => _users.close();

  @override
  Stream<AppUser?> userChanges() => _users.stream;

  @override
  AppUser? currentUser() => _currentUser;

  @override
  bool onboardingDone = false;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class _DelayedSettingsRepository implements UserSettingsRepository {
  final Map<String, Completer<Map<String, dynamic>?>> _loads = {};
  Object? updateError;
  String? savedName;
  String? savedVoiceId;
  TargetPlatform? savedVoicePlatform;

  void complete(String uid, Map<String, dynamic>? data) {
    _loads.putIfAbsent(uid, Completer.new).complete(data);
  }

  @override
  Future<Map<String, dynamic>?> load(String uid) =>
      _loads.putIfAbsent(uid, Completer.new).future;

  @override
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
    if (updateError != null) throw updateError!;
    if (name != null) savedName = name;
    if (systemVoiceId != null) {
      savedVoiceId = systemVoiceId;
      savedVoicePlatform = systemVoicePlatform;
    }
  }
}
