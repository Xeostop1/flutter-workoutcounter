import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  bool signedIn = false;

  AuthViewModel(this._repo) {
    _repo.authStateChanges().listen((v) {
      signedIn = v; notifyListeners();
    });
  }

  Future<void> google() => _repo.signInWithGoogle();
  Future<void> apple() => _repo.signInWithApple();
  Future<void> signOut() => _repo.signOut();
  Future<void> deleteAccount() => _repo.deleteAccount();
}
