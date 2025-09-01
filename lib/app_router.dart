import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'pages/login/login_page.dart';
import 'pages/home/home_page.dart';
import 'pages/home/character_room_page.dart';
import 'pages/counter/counter_page.dart';
import 'pages/records/record_page.dart';
import 'pages/routines/routine_page.dart';
import 'pages/routines/routine_detail_page.dart';
import 'pages/settings/settings_page.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'widgets/bottom_nav_shell.dart';

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (ctx, state) {
      final signedIn = context.read<AuthViewModel>().signedIn;
      final loggingIn = state.matchedLocation == '/login';
      if (!signedIn) return loggingIn ? null : '/login';
      if (signedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/buddy', builder: (_, __) => const CharacterRoomPage()),
      ShellRoute(
        builder: (c, s, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/records', builder: (_, __) => const RecordsPage()),
          GoRoute(
            path: '/routines',
            builder: (_, __) => const RoutinesPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, st) => RoutineDetailPage(routineId: st.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(path: '/counter', builder: (_, __) => const CounterPage()),
    ],
  );
}
