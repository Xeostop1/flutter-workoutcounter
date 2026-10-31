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
  Timer? _timer;
  bool _minimumElapsed = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _minimumElapsed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (_minimumElapsed && auth.authReady && !_navigating) {
      _navigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!auth.signedIn) {
          context.go('/login');
        } else if (!auth.onboardingDone) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1D20),
      body: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.72,
          child: const Image(
            image: AssetImage('assets/images/logo_sporkle.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
