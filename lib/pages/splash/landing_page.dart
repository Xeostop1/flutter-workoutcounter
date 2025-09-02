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
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Image(
              image: AssetImage('assets/images/splash_landing.jpg'), // SPORKLE 로고 이미지
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
