import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:counter_01/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    group('$platform Apple authentication', () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('uses Firebase provider with email and name scopes', () async {
        final h = _Harness();
        await h.repository.signInWithApple();
        final provider = h.firebase.provider! as auth.AppleAuthProvider;
        expect(provider.providerId, 'apple.com');
        expect(provider.scopes, ['email', 'name']);
        expect(h.events, ['sign-in']);
      });

      for (final code in [
        'canceled',
        'cancelled',
        'web-context-canceled',
        'web-context-cancelled',
        'popup-closed-by-user',
        'cancelled-popup-request',
      ]) {
        test('$code is a cancelled login, not a failure', () async {
          final h = _Harness();
          h.firebase.signInError = auth.FirebaseAuthException(code: code);
          await h.repository.signInWithApple();
          expect(h.events, ['sign-in']);
        });
      }

      test('configuration failure is not swallowed', () async {
        final h = _Harness();
        h.firebase.signInError = auth.FirebaseAuthException(
          code: 'operation-not-allowed',
        );
        await expectLater(
          h.repository.signInWithApple(),
          throwsA(isA<auth.FirebaseAuthException>()),
        );
        expect(h.events, ['sign-in']);
      });

      test(
        'deletion reauthenticates, revokes Apple, then deletes only this UID',
        () async {
          final h = _Harness();
          await h.repository.deleteAccount();
          final revoke = platform == TargetPlatform.iOS
              ? 'revoke-sdk'
              : 'revoke-rest';
          expect(h.user.provider!.providerId, 'apple.com');
          expect(
            h.events.indexOf('reauth'),
            lessThan(h.events.indexOf(revoke)),
          );
          expect(
            h.events.indexOf(revoke),
            lessThan(h.events.indexOf('db:users')),
          );
          expect(h.events, contains('doc:user-a'));
          expect(
            h.events.indexOf('delete-profile'),
            lessThan(h.events.indexOf('delete-auth')),
          );
          if (platform == TargetPlatform.iOS) {
            expect(h.firebase.revokedCode, 'fake-apple-code');
            expect(h.requests, isEmpty);
          } else {
            final request = h.requests.single;
            expect(request.url.scheme, 'https');
            expect(request.url.host, 'identitytoolkit.googleapis.com');
            expect(request.url.path, '/v2/accounts:revokeToken');
            expect(request.url.queryParameters, {'key': 'fake-api-key'});
            expect(jsonDecode(request.body), {
              'providerId': 'apple.com',
              'tokenType': 'ACCESS_TOKEN',
              'token': 'fake-apple-access',
              'idToken': 'fake-firebase-id',
            });
          }
        },
      );

      test(
        'cancelled deletion reauthentication must not delete data',
        () async {
          final h = _Harness();
          h.user.reauthError = auth.FirebaseAuthException(code: 'canceled');
          await expectLater(
            h.repository.deleteAccount(),
            throwsA(isA<auth.FirebaseAuthException>()),
          );
          expect(h.events, ['reauth']);
        },
      );

      test('revocation failure must not delete data or auth account', () async {
        final h = _Harness();
        h.firebase.revokeError = StateError('fake revoke failure');
        h.status = 401;
        await expectLater(h.repository.deleteAccount(), throwsStateError);
        expect(h.events.where((event) => event.startsWith('db:')), isEmpty);
        expect(h.events, isNot(contains('delete-auth')));
      });

      test('missing Apple revocation credentials must stop deletion', () async {
        final h = _Harness();
        h.user.result = _Credential(code: null, access: null);
        await expectLater(h.repository.deleteAccount(), throwsStateError);
        expect(h.events, ['reauth']);
      });

      test(
        'account change during reauthentication stops revocation and deletion',
        () async {
          final h = _Harness();
          h.user.afterReauth = () =>
              h.firebase.user = _User(h.events, uid: 'user-b');
          await expectLater(h.repository.deleteAccount(), throwsStateError);
          expect(h.events, ['reauth']);
        },
      );

      test('account change during revocation stops data deletion', () async {
        final h = _Harness();
        h.afterRevoke = () => h.firebase.user = _User(h.events, uid: 'user-b');
        await expectLater(h.repository.deleteAccount(), throwsStateError);
        expect(h.events.where((event) => event.startsWith('db:')), isEmpty);
      });

      test(
        'linked Google and Apple account still revokes Apple access',
        () async {
          final h = _Harness();
          h.user.providers = [_Provider('google.com'), _Provider('apple.com')];
          await h.repository.deleteAccount();
          expect(h.user.provider!.providerId, 'apple.com');
          expect(
            h.events,
            contains(
              platform == TargetPlatform.iOS ? 'revoke-sdk' : 'revoke-rest',
            ),
          );
        },
      );
    });
  }

  testWidgets('Android revocation timeout leaves all user data intact', (
    tester,
  ) async {
    final h = _Harness();
    h.pendingHttp = Completer<http.Response>();
    final deletion = expectLater(
      h.repository.deleteAccount(),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    await deletion;
    expect(h.events.where((event) => event.startsWith('db:')), isEmpty);
    expect(h.events, isNot(contains('delete-auth')));
  });

  test(
    'Android forwards a configured tenant and stops on missing Firebase token',
    () async {
      final h = _Harness();
      h.firebase.tenant = 'fake-tenant';
      await h.repository.deleteAccount();
      expect(jsonDecode(h.requests.single.body)['tenantId'], 'fake-tenant');
      final missing = _Harness();
      missing.user.idToken = null;
      await expectLater(missing.repository.deleteAccount(), throwsStateError);
      expect(missing.requests, isEmpty);
      expect(missing.events, ['reauth']);
    },
  );
}

