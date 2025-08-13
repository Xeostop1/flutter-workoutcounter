import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/social_button.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // ✔︎ 배경 이미지는 네가 준 sns_login.png를 그대로 사용
            Positioned.fill(
              child: Image.asset(
                'assets/images/sns_login.png',
                fit: BoxFit.cover,
              ),
            ),

            // 하단 버튼/스킵 오버레이
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SocialButton.apple(
                      label: 'Apple 로그인',
                      onPressed: () {
                        // TODO: signInWithApple() 연결
                      },
                      // iconAsset: 'assets/icons/apple.png',
                    ),
                    const SizedBox(height: 12),
                    SocialButton.google(
                      label: 'Google 로그인',
                      onPressed: () {
                        // TODO: signInWithGoogle() 연결
                      },
                      // iconAsset: 'assets/icons/google.png',
                    ),
                    const SizedBox(height: 8),
                    // ✅ 맨 아래 Skip: 디바이스 온보딩 스킵 저장 후 홈으로
                    TextButton(
                      onPressed: () async {
                        await context.read<AuthViewModel>().skipOnboarding();
                        if (context.mounted) context.go('/home');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                      ),
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
