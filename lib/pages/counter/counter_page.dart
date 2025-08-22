import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../widgets/circular_counter.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 예시 저장 루틴 (실제 앱에서는 ViewModel/Repository에서 읽어와 교체)
  final List<_RoutineConfig> _saved = [
    const _RoutineConfig(name: '스쿼트', sets: 3, reps: 15),
    const _RoutineConfig(name: '데드리프트', sets: 3, reps: 10),
    const _RoutineConfig(name: '스플릿 스쿼트', sets: 4, reps: 20),
  ];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        final vm = context.read<CounterViewModel>();
        final next = await vm.onTickComplete();
        if (next != CounterPhase.done && vm.isPlaying && !vm.isPaused) {
          _startRound();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRound() {
    final vm = context.read<CounterViewModel>();
    _controller.stop();
    _controller.duration = Duration(
      milliseconds: (vm.currentDurationSeconds * 1000).round(),
    );
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    final vm = context.watch<CounterViewModel>();

    // 재생 상태가 되면 라운드 시작
    if (vm.isPlaying &&
        !_controller.isAnimating &&
        !vm.isPaused &&
        vm.phase != CounterPhase.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startRound());
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          vm.routineName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            // 현재 운동 라벨
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6F2EE),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    vm.routineName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 원형 카운터 + 중앙 텍스트 (가독성: 검정 텍스트)
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      double progress;
                      if (vm.isRest) {
                        // 휴식은 0→1로 별도 진행
                        progress = _controller.value;
                      } else {
                        final total = vm.repsPerSet <= 0 ? 1 : vm.repsPerSet;
                        // ✅ 누적: (완료한 개수 + 현재 1회의 진행도) / 총 횟수
                        progress = (vm.currentRep + _controller.value) / total;
                      }
                      return CircularCounter(
                        progress: progress.clamp(0, 1),
                        resting: vm.isRest,
                        size: 220,
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFF222222)),
                          children: [
                            TextSpan(
                              text: '${vm.currentSet}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: '  Set',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFF222222)),
                          children: [
                            TextSpan(
                              text: '${vm.leftReps}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(
                              text: '  회',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 컨트롤 버튼 (리셋 / 플레이 / 음성)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CircleButton(
                    bg: const Color(0xFF3E3E3E),
                    icon: Icons.refresh,
                    iconColor: Colors.white,
                    onTap: () async {
                      await vm.resetSet();
                      _controller.stop();
                      _controller.reset();
                    },
                  ),
                  _CircleButton(
                    bg: Colors.white,
                    icon: vm.isPlaying ? Icons.pause : Icons.play_arrow,
                    iconColor: Colors.deepOrange,
                    onTap: () async {
                      if (vm.isPlaying) {
                        vm.pause();
                        _controller.stop();
                      } else {
                        await vm.play();
                        _startRound();
                      }
                    },
                  ),
                  _CircleButton(
                    bg: const Color(0xFF3E3E3E),
                    icon: vm.voiceOn ? Icons.volume_up : Icons.volume_off,
                    iconColor: Colors.white,
                    onTap: vm.toggleVoice,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // NEXT >>
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.double_arrow, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 저장된 카운터 칩 -> 탭하면 VM에 즉시 반영
            SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final it = _saved[i];
                  final selected = _selected == i;
                  return _NextChip(
                    title: it.name,
                    sub: '${it.sets}세트 · ${it.reps}회',
                    selected: selected,
                    onTap: () async {
                      setState(() => _selected = i);
                      await vm.applyRoutine(
                        name: it.name,
                        sets: it.sets,
                        reps: it.reps,
                        secPerRep: it.secPerRep,
                        restSec: it.restSec,
                      );
                      // 진행 중이었다면 현재 라운드부터 다시
                      if (vm.isPlaying) {
                        _controller.stop();
                        _startRound();
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: _saved.length,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _RoutineConfig {
  final String name;
  final int sets;
  final int reps;
  final double secPerRep;
  final int restSec;
  const _RoutineConfig({
    required this.name,
    required this.sets,
    required this.reps,
    this.secPerRep = 2.0,
    this.restSec = 10,
  });
}

class _CircleButton extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, size: 34, color: iconColor),
        ),
      ),
    );
  }
}

class _NextChip extends StatelessWidget {
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _NextChip({
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : const Color(0xFF5A5A5A);
    final fg = selected ? Colors.black : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 140,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(sub, style: TextStyle(color: fg.withOpacity(0.9))),
              ],
            ),
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Material(
            color: const Color(0xFF8A8A8A),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {}, // 필요 시 삭제 동작 연결
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