class _Harness {
  final events = <String>[];
  final requests = <http.Request>[];
  int status = 200;
  VoidCallback? afterRevoke;
  Completer<http.Response>? pendingHttp;
  late final user = _User(events);
  late final firebase = _FirebaseAuth(events, () => afterRevoke?.call())
    ..user = user;
  late final repository = FirebaseAuthRepository(
    auth: firebase,
    firestore: _Firestore(events),
    httpClient: MockClient((request) async {
      requests.add(request);
      events.add('revoke-rest');
      afterRevoke?.call();
      return pendingHttp?.future ?? http.Response('', status);
    }),
  );
}

class _FirebaseAuth extends Fake implements auth.FirebaseAuth {
  _FirebaseAuth(this.events, this.afterRevoke);
  final List<String> events;
  final VoidCallback afterRevoke;
  auth.User? user;
  auth.AuthProvider? provider;
  Object? signInError;
  Object? revokeError;
  String? revokedCode;
  String? tenant;
  @override
  auth.User? get currentUser => user;
  @override
  FirebaseApp get app => _App();
  @override
  String? get tenantId => tenant;
  @override
  Future<auth.UserCredential> signInWithProvider(
    auth.AuthProvider provider,
  ) async {
    events.add('sign-in');
    this.provider = provider;
    if (signInError != null) throw signInError!;
    return _Credential();
  }

  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    events.add('revoke-sdk');
    revokedCode = code;
    if (revokeError != null) throw revokeError!;
    afterRevoke();
  }
}

class _User extends Fake implements auth.User {
  _User(this.events, {this.uid = 'user-a'});
  final List<String> events;
  @override
  final String uid;
  List<auth.UserInfo> providers = [_Provider('apple.com')];
  Object? reauthError;
  VoidCallback? afterReauth;
  auth.AuthProvider? provider;
  auth.UserCredential result = _Credential();
  String? idToken = 'fake-firebase-id';
  @override
  List<auth.UserInfo> get providerData => providers;
  @override
  Future<auth.UserCredential> reauthenticateWithProvider(
    auth.AuthProvider provider,
  ) async {
    events.add('reauth');
    this.provider = provider;
    if (reauthError != null) throw reauthError!;
    afterReauth?.call();
    return result;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => idToken;
  @override
  Future<void> delete() async => events.add('delete-auth');
}

class _Provider extends Fake implements auth.UserInfo {
  _Provider(this.providerId);
  @override
  final String providerId;
}

class _Credential extends Fake implements auth.UserCredential {
  _Credential({
    String? code = 'fake-apple-code',
    String? access = 'fake-apple-access',
  }) : additionalUserInfo = _Info(code),
       credential = auth.OAuthProvider(
         'apple.com',
       ).credential(accessToken: access);
  @override
  final auth.AdditionalUserInfo additionalUserInfo;
  @override
  final auth.AuthCredential credential;
}

class _Info extends Fake implements auth.AdditionalUserInfo {
  _Info(this.authorizationCode);
  @override
  final String? authorizationCode;
}

class _App extends Fake implements FirebaseApp {
  @override
  FirebaseOptions get options => const FirebaseOptions(
    apiKey: 'fake-api-key',
    appId: 'fake-app',
    messagingSenderId: 'fake-sender',
    projectId: 'fake-project',
  );
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.events);
  final List<String> events;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    events.add('db:$path');
    return _Collection(events);
  }
}

// Firestore SDK의 sealed 인터페이스를 가짜 데이터 검증용으로만 구현한다.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.events);
  final List<String> events;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    events.add('doc:$path');
    return _Document(events);
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) => _Query();
}

// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.events);
  final List<String> events;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(events);
  @override
  Future<void> delete() async => events.add('delete-profile');
}

// ignore: subtype_of_sealed_class
class _Query extends Fake implements Query<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot();
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [];
}
