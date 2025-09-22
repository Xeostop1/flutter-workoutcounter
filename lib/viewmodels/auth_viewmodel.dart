// lib/viewmodels/auth_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart'; // AppUser, AuthRepository
import '../models/user_profile.dart'; // 도메인 사용자 모델

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    // Firebase/Auth 레포의 사용자 스트림을 받아서 도메인 모델(UserProfile)로 매핑
    _sub = _repo.userChanges().listen((u) {
      if (u == null) {
        _signedIn = false;
        _user = null;
      } else {
        _signedIn = true;

        // 로그인되면 온보딩은 한 번만 완료 처리(앱 정책에 맞게 조정 가능)
        if (!_repo.onboardingDone) {
          _repo.onboardingDone = true;
        }

        _user = UserProfile(
          uid: u.uid,
          name: u.displayName,
          email: u.email,
          photoUrl: u.photoUrl,
          onboardingDone: _repo.onboardingDone,
          weeklyTarget: _weeklyTarget,
        );
      }
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  StreamSubscription<AppUser?>? _sub;

  // --- Auth state ---
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  // --- 도메인 사용자(앱 전역에서 사용할 모델) ---
  UserProfile? _user;
  UserProfile? get user => _user;

  // --- 온보딩 상태(레포에 위임) ---
  bool get onboardingDone => _repo.onboardingDone;
  void setOnboardingDone(bool v) {
    if (_repo.onboardingDone == v) return;
    _repo.onboardingDone = v;
    if (_user != null) {
      _user = _user!.copyWith(onboardingDone: v);
    }
    notifyListeners();
  }

  // --- 사용자 선호(예: 주간 목표) ---
  int? _weeklyTarget;
  int? get weeklyTarget => _weeklyTarget;
  void setWeeklyTarget(int? v) {
    _weeklyTarget = v;
    if (_user != null) {
      _user = _user!.copyWith(weeklyTarget: v);
    }
    notifyListeners();
  }

  // ==== Actions (레포로 위임) ====
  Future<void> signInWithGoogle() => _repo.signInWithGoogle();
  Future<void> signInWithApple() => _repo.signInWithApple();
  Future<void> signOut() => _repo.signOut();
  Future<void> deleteAccount() => _repo.deleteAccount();

  // ==== (옵션) 뷰 전용 프로필 편집 ====
  // 원격 저장 로직이 아직 없다면 뷰모델에서 UI용으로만 업데이트
  void updateProfile({String? name, String? photoUrl}) {
    if (_user != null) {
      _user = _user!.copyWith(name: name, photoUrl: photoUrl);
      notifyListeners();
    }
  }

  // ==== 기존 화면과의 호환(점진적 마이그레이션용) ====
  String? get displayName => _user?.name;
  String? get photoUrl => _user?.photoUrl;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
