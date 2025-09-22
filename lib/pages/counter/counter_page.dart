// lib/pages/counter/counter_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show ImageFilter;

import '../../models/routine.dart';
import '../../models/exercise.dart';
import '../../data/categories_seed.dart'; // makeDefaultRoutine()
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/gradient_circular_counter.dart';
import '../../widgets/confirm_popup.dart';
import '../../widgets/end_workout_dialog.dart';



/// 라우트: /counter (extra로 Routine 전달 가능) 또는 /counter/:rid
/// - /counter      : context.go('/counter', extra: routine)
/// - /counter/:rid : pathParameters['rid'] 로 루틴 로드
class CounterPage extends StatefulWidget {
  final String? routineId;
  final Routine? routine;
  const CounterPage({super.key, this.routineId, this.routine});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  bool _scheduledAttach = false; // 빌드 중 중복 attach 방지

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final rvm = context.read<RoutinesViewModel>();
    final cvm = context.read<CounterViewModel>();

    // 우선순위: extra → rid → selected/first → default
    Routine? r;
    if (widget.routine != null) {
      r = widget.routine;
    } else if (widget.routineId == null) {
      r = makeDefaultRoutine();
    } else {
      r = rvm.getById(widget.routineId!);
      if (r != null) rvm.selectRoutine(r.id);
    }

    r ??= rvm.selected;
    r ??= rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null;

