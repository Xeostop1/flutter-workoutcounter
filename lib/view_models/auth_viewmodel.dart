import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/firestore_service.dart';

class AuthViewModel {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _initializeGoogleSignIn() async {
    try {
      print('Google 초기화 시작');
      await _googleSignIn.initialize(
        serverClientId: '825515648011-27rfeeqkakb70rg5rugb7i5favuapu3v.apps.googleusercontent.com',
      );
      print('Google 초기화 완료');
    } catch (e) {
      print('Google 초기화 실패: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _initializeGoogleSignIn();


    try {
      print('Google 인증 시작');
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );
      print('Google 인증 성공: ${account.email}');

      late final GoogleSignInAuthentication auth;
      try {
        auth = await account.authentication; // *** 추가된 예외 처리
        print('ID 토큰 수신됨: ${auth.idToken}');
        print('Google 토큰 받아오기 성공');
      } catch (e) {
        print('Google 인증 토큰 받아오는 중 오류 발생: $e'); // *** 추가된 예외 처리
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      print('Firebase 자격증명 생성 완료');

      final result = await _auth.signInWithCredential(credential);
      print('Firebase 로그인 성공: ${result.user?.email}');

      // Firestore에 사용자 정보 저장
      if (result.user != null) {
        print('[Auth] Firestore에 사용자 정보 저장 시도...');
        await FirestoreService().saveUserToFirestore(result.user!);
        print('[Auth] Firestore에 사용자 정보 저장 완료!');
      }


      return result;
    } on GoogleSignInException catch (e) {
      print('Google 로그인 실패 - 코드: ${e.code}');
      return null;
    } catch (e) {
      print('Google 로그인 중 알 수 없는 오류 발생: $e');
      return null;
    }
  }


  Future<UserCredential?> signInWithApple() async {
    try {
      print('Apple 인증 시작');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print('Apple 인증 성공: ${appleCredential.userIdentifier}');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      print('Firebase 자격증명 생성 완료 (Apple)');

      final result = await _auth.signInWithCredential(oauthCredential);
      print('Firebase 로그인 성공 (Apple): ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Apple 로그인 중 오류 발생: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print('로그아웃 시작');
      await _googleSignIn.disconnect();
      await _auth.signOut();
      print('로그아웃 완료');
    } catch (e) {
      print('로그아웃 실패: $e');
    }
  }
}
