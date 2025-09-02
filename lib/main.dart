import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/routine.dart';
import 'data/categories_seed.dart';

import 'repositories/record_repository.dart';
import 'repositories/tts_repository.dart';
import 'repositories/auth_repository.dart';

import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';

// 페이지 임시(빌드만 되게)
import 'pages/home/home_page.dart';
import 'pages/routines/routine_page.dart';
import 'pages/records/record_page.dart';
import 'pages/settings/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seedRoutines = categoriesSeed.expand((c) => c.routines).toList();

    return MultiProvider(
      providers: [
        // Auth
        Provider<AuthRepository>(
          create: (_) => FakeAuthRepository(startSignedIn: true),
        ),

        // Records repo & VM
        Provider<RecordRepository>(create: (_) => InMemoryRecordRepository()),
        ChangeNotifierProvider(
          create: (ctx) => RecordsViewModel(ctx.read<RecordRepository>()),
        ),

        // Routines VM (시드 주입)
        ChangeNotifierProvider(
          create: (_) => RoutinesViewModel()
            ..loadSeed(cats: categoriesSeed, routines: seedRoutines),
        ),

        // TTS
        Provider<TtsRepository>(create: (_) => TtsRepository()),

        // Counter VM
        ChangeNotifierProvider(
          create: (ctx) => CounterViewModel(
            ctx.read<TtsRepository>(),
            ctx.read<RecordsViewModel>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Workout',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomePage(), // 라우터 쓰면 교체
      ),
    );
  }
}
