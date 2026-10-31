import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/categories_seed.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../services/tts_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/edit_exercise_sheet.dart';
import '../../widgets/end_workout_dialog.dart';
import '../../widgets/gradient_circular_counter.dart';
import '../../widgets/workout_completed_dialog.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key, this.routineId, this.routine});

  final String? routineId;
  final Routine? routine;

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  static const _background = Color(0xFF1E1E1E);

  bool _didAttachRoutine = false;
  Routine? _fallbackRoutine;

  CounterViewModel? _counterVm;
  VoidCallback? _counterListener;
  int _lastRep = 0;
  int _lastExerciseIndex = -1;
  bool _handlingCompletion = false;

  @override
  void initState() {
    super.initState();
    TtsService.instance.warmUp();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _registerCounterListener(),
    );
  }

  @override
  void dispose() {
    if (_counterVm != null && _counterListener != null) {
      _counterVm!.removeListener(_counterListener!);
    }
    _counterListener = null;
    _counterVm = null;
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAttachRoutine) return;

    final routine = _resolveInitialRoutine(context);
    if (routine == null) return;

    _didAttachRoutine = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CounterViewModel>()
        ..setRestSeconds(context.read<AuthViewModel>().restSeconds)
        ..attachRoutine(routine);
    });
  }

  void _registerCounterListener() {
    if (!mounted) return;

    final vm = context.read<CounterViewModel>();
    _counterVm = vm;
    _lastRep = vm.repNow;
    _lastExerciseIndex = vm.exerciseIndex;

    _counterListener = () async {
      if (!mounted) return;

      if (vm.workoutCompleted || vm.workoutEndedEarly) {
        if (_handlingCompletion) return;
        _handlingCompletion = true;
        await TtsService.instance.stop();
        if (mounted &&
            vm.workoutCompleted &&
            context.read<AuthViewModel>().homeTutorialDone) {
          await showWorkoutCompletedDialog(context);
        }
        if (mounted) context.go('/home');
        return;
      }

      final authVm = context.read<AuthViewModel>();
      final routinesVm = context.read<RoutinesViewModel>();

      final globallyOn = authVm.voiceCountingEnabled;
      final sessionOn = vm.ttsOn;
      final routineOn = vm.routine?.id != null
          ? routinesVm.ttsEnabledOf(vm.routine!.id)
          : true;

      if (!vm.isRunning ||
          vm.isResting ||
          !(globallyOn && sessionOn && routineOn)) {
        await TtsService.instance.stop();
        return;
      }

      if (vm.exerciseIndex != _lastExerciseIndex) {
        _lastExerciseIndex = vm.exerciseIndex;
        _lastRep = vm.repNow;
      }

      if (vm.repNow <= 0 || vm.repNow == _lastRep) return;
      _lastRep = vm.repNow;

      await TtsService.instance.count(
        vm.repNow,
        totalReps: vm.current.reps,
        context: context,
      );
    };

    vm.addListener(_counterListener!);
  }

  Routine? _resolveInitialRoutine(BuildContext context) {
    final rvm = context.read<RoutinesViewModel>();

    if (widget.routine != null) return widget.routine;

    if (widget.routineId == null) {
      return _fallbackRoutine ??= makeDefaultRoutine();
    }

    final byId = rvm.getById(widget.routineId!);
    if (byId != null) {
      rvm.selectRoutine(byId.id);
      return byId;
    }

    return rvm.selected ??
        (rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null);
  }

  Future<bool> _handleBack(BuildContext context) async {
    final vm = context.read<CounterViewModel>();

    if (vm.hasPendingWorkout) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.isSavingWorkout ? '운동 기록을 저장하고 있어요.' : '운동 기록을 다시 저장해주세요.',
          ),
        ),
      );
      return false;
    }

    if (!vm.inProgress) {
      if (Navigator.of(context).canPop()) return true;
      context.go('/home');
      return false;
    }

    final shouldExit = await showEndWorkoutDialog(context);
    if (shouldExit == true) {
      final saved = await vm.finishNowAndRecord();
      if (!context.mounted) return false;
      if (saved && !vm.workoutEndedEarly) context.go('/home');
    }
    return false;
  }

  String _ellipsize10(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final runes = trimmed.runes.toList();
    if (runes.length <= 10) return trimmed;
    return '${String.fromCharCodes(runes.take(10))}...';
  }

  Future<void> _openEditSheet() async {
    final vm = context.read<CounterViewModel>();
    vm.pauseForEdit();

    final updated = await showEditExerciseSheet(context, initial: vm.current);
    if (!mounted || updated == null) return;

    context.read<CounterViewModel>().updateCurrentExercise(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final rvm = context.watch<RoutinesViewModel>();

    final routine =
        vm.routine ??
        widget.routine ??
        (widget.routineId == null
            ? (_fallbackRoutine ??= makeDefaultRoutine())
            : rvm.getById(widget.routineId!)) ??
        rvm.selected ??
        (rvm.allRoutines.isNotEmpty ? rvm.allRoutines.first : null);

    if (routine == null) return _buildNoRoutineView(context);

    final activeMode = vm.inProgress || vm.isResting;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _handleBack(context);
        if (allow && context.mounted && context.canPop()) context.pop();
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: activeMode ? null : _buildAppBar(routine),
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: activeMode ? _buildActiveBody(vm) : _buildReadyBody(vm),
              ),
            ),
            if (vm.hasPendingWorkout)
              _WorkoutSaveOverlay(
                saving: vm.isSavingWorkout,
                onRetry: vm.retryWorkoutSave,
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Routine routine) {
    return AppBar(
      backgroundColor: _background,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        _ellipsize10(routine.title),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      leading: IconButton(
        tooltip: '뒤로',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 23),
        onPressed: () async {
          final allow = await _handleBack(context);
          if (allow && mounted && context.canPop()) context.pop();
        },
      ),
      actions: [
        IconButton(
          tooltip: '운동 설정 수정',
          icon: Image.asset(
            'assets/icons/icon-edit.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          onPressed: _openEditSheet,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildReadyBody(CounterViewModel vm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight < 618
            ? 618.0
            : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 39),
                _exerciseName(vm.current.name),
                const SizedBox(height: 31),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x88FF6B35), blurRadius: 9),
                    ],
                  ),
                  child: GradientCircularCounter(
                    progress: vm.progress,
                    size: 228,
                    thickness: 23,
                    bgColor: const Color(0xFFF3AE94),
                    gradient1: const Color(0xFFFFE1A8),
                    gradient2: const Color(0xFFFFB685),
                    gradient3: const Color(0xFFFF6B35),
                    setNumber: vm.inProgress ? vm.setNow : 0,
                    reps: vm.repNow,
                    setLabel: 'Set',
                    repsLabel: '회',
                  ),
                ),
                const SizedBox(height: 39),
                SizedBox(
                  width: 238,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _assetButton(
                        'assets/images/btn_Initialization.png',
                        60,
                        vm.reset,
                        label: '현재 운동 초기화',
                      ),
                      _assetButton(
                        'assets/images/btn_play.png',
                        70,
                        vm.startPause,
                        label: '운동 시작',
                      ),
                      _assetButton(
                        vm.ttsOn
                            ? 'assets/images/btn_sound-on.png'
                            : 'assets/images/btn_sound-off.png',
                        60,
                        () => vm.setTts(!vm.ttsOn),
                        label: vm.ttsOn ? '음성 끄기' : '음성 켜기',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const ExerciseTray(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBody(CounterViewModel vm) {
    final value = vm.isResting ? vm.restLeftSeconds : vm.setSecondsLeft;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight < 674
            ? 674.0
            : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 195),
                _ActiveRing(value: value),
                const SizedBox(height: 39),
                _assetButton(
                  vm.isRunning
                      ? 'assets/images/btn_pause.png'
                      : 'assets/images/btn_play.png',
                  70,
                  vm.startPause,
                  label: vm.isRunning ? '일시정지' : '계속하기',
                ),
                const Spacer(),
                const ExerciseTray(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoRoutineView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('\uC6B4\uB3D9')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\uB8E8\uD2F4 \uB370\uC774\uD130\uAC00 \uC5C6\uC5B4\uC694. \uBA3C\uC800 \uB8E8\uD2F4\uC744 \uCD94\uAC00\uD574\uC8FC\uC138\uC694.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('\uD648\uC73C\uB85C'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseName(String name) {
    return Container(
      width: 280,
      height: 69,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _ellipsize10(name),
        style: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: Color(0xFF202020),
        ),
      ),
    );
  }

  Widget _assetButton(
    String assetPath,
    double size,
    VoidCallback onTap, {
    required String label,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

class _WorkoutSaveOverlay extends StatelessWidget {
  const _WorkoutSaveOverlay({required this.saving, required this.onRetry});

  final bool saving;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF4B4B4B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saving)
                  const CircularProgressIndicator(color: Color(0xFFFF6633))
                else
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFFFB098),
                    size: 42,
                  ),
                const SizedBox(height: 18),
                Text(
                  saving ? '운동 기록을 저장하고 있어요' : '운동 기록을 저장하지 못했어요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!saving) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '인터넷 연결을 확인하고 다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6633),
                      ),
                      child: const Text('다시 저장하기'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseTray extends StatelessWidget {
  const ExerciseTray({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final items = vm.routine?.items ?? const <Exercise>[];
    final doneList = vm.exerciseDone;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(left: 34, right: 21),
      child: Row(
        children: List.generate(items.length, (index) {
          final exercise = items[index];
          final isCurrent = index == vm.exerciseIndex;
          final isDone = index < doneList.length && doneList[index];
          final repsText = '${exercise.sets}/${exercise.reps}';

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ExerciseTile(
              title: exercise.name,
              repsText: repsText,
              isCurrent: isCurrent && !isDone,
              isDone: isDone,
              onTap: () =>
                  context.read<CounterViewModel>().selectExercise(index),
            ),
          );
        }),
      ),
    );
  }
}

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.title,
    required this.repsText,
    required this.isCurrent,
    required this.isDone,
    required this.onTap,
  });

  final String title;
  final String repsText;
  final bool isCurrent;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);
    const baseBg = Color(0xFF7A7A7A);
    const cardRadius = 11.0;
    const tileWidth = 93.0;
    const tileHeight = 92.0;

    if (isCurrent) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: const [
                  BoxShadow(color: Color(0xAAFF6B35), blurRadius: 6),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(cardRadius),
              child: Container(
                width: tileWidth,
                height: tileHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(
                    color: orange.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      repsText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      color: isDone ? const Color(0xFF3A3A3A) : baseBg,
      borderRadius: BorderRadius.circular(cardRadius),
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: isDone ? 0.2 : 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      repsText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                Image.asset(
                  'assets/images/stamp_done.png',
                  width: 61,
                  semanticLabel: '$title 완료',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveRing extends StatelessWidget {
  const _ActiveRing({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    const size = 228.0;
    const thickness = 23.0;
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
                color: const Color(0xFFC4C4C4),
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
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4D4D4D),
              height: 1.0,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}
