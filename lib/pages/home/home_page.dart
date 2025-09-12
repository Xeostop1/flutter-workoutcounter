import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/routines_viewmodel.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/streak_viewmodel.dart';

import '../../widgets/home/buddy_header.dart';
import '../../widgets/home/routine_list.dart';

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

    final routines = context.watch<RoutinesViewModel>().allRoutines;

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
              onPressed: () {
                context.read<RoutinesViewModel>().clearSelectedRoutine();
                context.push('/counter');
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

          const _SectionTitle('저장된 루틴'),
          const SizedBox(height: 8),

          // 저장된 루틴 섹션
          RoutineList(
            routines: routines,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
