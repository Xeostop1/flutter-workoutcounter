// lib/pages/counter/counter_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../models/exercise.dart';
import '../../data/categories_seed.dart'; // makeDefaultRoutine()
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/gradient_circular_counter.dart';
import '../../widgets/confirm_popup.dart';

/// 라우트: /counter 또는 /counter/:rid
class CounterPage extends StatefulWidget {
  final String? routineId; // 라우터에서 전달받는 routineId (없을 수도 있음)
  const CounterPage({super.key, this.routineId});

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

    // ✅ 우선순위: rid 없으면 '디폴트' 먼저 → 선택/첫 루틴은 백업
    Routine? r;
    if (widget.routineId == null) {
      // "루틴 없이 운동하기" 진입
      r = makeDefaultRoutine();
    } else {
      // 특정 루틴 id로 진입
      r = rvm.getById(widget.routineId!);
      if (r != null) rvm.selectRoutine(r.id); // 선택 동기화(옵션)
    }

    // 혹시 실패 시 백업
    r ??= rvm.selected;
    r ??= rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null;

    // 빌드가 끝난 뒤 안전하게 attach (notifyListeners 안전)
    if (r != null && !_scheduledAttach) {
      _scheduledAttach = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        cvm.attachRoutine(r!);
      });
    }
  }

  /// 뒤로가기 처리:
  /// - 진행 중이면 모달 → 네: 부분 기록 후 홈으로 이동 / 아니요: 머무름
  /// - 진행 중 아니면: 스택 있으면 pop, 없으면 홈 이동
  Future<bool> _handleBack(BuildContext context) async {
    final vm = context.read<CounterViewModel>();

    if (!vm.inProgress) {
      if (Navigator.of(context).canPop()) {
        return true; // 기본 pop
      } else {
        context.go('/'); // go로 들어와 스택이 없을 때
        return false;
      }
    }

    final ok = await showConfirmPopup(
      context,
      title: '운동을 끝낼까요?',
      message: '진행한 운동까지만 기록돼요',
      cancelText: '아니요',
      okText: '네',
    );

    if (ok == true) {
      await vm.finishNowAndRecord();
      if (context.mounted) context.go('/'); // 홈으로
      return false; // 기본 pop 막기
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final rvm = context.watch<RoutinesViewModel>();

    // 빌드 시에도 rid가 없으면 디폴트 우선 적용(깜빡임 최소화)
    final Routine? r = vm.routine
        ?? (widget.routineId == null
            ? makeDefaultRoutine() // ✅ rid 없으면 디폴트 먼저
            : rvm.getById(widget.routineId!))
        ?? rvm.selected
        ?? (rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null);

    // 루틴 데이터가 정말 없을 때
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

              // 중앙: 원형 링 (내부 텍스트는 위젯이 렌더링)
              Expanded(
                child: Center(
                  child: GradientCircularCounter(
                    progress: rest ? 0 : vm.progress,
                    size: 240,
                    thickness: 22,
                    dim: rest, // 휴식이면 회색 단색 모드
                    // 배경/그라데이션 컬러 스펙
                    bgColor: const Color(0xFFF3AE94),
                    gradient1: const Color(0xFFFFDEA9),
                    gradient2: const Color(0xFFFF6E38),
                    gradient3: const Color(0xFFEF7F4C),
                    dimColor: cs.onSurface.withOpacity(0.35),

                    // 링 중앙 텍스트
                    setNumber: vm.setNow,
                    reps: rest ? vm.restLeftSeconds : vm.repNow,
                    setLabel: 'Set',
                    repsLabel: rest ? '초' : '회',
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

          // 현재 타일은 진행 수치, 그 외는 0/n
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
                  )
                ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? Colors.black : Colors.white,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    repsText, // 예: 3/25
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

        // 완료 뱃지(DONE) 오버레이
        if (isDone)
          Positioned(
            left: 8,
            top: -6,
            child: Image.asset(
              'assets/images/stamp_done.png', // 프로젝트 파일명에 맞게 수정
              width: 90,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }
}
