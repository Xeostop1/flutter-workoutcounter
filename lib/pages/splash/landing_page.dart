import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // 짧게 보여주고 온보딩으로 이동
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.72,
          child: const Image(
            image: AssetImage('assets/images/logo_sporkle.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
