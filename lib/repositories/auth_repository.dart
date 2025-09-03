import 'dart:async';

abstract class AuthRepository {
  Stream<bool> authStateChanges();
  bool get isSignedIn;
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
  Future<void> deleteAccount();
}

class FakeAuthRepository implements AuthRepository {
  bool _signedIn;
  late final StreamController<bool> _ctrl;

  // 시작 상태를 T/F로 간단 제어
  FakeAuthRepository({bool startSignedIn = true}) : _signedIn = startSignedIn {
    // ✅ 새로 리슨할 때마다 최신 상태를 즉시 발행
    _ctrl = StreamController<bool>.broadcast(
      onListen: () => _ctrl.add(_signedIn),
    );
  }

  @override
  bool get isSignedIn => _signedIn; // ✅ 동기 getter

  @override
  Stream<bool> authStateChanges() => _ctrl.stream;

  @override
  Future<void> signInWithGoogle() async => _set(true);

  @override
  Future<void> signInWithApple() async => _set(true);

  @override
  Future<void> signOut() async => _set(false);

  @override
  Future<void> deleteAccount() async => _set(false);

  // 개발 중 직접 토글하고 싶으면 이 메서드 써도 됨
  void setSignedIn(bool v) => _set(v);

  void _set(bool v) {
    _signedIn = v;
    _ctrl.add(v); // 라우터/뷰모델이 즉시 감지
  }

  void dispose() {
    _ctrl.close();
  }
}
