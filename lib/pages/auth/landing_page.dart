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
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.authReady && !_navigating) {
      _navigating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!auth.canUseApp) {
          context.go('/login');
        } else if (!auth.onboardingDone) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      });
    }

    // The native launch screen already displays the high-resolution logo.
    // Only show loading feedback while the account state is being resolved.
    return Scaffold(
      backgroundColor: Colors.black,
      body: auth.authReady
          ? const SizedBox.shrink()
          : const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}
