import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                "마음 속 작은 불씨를 살려\n건강한 운동습관 만들기",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Center(child: Text('🔥', style: TextStyle(fontSize: 96))),
              const Spacer(),
              _LoginBtn(
                label: 'Apple 로그인',
                onTap: () {
                  /* TODO: 애플 로그인 */
                },
              ),
              const SizedBox(height: 12),
              _LoginBtn(
                label: 'Google 로그인',
                onTap: () {
                  /* TODO: 구글 로그인 */
                },
                light: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/onboarding/intro'),
                  child: const Text('로그인 없이 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool light;
  const _LoginBtn({
    required this.label,
    required this.onTap,
    this.light = false,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: light ? Colors.white : Colors.black,
          foregroundColor: light ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
