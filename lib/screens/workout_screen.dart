import 'dart:async';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../screens/routine_list_screen.dart';
import '../view_models/workout_viewmodel.dart';
import '../view_models/routine_viewmodel.dart';
import '../widgets/reset_button.dart';
import '../widgets/save_button.dart';
import '../widgets/repeat_count_buttons.dart';
import '../widgets/common_wheel_picker.dart';
import '../widgets/workout_circle.dart';
import '../widgets/saved_routine_tile.dart';
import 'settings_screen.dart';
import '../view_models/tts_viewmodel.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final viewModel = WorkoutViewModel();
  final routineVM = RoutineViewModel(); // *** 뷰모델 재사용 ***
  final TtsViewModel ttsVM = TtsViewModel(); // ★ TTS 뷰모델 인스턴스 추가

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
    final loaded = await routineVM.getRoutines(); // ***
    setState(() {
      _routines = loaded; // ***
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRoutines(); // ✅ 앱 실행 시 루틴 불러오기
    TtsViewModel().printAvailableVoices(); // 디버깅용 호출
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

  void _startExercise() {
    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;
    final totalSteps = totalReps;

    _timer?.cancel();
    // ★★ 운동 시작 안내 음성
    print('[TTS] 운동 시작: 세트 $totalSets, 반복 $totalReps');
    ttsVM.speak("${_currentSet}세트 시작. 1회"); // 예: 1세트 시작. 1회

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _isResting = false;
        _progress = _currentCount / totalSteps;

        if (_currentCount < totalReps) {
          _currentCount++;
          // ★★ 반복 중 음성 안내 (예: "2회")
          ttsVM.speak("$_currentCount회");
        } else {
          if (_currentSet < totalSets) {
            _startRest();
          } else {
            timer.cancel();
            _isRunning = false;
            _progress = 1.0;
            // ★★ 운동 종료 안내
            ttsVM.speak("운동이 끝났습니다");
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
          // ✅ 디버깅용 로그 및 TTS 출력
          print('[TTS] 다음 세트 시작: 세트 $_currentSet');
          ttsVM.speak('세트 $_currentSet 시작합니다.');
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
