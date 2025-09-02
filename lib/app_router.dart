// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'viewmodels/auth_viewmodel.dart';

// Pages
import 'pages/auth/landing_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/home/home_page.dart';
import 'pages/home/character_room_page.dart';
import 'pages/counter/counter_page.dart';
import 'pages/records/record_page.dart';
import 'pages/routines/routine_page.dart';
import 'pages/routines/routine_detail_page.dart';
import 'pages/settings/settings_page.dart';

GoRouter createRouter(BuildContext context) {
  final auth = context.read<AuthViewModel>(); // redirect 재평가용
  return GoRouter(
    initialLocation: '/landing',
    refreshListenable: auth, // auth 상태 바뀌면 redirect 재평가

    redirect: (ctx, state) {
      final signedIn = auth.signedIn;
      final done = auth.onboardingDone;
      final loc = state.matchedLocation;

      // 스플래시는 항상 통과
      if (loc == '/landing') return null;

      final isAuthFlow =
          loc == '/landing' || loc == '/login' || loc == '/onboarding';

      // 미로그인 → 로그인으로
      if (!signedIn && loc != '/login') return '/login';

      // 로그인 O + 온보딩 미완 → 온보딩으로
      if (signedIn && !done && loc != '/onboarding') return '/onboarding';

      // 로그인 O + 온보딩 완료 상태에서 인증 플로우 접근 → 홈
      if (signedIn && done && isAuthFlow) return '/home';

      return null;
    },

    routes: [
      GoRoute(path: '/landing', builder: (_, __) => const LandingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/buddy', builder: (_, __) => const CharacterRoomPage()),

      ShellRoute(
        builder: (c, s, child) => Scaffold(
          body: child,
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/records', builder: (_, __) => const RecordsPage()),
          GoRoute(
            path: '/routines',
            builder: (_, __) => const RoutinesPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, st) =>
                    RoutineDetailPage(routineId: st.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),

      GoRoute(path: '/counter', builder: (_, __) => const CounterPage()),
      GoRoute(
        path: '/counter/:rid',
        builder: (_, st) => CounterPage(routineId: st.pathParameters['rid']),
      ),
    ],
  );
}
