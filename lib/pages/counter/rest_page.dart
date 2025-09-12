import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../models/exercise.dart';
import '../../widgets/gradient_circular_counter.dart';

/// 휴식 전용 화면
class RestPage extends StatelessWidget {
  const RestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cvm = context.watch<CounterViewModel>();
    final rvm = context.watch<RoutinesViewModel>();
    final routine = cvm.routine ?? rvm.selected;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(routine?.title ?? '휴식'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {}, // 필요시 연결
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 상단 "휴식" 캡슐
            _pill(text: '휴식', color: Colors.black),

            const SizedBox(height: 24),

            // 중앙 원형 카운터(회색 링 + 흰 배경, 숫자만 큼직하게)
            Expanded(
              child: Center(
                child: GradientCircularCounter(
                  progress: 0, // 휴식 화면은 진행 링 비표시
                  dim: true, // 회색 단색 링
                  size: 240,
                  thickness: 22,
                  bgColor: const Color(0xFFD0D0D0), // 링 배경 회색
                  dimColor: const Color(0xFFBDBDBD), // dim 모드 색
                  centerBackgroundColor: Colors.white, // 내부 흰색
                  // 중앙 텍스트 (숫자만)
                  reps: cvm.restLeftSeconds,
                  repsStyle: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5A5A5A),
                  ),
                  repsLabel: null,
                ),
              ),
            ),

            // 하단 세 개 컨트롤 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _circleBtn(
                    icon: Icons.replay,
                    onTap: () => cvm.reset(), // 휴식/운동 모두 초기화
                    bg: cs.onSurface.withOpacity(0.20),
                    fg: Colors.white70,
                  ),
                  _circleBtn(
                    size: 64,
                    icon: cvm.isRunning ? Icons.pause : Icons.play_arrow,
                    onTap: () => cvm.startPause(),
                    bg: cs.onSurface.withOpacity(0.20),
                    fg: Colors.white,
                    elevation: 4,
                  ),
                  _circleBtn(
                    icon: Icons.volume_up,
                    onTap: () => cvm.setTts(!cvm.ttsOn),
                    bg: cs.onSurface.withOpacity(0.20),
                    fg: Colors.white70,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 하부 운동 트레이 (가로 스크롤)
            const _ExerciseTray(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ===== 재사용 작은 위젯 =====
  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    double size = 56,
    Color? bg,
    Color? fg,
    double elevation = 2,
  }) {
    return Material(
      color: bg ?? Colors.white,
      shape: const CircleBorder(),
      elevation: elevation,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.42, color: fg ?? Colors.black),
        ),
      ),
    );
  }
}

/// 하부 운동 카드 트레이 — 현재/완료 표시
class _ExerciseTray extends StatelessWidget {
  const _ExerciseTray();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final items = vm.routine?.items ?? const <Exercise>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(items.length, (i) {
          final ex = items[i];
          final isCurrent = i == vm.exerciseIndex;
          final isDone = vm.exerciseDone.isNotEmpty && vm.exerciseDone[i];

          final repsText = '${vm.getDoneRepsOf(i)}/${ex.reps}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _ExerciseTile(
              title: ex.name,
              repsText: repsText,
              isCurrent: isCurrent,
              isDone: isDone,
              onTap: () => context.read<CounterViewModel>().selectExercise(i),
            ),
          );
        }),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String title;
  final String repsText;
  final bool isCurrent;
  final bool isDone;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.title,
    required this.repsText,
    required this.isCurrent,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);
    final baseBg = const Color(0xFF6C6C6C);
    final currentBg = Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isCurrent ? currentBg : baseBg,
          borderRadius: BorderRadius.circular(14),
          elevation: isCurrent ? 6 : 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: orange.withOpacity(0.6),
                          blurRadius: 16,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    repsText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 완료 뱃지 오버레이
        if (isDone)
          Positioned(
            left: 8,
            top: -6,
            child: Image.asset(
              'assets/images/stamp_done.png', // 프로젝트 에셋명에 맞게
              width: 90,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }
}
