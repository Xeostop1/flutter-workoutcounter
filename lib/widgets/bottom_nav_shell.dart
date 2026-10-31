import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/records_viewmodel.dart';

const _iconSize = 24.0;
const _homeOff = 'assets/icons/nav_home_off.png';
const _homeOn = 'assets/icons/nav_home_on.png';
const _settingsOff = 'assets/icons/nav_settings_off.png';
const _settingsOn = 'assets/icons/nav_settings_on.png';

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.child});

  final Widget child;

  int _index(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/records')) return 1;
    if (location.startsWith('/routines')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/records');
      case 2:
        context.go('/routines');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RecordsViewModel>();
    return Scaffold(
      body: Column(
        children: [
          if (records.recovering ||
              records.pendingCount > 0 ||
              records.recoveryFailed)
            SafeArea(
              bottom: false,
              child: MaterialBanner(
                content: Text(
                  records.recovering
                      ? '저장 대기 중인 운동 기록을 복구하고 있어요.'
                      : records.pendingCount > 0
                      ? '저장하지 못한 운동 기록 ${records.pendingCount}개가 기기에 보관되어 있어요.'
                      : '운동 기록 복구를 완료하지 못했어요.',
                ),
                actions: [
                  if (records.recovering)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: records.retryPendingRecords,
                      child: const Text('다시 저장하기'),
                    ),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? const Color(0xFFFF6633)
                  : const Color(0xFFBDBDBD),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelPadding: const EdgeInsets.only(bottom: 20),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF686868))),
          ),
          child: NavigationBar(
            height: 80,
            selectedIndex: _index(context),
            onDestinationSelected: (index) => _onTap(context, index),
            indicatorColor: Colors.transparent,
            backgroundColor: const Color(0xFF1E1E1E),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                label: '운동',
                icon: _NavImage(_homeOff),
                selectedIcon: _NavImage(_homeOn),
              ),
              NavigationDestination(
                label: '기록',
                icon: Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFBDBDBD),
                ),
                selectedIcon: Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFFF6633),
                ),
              ),
              NavigationDestination(
                label: '루틴',
                icon: Icon(Icons.assignment_rounded, color: Color(0xFFBDBDBD)),
                selectedIcon: Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFFFF6633),
                ),
              ),
              NavigationDestination(
                label: '설정',
                icon: _NavImage(_settingsOff),
                selectedIcon: _NavImage(_settingsOn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavImage extends StatelessWidget {
  const _NavImage(this.assetPath);

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: _iconSize,
      height: _iconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
