import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';          // ** ① 올바른 패키지 import **
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(            // ** ② 기본 생성자 사용 **
    scopes: <String>['email', 'profile'],                     // 필요 시 scope 추가
  );

  User? get currentUser => _auth.currentUser;

  // ▶ Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();   // ** ③ signIn() 호출 **
      if (googleUser == null) return null;                                   // 사용자가 취소했을 때

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;                                   // ** ④ authentication 가져오기 **

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,  // ** ⑤ accessToken/idToken **
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('🔴 Google sign-in error: $e');
      return null;
    }
  }

  // ▶ Apple 로그인 (기존 그대로)
  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCred = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await _auth.signInWithCredential(oauthCred);
  }

  // ▶ 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();    // ** ⑥ GoogleSignIn signOut **
    await _auth.signOut();
  }
}
