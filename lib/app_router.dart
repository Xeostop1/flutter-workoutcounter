// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';

// Services
import 'services/tts_service.dart';

// Pages
import 'pages/home/home_page.dart';
import 'pages/record/record_page.dart';
import 'pages/routine/routine_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/splash/splash_page.dart';
import 'pages/auth/landing_page.dart';
import 'pages/onboarding/onboarding_intro_page.dart';
import 'pages/onboarding/onboarding_goal_page.dart';
import 'pages/counter/counter_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int idx = 0;

  int _indexFromLocation(String loc) {
    if (loc.startsWith('/record')) return 1;
    if (loc.startsWith('/routine')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0; // /home
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).uri.toString();
    idx = _indexFromLocation(loc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          setState(() => idx = i);
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/record');
              break;
            case 2:
              context.go('/routine');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '운동'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '기록'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '루틴'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

/// ✅ 반드시 이 **함수 이름과 시그니처**로 유지하세요.
GoRouter buildRouter(BuildContext context) {
  final auth = context.read<AuthViewModel>();

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    routes: [
      // 스플래시/랜딩/온보딩
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/landing', builder: (_, __) => const LandingPage()),
      GoRoute(
        path: '/onboarding/intro',
        builder: (_, __) => const OnboardingIntroPage(),
      ),
      GoRoute(
        path: '/onboarding/goal',
        builder: (_, __) => const OnboardingGoalPage(),
      ),

      // 카운터: 탭바 없이 전체 화면 → ShellRoute 바깥
      GoRoute(
        path: '/counter',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CounterViewModel(
            tts: TtsService(),
            // 기본값: 3세트 15회, 휴식 10초
          ),
          child: const CounterPage(),
        ),
      ),

      // 탭 쉘
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/record', builder: (_, __) => const RecordPage()),
          GoRoute(path: '/routine', builder: (_, __) => const RoutinePage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
    redirect: (ctx, state) {
      final a = ctx.read<AuthViewModel>();
      final loc = state.matchedLocation;

      if (loc == '/splash') {
        return a.onboardingSkippedDevice ? '/home' : '/landing';
      }

      const allow = [
        '/landing',
        '/onboarding/intro',
        '/onboarding/goal',
        '/splash',
      ];
      if (!a.onboardingSkippedDevice && !allow.contains(loc)) {
        return '/landing';
      }

      if (a.onboardingSkippedDevice && loc.startsWith('/onboarding')) {
        return '/home';
      }

      return null;
    },
  );
}
