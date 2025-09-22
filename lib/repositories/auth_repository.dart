// lib/repositories/auth_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

/// 뷰모델/앱이 참조할 가벼운 유저 모델
class AppUser {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  const AppUser({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.email,
  });
}

/// Repository 인터페이스 (유지)
abstract class AuthRepository {
  Stream<AppUser?> userChanges();
  AppUser? currentUser();

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();

  // 온보딩 완료 여부(임시 메모리/로컬)
  bool get onboardingDone;
  set onboardingDone(bool v);
}

/// Firebase 실제 구현 (FakeAuthRepository 제거하고 이걸 사용)
class FirebaseAuthRepository implements AuthRepository {
  final fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;
  bool _onboardingDone = false; // 필요 시 SharedPreferences 등으로 교체 가능

  AppUser? _map(fba.User? u) => u == null
      ? null
      : AppUser(
          uid: u.uid,
          displayName: u.displayName,
          photoUrl: u.photoURL,
          email: u.email,
        );

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  AppUser? currentUser() => _map(_auth.currentUser);

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = fba.GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
    } else {
      final google = gsi.GoogleSignIn(scopes: const ['email', 'profile']);
      final acc = await google.signIn(); // 사용자가 취소하면 null
      if (acc == null) return;

      final auth = await acc.authentication;
      final cred = fba.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred);
    }
  }

  @override
  Future<void> signInWithApple() async {
    // 다음 단계에서 sign_in_with_apple로 붙일 예정
    throw UnimplementedError('Apple 로그인은 다음 단계에서 붙일게요.');
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await gsi.GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u != null) {
      await u.delete(); // 재인증 필요 시 예외 가능
    }
  }

  @override
  bool get onboardingDone => _onboardingDone;

  @override
  set onboardingDone(bool v) => _onboardingDone = v;
}
