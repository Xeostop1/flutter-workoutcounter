import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/record_screen.dart';
import '../screens/routine_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/workout_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeTabKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeTab',
);
final GlobalKey<NavigatorState> _recordTabKey = GlobalKey<NavigatorState>(
  debugLabel: 'recordTab',
);
final GlobalKey<NavigatorState> _routineTabKey = GlobalKey<NavigatorState>(
  debugLabel: 'routineTab',
);
final GlobalKey<NavigatorState> _settingsTabKey = GlobalKey<NavigatorState>(
  debugLabel: 'settingsTab',
);

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/workout',
      parentNavigatorKey: _rootNavigatorKey, // ← 탭바 숨김
      builder: (context, state) => const WorkoutScreen(),
    ),

    // 탭 구조
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(index),
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '운동'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '기록'),
              BottomNavigationBarItem(
                icon: Icon(Icons.brightness_low),
                label: '루틴',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            ],
          ),
        );
      },
      branches: [
        // 운동 탭
        StatefulShellBranch(
          navigatorKey: _homeTabKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // 기록 탭
        StatefulShellBranch(
          navigatorKey: _recordTabKey,
          routes: [
            GoRoute(
              path: '/record',
              builder: (context, state) => const RecordScreen(),
            ),
          ],
        ),
        // 루틴 탭
        StatefulShellBranch(
          navigatorKey: _routineTabKey,
          routes: [
            GoRoute(
              path: '/routine',
              builder: (context, state) => const RoutineScreen(),
            ),
          ],
        ),
        // 설정 탭
        StatefulShellBranch(
          navigatorKey: _settingsTabKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
