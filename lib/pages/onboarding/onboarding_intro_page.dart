import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthViewModel>().skipOnboarding();
              if (context.mounted) context.go('/home');
            },
            child: const Text('건너뛰기'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 에셋이 아직 없어도 문제 없도록 임시 컨테이너
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                'Burning Start',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/onboarding/goal'),
                  child: const Text('다음'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
