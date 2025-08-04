// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

<<<<<<< HEAD
import 'screens/workout_screen.dart';
import 'view_models/workout_viewmodel.dart';
import 'view_models/tts_viewmodel.dart';
=======
import 'screens/home_screen.dart'; // 새로 만든 HomeScreen
import 'screens/workout_screen.dart'; // 운동 화면
>>>>>>> 3f29e40 (홈화면 메인다트 수정 1/2)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutViewModel()),
        ChangeNotifierProvider(create: (_) => TtsViewModel()),
      ],
      child: MaterialApp(
        title: 'Workout Counter',
        home: const WorkoutScreen(),
      ),
=======
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
>>>>>>> 3f29e40 (홈화면 메인다트 수정 1/2)
    );
  }
}
