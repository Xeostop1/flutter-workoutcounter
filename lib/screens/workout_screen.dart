import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../view_models/tts_viewmodel.dart';
import '../view_models/workout_viewmodel.dart';
import '../view_models/routine_viewmodel.dart';
import '../widgets/control_buttons.dart';
import '../widgets/workout_circle.dart';
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
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isResting = false;
  int _currentSet = 1;
  int _currentCount = 1;
  double _progress = 0.0;
  Duration? _restTimeRemaining;
  List<Routine> _routines = [];

  void _stopWorkout() {
    _timer?.cancel();
    _ttsViewModel.stop();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isResting = false;
      _currentSet = 1;
      _currentCount = 1;
      _progress = 0.0;
    });
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

  void _startRest(WorkoutViewModel viewModel) {
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

  void _startExercise() {
    final viewModel = context.read<WorkoutViewModel>();
    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isPaused) return;
      await _ttsViewModel.speak('$_currentCount');
      setState(() {
        _isResting = false;
        _progress = _currentCount / totalReps;
      });
      if (_currentCount < totalReps) {
        _currentCount++;
      } else {
        timer.cancel();
        if (_currentSet < totalSets) {
          _startRest(viewModel);
        } else {
          setState(() {
            _isRunning = false;
            _progress = 1.0;
          });
        }
      }
    });
  }

  void _togglePauseResume() {
    setState(() {
      if (!_isRunning) {
        _startExercise();
        _isRunning = true;
        _isPaused = false;
      } else {
        if (_isPaused) {
          _startExercise();
        } else {
          _timer?.cancel();
          _ttsViewModel.stop();
        }
        _isPaused = !_isPaused;
      }
    });
  }

  void _resetSettings() {
    final viewModel = context.read<WorkoutViewModel>();
    viewModel.resetWorkout(
      isLoggedIn: true,
      lastWorkout: {'sets': 3, 'reps': 12},
    );
    setState(() {
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
    final viewModel = context.watch<WorkoutViewModel>();
    final settings = viewModel.settings;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFCF8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "운동",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // 운동명 버튼
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "스쿼트",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          // 수정된 WorkoutCircle
          WorkoutCircle(
            currentSet: _currentSet,
            totalSets: settings.totalSets,
            currentCount: _currentCount,
            totalCount: settings.repeatCount,
            progress: _progress,
          ),
          const SizedBox(height: 50),
          ControlButtons(
            onReset: _resetSettings,
            onPlayPause: _isRunning ? _togglePauseResume : _startTimer,
            onStop: _stopWorkout,
            isRunning: _isRunning,
          ),
        ],
      ),
    );
  }
}
