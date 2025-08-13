import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 첫 실행/온보딩 스킵 플래그 부트스트랩
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthViewModel>().bootstrap();
      // 라우터 redirect가 목적지를 결정하므로, 살짝 대기만 주자.
      Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        // 목적지는 GoRouter.redirect가 정함. 아무 것도 안 해도 됨.
        // 단, 초기 진입을 트리거하기 위해 setState 정도만 해도 충분.
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // 에셋이 아직 없을 수 있으니 임시 텍스트로
        child: Text(
          'SPARKLE',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
