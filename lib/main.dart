// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// ↓ 이 줄을 추가해주세요. (패키지 이름은 pubspec.yaml의 name 과 일치해야 합니다)
import 'package:counter_01/firebase_options.dart';

import 'screens/workout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Counter',
      home: const WorkoutScreen(),
    );
  }
}
