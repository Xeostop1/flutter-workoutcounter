import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 온보딩/스킵 상태
import 'viewmodels/auth_viewmodel.dart';

// 기존 탭 페이지
import 'pages/home/home_page.dart';
import 'pages/record/record_page.dart';
import 'pages/routine/routine_page.dart';
import 'pages/settings/settings_page.dart';

// 추가: 스플래시/랜딩/온보딩
import 'pages/splash/splash_page.dart';
import 'pages/auth/landing_page.dart';
import 'pages/onboarding/onboarding_intro_page.dart';
import 'pages/onboarding/onboarding_goal_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int idx = 0;

  // 현재 경로에 따라 탭 인덱스 동기화
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

// ✨ BuildContext를 받도록 변경 (redirect에서 Provider 상태를 씀)
GoRouter buildRouter(BuildContext context) {
  final auth = context.read<AuthViewModel>(); // refreshListenable로도 감지됨

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth, // AuthViewModel 변경 시 redirect 재평가
    routes: [
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

      // 스플래시에서 분기: 디바이스에서 온보딩을 스킵했으면 홈, 아니면 랜딩
      if (loc == '/splash') {
        return a.onboardingSkippedDevice ? '/home' : '/landing';
      }

      // 온보딩 미스킵 상태에서는 온보딩/랜딩만 허용
      const allow = [
        '/landing',
        '/onboarding/intro',
        '/onboarding/goal',
        '/splash',
      ];
      if (!a.onboardingSkippedDevice && !allow.contains(loc)) {
        return '/landing';
      }

      // 온보딩 스킵 이미 한 사용자가 온보딩 경로 접근 시 홈으로
      if (a.onboardingSkippedDevice && loc.startsWith('/onboarding')) {
        return '/home';
      }

      return null;
    },
  );
}
