// lib/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signInGoogle(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    try {
      await auth.signInWithGoogle();
      // 성공 시 라우터 redirect가 자동 처리
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 로그인에 실패했어요: $e')));
    }
  }

  Future<void> _signInApple(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    try {
      await auth.signInWithApple();
      // 성공 시 라우터 redirect가 자동 처리
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('애플 로그인에 실패했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 70),

                      // 헤드라인
                      const Text(
                        '마음 속 작은 불씨를 살려\n건강한 운동습관 만들기',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 서브 텍스트
                      Text(
                        '아래 버튼을 눌러 로그인을 진행해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3,
                          height: 1.4,
                        ),
                      ),

                      // 남는 공간 밀어내기
                      const Spacer(),

                      // ✅ 마스코트: 버튼 바로 위
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 은은한 스폿 배경
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment(0, 0.2),
                                      radius: 0.65,
                                      colors: [
                                        Color(0x22FFFFFF),
                                        Color(0x00000000),
                                      ],
                                      stops: [0.0, 1.0],
                                    ),
                                  ),
                                ),
                                // 크롭 없이 전체 보이게
                                FittedBox(
                                  fit: BoxFit.contain,
                                  child: Image.asset(
                                    'assets/images/charactor_login.png',
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 약관 안내 (마스코트 아래, 버튼 위)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '하단 버튼으로 로그인하면\n개인정보처리방침에 동의하는 것으로 간주합니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      // Apple 로그인
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _signInApple(context),
                          icon: Image.asset(
                            'assets/icons/icon_apple.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 22, height: 22),
                          ),
                          label: const Text(
                            'Apple 로그인',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Google 로그인
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _signInGoogle(context),
                          icon: Image.asset(
                            'assets/icons/icon_google.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 22, height: 22),
                          ),
                          label: const Text(
                            'Google 로그인',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
