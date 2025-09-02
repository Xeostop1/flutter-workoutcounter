import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/auth_repository.dart';
import 'repositories/record_repository.dart';
import 'repositories/tts_repository.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';

import 'data/categories_seed.dart';
import 'app_router.dart' as app_router;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => FakeAuthRepository(startSignedIn: false), // 반드시 false
        ),
        // ✅ 수정: AuthViewModel은 이제 인자 없는 생성자(옵션 플래그만)
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            startSignedIn: false,
            startOnboardingDone: false,
          ),
        ),

        Provider<RecordRepository>(create: (_) => InMemoryRecordRepository()),
        ChangeNotifierProvider(create: (ctx) => RecordsViewModel(ctx.read<RecordRepository>())),

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
