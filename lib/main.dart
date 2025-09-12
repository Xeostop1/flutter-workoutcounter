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

import 'package:firebase_core/firebase_core.dart'; // ✅ firebase_core만 유지
// import 'firebase_options.dart'; // ❌ 당장은 주석/삭제

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ 모바일(iOS/Android)은 google-services 파일만 있으면 옵션 없이 초기화 가능
  await Firebase.initializeApp();
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
