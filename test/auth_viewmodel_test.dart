import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/user_settings_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';

void main() {
  test('계정 전환 중 이전 설정 응답을 무시한다', () async {
    final auth = _FakeAuthRepository();
    final settings = _DelayedSettingsRepository();
    final viewModel = AuthViewModel(auth, settingsRepo: settings);

    auth.emit(const AppUser(uid: 'user-a'));
    settings.complete('user-a', {'weeklyTarget': 7, 'restSeconds': 60});
    await pumpEventQueue();
    expect(viewModel.weeklyTarget, 7);

    auth.emit(const AppUser(uid: 'user-b'));
    expect(viewModel.authReady, isFalse);
    expect(viewModel.weeklyTarget, isNull);
    expect(viewModel.restSeconds, 3);

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
    int? restSeconds,
    String? name,
  }) async {
    if (updateError != null) throw updateError!;
    if (name != null) savedName = name;
  }
}
