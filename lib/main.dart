import 'package:flutter/material.dart';
import 'screens/workout_screen.dart';// 모델 클래스 불러오기

void main() {
  runApp(MyApp()); // 앱 시작
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WorkoutScreen(),
    );
  }
}
