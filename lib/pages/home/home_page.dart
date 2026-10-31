import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../viewmodels/streak_viewmodel.dart';
import '../../widgets/free_workout_sheet.dart';
import '../../widgets/home/buddy_header.dart';
import '../../widgets/home/routine_list.dart';

enum _HomeTutorialStep { welcome, freeWorkout, firstWorkoutDone, addRoutine }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LayerLink _freeWorkoutLink = LayerLink();
  final LayerLink _addRoutineLink = LayerLink();

  bool _tutorialInitialized = false;
  bool _showTutorial = false;
  bool _waitingWorkoutResult = false;
  bool _openingFreeWorkoutSheet = false;

  _HomeTutorialStep _tutorialStep = _HomeTutorialStep.welcome;
  int _baselineRecordCount = 0;

  void _syncTutorialState({
    required AuthViewModel auth,
    required int recordCount,
    required bool recordsReady,
    required bool workoutCompleted,
  }) {
    if (!mounted) return;

    if (!auth.signedIn) {
      if (_tutorialInitialized || _showTutorial || _waitingWorkoutResult) {
        setState(() {
          _tutorialInitialized = false;
          _showTutorial = false;
          _waitingWorkoutResult = false;
          _tutorialStep = _HomeTutorialStep.welcome;
          _baselineRecordCount = 0;
        });
      }
      return;
    }

    // 짧은 한국어 주석: 사용자 설정 로딩 전에는 대기
    if (!auth.settingsLoaded || !recordsReady) return;

    if (auth.homeTutorialDone) {
      if (_showTutorial || _waitingWorkoutResult || !_tutorialInitialized) {
        setState(() {
          _tutorialInitialized = true;
          _showTutorial = false;
          _waitingWorkoutResult = false;
        });
      }
      return;
    }

    if (!_tutorialInitialized) {
      // 카운터 화면에서 돌아오면 새 HomePage에서도 완료 안내를 이어간다.
      if (workoutCompleted) {
        setState(() {
          _tutorialInitialized = true;
          _showTutorial = true;
          _waitingWorkoutResult = false;
          _tutorialStep = _HomeTutorialStep.firstWorkoutDone;
          _baselineRecordCount = recordCount;
        });
        return;
      }

      // 짧은 한국어 주석: 기존 사용자(기록 있음)는 튜토리얼 생략
      if (recordCount > 0) {
        _tutorialInitialized = true;
        unawaited(_completeTutorial());
        return;
      }

      setState(() {
        _tutorialInitialized = true;
        _showTutorial = true;
        _tutorialStep = _HomeTutorialStep.welcome;
        _baselineRecordCount = recordCount;
      });
      return;
    }

    if (_waitingWorkoutResult &&
        (workoutCompleted || recordCount > _baselineRecordCount)) {
      setState(() {
        _waitingWorkoutResult = false;
        _showTutorial = true;
        _tutorialStep = _HomeTutorialStep.firstWorkoutDone;
        _baselineRecordCount = recordCount;
      });
    }
  }

  void _goTutorialStep(_HomeTutorialStep step) {
    if (!mounted) return;
    setState(() => _tutorialStep = step);
  }

  Future<void> _completeTutorial({bool openRoutines = false}) async {
    try {
      await context.read<AuthViewModel>().markHomeTutorialDone();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('완료 상태를 저장하지 못했습니다.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () =>
                  unawaited(_completeTutorial(openRoutines: openRoutines)),
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    context.read<CounterViewModel>().consumeWorkoutCompletion();
    setState(() {
      _showTutorial = false;
      _waitingWorkoutResult = false;
    });

    if (openRoutines) {
      context.push('/routines');
    }
  }

  Future<void> _startNormalFreeWorkout() async {
    context.read<RoutinesViewModel>().clearSelectedRoutine();
    await showFreeWorkoutSheet(context);
  }

  Future<void> _startTutorialFreeWorkout() async {
    if (_openingFreeWorkoutSheet) return;

    setState(() {
      _openingFreeWorkoutSheet = true;
      _showTutorial = false;
    });

    context.read<RoutinesViewModel>().clearSelectedRoutine();
    final started = await showFreeWorkoutSheet(context, tutorialMode: true);

    if (!mounted) return;

    setState(() {
      _openingFreeWorkoutSheet = false;
      if (started) {
        _waitingWorkoutResult = true;
      } else {
        _showTutorial = true;
        _tutorialStep = _HomeTutorialStep.freeWorkout;
      }
    });
  }

  // 짧은 한국어 주석: 소셜 이름 10글자 제한
  String _displayName(String? rawName) {
    final name = rawName?.trim() ?? '';
    if (name.isEmpty) return '\uC0AC\uC6A9\uC790';

    final runes = name.runes.toList();
    if (runes.length <= 10) return name;
    return '${String.fromCharCodes(runes.take(10))}...';
  }

  // 짧은 한국어 주석: 불씨 단계 문구(-2 ~ 10)
  String _stageLine(int stage) {
    const lines = <int, String>{
      -2: '\uBD88\uC528\uAC00 \uAC70\uC758 \uAEBC\uC84C\uC5B4\uC694',
      -1: '\uBD88\uC528\uAC00 \uC57D\uD574\uC84C\uC5B4\uC694',
      0: '\uC791\uC740 \uBD88\uC528\uAC00 \uAE68\uC5B4\uB0AC\uC5B4',
      1: '\uC624\uB298\uB3C4 \uCC9C\uCC9C\uD788 \uBC1D\uD600\uC694',
      2: '\uB530\uB73B\uD55C \uBE5B\uC774 \uD37C\uC838\uC694',
      3: '\uC6B4\uB3D9 \uB9AC\uB4EC\uC774 \uC0B4\uC544\uB0AC\uC5B4',
      4: '\uBAB8\uACFC \uB9C8\uC74C\uC774 \uB2EC\uB77C\uC84C\uC5B4',
      5: '\uBD88\uC528\uAC00 \uB2E8\uB2E8\uD574\uC84C\uC5B4\uC694',
      6: '\uAFB8\uC900\uD568\uC774 \uBE5B\uC744 \uB9CC\uB4E4\uC5C8\uC5B4',
      7: '\uC624\uB298\uC758 \uB555\uC774 \uD798\uC774 \uB410\uC5B4',
      8: '\uBE5B\uB098\uB294 \uC2B5\uAD00\uC774 \uC790\uB9AC\uC7A1\uC558\uC5B4',
      9: '\uAC15\uD55C \uBD88\uAF43\uC774 \uD0C0\uC624\uB974\uB294 \uC911',
      10: '\uCD5C\uACE0 \uB2E8\uACC4 \uBD88\uAF43\uC774 \uC644\uC131\uB410\uC5B4',
    };
    return lines[stage] ?? lines[0]!;
  }

  // 짧은 한국어 주석: 하루 1개, 사용자별 고정 랜덤
  String _dailyCheer({required DateTime now, required String uid}) {
    const cheers = <String>[
      '\uC624\uB298 10\uBD84\uB9CC \uC6C0\uC9C1\uC5EC\uBD10\uC694',
      '\uAC00\uBCD1\uAC8C \uBAB8\uBD80\uD130 \uAE68\uC6CC\uBCFC\uAE4C\uC694',
      '\uC9E7\uAC8C\uB77C\uB3C4 \uC2DC\uC791\uC774 \uC911\uC694\uD574\uC694',
      '\uC624\uB298\uB3C4 \uD55C \uC138\uD2B8 \uB3C4\uC804\uD574\uC694',
      '\uC5B4\uC81C\uBCF4\uB2E4 \uD55C \uBC88\uB9CC \uB354 \uD574\uC694',
      '\uC644\uBCBD\uBCF4\uB2E4 \uAFB8\uC900\uD568\uC774 \uC774\uACA8\uC694',
      '\uC9C0\uAE08 \uC2A4\uD2B8\uB808\uCE6D\uBD80\uD130 \uC2DC\uC791\uD574\uC694',
      '\uC791\uC740 \uB555\uC774 \uD070 \uBCC0\uD654\uB97C \uB9CC\uB4E4\uC5B4\uC694',
      '\uC624\uB298\uC758 \uC6B4\uB3D9 \uCCB4\uD06C\uD574\uBCFC\uAE4C\uC694',
      '\uBAB8\uC774 \uAE68\uC5B4\uB098\uB294 \uD558\uB8E8\uB85C \uAC00\uC694',
      '\uB531 5\uBD84\uB9CC \uD22C\uC790\uD574\uBD10\uC694',
      '\uC9C0\uAE08 \uC2DC\uC791\uD558\uBA74 \uC774\uBBF8 \uC131\uACF5\uC774\uC5D0\uC694',
      '\uC624\uB298\uB3C4 \uB098\uB97C \uC704\uD55C \uC2DC\uAC04\uC774\uC5D0\uC694',
      '\uD638\uD761 \uB9DE\uCD94\uACE0 \uCC9C\uCC9C\uD788 \uD574\uBD10\uC694',
      '\uD55C \uBC88 \uB354 \uD558\uBA74 \uB354 \uAC15\uD574\uC838\uC694',
      '\uC624\uB298\uC758 \uB9AC\uB4EC\uC744 \uB9CC\uB4E4\uC5B4\uBD10\uC694',
      '\uAC00\uBCD1\uAC8C \uC6C0\uC9C1\uC774\uBA74 \uCDA9\uBD84\uD574\uC694',
      '\uAFB8\uC900\uD568\uC774 \uACB0\uAD6D \uC2B5\uAD00\uC774 \uB3FC\uC694',
      '\uC9C0\uAE08 \uD55C \uB3D9\uC791\uBD80\uD130 \uC2DC\uC791\uD574\uC694',
      '\uC624\uB298\uB3C4 \uBAB8\uC5D0\uAC8C \uC778\uC0AC\uD574\uC694',
      '\uC9E7\uC544\uB3C4 \uC88B\uC740 \uC6B4\uB3D9\uC774 \uB3FC\uC694',
      '\uC624\uB298\uC758 \uD55C \uAC78\uC74C\uC744 \uB0A8\uACA8\uBD10\uC694',
      '\uD3EC\uAE30 \uB9D0\uACE0 \uAC00\uBCD1\uAC8C \uC774\uC5B4\uAC00\uC694',
      '\uC791\uC740 \uBC18\uBCF5\uC774 \uBCC0\uD654\uB97C \uB9CC\uB4E4\uC5B4\uC694',
      '\uC624\uB298\uC758 \uC5D0\uB108\uC9C0\uB97C \uCC44\uC6CC\uBD10\uC694',
      '\uC870\uAE08\uB9CC \uC6C0\uC9C1\uC5EC\uB3C4 \uB2EC\uB77C\uC838\uC694',
      '\uC9C0\uAE08 \uC2DC\uC791\uD558\uBA74 \uB0B4\uC77C\uC774 \uC26C\uC6CC\uC694',
      '\uD558\uB098\uC529 \uD574\uB0B4\uBA74 \uCDA9\uBD84\uD574\uC694',
      '\uC624\uB298\uB3C4 \uADFC\uC721\uC744 \uAE68\uC6CC\uBCFC\uAE4C\uC694',
      '\uB098\uB97C \uC704\uD55C 15\uBD84 \uCC59\uACA8\uBD10\uC694',
      '\uC624\uB298\uC758 \uBAA9\uD45C\uB97C \uBC14\uB85C \uC2E4\uD589\uD574\uC694',
      '\uD55C \uB3D9\uC791 \uB354, \uC790\uC2E0\uAC10\uB3C4 \uB354',
      '\uC9C0\uAE08\uC758 \uB555\uC774 \uB0B4\uC77C\uC744 \uBC14\uAFD4\uC694',
      '\uC624\uB298\uC740 \uAC00\uBCD1\uAC8C \uB05D\uAE4C\uC9C0 \uAC00\uC694',
      '\uC9C0\uAE08 \uB9AC\uB4EC \uD0C0\uACE0 \uC2DC\uC791\uD574\uBD10\uC694',
      '\uBAB8\uC774 \uC6D0\uD560 \uB54C \uBC14\uB85C \uC6C0\uC9C1\uC5EC\uC694',
      '\uC624\uB298\uB3C4 \uC131\uC2E4\uD568\uC774 \uC313\uC774\uB294 \uB0A0',
      '\uC9E7\uAC8C \uD574\uB3C4 \uD655\uC2E4\uD788 \uB0A8\uC544\uC694',
      '\uC624\uB298\uC758 \uC6B4\uB3D9 \uB3C4\uC7A5 \uCC0D\uC5B4\uBD10\uC694',
      '\uACC4\uC18D\uD558\uBA74 \uC9C4\uC9DC \uC2B5\uAD00\uC774 \uB3FC\uC694',
    ];

    final daySerial =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final uidHash = uid.runes.fold<int>(0, (sum, code) => sum + code);
    final index = (daySerial + uidHash) % cheers.length;
    return cheers[index];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final recordCount = context.select<RecordsViewModel, int>(
      (vm) => vm.totalCount,
    );
    final recordsReady = context.select<RecordsViewModel, bool>(
      (vm) => !vm.isLoading && vm.loadError == null,
    );
    final workoutCompleted = context.select<CounterViewModel, bool>(
      (vm) => vm.workoutCompleted,
    );
    final weeklyWorkoutCount = context.select<RecordsViewModel, int>(
      (vm) => vm.workoutsThisWeek(),
    );
    final showGoalAchievement =
        workoutCompleted && weeklyWorkoutCount == (auth.weeklyTarget ?? 3);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTutorialState(
        auth: auth,
        recordCount: recordCount,
        recordsReady: recordsReady,
        workoutCompleted: workoutCompleted,
      );
      if (auth.homeTutorialDone && workoutCompleted && !showGoalAchievement) {
        context.read<CounterViewModel>().consumeWorkoutCompletion();
      }
    });

    final day = context.select<StreakViewModel, int>((vm) => vm.day);
    final flameStage = context.select<StreakViewModel, int>(
      (vm) => vm.flameStage,
    );
    final uid = auth.user?.uid ?? 'guest';
    final message =
        '${_stageLine(flameStage)}\n${_dailyCheer(now: DateTime.now(), uid: uid)}';
    final nickname = _displayName(auth.user?.name);
    final routinesVm = context.watch<RoutinesViewModel>();
    final routines = routinesVm.items;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/logo_sporkle.png',
          width: 88,
          height: 18,
          fit: BoxFit.contain,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 19, 16, 24),
            children: [
              BuddyHeader(
                day: day,
                flameStage: flameStage,
                nickname: nickname,
                message: message,
                onTap: () => context.push('/buddy'),
              ),
              const SizedBox(height: 32),
              _freeWorkoutButton(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _SectionTitle('\uC800\uC7A5\uB41C \uB8E8\uD2F4'),
              ),
              const SizedBox(height: 13),
              if (routinesVm.loadError != null)
                _HomeRoutineLoadError(onRetry: routinesVm.retryLoad)
              else if (routinesVm.isLoading && routines.isEmpty)
                const SizedBox(
                  height: 184,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                RoutineList(
                  routines: routines,
                  emptyTargetLink: _addRoutineLink,
                  onPlay: (routine) {
                    context.read<CounterViewModel>().attachRoutine(routine);
                    context.go('/counter', extra: routine);
                  },
                ),
            ],
          ),
          if (_showTutorial)
            _HomeTutorialOverlay(
              step: _tutorialStep,
              freeWorkoutLink: _freeWorkoutLink,
              addRoutineLink: _addRoutineLink,
              onBackgroundTap: () {
                switch (_tutorialStep) {
                  case _HomeTutorialStep.welcome:
                    _goTutorialStep(_HomeTutorialStep.freeWorkout);
                    break;
                  case _HomeTutorialStep.firstWorkoutDone:
                    _goTutorialStep(_HomeTutorialStep.addRoutine);
                    break;
                  case _HomeTutorialStep.freeWorkout:
                  case _HomeTutorialStep.addRoutine:
                    break;
                }
              },
              onSkip: _completeTutorial,
              onTapFreeWorkout: _startTutorialFreeWorkout,
              onTapAddRoutine: () => _completeTutorial(openRoutines: true),
            ),
          if (showGoalAchievement && auth.homeTutorialDone)
            _GoalAchievementOverlay(
              onDismiss: () =>
                  context.read<CounterViewModel>().consumeWorkoutCompletion(),
            ),
        ],
      ),
    );
  }

  Widget _freeWorkoutButton() {
    return CompositedTransformTarget(
      link: _freeWorkoutLink,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: FilledButton(
          onPressed: () {
            if (_showTutorial &&
                _tutorialStep == _HomeTutorialStep.freeWorkout) {
              _startTutorialFreeWorkout();
              return;
            }
            _startNormalFreeWorkout();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6633),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '루틴 없이 운동하기',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeRoutineLoadError extends StatelessWidget {
  const _HomeRoutineLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('루틴을 불러오지 못했어요.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _GoalAchievementOverlay extends StatelessWidget {
  const _GoalAchievementOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        button: true,
        label: '목표 달성 확인',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
              ),
              const Positioned(
                left: 0,
                right: 0,
                top: 350,
                child: Text(
                  '목표 달성!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                  ),
                ),
              ),
              Positioned(
                left: -48,
                bottom: -185,
                child: Image.asset(
                  'assets/images/firedefalut.png',
                  width: 470,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _HomeTutorialOverlay extends StatelessWidget {
  const _HomeTutorialOverlay({
    required this.step,
    required this.freeWorkoutLink,
    required this.addRoutineLink,
    required this.onBackgroundTap,
    required this.onSkip,
    required this.onTapFreeWorkout,
    required this.onTapAddRoutine,
  });

  final _HomeTutorialStep step;
  final LayerLink freeWorkoutLink;
  final LayerLink addRoutineLink;
  final VoidCallback onBackgroundTap;
  final Future<void> Function({bool openRoutines}) onSkip;
  final VoidCallback onTapFreeWorkout;
  final VoidCallback onTapAddRoutine;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBackgroundTap,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.66)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => onSkip(openRoutines: false),
                child: const Text(
                  '\uAC74\uB108\uB6F0\uAE30',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          ..._buildStepWidgets(context, width),
        ],
      ),
    );
  }

  List<Widget> _buildStepWidgets(BuildContext context, double width) {
    switch (step) {
      case _HomeTutorialStep.welcome:
        return const [
          Positioned(
            left: 0,
            right: 0,
            bottom: 230,
            child: Center(
              child: _TutorialBubble(
                text:
                    '\uBC18\uAC00\uC6CC\uC694!\n\uC9C0\uAE08\uBD80\uD130 \uAC19\uC774 \uBD88\uC528\uB97C \uD0A4\uC6CC\uBD10\uC694',
              ),
            ),
          ),
          Positioned(
            right: -36,
            bottom: -66,
            child: _TutorialMascot(size: 250),
          ),
        ];
      case _HomeTutorialStep.freeWorkout:
        return [
          CompositedTransformFollower(
            link: freeWorkoutLink,
            showWhenUnlinked: false,
            child: SizedBox(
              width: width - 32,
              height: 88,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    child: GestureDetector(
                      onTap: onTapFreeWorkout,
                      child: Container(
                        width: width - 32,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FF6B35),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          '\uB8E8\uD2F4 \uC5C6\uC774 \uC6B4\uB3D9\uD558\uAE30',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(right: 14, top: 40, child: _TapHandIcon()),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 230,
            child: Center(
              child: _TutorialBubble(
                text:
                    '\uB8E8\uD2F4 \uC5C6\uC774 \uC6B4\uB3D9\uD558\uAE30\uB97C \uB204\uB974\uBA74,\n\uC790\uC720\uB86D\uAC8C \uC6B4\uB3D9\uC744 \uC2DC\uC791\uD560 \uC218 \uC788\uC5B4\uC694',
              ),
            ),
          ),
          const Positioned(
            right: -36,
            bottom: -66,
            child: _TutorialMascot(size: 250),
          ),
        ];
      case _HomeTutorialStep.firstWorkoutDone:
        return const [
          Positioned(
            left: 0,
            right: 0,
            bottom: 260,
            child: Center(
              child: _TutorialBubble(
                text:
                    '\uCCAB \uC6B4\uB3D9 \uC644\uB8CC!\n\uBD88\uC528\uAC00 \uD55C \uB2E8\uACC4 \uC131\uC7A5\uD588\uC5B4\uC694',
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -70,
            child: Center(child: _TutorialMascot(size: 280)),
          ),
        ];
      case _HomeTutorialStep.addRoutine:
        return [
          CompositedTransformFollower(
            link: addRoutineLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.center,
            followerAnchor: Alignment.center,
            child: GestureDetector(
              onTap: onTapAddRoutine,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEFEFEF),
                    width: 1.3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88FFFFFF),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          CompositedTransformFollower(
            link: addRoutineLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: Offset(0, -34),
            child: const _TutorialBubble(
              text:
                  '\uB8E8\uD2F4\uC744 \uB4F1\uB85D\uD558\uACE0\n\uB354 \uD3B8\uD558\uAC8C \uC6B4\uB3D9\uC744 \uAD00\uB9AC\uD574\uBCF4\uC138\uC694',
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -58,
            child: Center(child: _TutorialMascot(size: 240)),
          ),
        ];
    }
  }
}

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF373737),
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(width: 12, height: 12, color: Colors.white),
        ),
      ],
    );
  }
}

class _TutorialMascot extends StatelessWidget {
  const _TutorialMascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Image.asset(
        'assets/images/charactor_login.png',
        width: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _TapHandIcon extends StatelessWidget {
  const _TapHandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.touch_app_rounded,
        color: Color(0xFF2E2E2E),
        size: 22,
      ),
    );
  }
}
