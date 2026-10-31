import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/routine.dart';
import 'pages/auth/landing_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/counter/counter_page.dart';
import 'pages/home/character_room_page.dart';
import 'pages/home/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/records/record_page.dart';
import 'pages/routines/routine_create_page.dart';
import 'pages/routines/routine_detail_page.dart';
import 'pages/routines/routine_edit_page.dart';
import 'pages/routines/routine_page.dart';
import 'pages/settings/credits_page.dart';
import 'pages/settings/legal_page.dart';
import 'pages/settings/settings_page.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'widgets/bottom_nav_shell.dart';

GoRouter createRouter(BuildContext context) {
  final auth = context.read<AuthViewModel>();

  return GoRouter(
    initialLocation: '/landing',
    refreshListenable: auth,
    redirect: (_, state) => redirectForAuth(
      authReady: auth.authReady,
      signedIn: auth.signedIn,
      onboardingDone: auth.onboardingDone,
      location: state.matchedLocation,
    ),
    routes: [
      // 인증 흐름
      GoRoute(path: '/landing', builder: (_, __) => const LandingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/buddy', builder: (_, __) => const CharacterRoomPage()),

      // 하단 탭이 있는 화면들
      ShellRoute(
        builder: (_, __, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/records', builder: (_, __) => const RecordsPage()),
          GoRoute(path: '/routines', builder: (_, __) => const RoutinePage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),

      GoRoute(
        path: '/routines/create',
        builder: (_, __) => const RoutineCreatePage(),
      ),
      GoRoute(
        path: '/routines/edit/:id',
        builder: (_, st) =>
            RoutineEditPage(routineId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/routines/:id',
        builder: (_, st) =>
            RoutineDetailPage(routineId: st.pathParameters['id']!),
      ),

      // 카운터는 하단 탭 밖에서 표시
      GoRoute(
        path: '/counter',
        builder: (_, state) {
          final routine = state.extra is Routine
              ? state.extra as Routine
              : null;
          return CounterPage(routine: routine);
        },
      ),
      GoRoute(
        path: '/counter/:rid',
        builder: (_, st) => CounterPage(routineId: st.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, __) => const LegalPage(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (_, __) => const LegalPage(document: LegalDocument.terms),
      ),
      GoRoute(
        path: '/settings/credits',
        builder: (_, __) => const CreditsPage(),
      ),
    ],
  );
}

String? redirectForAuth({
  required bool authReady,
  required bool signedIn,
  required bool onboardingDone,
  required String location,
}) {
  final isLanding = location == '/landing';
  final isLogin = location == '/login';
  final isOnboarding = location == '/onboarding';
  final isAuthFlow = isLanding || isLogin || isOnboarding;
  final isPublicLegal = location.startsWith('/legal/');

  if (isPublicLegal) return null;
  if (!authReady) return isLanding ? null : '/landing';
  if (isLanding) return null;
  if (!signedIn && !isLogin) return '/login';
  if (signedIn && !onboardingDone && !isOnboarding) return '/onboarding';
  if (signedIn && onboardingDone && isAuthFlow) return '/home';
  return null;
}
