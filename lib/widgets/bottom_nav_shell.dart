import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ===== 아이콘 경로(필요하면 여기 수정) =====
const _kIconSize = 24.0;
const _homeOff = 'assets/icons/nav_home_off.png';
const _homeOn  = 'assets/icons/nav_home_on.png';
const _recOff  = 'assets/icons/nav_records_off.png';
const _recOn   = 'assets/icons/nav_records_on.png';
const _rtOff   = 'assets/icons/nav_routines_off.png';
const _rtOn    = 'assets/icons/nav_routines_on.png';
const _setOff  = 'assets/icons/nav_settings_off.png';
const _setOn   = 'assets/icons/nav_settings_on.png';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  int _index(BuildContext c) {
    final l = GoRouterState.of(c).uri.toString();
    if (l.startsWith('/records')) return 1;
    if (l.startsWith('/routines')) return 2;
    if (l.startsWith('/settings')) return 3;
    return 0; // /home (기본)
  }

  void _onTap(BuildContext c, int i) {
    switch (i) {
      case 0: c.go('/home'); break;
      case 1: c.go('/records'); break;
      case 2: c.go('/routines'); break;
      case 3: c.go('/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),

        // 인디케이터 캡슐 없애고(스크린샷 느낌),
        // 배경은 테마에서 검정색이라면 생략 가능
        indicatorColor: Colors.transparent,
        backgroundColor: const Color(0xFF5D5D5D),

        destinations: const [
          NavigationDestination(
            label: '운동',
            icon: _NavImg(_homeOff),
            selectedIcon: _NavImg(_homeOn),
          ),
          NavigationDestination(
            label: '기록',
            icon: _NavImg(_recOff),
            selectedIcon: _NavImg(_recOn),
          ),
          NavigationDestination(
            label: '루틴',
            icon: _NavImg(_rtOff),
            selectedIcon: _NavImg(_rtOn),
          ),
          NavigationDestination(
            label: '설정',
            icon: _NavImg(_setOff),
            selectedIcon: _NavImg(_setOn),
          ),
        ],
      ),
    );
  }
}

class _NavImg extends StatelessWidget {
  final String src;
  const _NavImg(this.src);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      src,
      width: _kIconSize,
      height: _kIconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