    if (r != null && !_scheduledAttach) {
      _scheduledAttach = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        cvm.attachRoutine(r!);
      });
    }
  }

  Future<bool> _handleBack(BuildContext context) async {
    final vm = context.read<CounterViewModel>();

    // 운동 중이 아니면 기본 뒤로가기
    if (!vm.inProgress) {
      if (Navigator.of(context).canPop()) return true;
      context.go('/home');            // 홈 루트로
      return false;
    }

    // 운동 중이면 모달 표시
    final ok = await showEndWorkoutDialog(context);

    if (ok == true) {
      await vm.finishNowAndRecord();  // 진행한 만큼 기록
      if (context.mounted) context.go('/home');
      return false;                   // 기본 pop 막기(이미 이동)
    }
    return false;                     // 취소: 머무르기
  }


  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final rvm = context.watch<RoutinesViewModel>();

    // 빌드 시에도 동일 우선순위
    final Routine? r = vm.routine
        ?? widget.routine
        ?? (widget.routineId == null ? makeDefaultRoutine() : rvm.getById(widget.routineId!))
        ?? rvm.selected
        ?? (rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null);

    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('운동')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('루틴 데이터가 없습니다. 루틴을 먼저 추가해 주세요.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('홈으로'),
              ),
            ],
          ),
        ),
      );
    }

    final rest = vm.isResting;
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () => _handleBack(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(r.title),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () async {
              final allow = await _handleBack(context);
              if (allow && context.canPop()) context.pop();
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 상단 Pill (휴식 / 현재 운동명)
              _pill(
                text: rest ? '휴식' : r.primary.name,
                color: rest ? cs.onSurface.withOpacity(0.85) : cs.onSurface,
              ),

              const SizedBox(height: 16),

              // 중앙: 휴식이면 회색 도넛+큰 숫자, 아니면 기존 링
              Expanded(
                child: Center(
                  child: rest
                      ? const _RestRingContainer()
                      : GradientCircularCounter(
                    progress: vm.progress,
                    size: 240,
                    thickness: 22,
                    dim: false,
                    // 배경/그라데이션 컬러 스펙
                    bgColor: const Color(0xFFF3AE94),
                    gradient1: const Color(0xFFFFDEA9),
                    gradient2: const Color(0xFFFF6E38),
                    gradient3: const Color(0xFFEF7F4C),
                    dimColor: cs.onSurface.withOpacity(0.35),

                    // 링 중앙 텍스트
                    setNumber: vm.setNow,
                    reps: vm.repNow,
                    setLabel: 'Set',
                    repsLabel: '회',
                  ),
                ),
              ),

              // 하단 컨트롤 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _circleBtn(
                      icon: Icons.replay,
                      onTap: () => vm.reset(),
                      bg: cs.onSurface.withOpacity(0.25),
                      fg: cs.onSurface.withOpacity(0.7),
                    ),
                    _circleBtn(
                      size: 64,
                      icon: vm.isRunning ? Icons.pause : Icons.play_arrow,
                      onTap: () => vm.startPause(),
                      bg: rest ? cs.onSurface.withOpacity(0.25) : Colors.white,
                      fg: rest ? cs.onSurface.withOpacity(0.8) : Colors.black,
                      elevation: 6,
                    ),
                    _circleBtn(
                      icon: Icons.volume_up,
                      onTap: () => vm.setTts(!vm.ttsOn),
                      bg: cs.onSurface.withOpacity(0.25),
                      fg: cs.onSurface.withOpacity(0.7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 하부 운동 트레이 (가로 스크롤)
              const ExerciseTray(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 공통 작은 위젯들 =====
  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _numberWithUnit({
    required String value,
    required String unit,
    required TextStyle valueStyle,
    required TextStyle unitStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(width: 6),
        Text(unit, style: unitStyle),
      ],
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

// ====== 하부 운동 트레이 & 타일 ======

class ExerciseTray extends StatelessWidget {
  const ExerciseTray({super.key});

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

          final repsText = isCurrent ? '${vm.repNow}/${ex.reps}' : '0/${ex.reps}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ExerciseTile(
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

class ExerciseTile extends StatelessWidget {
  final String title;
  final String repsText;
  final bool isCurrent;
  final bool isDone;
  final VoidCallback onTap;

  const ExerciseTile({
    super.key,
    required this.title,
    required this.repsText,
    required this.isCurrent,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 기본/현재 타일 공통 스타일
    const orange = Color(0xFFFF6B35);
    const baseBg = Color(0xFF6C6C6C);
    const cardRadius = 14.0;

    // 현재 타일: 글로우 + 흰 카드
    if (isCurrent) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 붉은 그라데이션 글로우 (뒤에 깔기)
          Positioned.fill(
            child: Center(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 132,  // 카드보다 살짝 크게
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius + 2),
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      radius: 0.75,
                      colors: [
                        Color(0xFFFF9A5C), // 밝은 주황
                        Color(0xFFFF6B35), // 진한 주황
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 흰색 카드
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            elevation: 6,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(cardRadius),
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: orange.withOpacity(0.9), width: 1.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repsText, // 예: 3 / 20
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 완료 뱃지(필요 시)
          if (isDone)
            Positioned(
              left: 8,
              top: -6,
              child: Image.asset(
                'assets/images/stamp_done.png',
                width: 90,
                fit: BoxFit.contain,
              ),
            ),
        ],
      );
    }

    // 일반 타일(현재 아님): 기존 회색 카드
    return Material(
      color: baseBg,
      borderRadius: BorderRadius.circular(cardRadius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                repsText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ===== 휴식 전용 링 위젯(회색 도넛 + 중앙 큰 숫자) =====

class _RestRingContainer extends StatelessWidget {
  const _RestRingContainer();

  @override
  Widget build(BuildContext context) {
    final secs = context.select<CounterViewModel, int>((v) => v.restLeftSeconds);
    return _RestRing(seconds: secs);
  }
}

class _RestRing extends StatelessWidget {
  const _RestRing({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    const double size = 240;
    const double thickness = 22;
    const double inner = size - thickness * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 회색 도넛 링
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: const Color(0xFFD4D4D4),
                width: thickness,
              ),
            ),
          ),
          // 내부 흰 원
          Container(
            width: inner,
            height: inner,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          // 큰 초 숫자
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              '$seconds',
              key: ValueKey(seconds),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5A5A5A),
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
