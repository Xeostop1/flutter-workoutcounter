abstract class AuthRepository {
  Stream<bool> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class FakeAuthRepository implements AuthRepository {
  bool _signedIn = true;
  @override
  Stream<bool> authStateChanges() => Stream.value(_signedIn);
  @override
  Future<void> signInWithGoogle() async => _signedIn = true;
  @override
  Future<void> signInWithApple() async => _signedIn = true;
  @override
  Future<void> signOut() async => _signedIn = false;
  @override
  Future<void> deleteAccount() async => _signedIn = false;
}
