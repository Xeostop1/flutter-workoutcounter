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

  WorkoutViewModel get viewModel => context.watch<WorkoutViewModel>();

  void _stopWorkout() {
    _timer?.cancel();
    _ttsViewModel.stop();
    viewModel.stopWorkout(); // ViewModel에서 상태 초기화
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
    viewModel.startTimer(
      ttsViewModel: _ttsViewModel,
      onStartRest: _startRest,
      onComplete: () {
        _timer?.cancel();
      },
    );
  }

  void _startRest() {
    _timer?.cancel();
    _restTimeRemaining = viewModel.settings.breakTime;
    final totalRestSeconds = _restTimeRemaining!.inSeconds;

    viewModel.startResting(); // 상태 업데이트

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
      viewModel.updateRepeatCount(newValue);
    }
  }

  void _updateTotalSet(int? newValue) {
    if (newValue != null) {
      viewModel.updateTotalSet(newValue);
    }
  }

  void _resetSettings() {
    final isLoggedIn = true;
    final lastWorkout = {'sets': 3, 'reps': 12};
    viewModel.resetWorkout(isLoggedIn: isLoggedIn, lastWorkout: lastWorkout);
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
              setupWidget: CounterSetup(
                selectedSets: settings.totalSets,
                selectedReps: settings.repeatCount,
                onRepsChanged: _updateRepeatCount,
                onSetsChanged: _updateTotalSet,
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
