import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../models/exercise.dart';

/// 휴식 전용 화면 (스샷 스타일)
class RestPage extends StatelessWidget {
  const RestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cvm = context.watch<CounterViewModel>();
    final rvm = context.watch<RoutinesViewModel>();

    final routine = cvm.routine ?? rvm.selected;
    final items = routine?.items ?? const <Exercise>[];

    // 안전한 현재 인덱스/아이템 계산
    final idx = items.isEmpty ? 0 : cvm.exerciseIndex.clamp(0, items.length - 1);
    final current = items.isEmpty ? null : items[idx];

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171717),
        elevation: 0,
        title: Text(routine?.title ?? '자유 운동'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {}, // 필요 시 연결
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),

                // 상단 흰 캡슐 (현재 운동명)
                _pill(
                  text: current?.name ?? '휴식',
                  color: Colors.black,
                ),

                const SizedBox(height: 20),

                // 중앙: 회색 도넛 링 + 내부 흰 원 + 큰 숫자(남은 휴식 초)
                Expanded(
                  child: Center(
                    child: _RestRing(seconds: cvm.restLeftSeconds),
                  ),
                ),

                // 하단 컨트롤 버튼 3개 (회색)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _circleBtn(
                        icon: Icons.replay,
                        onTap: () => cvm.reset(),
                        bg: const Color(0xFF4A4A4A),
                        fg: Colors.white70,
                      ),
                      _circleBtn(
                        size: 64,
                        icon: cvm.isRunning ? Icons.pause : Icons.play_arrow,
                        onTap: () => cvm.startPause(),
                        bg: const Color(0xFF6D6D6D),
                        fg: Colors.white,
                        elevation: 6,
                      ),
                      _circleBtn(
                        icon: Icons.volume_up,
                        onTap: () => cvm.setTts(!cvm.ttsOn),
                        bg: const Color(0xFF4A4A4A),
                        fg: Colors.white70,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 70), // 좌하단 카드와 간격 확보
              ],
            ),

            // 좌하단 흰 카드(현재 운동 + 3/20), 주황 글로우
            if (current != null)
              Positioned(
                left: 14,
                bottom: 18,
                child: _miniTile(
                  title: current.name,
                  repsText: '${_doneReps(cvm, idx, current.reps)}/${current.reps}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== 내부 작은 위젯/헬퍼 =====

  // 현재 인덱스 이전: 전부 완료, 이후: 0, 현재: 진행 중인 반복 수
  int _doneReps(CounterViewModel vm, int index, int totalReps) {
    if (vm.routine == null) return 0;
    if (index < vm.exerciseIndex) return totalReps;
    if (index > vm.exerciseIndex) return 0;
    return vm.repNow;
  }

  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
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

  Widget _miniTile({required String title, required String repsText}) {
    const orange = Color(0xFFFF6B35);
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // 주황빛 글로우
          BoxShadow(
            color: orange.withOpacity(0.55),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
        border: Border.all(color: orange.withOpacity(0.9), width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            repsText, // 예: 3/20
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// 회색 도넛 링 + 내부 흰 원 + 큰 숫자(남은 휴식 초)
class _RestRing extends StatelessWidget {
  const _RestRing({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    const double size = 240;
    const double thickness = 22;
    const double inner = size - thickness * 2; // 내부 흰 원 지름

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 회색 도넛 링 (Border로 구현)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: const Color(0xFFD4D4D4), // 링 색상(밝은 회색)
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
          // 큰 초 숫자 (부드러운 전환)
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
