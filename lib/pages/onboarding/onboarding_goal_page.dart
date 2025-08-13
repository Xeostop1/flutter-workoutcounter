import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OnboardingGoalPage extends StatefulWidget {
  const OnboardingGoalPage({super.key});

  @override
  State<OnboardingGoalPage> createState() => _OnboardingGoalPageState();
}

class _OnboardingGoalPageState extends State<OnboardingGoalPage> {
  int perWeek = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            '주에  몇 번  운동하기',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => perWeek = perWeek > 1 ? perWeek - 1 : 1),
                icon: const Icon(Icons.remove, color: Colors.white),
              ),
              Text(
                '$perWeek',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => perWeek++),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  // TODO: perWeek 저장이 필요하면 여기서 SharedPreferences/Firestore로 저장
                  await context.read<AuthViewModel>().skipOnboarding();
                  if (context.mounted) context.go('/home');
                },
                child: const Text('시작하기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
