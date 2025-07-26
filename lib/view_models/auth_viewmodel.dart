import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId: '825515648011-27rfeeqkakb70rg5rugb7i5favuapu3v.apps.googleusercontent.com',
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      print('Google Sign-In failed: ${e.code}');
      return null;
    }
  }


  Future<UserCredential?> signInWithApple() async { // ✅ Apple 로그인 추가 ***
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
