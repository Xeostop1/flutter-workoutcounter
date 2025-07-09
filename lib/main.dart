import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/workout_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 반드시 맨 앞에!
  MobileAds.instance.initialize();           // AdMob SDK 초기화
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WorkoutScreen(),
    );
  }
}
