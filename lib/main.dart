// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/record_repository.dart';
import 'repositories/tts_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/streak_repository.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';
import 'viewmodels/streak_viewmodel.dart';

import 'data/categories_seed.dart';
import 'app_router.dart' as app_router;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform; // ****
import 'dart:io' show Platform; // ****

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // **** 이미 초기화된 경우 건너뛰기 + 플랫폼별 초기화 방식 분기
  if (Firebase.apps.isEmpty) {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        // iOS/macOS는 plist 기반으로 네이티브가 먼저 초기화될 수 있어 옵션 없이 호출 // ****
        await Firebase.initializeApp(); // ****
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform, // ****
        );
      }
    } on FirebaseException catch (e) {
      // 네이티브가 먼저 올렸다면 duplicate-app이 날 수 있음 → 무시하고 진행 // ****
      if (e.code != 'duplicate-app') rethrow; // ****
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StreakRepository>(create: (_) => PrefsStreakRepository()),
        ChangeNotifierProvider(
          create: (ctx) =>
              StreakViewModel(ctx.read<StreakRepository>())
                ..ensureTodayUpdated(),
        ),

        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        ChangeNotifierProvider(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        Provider<RecordRepository>(create: (_) => InMemoryRecordRepository()),
        ChangeNotifierProvider(
          create: (ctx) => RecordsViewModel(ctx.read<RecordRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutinesViewModel()
            ..loadSeed(
              cats: categoriesSeed,
              routines: categoriesSeed.expand((c) => c.routines).toList(),
            ),
        ),
        Provider<TtsRepository>(create: (_) => TtsRepository()),
        ChangeNotifierProvider(
          create: (ctx) => CounterViewModel(
            ctx.read<TtsRepository>(),
            ctx.read<RecordsViewModel>(),
          ),
        ),
      ],
      child: Builder(
        builder: (ctx) {
          final router = app_router.createRouter(ctx);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFF6B35),
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
