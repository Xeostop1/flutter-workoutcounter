import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

class _CounterPageState extends State<CounterPage> with WidgetsBindingObserver {
  static const _background = Color(0xFF101114);
  static const _screenAwakeChannel = MethodChannel('sporkle/screen_awake');
  bool? _screenAwake;
  bool _foreground = true;

  bool _didAttachRoutine = false;
  Routine? _fallbackRoutine;

  CounterViewModel? _counterVm;
  VoidCallback? _counterListener;
  int _lastRep = 0;
  int _lastExerciseIndex = -1;
  int _lastSet = -1;
  int _lastRestCount = 0;
  Future<void>? _countSpeech;
  String _lastEncouragedSet = '';
  bool _handlingCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    TtsService.instance.warmUp().catchError((Object error) {
      debugPrint("음성 준비 실패: $error");
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _registerCounterListener(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setScreenAwake(false);
    if (_counterVm != null && _counterListener != null) {
      _counterVm!.removeListener(_counterListener!);
    }
    _counterListener = null;
    _counterVm = null;
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncScreenAwake();
  }

  void _syncScreenAwake() {
    final vm = _counterVm;
    _setScreenAwake(
      _foreground &&
          vm != null &&
          !vm.hasPendingWorkout &&
          (vm.isRunning || vm.isResting || vm.isWaitingForNextSet),
    );
  }

  void _setScreenAwake(bool enabled) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    if (_screenAwake == enabled) return;
    _screenAwake = enabled;
    unawaited(
      _screenAwakeChannel.invokeMethod<void>('setEnabled', enabled).catchError((
        Object error,
      ) {
        debugPrint('화면 켜짐 유지 설정 실패: $error');
        if (mounted && enabled && _screenAwake == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('화면 켜짐 유지에 실패했어요. 운동을 일시정지한 뒤 다시 시작해주세요.'),
            ),
          );
        }
      }),
    );
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
    _syncScreenAwake();
    _lastRep = vm.currentRep;
    _lastExerciseIndex = vm.exerciseIndex;

