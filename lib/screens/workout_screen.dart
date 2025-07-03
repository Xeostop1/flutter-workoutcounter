import 'dart:async';
import 'package:flutter/material.dart';
import '../view_models/workout_viewmodel.dart';
import '../widgets/reset_button.dart';
import '../widgets/save_button.dart';
import '../widgets/repeat_count_buttons.dart';
import '../widgets/common_wheel_picker.dart';
import '../widgets/workout_circle.dart';
import '../widgets/saved_routine_tile.dart';
import 'settings_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final viewModel = WorkoutViewModel();
  Timer? _timer;
  int _currentSet = 1;
  int _currentCount = 1;
  double _progress = 0.0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isResting = false;
  Duration? _restTimeRemaining;

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isResting = false;
      _progress = 0.0;
      _currentSet = 1;
      _currentCount = 1;
    });

    _startExercise();
  }

  void _startExercise() {
    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;
    final totalSteps = totalReps;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _isResting = false;
        _progress = _currentCount / totalSteps;

        if (_currentCount < totalReps) {
          _currentCount++;
        } else {
          if (_currentSet < totalSets) {
            _startRest();
          } else {
            timer.cancel();
            _isRunning = false;
            _progress = 1.0;
          }
        }
      });
    });
  }

  void _startRest() {
    _timer?.cancel();
    _restTimeRemaining = viewModel.settings.breakTime;
    final totalRestSeconds = _restTimeRemaining!.inSeconds;

    setState(() {
      _isResting = true;
      _currentCount = 1;
      _progress = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        final secondsLeft = _restTimeRemaining!.inSeconds - 1;

        if (secondsLeft <= 0) {
          timer.cancel();
          _currentSet++;
          _startExercise();
        } else {
          _restTimeRemaining = Duration(seconds: secondsLeft);
          _progress = 1 - (secondsLeft / totalRestSeconds);
        }
      });
    });
  }

  void _togglePauseResume() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _updateRepeatCount(int newValue) {
    setState(() {
      viewModel.updateRepeatCount(newValue);
    });
  }

  void _updateTotalSet(int newValue) {
    setState(() {
      viewModel.updateTotalSet(newValue);
    });
  }

  void _resetSettings() {
    _timer?.cancel();
    setState(() {
      viewModel.resetSettings();
      _isRunning = false;
      _isPaused = false;
      _isResting = false;
      _progress = 0.0;
      _currentSet = 1;
      _currentCount = 1;
    });
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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
            RepeatCountButtons(
              selectedValue: settings.repeatCount,
              onChanged: _updateRepeatCount,
            ),
            const SizedBox(height: 20),
            WorkoutCircle(
              totalSets: settings.totalSets,
              currentSet: _currentSet,
              repeatCount: settings.repeatCount,
              restSeconds: _restTimeRemaining?.inSeconds ?? settings.breakTime.inSeconds,
              progress: _progress,
              onStartPressed: _isRunning ? _togglePauseResume : _startTimer,
              isRunning: _isRunning,
              isPaused: _isPaused,
              isResting: _isResting,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CommonWheelPicker(
                  values: List.generate(10, (i) => i + 1),
                  selectedValue: settings.totalSets,
                  onChanged: _updateTotalSet,
                  unitLabel: '세트',
                ),
                const SizedBox(width: 10),
                CommonWheelPicker(
                  values: List.generate(20, (i) => (i + 1) * 5),
                  selectedValue: settings.repeatCount,
                  onChanged: _updateRepeatCount,
                  unitLabel: '회',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResetButton(onPressed: _resetSettings),
                const SizedBox(width: 16),
                SaveButton(onPressed: () {}),

              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Text(
                      '저장된 루틴',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SavedRoutineTile(
                    title: '스쿼트',
                    sets: 3,
                    reps: 15,
                    onTap: () {
                      // TODO: 스쿼트 루틴 적용
                      setState(() {
                        viewModel.updateTotalSet(3);
                        viewModel.updateRepeatCount(15);
                      });
                    },
                  ),
                  SavedRoutineTile(
                    title: '데드리프트',
                    sets: 2,
                    reps: 10,
                    onTap: () {
                      setState(() {
                        viewModel.updateTotalSet(2);
                        viewModel.updateRepeatCount(10);
                      });
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
