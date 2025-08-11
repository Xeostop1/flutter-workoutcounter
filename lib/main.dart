// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:counter_01/router/app_router.dart';

// ▼ ViewModel 전역 주입 (프로젝트 경로에 맞게 조정)
import 'package:counter_01/view_models/workout_viewmodel.dart';
import 'package:counter_01/view_models/tts_viewmodel.dart';
import 'package:counter_01/view_models/routine_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // firebase_options.dart를 쓰고 있다면 옵션과 함께 초기화하는 게 안전합니다.
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutViewModel()),
        ChangeNotifierProvider(create: (_) => TtsViewModel()),
        ChangeNotifierProvider(create: (_) => RoutineViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Workout Counter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          scaffoldBackgroundColor: Colors.white,
        ),
        routerConfig: router, // GoRouter 라우팅 유지
      ),
    );
  }
}
