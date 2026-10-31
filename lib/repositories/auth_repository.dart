// lib/repositories/auth_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:http/http.dart' as http;

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
  FirebaseAuthRepository({
    PendingWorkoutStore? pendingWorkouts,
    fba.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  }) : _pendingWorkouts = pendingWorkouts,
       _auth = auth ?? fba.FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _httpClient = httpClient;

  final PendingWorkoutStore? _pendingWorkouts;
  final fba.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final http.Client? _httpClient;
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

    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        // Firebase SDK가 iOS의 nonce·이름 처리와 Android 웹 인증을 담당한다.
        await _auth.signInWithProvider(provider);
      }
    } on fba.FirebaseAuthException catch (e) {
      if (const {
        'canceled',
        'cancelled',
        'web-context-canceled',
        'web-context-cancelled',
        'popup-closed-by-user',
        'cancelled-popup-request',
      }.contains(e.code)) {
        return;
      }
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
    if (_auth.currentUser?.uid != user.uid) {
      throw StateError('회원탈퇴 확인 중 로그인 계정이 변경되었습니다. 다시 시도해주세요.');
    }
    await _deleteUserData(user.uid);
    await user.delete();
    await _pendingWorkouts?.clear(user.uid);
  }

  Future<void> _reauthenticate(fba.User user) async {
    final providerIds = user.providerData.map((info) => info.providerId);

    if (providerIds.contains('google.com') &&
        !providerIds.contains('apple.com')) {
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

      final result = kIsWeb
          ? await user.reauthenticateWithPopup(provider)
          : await user.reauthenticateWithProvider(provider);
      if (_auth.currentUser?.uid != user.uid) {
        throw StateError('Apple 재인증 중 로그인 계정이 변경되었습니다.');
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final code = result.additionalUserInfo?.authorizationCode;
        if (code == null || code.isEmpty) {
          throw StateError('Apple 인증 코드를 받지 못해 탈퇴를 중단했습니다. 다시 시도해주세요.');
        }
        // Apple 권한 회수가 실패하면 사용자 데이터와 계정을 삭제하지 않는다.
        await _auth.revokeTokenWithAuthorizationCode(code);
      } else {
        await _revokeAppleAccessToken(user, result);
      }
      return;
    }

    throw UnsupportedError('지원하지 않는 로그인 방식입니다.');
  }

  Future<void> _revokeAppleAccessToken(
    fba.User user,
    fba.UserCredential result,
  ) async {
    final accessToken = result.credential?.accessToken;
    final idToken = await user.getIdToken();
    if (accessToken == null ||
        accessToken.isEmpty ||
        idToken == null ||
        idToken.isEmpty) {
      throw StateError('Apple 인증 정보를 받지 못해 탈퇴를 중단했습니다. 다시 시도해주세요.');
    }
    final client = _httpClient ?? http.Client();
    try {
      // Android/web SDK에는 회수 API가 없어 Firebase의 공식 클라이언트 REST API를 사용한다.
      final response = await client
          .post(
            Uri.https(
              'identitytoolkit.googleapis.com',
              '/v2/accounts:revokeToken',
              {'key': _auth.app.options.apiKey},
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'providerId': 'apple.com',
              'tokenType': 'ACCESS_TOKEN',
              'token': accessToken,
              'idToken': idToken,
              if (_auth.tenantId != null) 'tenantId': _auth.tenantId,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Apple 연결을 해제하지 못해 탈퇴를 중단했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (_httpClient == null) client.close();
    }
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