    _counterListener = () async {
      if (!mounted) return;

      _syncScreenAwake();

      if (vm.workoutCompleted || vm.workoutEndedEarly) {
        if (_handlingCompletion) return;
        _handlingCompletion = true;
        if (!vm.workoutEndedEarly) {
          // Audio callbacks can be lost when iOS interrupts speech.
          // A missing callback must never trap the user on this screen.
          await _countSpeech
              ?.timeout(const Duration(seconds: 2), onTimeout: () {})
              .catchError((Object _) {});
        }
        if (!mounted) return;
        unawaited(TtsService.instance.stop());
        if (mounted &&
            vm.workoutCompleted &&
            context.read<AuthViewModel>().homeTutorialDone) {
          await showWorkoutCompletedDialog(context);
        }
        if (mounted) context.go('/home');
        return;
      }

      if (vm.hasPendingWorkout) return;

      final authVm = context.read<AuthViewModel>();
      final routinesVm = context.read<RoutinesViewModel>();

      final globallyOn = authVm.voiceCountingEnabled;
      final sessionOn = vm.ttsOn;
      final routineOn = vm.routine?.id != null
          ? routinesVm.ttsEnabledOf(vm.routine!.id)
          : true;

      if (!vm.isResting) _lastRestCount = 0;
      if (!(globallyOn && sessionOn && routineOn)) {
        await TtsService.instance.stop();
        return;
      }

      if (vm.exerciseIndex != _lastExerciseIndex || vm.setNow != _lastSet) {
        _lastExerciseIndex = vm.exerciseIndex;
        _lastSet = vm.setNow;
        _lastRep = 0;
      }
      final setFinished = vm.repNow == vm.current.reps && vm.progress == 1;
      if (!vm.isResting && !vm.isRunning && !setFinished) {
        _lastRep = vm.setStarted ? vm.currentRep : 0;
        await TtsService.instance.stop();
        return;
      }
      final restCount = (vm.restSeconds - vm.restLeftSeconds + 1).clamp(
        1,
        vm.restSeconds,
      );
      if (vm.isResting && restCount == _lastRestCount) return;
      final setKey = '${vm.exerciseIndex}:${vm.setNow}';
      final encourage = setFinished && _lastEncouragedSet != setKey;
      final start = vm.currentRep == 1 && _lastRep == 0;
      if (vm.isResting) {
        _lastRestCount = restCount;
      } else if (!encourage && vm.currentRep == _lastRep) {
        return;
      } else if (encourage) {
        _lastEncouragedSet = setKey;
      } else {
        _lastRep = vm.currentRep;
        if (vm.currentRep == 1) _lastEncouragedSet = '';
      }

      try {
        _countSpeech = vm.isResting
            ? TtsService.instance.restCount(restCount, context: context)
            : encourage
            ? TtsService.instance.speak('좋아요, 한 세트 끝!', context: context)
            : TtsService.instance.count(
                vm.currentRep,
                start: start,
                totalReps: vm.current.reps,
                mode: TtsVerbosity.everyRep,
                context: context,
              );
        vm.waitForSpeech(_countSpeech!);
        await _countSpeech;
      } catch (_) {
        if (!mounted) return;
        vm.setTts(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 재생에 실패했어요. 스피커 버튼을 눌러 다시 켜 주세요.')),
        );
      }
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
    if (shouldExit == true && context.mounted) {
      // This action owns navigation; don't delegate it to a speech listener.
      _handlingCompletion = true;
      _countSpeech = null;
      unawaited(TtsService.instance.stop());
      final saved = await vm.finishNowAndRecord();
      if (!context.mounted) return false;
      if (saved) {
        context.go('/home');
      } else {
        // A later successful retry is handled by the completion listener.
        _handlingCompletion = false;
      }
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
    context.watch<AuthViewModel>();
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
        appBar: _buildAppBar(routine),
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
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
        final height = constraints.maxHeight < 700
            ? 700.0
            : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 24),
                _exerciseName(vm.current.name),
                const SizedBox(height: 23),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.transparent, blurRadius: 0),
                    ],
                  ),
                  child: GradientCircularCounter(
                    progress: vm.progress,
                    size: (constraints.maxWidth - 40).clamp(0.0, 280.0),
                    thickness: 30,
                    bgColor: const Color(0xFF30333A),
                    gradient1: const Color(0xFFFFE1A8),
                    gradient2: const Color(0xFFFFB685),
                    gradient3: const Color(0xFFFF784F),
                    setNumber: vm.inProgress ? vm.setNow : 0,
                    reps: vm.repNow,
                    setLabel: 'Set',
                    repsLabel: '회',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 268,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _assetButton(
                        'assets/images/btn_Initialization.png',
                        68,
                        vm.reset,
                        label: '현재 운동 초기화',
                      ),
                      _assetButton(
                        'assets/images/btn_play.png',
                        80,
                        vm.startPause,
                        label: '운동 시작',
                      ),
                      _voiceButton(vm),
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
    final value = vm.isResting ? vm.restLeftSeconds : vm.currentRep;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight < 700
            ? 700.0
            : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 116),
                GradientCircularCounter(
                  progress: vm.isResting
                      ? (vm.restSeconds > 0
                            ? 1 - vm.restLeftSeconds / vm.restSeconds
                            : 1)
                      : vm.progress,
                  size: (constraints.maxWidth - 40).clamp(0.0, 280.0),
                  thickness: 30,
                  gradient1: vm.isResting
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFFE3B8),
                  gradient2: vm.isResting
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFFFFB783),
                  gradient3: vm.isResting
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFFF784F),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vm.isResting
                            ? '휴식'
                            : '${vm.setNow} / ${vm.totalSets} 세트',
                        style: const TextStyle(
                          color: Color(0xFF9B9EA8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF4F4F6),
                          height: 1,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.isResting ? '초 남음' : '/ ${vm.current.reps}회',
                        style: const TextStyle(
                          color: Color(0xFF9B9EA8),
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 268,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 68),
                      _assetButton(
                        vm.isRunning
                            ? 'assets/images/btn_pause.png'
                            : 'assets/images/btn_play.png',
                        80,
                        vm.startPause,
                        label: vm.isRunning ? '일시정지' : '계속하기',
                      ),
                      _voiceButton(vm),
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

  bool _voiceEnabled(CounterViewModel vm) =>
      context.read<AuthViewModel>().voiceCountingEnabled &&
      vm.ttsOn &&
      (vm.routine == null ||
          context.read<RoutinesViewModel>().ttsEnabledOf(vm.routine!.id));

  Widget _voiceButton(CounterViewModel vm) {
    final enabled = _voiceEnabled(vm);
    return _assetButton(
      '',
      68,
      () => _toggleVoice(vm),
      label: enabled ? '음성 끄기' : '음성 켜기',
    );
  }

  Future<void> _toggleVoice(CounterViewModel vm) async {
    if (_voiceEnabled(vm)) {
      vm.setTts(false);
      await TtsService.instance.stop();
      return;
    }
    final auth = context.read<AuthViewModel>();
    final routines = context.read<RoutinesViewModel>();
    try {
      await auth.setVoiceCountingEnabled(true);
      if (!mounted) return;
      final id = vm.routine?.id;
      if (id != null && !routines.ttsEnabledOf(id)) {
        await routines.setRoutineTts(id, true);
      }
      if (!mounted) return;
      vm.setTts(true);
      if (!vm.isRunning) {
        await TtsService.instance.speak('준비됐어요. 함께 시작해요!', context: context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성을 켜지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    }
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
        color: const Color(0xFF1C1E23),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _ellipsize10(name),
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: label == '운동 시작' || label == '계속하기' || label == '일시정지'
                ? const Color(0xFFFF784F)
                : const Color(0xFF272A30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == '일시정지'
                ? Icons.pause_rounded
                : label == '운동 시작' || label == '계속하기'
                ? Icons.play_arrow_rounded
                : label.contains('음성')
                ? (label == '음성 끄기'
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded)
                : Icons.replay_rounded,
            size: size * (label == '운동 시작' || label == '계속하기' ? 0.62 : 0.44),
            color: label.contains('음성') || label.contains('초기')
                ? Colors.white
                : Colors.black,
          ),
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
              color: const Color(0xFF1C1E23),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saving)
                  const CircularProgressIndicator(color: Color(0xFFFF784F))
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
                        backgroundColor: const Color(0xFFFF784F),
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
    const orange = Color(0xFFFF784F);
    const baseBg = Color(0xFF272A30);
    const cardRadius = 18.0;
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
                  BoxShadow(color: Colors.transparent, blurRadius: 0),
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
