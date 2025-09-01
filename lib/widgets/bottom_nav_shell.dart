import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  int _index(BuildContext c) {
    final l = GoRouterState.of(c).uri.toString();
    if (l.startsWith('/records')) return 1;
    if (l.startsWith('/routines')) return 2;
    if (l.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/records'); break;
            case 2: context.go('/routines'); break;
            case 3: context.go('/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: '운동'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '기록'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '루틴'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
