import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/record_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

import '../../models/routine_preset.dart';
import '../../widgets/circular_counter.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/next_routine_chip.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 디버그 출력(짧은 한글)
  void _d(String m) => debugPrint('$m');

  // 하단 디버그 바 표시 여부
  final bool _showDebugBar = true;
  String _lastDoneLog = '';

  // 예시 프리셋 (서비스에선 VM/Repo 사용)
  final List<RoutinePreset> _presets = [
    RoutinePreset(id: 'warmup', name: '웜업', sets: 1, reps: 2),
    RoutinePreset(id: 'squat', name: '스쿼트', sets: 3, reps: 25),
    RoutinePreset(id: 'lunge', name: '런지', sets: 3, reps: 20),
  ];
  int _selected = 0; // 웜업 먼저 선택

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // 라운드(반복/휴식) 한 번 끝날 때마다 호출
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        final vm = context.read<CounterViewModel>();
        final phase = await vm.onTickComplete();

        if (phase == CounterPhase.done) {
          final auth = context.read<AuthViewModel>();
          _d('완료 저장시도 로그인?=${auth.isLoggedIn} id=${vm.routineId}');
          if (auth.isLoggedIn) {
            await context.read<RecordViewModel>().saveWorkout(
              dateTime: DateTime.now(),
              routineId: vm.routineId,
              routineName: vm.routineName,
              sets: vm.totalSets,
              repsPerSet: vm.repsPerSet,
            );
            _d('저장완료 id=${vm.routineId}');
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

    // 첫 진입 시 현재 선택 프리셋을 VM에 적용(아이디 일치 보장)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<CounterViewModel>();
      final p = _presets[_selected];
      await vm.applyRoutine(
        name: p.name,
        sets: p.sets,
        reps: p.reps,
        secPerRep: p.secPerRep,
        restSec: p.restSec,
        routineId: p.id,
      );
      _d('프리셋적용 id=${p.id} 이름=${p.name} ${p.sets}/${p.reps}');
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
    final auth = context.watch<AuthViewModel>();
    final rec = context.watch<RecordViewModel>();

    // 오늘 완료한 routineId 집합
    final DateTime today = DateTime.now();
    final Set<String> doneTodayIds = auth.isLoggedIn
        ? rec.all
              .where(
                (r) =>
                    r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day,
              )
              .map((r) => r.routineId)
              .toSet()
        : <String>{};

    // 한 줄 로그(집합 변경시에만)
    final doneStr = '{${doneTodayIds.join(",")}}';
    if (doneStr != _lastDoneLog) {
      _lastDoneLog = doneStr;
      _d('오늘완료 $doneStr');
    }

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
                      await vm.resetSet();
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
                        await vm.play();
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

            // 프리셋 칩 리스트
            SizedBox(
              height: 118,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final p = _presets[i];
                  final selected = _selected == i;
                  final done = doneTodayIds.contains(p.id);

                  _d('칩 id=${p.id} 선택=$selected 완료=$done');

                  return NextRoutineChip(
                    title: p.name,
                    sets: p.sets,
                    reps: p.reps,
                    selected: selected,
                    done: done,
                    onTap: () async {
                      setState(() => _selected = i);
                      await vm.applyRoutine(
                        name: p.name,
                        sets: p.sets,
                        reps: p.reps,
                        secPerRep: p.secPerRep,
                        restSec: p.restSec,
                        routineId: p.id,
                      );
                      _d('프리셋적용 id=${p.id} 이름=${p.name} ${p.sets}/${p.reps}');
                      if (vm.isPlaying) {
                        _controller.stop();
                        _startRound();
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemCount: _presets.length,
              ),
            ),

            if (_showDebugBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  child: Row(
                    children: [
                      Text('로그인:${auth.isLoggedIn ? "Y" : "N"}  '),
                      const SizedBox(width: 8),
                      Text('선택:${_presets[_selected].id}  '),
                      const SizedBox(width: 8),
                      Expanded(child: Text('오늘완료:${doneStr}')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
