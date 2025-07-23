// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../view_models/auth_viewmodel.dart';
import 'workout_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authVM = AuthViewModel();
  bool _loading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    final cred = await _authVM.signInWithGoogle();
    setState(() => _loading = false);
    if (cred != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _loading = true);
    final cred = await _authVM.signInWithApple();
    setState(() => _loading = false);
    if (cred != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: Image.asset('assets/google_logo.png', width: 24),
              label: const Text('Google로 계속'),
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 16),

            // *** 비동기로 Apple 로그인 가능 여부를 체크해서 버튼 노출 ***
            FutureBuilder<bool>(
              future: SignInWithApple.isAvailable(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // 로딩 중에는 빈 공간
                }
                if (snapshot.hasData && snapshot.data! == true) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple로 계속'),
                    onPressed: _handleAppleSignIn,
                  );
                }
                return const SizedBox(); // 사용 불가 시 아무것도 안 보여 줌
              },
            ),
          ],
        ),
      ),
    );
  }
}
