import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 변경된 부분: GoogleSignIn() 생성자는 이제 인자를 받지 않습니다.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // ✨ 추가된 부분: GoogleSignIn 초기화를 위한 메서드
  // 이 메서드를 AuthViewModel 인스턴스를 생성한 후, 다른 GoogleSignIn 메서드를 호출하기 전에 반드시 호출해야 합니다.
  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      scopes: <String>['email', 'profile'], // 이곳에서 스코프를 설정합니다.
    );
  }

  // ▶ Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // GoogleSignIn.initialize()가 먼저 호출되었는지 확인하세요.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // 사용자가 취소했을 때

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}