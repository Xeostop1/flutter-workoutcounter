// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/record_repository.dart';
import 'repositories/tts_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/streak_repository.dart';

// 👇 별칭 부여
import 'viewmodels/auth_viewmodel.dart' as authvm;
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart' as rvm;
import 'viewmodels/counter_viewmodel.dart';
import 'viewmodels/streak_viewmodel.dart';

import 'data/categories_seed.dart';
import 'app_router.dart' as app_router;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
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
          StreakViewModel(ctx.read<StreakRepository>())..ensureTodayUpdated(),
        ),

        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        // ✅ 별칭으로 타입 명시
        ChangeNotifierProvider<authvm.AuthViewModel>(
          create: (ctx) => authvm.AuthViewModel(ctx.read<AuthRepository>()),
        ),

        Provider<RecordRepository>(create: (_) => InMemoryRecordRepository()),
        ChangeNotifierProvider(
          create: (ctx) => RecordsViewModel(ctx.read<RecordRepository>()),
        ),

        // ✅ 별칭으로 타입 명시 + bind()
        ChangeNotifierProvider<rvm.RoutinesViewModel>(
          create: (_) => rvm.RoutinesViewModel()..bind(),
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
