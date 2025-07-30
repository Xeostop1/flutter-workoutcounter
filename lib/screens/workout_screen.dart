import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../screens/routine_list_screen.dart';
import '../view_models/tts_viewmodel.dart';
import '../view_models/workout_viewmodel.dart';
import '../view_models/routine_viewmodel.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/control_buttons.dart';
import '../widgets/counter_setup.dart';
import '../widgets/reset_button.dart';
import '../widgets/save_button.dart';
import '../widgets/repeat_count_buttons.dart';
import '../widgets/common_wheel_picker.dart';
import '../widgets/stop_button.dart';
import '../widgets/user_info_widget.dart';
import '../widgets/workout_circle.dart';
import '../widgets/saved_routine_tile.dart';
import '../widgets/workout_circle_container.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final routineVM = RoutineViewModel();
  final TtsViewModel _ttsViewModel = TtsViewModel();
  Timer? _timer;
  Duration? _restTimeRemaining;
  List<Routine> _routines = [];

  // *** getter 제거됨 ***

  void _stopWorkout() {
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
    _timer?.cancel();
    _ttsViewModel.stop();
    viewModel.stopWorkout();
  }

  Future<void> _loadRoutines() async {
    final loaded = await routineVM.getRoutines();
    setState(() {
      _routines = loaded;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRoutines();
    _ttsViewModel.saveSettings(isFemale: true, isOn: true);
    _ttsViewModel.loadSettings();
    _ttsViewModel.initTts();
  }

  void _startTimer() {
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
    viewModel.startTimer(
      ttsViewModel: _ttsViewModel,
      onStartRest: _startRest,
      onComplete: () {
        _timer?.cancel();
      },
    );
  }

  void _startRest() {
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
    _timer?.cancel();
    _restTimeRemaining = viewModel.settings.breakTime;
    final totalRestSeconds = _restTimeRemaining!.inSeconds;

    viewModel.startResting();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (viewModel.isPaused) return;

      final secondsLeft = _restTimeRemaining!.inSeconds - 1;

      if (secondsLeft <= 0) {
        timer.cancel();
        viewModel.nextSet();
        _startTimer();
      } else {
        _restTimeRemaining = Duration(seconds: secondsLeft);
        viewModel.updateProgress(1 - (secondsLeft / totalRestSeconds));
      }
    });
  }

  void _togglePauseResume() {
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
    if (!viewModel.isRunning) {
      _startTimer();
    } else {
      if (viewModel.isPaused) {
        _startTimer();
      } else {
        _timer?.cancel();
        _ttsViewModel.stop();
      }
      viewModel.togglePause();
    }
  }

  void _updateRepeatCount(int? newValue) {
    if (newValue != null) {
      final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
      viewModel.updateRepeatCount(newValue);
    }
  }

  void _updateTotalSet(int? newValue) {
    if (newValue != null) {
      final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
      viewModel.updateTotalSet(newValue);
    }
  }

  void _resetSettings() {
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false);

    // 마지막 운동 값 가져오기
    final lastSets = viewModel.lastWorkout?['sets'] ?? 2;       // 없으면 2세트
    final lastReps = viewModel.lastWorkout?['reps'] ?? 10;      // 없으면 10회

    viewModel.resetWorkout(
      isLoggedIn: true,
      lastWorkout: {'sets': lastSets, 'reps': lastReps},
    );

    _timer?.cancel();
    _restTimeRemaining = null;
  }


  Future<void> _saveCurrentRoutine(BuildContext context) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("루틴 이름 저장"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "루틴 이름",
            hintText: "예: 하체 루틴",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final routine = Routine(
                  name: name,
                  sets: viewModel.settings.totalSets,
                  reps: viewModel.settings.repeatCount,
                );
                await routineVM.saveRoutine(routine);
                await _loadRoutines();
              }
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkoutViewModel>(); // *** UI에서는 watch로 구독
    final settings = viewModel.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutineListScreen()),
              ).then((needRefresh) {
                if (needRefresh == true) _loadRoutines();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            WorkoutCircleContainer(
              totalSets: settings.totalSets,
              currentSet: viewModel.currentSet,
              repeatCount: settings.repeatCount,
              currentCount: viewModel.currentCount,
              restSeconds: _restTimeRemaining?.inSeconds ?? settings.breakTime.inSeconds,
              progress: viewModel.progress,
              onStartPressed: viewModel.isRunning ? _togglePauseResume : _startTimer,
              isRunning: viewModel.isRunning,
              isPaused: viewModel.isPaused,
              isResting: viewModel.isResting,
              setupWidget: Consumer<WorkoutViewModel>(
                builder: (context, viewModel, _) {
                  final settings = viewModel.settings;
                  return CounterSetup(
                    selectedSets: settings.totalSets,
                    selectedReps: settings.repeatCount,
                    onRepsChanged: _updateRepeatCount,
                    onSetsChanged: _updateTotalSet,
                  );
                },
              ),
            ),
            ControlButtons(
              isRunning: viewModel.isRunning,
              isPaused: viewModel.isPaused,
              onReset: _resetSettings,
              onStartPause: _togglePauseResume,
              onStop: _stopWorkout,
            ),
            Expanded(
              child: _routines.isEmpty
                  ? const Center(child: Text('저장된 루틴이 없습니다.'))
                  : ListView.builder(
                itemCount: _routines.length,
                itemBuilder: (context, index) {
                  final r = _routines[index];
                  return SavedRoutineTile(
                    title: r.name,
                    sets: r.sets,
                    reps: r.reps,
                    onTap: () {
                      final viewModel = Provider.of<WorkoutViewModel>(context, listen: false); // ***
                      viewModel.updateTotalSet(r.sets);
                      viewModel.updateRepeatCount(r.reps);
                    },
                  );
                },
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
