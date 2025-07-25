import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthViewModel() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      // 클라이언트 ID는 web이면 반드시 설정해야 함
      // clientId: 'your-client-id.apps.googleusercontent.com',
    );

    _googleSignIn.authenticationEvents.listen((event) {
      // 로그인 성공, 실패 등의 이벤트 처리
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.authenticate();
      if (user == null) return null;

      final GoogleSignInAuthentication googleAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // ❌ accessToken 생략
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      print('Google Sign-In failed: ${e.code}');
      return null;
    }
  }


  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      print('Apple Sign-In failed: $e');
      return null;
    }
  }


  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _auth.signOut();
  }
}
