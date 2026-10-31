import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_settings_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo, {UserSettingsRepository? settingsRepo})
    : _settingsRepo = settingsRepo ?? UserSettingsRepository() {
    _sub = _repo.userChanges().listen(_onUserChanged);
  }

  final AuthRepository _repo;
  final UserSettingsRepository _settingsRepo;
  StreamSubscription<AppUser?>? _sub;
  int _authGeneration = 0;

  bool _signedIn = false;
  bool get signedIn => _signedIn;
  bool _authReady = false;
  bool get authReady => _authReady;

  // 짧은 한국어 주석: 사용자 설정 로드 완료 여부
  bool _settingsLoaded = false;
  bool get settingsLoaded => _settingsLoaded;

  UserProfile? _user;
  UserProfile? get user => _user;

  int? _weeklyTarget;
  int? get weeklyTarget => _weeklyTarget;

  bool _homeTutorialDone = false;
  bool get homeTutorialDone => _homeTutorialDone;

  bool _voiceCountingEnabled = false;
  double _voicePitch = 1.0;
  int _restSeconds = 3;
  bool get voiceCountingEnabled => _voiceCountingEnabled;
  double get voicePitch => _voicePitch;
  int get restSeconds => _restSeconds;

  bool get onboardingDone => _repo.onboardingDone;

  Future<void> _onUserChanged(AppUser? appUser) async {
    final generation = ++_authGeneration;
    if (appUser == null) {
      _resetToSignedOutState();
      _authReady = true;
      notifyListeners();
      return;
    }

    if (_user?.uid != appUser.uid) _resetToSignedOutState();
    _authReady = false;
    _signedIn = true;
    _settingsLoaded = false;
    final uid = appUser.uid;

    // 먼저 기본값으로 화면 표시
    _user = UserProfile(
      uid: uid,
      name: appUser.displayName,
      email: appUser.email,
      photoUrl: appUser.photoUrl,
      onboardingDone: _repo.onboardingDone,
      weeklyTarget: _weeklyTarget,
      homeTutorialDone: _homeTutorialDone,
      voiceCountingEnabled: _voiceCountingEnabled,
      voicePitch: _voicePitch,
      restSeconds: _restSeconds,
    );
    notifyListeners();

    try {
      final data = await _settingsRepo.load(uid);

      // 계정 전환 중 오래된 응답은 무시
      if (generation != _authGeneration || _repo.currentUser()?.uid != uid) {
        return;
      }

      final loadedOnboardingDone = (data?['onboardingDone'] as bool?) ?? false;
      final loadedWeeklyTarget = _parseWeeklyTarget(data?['weeklyTarget']);
      final loadedHomeTutorialDone =
          (data?['homeTutorialDone'] as bool?) ?? false;
      final loadedVoiceCountingEnabled =
          (data?['voiceCountingEnabled'] as bool?) ?? _voiceCountingEnabled;
      final loadedVoicePitch =
          ((data?['voicePitch'] as num?)?.toDouble() ?? _voicePitch)
              .clamp(0.5, 2.0)
              .toDouble();
      final loadedRestSeconds = ((data?['restSeconds'] as num?)?.toInt() ?? 3)
          .clamp(1, 600);
      final loadedName = (data?['name'] as String?)?.trim();

      _repo.onboardingDone = loadedOnboardingDone;
      _weeklyTarget = loadedWeeklyTarget;
      _homeTutorialDone = loadedHomeTutorialDone;
      _voiceCountingEnabled = loadedVoiceCountingEnabled;
      _voicePitch = loadedVoicePitch;
      _restSeconds = loadedRestSeconds;

      _user = _user?.copyWith(
        name: loadedName?.isNotEmpty == true ? loadedName : appUser.displayName,
        onboardingDone: loadedOnboardingDone,
        weeklyTarget: loadedWeeklyTarget,
        homeTutorialDone: loadedHomeTutorialDone,
        voiceCountingEnabled: loadedVoiceCountingEnabled,
        voicePitch: loadedVoicePitch,
        restSeconds: loadedRestSeconds,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: failed to load user settings: $e');
      }
    } finally {
      if (generation == _authGeneration && _repo.currentUser()?.uid == uid) {
        _settingsLoaded = true;
        _authReady = true;
        notifyListeners();
      }
    }
  }

  int? _parseWeeklyTarget(Object? value) {
    if (value is int && value > 0) return value.clamp(1, 7);
    if (value is num) {
      final parsed = value.toInt();
      return parsed > 0 ? parsed.clamp(1, 7) : null;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0) return parsed.clamp(1, 7);
    }
    return null;
  }

  void _resetToSignedOutState() {
    _signedIn = false;
    _settingsLoaded = false;
    _repo.onboardingDone = false;
    _user = null;
    _weeklyTarget = null;
    _homeTutorialDone = false;
    _voiceCountingEnabled = false;
    _voicePitch = 1.0;
    _restSeconds = 3;
  }

  // 온보딩 완료 + 주간 목표 저장
  Future<void> completeOnboarding({required int weeklyTarget}) async {
    final uid = _user?.uid;
    if (uid == null) {
      throw StateError('로그인 정보가 없습니다.');
    }

    final safeTarget = weeklyTarget.clamp(1, 7);
    try {
      await _settingsRepo.update(
        uid,
        onboardingDone: true,
        weeklyTarget: safeTarget,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: failed to save onboarding data: $e');
      }
      rethrow;
    }

    if (_user?.uid != uid) {
      throw StateError('온보딩 중 로그인 계정이 변경되었습니다.');
    }
    _repo.onboardingDone = true;
    _weeklyTarget = safeTarget;
    _user = _user?.copyWith(onboardingDone: true, weeklyTarget: safeTarget);
    notifyListeners();
  }

  Future<void> markHomeTutorialDone() async {
    final uid = _user?.uid;
    if (uid == null || _homeTutorialDone) return;

    try {
      await _settingsRepo.update(uid, homeTutorialDone: true);
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: failed to save homeTutorialDone: $e');
      }
      rethrow;
    }

    if (_user?.uid != uid) {
      throw StateError('튜토리얼 저장 중 로그인 계정이 변경되었습니다.');
    }
    _homeTutorialDone = true;
    _user = _user?.copyWith(homeTutorialDone: true);
    notifyListeners();
  }

  void setOnboardingDone(bool value) {
    if (_repo.onboardingDone == value) return;
    _repo.onboardingDone = value;
    if (_user != null) {
      _user = _user!.copyWith(onboardingDone: value);
    }
    notifyListeners();
  }

  void setWeeklyTarget(int? value) {
    final normalized = (value != null && value > 0) ? value : null;
    _weeklyTarget = normalized;
    if (_user != null) {
      _user = _user!.copyWith(weeklyTarget: normalized);
    }
    notifyListeners();
  }

  Future<void> setVoiceCountingEnabled(bool enabled) async {
    if (_voiceCountingEnabled == enabled) return;

    final uid = _user?.uid;
    final previous = _voiceCountingEnabled;

    _voiceCountingEnabled = enabled;
    if (_user != null) {
      _user = _user!.copyWith(voiceCountingEnabled: enabled);
    }
    notifyListeners();

    if (uid != null) {
      try {
        await _settingsRepo.update(uid, voiceCountingEnabled: enabled);
      } catch (e) {
        if (_user?.uid == uid && _voiceCountingEnabled == enabled) {
          _voiceCountingEnabled = previous;
          _user = _user?.copyWith(voiceCountingEnabled: previous);
          notifyListeners();
        }
        if (kDebugMode) {
          print('AuthViewModel: failed to save voiceCountingEnabled: $e');
        }
        rethrow;
      }
    }
  }

  Future<void> setVoicePitch(double pitch) async {
    final clamped = pitch.clamp(0.5, 2.0).toDouble();
    if (_voicePitch == clamped) return;

    final uid = _user?.uid;
    final previous = _voicePitch;
    _voicePitch = clamped;
    if (_user != null) {
      _user = _user!.copyWith(voicePitch: clamped);
    }
    notifyListeners();

    if (uid != null) {
      try {
        await _settingsRepo.update(uid, voicePitch: clamped);
      } catch (e) {
        if (_user?.uid == uid && _voicePitch == clamped) {
          _voicePitch = previous;
          _user = _user?.copyWith(voicePitch: previous);
          notifyListeners();
        }
        if (kDebugMode) {
          print('AuthViewModel: failed to save voicePitch: $e');
        }
        rethrow;
      }
    }
  }

  Future<void> setVoicePresetFemale() => setVoicePitch(1.10);
  Future<void> setVoicePresetMale() => setVoicePitch(0.90);

  Future<void> setRestSeconds(int seconds) async {
    final value = seconds.clamp(1, 600);
    if (_restSeconds == value) return;

    final uid = _user?.uid;
    final previous = _restSeconds;
    _restSeconds = value;
    _user = _user?.copyWith(restSeconds: value);
    notifyListeners();

    if (uid != null) {
      try {
        await _settingsRepo.update(uid, restSeconds: value);
      } catch (_) {
        if (_user?.uid == uid && _restSeconds == value) {
          _restSeconds = previous;
          _user = _user?.copyWith(restSeconds: previous);
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  Future<void> setDisplayName(String name) async {
    final value = name.trim();
    final uid = _user?.uid;
    if (value.isEmpty || uid == null || value == _user?.name) return;

    await _settingsRepo.update(uid, name: value);
    if (_user?.uid != uid) {
      throw StateError('닉네임 저장 중 로그인 계정이 변경되었습니다.');
    }
    _user = _user?.copyWith(name: value);
    notifyListeners();
  }

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();
  Future<void> signInWithApple() => _repo.signInWithApple();
  Future<void> signOut() => _repo.signOut();
  Future<void> deleteAccount() => _repo.deleteAccount();

  void updateProfile({String? name, String? photoUrl}) {
    if (_user != null) {
      _user = _user!.copyWith(name: name, photoUrl: photoUrl);
      notifyListeners();
    }
  }

  String? get displayName => _user?.name;
  String? get photoUrl => _user?.photoUrl;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
