import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      _t = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (!auth.signedIn) {
          context.go('/login');                 // 스플래시 → 로그인
        } else if (!auth.onboardingDone) {
          context.go('/onboarding');            // 로그인 O + 온보딩 X
        } else {
          context.go('/home');                  // 로그인 O + 온보딩 O
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image(
          image: AssetImage('assets/images/splash_landing.jpg'),
          width: 220,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
