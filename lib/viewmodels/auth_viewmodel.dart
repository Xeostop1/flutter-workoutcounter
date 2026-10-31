import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../models/trainer_voice.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_settings_repository.dart';
import '../repositories/guest_store.dart';
import '../repositories/guest_migration.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._repo, {
    UserSettingsRepository? settingsRepo,
    TargetPlatform? voicePlatform,
    GuestStore? guestStore,
    GuestMigration? guestMigration,
  }) : _settingsRepo =
           settingsRepo ?? UserSettingsRepository(guestStore: guestStore),
       _guests = guestStore,
       _guestMigration = guestMigration,
       _voicePlatform = voicePlatform ?? defaultTargetPlatform {
    _sub = _repo.userChanges().listen(_onUserChanged);
  }

  final AuthRepository _repo;
  final UserSettingsRepository _settingsRepo;
  final GuestStore? _guests;
  final GuestMigration? _guestMigration;
  bool get isGuest => _user?.uid == GuestStore.uid;
  bool get canUseApp => signedIn || isGuest;
  bool _deletingAccount = false;
  String? get dataUid => _deletingAccount ? null : _user?.uid;
  String? get _sessionUid =>
      _repo.currentUser()?.uid ??
      (_guests?.active == true ? GuestStore.uid : null);
  final TargetPlatform _voicePlatform;
  StreamSubscription<AppUser?>? _sub;
  int _authGeneration = 0;
  bool _disposed = false;
  int get sessionGeneration => _authGeneration;

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
  String? _systemVoiceId;
  String? get systemVoiceId => _systemVoiceId;
  TrainerVoice? _trainerVoice;
  TrainerVoice? get trainerVoice => _trainerVoice;
  int _restSeconds = 3;
  bool get voiceCountingEnabled => _voiceCountingEnabled;
  double get voicePitch => _voicePitch;
  int get restSeconds => _restSeconds;

  bool get onboardingDone => _repo.onboardingDone;

  Future<void> _onUserChanged(AppUser? appUser) async {
    if (_disposed) return;
    final generation = ++_authGeneration;
    if (appUser == null && _guests != null) {
      try {
        if (await _guests.restore()) {
          appUser = const AppUser(uid: GuestStore.uid, displayName: '게스트');
        }
      } catch (_) {
        // Keep damaged local data intact; entering guest mode will report the error.
      }
      if (generation != _authGeneration) return;
    }
    if (appUser == null) {
      _resetToSignedOutState();
      _authReady = true;
      notifyListeners();
      return;
    }

    final incomingUid = appUser.uid;
    if (incomingUid != GuestStore.uid && _guests != null) {
      try {
        await _guests.claim(
          incomingUid,
          isCurrent: () =>
              generation == _authGeneration &&
              _repo.currentUser()?.uid == incomingUid,
        );
      } catch (_) {
        // The records recovery banner retries a failed local claim without deletion.
      }
      if (generation != _authGeneration) return;
    }

    if (_user?.uid != appUser.uid) _resetToSignedOutState();
    _authReady = false;
    _signedIn = appUser.uid != GuestStore.uid;
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
      trainerVoiceId: _trainerVoice?.id,
      systemVoiceId: _systemVoiceId,
      restSeconds: _restSeconds,
    );
    notifyListeners();

    try {
      final data = await _settingsRepo.load(uid);

      // 계정 전환 중 오래된 응답은 무시
      if (generation != _authGeneration || _sessionUid != uid) {
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
      // Keep legacy choices until this platform saves its own voice selection.
      _systemVoiceId =
          (data?[systemVoiceSettingsKey(_voicePlatform)] ??
                  data?['systemVoiceId'])
              as String?;
      _trainerVoice = TrainerVoice.values
          .where((voice) => voice.id == data?['trainerVoiceId'])
          .firstOrNull;
      _restSeconds = loadedRestSeconds;

      _user = _user?.copyWith(
        name: loadedName?.isNotEmpty == true ? loadedName : appUser.displayName,
        onboardingDone: loadedOnboardingDone,
        weeklyTarget: loadedWeeklyTarget,
        homeTutorialDone: loadedHomeTutorialDone,
        voiceCountingEnabled: loadedVoiceCountingEnabled,
        voicePitch: loadedVoicePitch,
        trainerVoiceId: _trainerVoice?.id,
        systemVoiceId: _systemVoiceId,
        restSeconds: loadedRestSeconds,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: failed to load user settings: $e');
      }
    } finally {
      if (generation == _authGeneration && _sessionUid == uid) {
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
    _trainerVoice = null;
    _systemVoiceId = null;
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

  Future<void> setSystemVoice(String identifier) async {
    final uid = _user?.uid;
    final generation = _authGeneration;
    if (uid != null) {
      await _settingsRepo.update(
        uid,
        systemVoiceId: identifier,
        systemVoicePlatform: _voicePlatform,
      );
    }
    if (generation != _authGeneration || _user?.uid != uid) return;
    _systemVoiceId = identifier;
    _user = _user?.copyWith(systemVoiceId: identifier);
    notifyListeners();
  }

  Future<void> setTrainerVoice(TrainerVoice voice) async {
    final uid = _user?.uid;
    final generation = _authGeneration;
    // Persist before applying, so a failed save never changes the active voice.
    if (uid != null) await _settingsRepo.update(uid, trainerVoiceId: voice.id);
    if (generation != _authGeneration || _user?.uid != uid) return;
    _trainerVoice = voice;
    _user = _user?.copyWith(trainerVoiceId: voice.id);
    notifyListeners();
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
  Future<void> continueAsGuest() async {
    final guests = _guests;
    if (guests == null) throw StateError('게스트 저장소를 열 수 없습니다.');
    if (_repo.currentUser() != null) return;
    await guests.setActive(true);
    if (_repo.currentUser() == null) await _onUserChanged(null);
  }

  Future<void> signOut() async {
    await _guests?.setActive(false);
    await _repo.signOut();
  }

  Future<void> deleteAccount() async {
    if (isGuest) throw StateError('게스트는 탈퇴할 계정이 없습니다.');
    final uid = _user?.uid;
    if (_deletingAccount) return;
    _deletingAccount = true;
    notifyListeners();
    try {
      if (uid != null) await _guestMigration?.pause(uid);
      await _repo.deleteAccount();
      if (uid != null) await _guests?.forgetAccount(uid);
    } finally {
      if (uid != null) _guestMigration?.resume(uid);
      _deletingAccount = false;
      if (!_disposed) notifyListeners();
    }
  }

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
    _disposed = true;
    _authGeneration++;
    _sub?.cancel();
    super.dispose();
  }
}
