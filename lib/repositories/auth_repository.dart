// lib/repositories/auth_repository.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as sia;

import 'pending_workout_store.dart';

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
  FirebaseAuthRepository({PendingWorkoutStore? pendingWorkouts})
    : _pendingWorkouts = pendingWorkouts;

  final PendingWorkoutStore? _pendingWorkouts;
  final fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
    final provider = fba.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
      return;
    }

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android) {
      await _auth.signInWithProvider(provider);
      return;
    }

    final canUseNativeApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (!canUseNativeApple) {
      throw UnsupportedError('Apple 로그인은 iOS/macOS에서 지원됩니다.');
    }

    try {
      final apple = await sia.SignInWithApple.getAppleIDCredential(
        scopes: const [
          sia.AppleIDAuthorizationScopes.email,
          sia.AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = apple.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple 로그인 토큰을 받지 못했습니다.');
      }

      final cred = fba.OAuthProvider(
        'apple.com',
      ).credential(idToken: idToken, accessToken: apple.authorizationCode);
      await _auth.signInWithCredential(cred);

      // 최초 로그인 시 이름이 넘어오면 표시 이름 저장
      final user = _auth.currentUser;
      if (user != null &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        final displayName = [
          apple.givenName ?? '',
          apple.familyName ?? '',
        ].join(' ').trim();
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
      }
    } on sia.SignInWithAppleAuthorizationException catch (e) {
      if (e.code == sia.AuthorizationErrorCode.canceled) return;
      rethrow;
    }
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
    final user = _auth.currentUser;
    if (user == null) return;

    await _reauthenticate(user);
    await _deleteUserData(user.uid);
    await user.delete();
    await _pendingWorkouts?.clear(user.uid);
  }

  Future<void> _reauthenticate(fba.User user) async {
    final providerIds = user.providerData.map((info) => info.providerId);

    if (providerIds.contains('google.com')) {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(fba.GoogleAuthProvider());
        return;
      }

      final google = gsi.GoogleSignIn(scopes: const ['email', 'profile']);
      await google.signOut();
      final account = await google.signIn();
      if (account == null) throw StateError('Google 재인증이 취소되었습니다.');

      final auth = await account.authentication;
      await user.reauthenticateWithCredential(
        fba.GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        ),
      );
      return;
    }

    if (providerIds.contains('apple.com')) {
      final provider = fba.AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      if (kIsWeb) {
        await user.reauthenticateWithPopup(provider);
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await user.reauthenticateWithProvider(provider);
        return;
      }

      final apple = await sia.SignInWithApple.getAppleIDCredential(
        scopes: const [
          sia.AppleIDAuthorizationScopes.email,
          sia.AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = apple.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Apple 재인증 토큰을 받지 못했습니다.');
      }

      await user.reauthenticateWithCredential(
        fba.OAuthProvider(
          'apple.com',
        ).credential(idToken: idToken, accessToken: apple.authorizationCode),
      );
      return;
    }

    throw UnsupportedError('지원하지 않는 로그인 방식입니다.');
  }

  Future<void> _deleteUserData(String uid) async {
    final userDocument = _db.collection('users').doc(uid);
    // ponytail: 사용자 하위 컬렉션을 추가하면 이 삭제 목록에도 함께 추가한다.
    for (final name in const ['routines', 'workoutRecords']) {
      await _deleteCollection(userDocument.collection(name));
    }
    await userDocument.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final page = await collection.limit(450).get();
      if (page.docs.isEmpty) return;

      final batch = _db.batch();
      for (final document in page.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  @override
  bool get onboardingDone => _onboardingDone;

  @override
  set onboardingDone(bool v) => _onboardingDone = v;
}
