import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';

class RestPage extends StatelessWidget {
  const RestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counterVm = context.watch<CounterViewModel>();
    final routinesVm = context.watch<RoutinesViewModel>();

    final routine = counterVm.routine ?? routinesVm.selected;
    final items = routine?.items ?? const <Exercise>[];
    final current = _currentExercise(items, counterVm.exerciseIndex);

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
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                _pill(text: current?.name ?? '휴식', color: Colors.black),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _RestRing(seconds: counterVm.restLeftSeconds),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _circleBtn(
                        icon: Icons.replay,
                        onTap: counterVm.reset,
                        bg: const Color(0xFF4A4A4A),
                        fg: Colors.white70,
                      ),
                      _circleBtn(
                        size: 64,
                        icon: counterVm.isRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                        onTap: counterVm.startPause,
                        bg: const Color(0xFF6D6D6D),
                        fg: Colors.white,
                        elevation: 6,
                      ),
                      _circleBtn(
                        icon: counterVm.ttsOn
                            ? Icons.volume_up
                            : Icons.volume_off,
                        onTap: () => counterVm.setTts(!counterVm.ttsOn),
                        bg: const Color(0xFF4A4A4A),
                        fg: Colors.white70,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
            if (current != null)
              Positioned(
                left: 14,
                bottom: 18,
                child: _miniTile(
                  title: current.name,
                  repsText:
                      '${_doneReps(counterVm, items, current)}/${current.reps}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Exercise? _currentExercise(List<Exercise> items, int index) {
    if (items.isEmpty) return null;
    final safeIndex = index.clamp(0, items.length - 1).toInt();
    return items[safeIndex];
  }

  int _doneReps(CounterViewModel vm, List<Exercise> items, Exercise current) {
    final index = items.indexWhere((item) => item.id == current.id);
    if (index == -1) return 0;
    if (index < vm.exerciseIndex) return current.reps;
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
            color: Colors.black.withValues(alpha: 0.30),
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
    const orange = Color(0xFFFF784F);
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orange.withValues(alpha: 0.9), width: 1.6),
        boxShadow: [
          BoxShadow(color: orange.withValues(alpha: 0.55), blurRadius: 16),
        ],
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
            repsText,
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

class _RestRing extends StatelessWidget {
  const _RestRing({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    const size = 240.0;
    const thickness = 22.0;
    const inner = size - thickness * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4D4D4),
                width: thickness,
              ),
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
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
