import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart'; // 파일명에 맞춰주세요 (counter_viewmodel3.dart를 쓰면 그걸로)
import '../../viewmodels/record_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

import '../../models/routine.dart';
import '../../widgets/circular_counter.dart';
import '../../widgets/circle_button.dart';

class CounterPage extends StatefulWidget {
  CounterPage({super.key, required this.routine});
  final Routine routine; // ✅ 외부에서 선택된 루틴을 객체로 받음

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // 라운드(반복/휴식) 한 번 끝날 때마다 호출
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        final vm = context.read<CounterViewModel>();
        final phase = await vm.onTickEnd();

        if (phase == CounterPhase.done) {
          final auth = context.read<AuthViewModel>();
          if (auth.isLoggedIn) {
            await context.read<RecordViewModel>().saveWorkout(
              dateTime: DateTime.now(),
              routineId: vm.routineId,
              routineName: vm.routineName,
              sets: vm.totalSets,
              repsPerSet: vm.repsPerSet,
              durationSec: vm.sessionSeconds,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('기록이 저장되었어요!')));
          }
        } else if (vm.isPlaying && !vm.isPaused) {
          _startRound();
        }
      }
    });

    // ✅ 들어온 루틴을 즉시 반영
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.updateRoutine(widget.routine);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRound() {
    final vm = context.read<CounterViewModel>();

    // 안전 방어: 최소 1초
    final double durSeconds =
        vm.currentDurationSeconds.isFinite && vm.currentDurationSeconds > 0
        ? vm.currentDurationSeconds
        : 1.0;
    final int ms = (durSeconds * 1000).toInt();

    _controller.stop();
    _controller.duration = Duration(milliseconds: ms);
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);

    final vm = context.watch<CounterViewModel>();

    // 재생 상태가 되면 라운드 시작
    final canAnimate =
        vm.isPlaying && !vm.isPaused && vm.phase != CounterPhase.done;
    if (canAnimate && !_controller.isAnimating) {
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

            // 원형 카운터 + 중앙 텍스트 (누적 채움)
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
                        progress = _controller.value; // 휴식 0→1
                      } else {
                        final total = vm.repsPerSet <= 0 ? 1 : vm.repsPerSet;
                        // 누적: (완료한 개수 + 현재 1회의 진행도) / 총 횟수
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
                  CircleButton(
                    bg: const Color(0xFF3E3E3E),
                    icon: Icons.refresh,
                    iconColor: Colors.white,
                    onTap: () async {
                      await vm.resetCurrentSet();
                      _controller.stop();
                      _controller.reset();
                    },
                  ),
                  CircleButton(
                    bg: Colors.white,
                    icon: vm.isPlaying ? Icons.pause : Icons.play_arrow,
                    iconColor: Colors.deepOrange,
                    onTap: () async {
                      if (vm.isPlaying) {
                        vm.pause();
                        _controller.stop();
                      } else {
                        await vm.start();
                        _startRound();
                      }
                    },
                  ),
                  CircleButton(
                    bg: const Color(0xFF3E3E3E),
                    icon: vm.voiceOn ? Icons.volume_up : Icons.volume_off,
                    iconColor: Colors.white,
                    onTap: vm.toggleVoice,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
