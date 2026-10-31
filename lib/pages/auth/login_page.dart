import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

enum _LoginType { apple, google }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _LoginType? _loadingType;

  bool get _isLoading => _loadingType != null;

  Future<void> _signInGoogle() async {
    await _runLogin(
      type: _LoginType.google,
      action: () => context.read<AuthViewModel>().signInWithGoogle(),
      failTitle: '구글 로그인',
    );
  }

  Future<void> _signInApple() async {
    await _runLogin(
      type: _LoginType.apple,
      action: () => context.read<AuthViewModel>().signInWithApple(),
      failTitle: '애플 로그인',
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failTitle에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingType = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1D20),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 78),
                      const Text(
                        '마음 속 작은 불씨를 살려\n건강한 운동습관 만들기',
                        style: TextStyle(
                          color: Color(0xFFF1F1F1),
                          fontSize: 47 / 2,
                          fontWeight: FontWeight.w700,
                          height: 1.36,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '아래 버튼을 눌러 로그인을 진행해주세요',
                        style: TextStyle(
                          color: Color(0xFF898989),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Image.asset(
                          'assets/images/charactor_login.png',
                          width: 126,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/legal/privacy'),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
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
                      const SizedBox(height: 18),
                      _loginButton(
                        onPressed: _isLoading ? null : _signInApple,
                        backgroundColor: const Color(0xFFEBEBEB),
                        iconPath: 'assets/icons/icon_apple.png',
                        label: 'Apple 로그인',
                        loading: _loadingType == _LoginType.apple,
                      ),
                      const SizedBox(height: 8),
                      _loginButton(
                        onPressed: _isLoading ? null : _signInGoogle,
                        backgroundColor: const Color(0xFFB9B9BC),
                        iconPath: 'assets/icons/icon_google.png',
                        label: 'Google 로그인',
                        loading: _loadingType == _LoginType.google,
                      ),
                      const SizedBox(height: 28),
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
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: const Color(0xFF1E1E1E),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 18 / 1.2,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
