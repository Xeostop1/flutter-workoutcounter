import 'dart:async';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../screens/routine_list_screen.dart';
import '../view_models/tts_viewmodel.dart';
import '../view_models/workout_viewmodel.dart';
import '../view_models/routine_viewmodel.dart';
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
  final routineVM = RoutineViewModel();
  final TtsViewModel _ttsViewModel = TtsViewModel();

  Timer? _timer;
  int _currentSet = 1;
  int _currentCount = 1;
  double _progress = 0.0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isResting = false;
  Duration? _restTimeRemaining;

  List<Routine> _routines = []; // *** 루틴 상태 변수 추가 ***


  Future<void> _loadRoutines() async {
    final loaded = await routineVM.getRoutines();
    setState(() {
      _routines = loaded;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRoutines(); // ✅ 앱 실행 시 루틴 불러오기

    _ttsViewModel.saveSettings(
      isFemale: true,
      isOn: true,
    );


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

  void _startExercise() async {
    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;
    final totalSteps = totalReps;

    _timer?.cancel();

    // ✅ TTS + 화면 같이 동기화
    await _ttsViewModel.loadSettings();
    await _ttsViewModel.initTts();
    await _ttsViewModel.speakCountSequence(
      totalReps,
      delayMillis: 1000,
      onCount: (count) {
        setState(() {
          _isResting = false;
          _currentCount = count;
          _progress = count / totalSteps;
        });
      },
    );

    // ✅ TTS 끝나고 다음 세트 or 종료
    if (_currentSet < totalSets) {
      _startRest();
    } else {
      setState(() {
        _isRunning = false;
        _progress = 1.0;
      });
    }
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

    // ✅ 휴식 타이머 시작
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        final secondsLeft = _restTimeRemaining!.inSeconds - 1;

        if (secondsLeft <= 0) {
          timer.cancel();
          _currentSet++;
          _startExercise(); // → 여기에 다시 TTS 포함됨
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

  Future<void> _saveCurrentRoutine(BuildContext context) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("루틴 이름 저장"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "루틴 이름",
              hintText: "예: 하체 루틴",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final routine = Routine(
                    name: name,
                    sets: viewModel.settings.totalSets,
                    reps: viewModel.settings.repeatCount,
                  );
                  await routineVM.saveRoutine(routine); // ***
                  await _loadRoutines(); // *** 저장 후 바로 다시 불러오기
                }
                Navigator.pop(context);
              },
              child: const Text("저장"),
            ),
          ],
        );
      },
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
          // ✅ 저장된 루틴 보기 버튼
          IconButton(
            icon: const Icon(Icons.list_alt), // 리스트 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineListScreen(),
                ),
              ).then((needRefresh) {
                if (needRefresh == true) {
                  _loadRoutines(); // *** 수정 후 루틴 다시 불러오기 ***
                }
              });
            },
          ),
          // ✅ 기존 설정 버튼
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
                  values: List.generate(200, (i) => (i + 1)),
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
                SaveButton(
                  sets: viewModel.settings.totalSets,
                  reps: viewModel.settings.repeatCount,
                  onPressed: () => _saveCurrentRoutine(context), // *** 저장 버튼 연결 ***
                ),

              ],
            ),
            Expanded(
              child: _routines.isEmpty // ***
                  ? const Center(child: Text('저장된 루틴이 없습니다.')) // ***
                  : ListView.builder(
                itemCount: _routines.length, // ***
                itemBuilder: (context, index) {
                  final r = _routines[index]; // ***
                  return SavedRoutineTile(
                    title: r.name,
                    sets: r.sets,
                    reps: r.reps,
                    onTap: () {
                      setState(() {
                        viewModel.updateTotalSet(r.sets);
                        viewModel.updateRepeatCount(r.reps);
                      });
                    },
                  );
                },
              ),
            ),


          ],
        ),
      ),
    );
  }
}
