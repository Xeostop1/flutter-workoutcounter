import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart';
import '../../models/routine.dart';
import '../../widgets/gradient_circular_counter.dart';

class CounterPage extends StatefulWidget {
  final Routine? routine; // 라우트로 전달받는 선택 루틴
  const CounterPage({super.key, this.routine});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  Routine? _attached;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<CounterViewModel>();
    final incoming = widget.routine;
    if (incoming != null && (_attached == null || _attached!.id != incoming.id)) {
      vm.attachRoutine(incoming);
      _attached = incoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final r = vm.routine ?? widget.routine;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(r?.title ?? '운동'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (r != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
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
                  r.primary.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(height: 16),

            // ===== 중앙 원형 카운터 =====
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GradientCircularCounter(
                      progress: vm.progress, // ✅ 0~1 자동 계산
                      size: 240,
                      thickness: 22,
                    ),

                    // 중앙 숫자: 세트 / 현재 반복수
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 세트 숫자 (변경 시 커지며 등장)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: Tween(begin: 0.85, end: 1.0).animate(
                                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                              ),
                              child: child,
                            );
                          },
                          child: Text(
                            '${vm.setNow}',
                            key: ValueKey<int>(vm.setNow),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 56, fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Set', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),

                        // 현재 반복수 (변경 시 커지며 등장)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: Tween(begin: 0.8, end: 1.0).animate(
                                CurvedAnimation(parent: anim, curve: Curves.easeOut),
                              ),
                              child: child,
                            );
                          },
                          child: Text(
                            '${vm.repNow}',
                            key: ValueKey<int>(vm.repNow),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('회', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== 하단 컨트롤 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CircleIconButton(
                    icon: Icons.replay,
                    onPressed: () => context.read<CounterViewModel>().reset(),
                    bg: cs.surfaceVariant,
                  ),
                  _CircleIconButton(
                    size: 64,
                    icon: vm.isRunning ? Icons.pause : Icons.play_arrow,
                    onPressed: () => context.read<CounterViewModel>().startPause(),
                    bg: Colors.white,
                    fg: Colors.black,
                    elevation: 6,
                  ),
                  _CircleIconButton(
                    icon: Icons.volume_up,
                    onPressed: () => context.read<CounterViewModel>().setTts(!vm.ttsOn),
                    bg: cs.surfaceVariant,
                    fg: vm.ttsOn ? cs.primary : cs.onSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// 재사용: 원형 아이콘 버튼
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? bg;
  final Color? fg;
  final double elevation;
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.bg,
    this.fg,
    this.elevation = 2,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: bg ?? cs.surface,
      shape: const CircleBorder(),
      elevation: elevation,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.42, color: fg ?? cs.onSurface),
        ),
      ),
    );
  }
}
