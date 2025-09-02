import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Pages
import 'pages/auth/landing_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/home/home_page.dart';
import 'pages/counter/counter_page.dart';
import 'pages/records/record_page.dart';
import 'pages/routines/routine_page.dart';
import 'pages/routines/routine_detail_page.dart';
import 'pages/settings/settings_page.dart';

// Data
import 'data/categories_seed.dart';
import 'models/routine.dart';

// Repositories
import 'repositories/record_repository.dart';
import 'repositories/tts_repository.dart';
import 'repositories/auth_repository.dart';

// ViewModels
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart'; // ✅ 추가

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
        // ---- Repos ----
        Provider<AuthRepository>(
          // 테스트 용도: 시작부터 로그인 상태면 true, 로그인 흐름 붙이면 false
          create: (_) => FakeAuthRepository(startSignedIn: true),
        ),
        Provider<RecordRepository>(create: (_) => InMemoryRecordRepository()),
        Provider<TtsRepository>(create: (_) => TtsRepository()),

        // ---- ViewModels ----
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<RecordsViewModel>(
          create: (ctx) => RecordsViewModel(ctx.read<RecordRepository>()),
        ),
        ChangeNotifierProvider<RoutinesViewModel>(
          create: (_) => RoutinesViewModel()
            ..loadSeed(cats: categoriesSeed, routines: seedRoutines),
        ),
        ChangeNotifierProvider<CounterViewModel>(
          create: (ctx) => CounterViewModel(
            ctx.read<TtsRepository>(),
            ctx.read<RecordsViewModel>(),
          ),
        ),
      ],

      // 🔑 Provider가 만들어진 후 AuthViewModel을 읽어 라우터 구성
      child: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          final router = GoRouter(
            initialLocation: '/landing',        // ✅ 첫 화면: 랜딩
            refreshListenable: auth,            // ✅ auth 변경 시 redirect 재평가
            redirect: (context, state) {
              final done = auth.onboardingDone;
              final loc = state.matchedLocation;
              final isOnboardingRoute =
                  loc == '/landing' || loc == '/onboarding';

              // 온보딩 아직이면 어디로 가더라도 온보딩으로
              if (!done && !isOnboardingRoute) return '/onboarding';

              // 온보딩 끝났는데 온보딩 경로로 가면 홈으로
              if (done && isOnboardingRoute) return '/';

              return null;
            },
            routes: [
              GoRoute(path: '/landing', builder: (_, __) => const LandingPage()),
              GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
              GoRoute(path: '/', builder: (_, __) => const HomePage()),
              GoRoute(path: '/counter', builder: (ctx, st) => const CounterPage()),
              GoRoute(
                path: '/counter/:rid',
                builder: (ctx, st) =>
                    CounterPage(routineId: st.pathParameters['rid']),
              ),
              GoRoute(path: '/records', builder: (_, __) => const RecordsPage()),
              GoRoute(path: '/routines', builder: (_, __) => const RoutinesPage()),
              GoRoute(
                path: '/routines/:id',
                builder: (ctx, st) =>
                    RoutineDetailPage(routineId: st.pathParameters['id']!),
              ),
              GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
              GoRoute(path: '/buddy', builder: (_, __) => const Placeholder()),
            ],
          );

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Workout',
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
