import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

enum _LoginType { apple, google, guest }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _LoginType? _loadingType;
  bool get _isLoading => _loadingType != null;

  Future<void> _startGuest() => _runLogin(
    type: _LoginType.guest,
    action: () async {
      final auth = context.read<AuthViewModel>();
      await auth.continueAsGuest();
      if (mounted) context.go(auth.onboardingDone ? '/home' : '/onboarding');
    },
    failTitle: '게스트 시작',
  );

  Future<void> _signInGoogle() => _runLogin(
    type: _LoginType.google,
    action: () => context.read<AuthViewModel>().signInWithGoogle(),
    failTitle: '구글 로그인',
  );

  Future<void> _signInApple() => _runLogin(
    type: _LoginType.apple,
    action: () => context.read<AuthViewModel>().signInWithApple(),
    failTitle: '애플 로그인',
  );

  Future<void> _runLogin({
    required _LoginType type,
    required Future<void> Function() action,
    required String failTitle,
  }) async {
    if (_isLoading) return;

    setState(() => _loadingType = type);
    try {
      await action();
      // 성공 시 라우터 redirect가 자동 처리
    } catch (e) {
      if (!mounted) return;
      var message = '$failTitle에 실패했어요. 잠시 후 다시 시도해 주세요.';
      if (type == _LoginType.apple && e is FirebaseAuthException) {
        message = switch (e.code) {
          'operation-not-allowed' ||
          'invalid-oauth-client-id' ||
          'invalid-oauth-response' => 'Apple 로그인 설정을 확인해야 해요. 운영자에게 문의해주세요.',
          'account-exists-with-different-credential' =>
            '다른 로그인 방식으로 가입된 계정이에요. 기존 로그인 방법을 사용해주세요.',
          'network-request-failed' => '네트워크 연결을 확인한 뒤 Apple 로그인을 다시 시도해주세요.',
          _ => message,
        };
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _loadingType = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            // Reserve the copy and sign-in controls before enlarging the approved artwork.
            final artworkWidth = math.min(
              constraints.maxWidth - 32,
              ((constraints.maxHeight - (compact ? 364 : 426)) * 6 / 5)
                  .clamp(144.0, 360.0)
                  .toDouble(),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: compact ? 16 : 60),
                      const Text(
                        '마음 속 작은 불씨를 살려',
                        style: TextStyle(
                          color: Color(0xFFF1F1F1),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '건강한 운동습관 만들기',
                        style: TextStyle(
                          color: const Color(0xFFF1F1F1),
                          fontSize: compact ? 26 : 28,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 14),
                      const Text(
                        '로그인 없이 시작하거나 계정으로 로그인해주세요',
                        style: TextStyle(
                          color: Color(0xFF898989),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: RepaintBoundary(
                          child: Image.asset(
                            MediaQuery.disableAnimationsOf(context)
                                ? 'assets/images/login_flame_still.png'
                                : 'assets/images/login_flame_approved.webp',
                            key: const ValueKey('login-flame'),
                            width: artworkWidth,
                            height: artworkWidth * 5 / 6,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            excludeFromSemantics: true,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 18),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/legal/privacy'),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                color: Color(0xFF6E6E6E),
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(text: '하단 버튼으로 로그인하면\n'),
                                TextSpan(
                                  text: '개인정보처리방침',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.2,
                                  ),
                                ),
                                TextSpan(text: '에 동의하는 것으로 간주합니다.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _startGuest,
                          child: Text(
                            _loadingType == _LoginType.guest
                                ? '기기 저장소를 여는 중…'
                                : '로그인 없이 시작하기',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          '게스트 기록은 이 기기에 저장돼요. 앱 삭제 시 사라질 수 있어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9B9EA8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loginButton(
                        onPressed: _isLoading ? null : _signInGoogle,
                        backgroundColor: const Color(0xFFB9B9BC),
                        iconPath: 'assets/icons/icon_google.png',
                        label: 'Google 로그인',
                        loading: _loadingType == _LoginType.google,
                      ),
                      const SizedBox(height: 8),
                      _loginButton(
                        onPressed: _isLoading ? null : _signInApple,
                        backgroundColor: const Color(0xFFEBEBEB),
                        iconPath: 'assets/icons/icon_apple.png',
                        label: 'Apple 로그인',
                        loading: _loadingType == _LoginType.apple,
                      ),
                      SizedBox(height: compact ? 12 : 28),
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

  Widget _loginButton({
    required Future<void> Function()? onPressed,
    required Color backgroundColor,
    required String iconPath,
    required String label,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: const Color(0xFF101114),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.82),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A2A2A)),
                ),
              )
            else
              Image.asset(
                iconPath,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 20, height: 20),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18 / 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
