import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/records_viewmodel.dart';

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
                  ? const Color(0xFFFF784F)
                  : const Color(0xFFBDBDBD),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelPadding: const EdgeInsets.only(bottom: 4),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF555555))),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: _index(context),
            onDestinationSelected: (index) => _onTap(context, index),
            indicatorColor: Colors.transparent,
            backgroundColor: const Color(0xFF303030),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                label: '운동',
                icon: _NavIcon('home'),
                selectedIcon: _NavIcon('home', selected: true),
              ),
              NavigationDestination(
                label: '기록',
                icon: _NavIcon('records'),
                selectedIcon: _NavIcon('records', selected: true),
              ),
              NavigationDestination(
                label: '루틴',
                icon: _NavIcon('routines'),
                selectedIcon: _NavIcon('routines', selected: true),
              ),
              NavigationDestination(
                label: '설정',
                icon: _NavIcon('settings'),
                selectedIcon: _NavIcon('settings', selected: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.name, {this.selected = false});
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (name == 'home') {
      return Image.asset(
        'assets/icons/nav_home_${selected ? 'on' : 'off'}.png',
        width: 24,
        height: 24,
        excludeFromSemantics: true,
      );
    }
    return Icon(
      switch (name) {
        'records' => CupertinoIcons.calendar,
        'routines' => CupertinoIcons.doc_on_clipboard_fill,
        _ => CupertinoIcons.gear_solid,
      },
      size: 24,
      color: selected ? const Color(0xFFFF784F) : const Color(0xFFBDBDBD),
    );
  }
}
