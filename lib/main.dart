// lib/main.dart

import 'package:counter_01/screens/home_screen.dart';
import 'package:counter_01/screens/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Workout Counter',
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(), // 앱 첫 화면을 HomeScreen으로 설정
      routes: {
        '/workout': (context) => const WorkoutScreen(), // 네비게이션 이동용
      },

    );
  }
}
