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
    // 잠깐 보여준 뒤 온보딩으로 이동
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 배경
            Positioned.fill(child: ColoredBox(color: Colors.black)),
            // 하단 중앙 로고 이미지
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image(
                    image: AssetImage('assets/images/splash_landing.jpg'),
                    fit: BoxFit.contain,
                    width: 450, // 필요 시 조절
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
