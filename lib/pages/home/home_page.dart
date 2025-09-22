// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/routines_viewmodel.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/streak_viewmodel.dart';

import '../../widgets/free_workout_sheet.dart';                // ← 경로 수정
import '../../widgets/home/buddy_header.dart';
import '../../widgets/home/routine_list.dart';
import '../../widgets/home/saved_routines_strip.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 필요한 값만 선택해서 리빌드 최소화
    final day = context.select<StreakViewModel, int>((vm) => vm.day);
    final message = _buddyMessage(context.read<RecordsViewModel>());
    final nickname = (() {
      final n = context.read<AuthViewModel>().user?.name?.trim();
      return (n != null && n.isNotEmpty) ? n : '사용자';
    })();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_sporkle.png',
              height: 22,
              fit: BoxFit.contain,
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BuddyHeader(
            day: day,
            nickname: nickname,
            message: message,
            onTap: () => context.push('/buddy'),
          ),
          const SizedBox(height: 16),

          // 루틴 없이 운동하기
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () async {
                // 자유 운동으로 시작할 것이므로 선택 루틴 해제
                context.read<RoutinesViewModel>().clearSelectedRoutine();
                // 액션시트 → 내부에서 시작하기 누르면 /counter로 이동
                await showFreeWorkoutSheet(context);
              },
              label: const Text('루틴 없이 운동하기'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 저장된 루틴 섹션 헤더 + 즐겨찾기 토글 ──
          _SectionTitle(
            '저장된 루틴',
            trailing: const _FavOnlyToggleButton(),
          ),
          const SizedBox(height: 8),

          // 저장된 루틴 (전역 즐겨찾기 필터 반영)
          RoutineList(
            routines: context.watch<RoutinesViewModel>().filteredItems,
            onPlay: (r) {
              context.read<CounterViewModel>().attachRoutine(r);
              context.go('/counter', extra: r);
            },
          ),
        ],
      ),
    );
  }

  String _buddyMessage(RecordsViewModel rec) {
    final today = DateTime.now();
    final hasToday = rec.hasAnyOn(today);
    return hasToday ? '오늘도 고생했어!' : '아직 너무 어두워 ..';
  }
}

// ──────────────────────────────────────────────────────────────
// 공통 섹션 타이틀 (trailing 지원)
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// 즐겨찾기만 보기 토글 버튼
class _FavOnlyToggleButton extends StatelessWidget {
  const _FavOnlyToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    return IconButton(
      tooltip: vm.favOnly ? '즐겨찾기만 보기 해제' : '즐겨찾기만 보기',
      icon: Icon(vm.favOnly ? Icons.star_rounded : Icons.star_outline_rounded),
      color: vm.favOnly ? const Color(0xFFFF6B35) : Colors.white70,
      onPressed: () => context.read<RoutinesViewModel>().toggleFavOnly(),
    );
  }
}
