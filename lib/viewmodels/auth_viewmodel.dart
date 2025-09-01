import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  bool signedIn;

  AuthViewModel(this._repo)
      : signedIn = _repo.isSignedIn {               // ✅ 초깃값을 즉시 반영
    _repo.authStateChanges().listen((v) {
      signedIn = v;
      notifyListeners();                            // ✅ 라우터 refreshListenable이 감지
    });
  }

  Future<void> google() => _repo.signInWithGoogle();
  Future<void> apple()  => _repo.signInWithApple();
  Future<void> signOut() => _repo.signOut();
  Future<void> deleteAccount() => _repo.deleteAccount();
}
