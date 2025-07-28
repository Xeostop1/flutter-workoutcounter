import 'dart:async';
import 'package:flutter/material.dart';
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


  // *** Stop 상태: 운동은 끝났으나, 현재 세트/회차는 기억됨 ***

  /// 완전 정지: 타이머 종료하고, isRunning=false 로 전환
  void _stopWorkout() {
    _timer?.cancel();           // 타이머만 멈추고
    _ttsViewModel.stop();       // TTS도 멈춥니다
    setState(() {
      _isRunning   = false;     // 실행 중 플래그 해제
      _isPaused    = false;     // 일시정지 해제
      _isResting   = false;     // 휴식 상태 해제
      _currentSet   = 1;        // 진행 세트는 1로
      _currentCount = 1;        // 진행 카운트도 1로
      _progress     = 0.0;      // 원형 진행도 리셋
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
    _loadRoutines(); // ✅ 앱 실행 시 루틴 불러오기

    _ttsViewModel.saveSettings(
      isFemale: true,
      isOn: true,
    );

    _ttsViewModel.loadSettings();    // *** 설정 로드 ***
    _ttsViewModel.initTts();         // *** 음성 속도·언어 셋업 ***

  }



  void _startTimer() {
    print('[WorkoutScreen] ▶️ startTimer 호출 (isRunning=$_isRunning)');
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
  void _startExercise() {
    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isPaused) return;              // *** 일시정지 중이면 아무 것도 안 함 ***

      // TTS 발화
      await _ttsViewModel.speak('$_currentCount'); // 현재 카운트 숫자 말하기

      setState(() {
        _isResting = false;
        // 진행도: (현재 세트-1)*총반복 + 현재 카운트 으로 계산해도 되지만
        // 여기서는 한 세트 내에서만 보여줍니다.
        _progress = _currentCount / totalReps;
      });

      // 다음 카운트/세트 이동
      if (_currentCount < totalReps) {
        _currentCount++;
      } else {
        timer.cancel();
        if (_currentSet < totalSets) {
          _startRest();
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
        // 첫 실행인 경우
        _startExercise();
        _isRunning = true; // ***
        _isPaused = false; // ***
      } else {
        // 실행 중 → 일시정지 또는 재개
        if (_isPaused) {
          _startExercise(); // 재개
        } else {
          _timer?.cancel();
          _ttsViewModel.stop();
        }
        _isPaused = !_isPaused;
      }
    });

    print('[WorkoutScreen] togglePauseResume → isPaused=$_isPaused, isRunning=$_isRunning');
  }






  void _updateRepeatCount(int? newValue) {
    if (newValue != null) {
      setState(() {
        viewModel.updateRepeatCount(newValue);
      });
    }
  }

  void _updateTotalSet(int? newValue) {
    if (newValue != null) {
      setState(() {
        viewModel.updateTotalSet(newValue);
      });
    }
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
          IconButton( // *** 로그인 아이콘 버튼 추가 ***
            icon: const Icon(Icons.login), // 로그인 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(), // *** 로그인 화면으로 이동 ***
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
            // 유저정보 확인용
            // UserInfoWidget(),
            SizedBox(height: 20),
            const SizedBox(height: 20),
            // RepeatCountButtons(
            //   selectedValue: settings.repeatCount,
            //   onChanged: _updateRepeatCount,
            // ),
            const SizedBox(height: 20),
            //원형 그래프
            WorkoutCircleContainer( // ***
              totalSets: settings.totalSets, // ***
              currentSet: _currentSet, // ***
              repeatCount: settings.repeatCount, // ***
              currentCount: _currentCount, // ***
              restSeconds: _restTimeRemaining?.inSeconds ?? settings.breakTime.inSeconds, // ***
              progress: _progress, // ***
              onStartPressed: _isRunning ? _togglePauseResume : _startTimer, // ***
              isRunning: _isRunning, // ***
              isPaused: _isPaused, // ***
              isResting: _isResting, // ***
              setupWidget: CounterSetup( // *** 중앙에 들어갈 세팅 UI
                selectedSets: settings.totalSets,
                selectedReps: settings.repeatCount,
                onRepsChanged: _updateRepeatCount,
                onSetsChanged: _updateTotalSet,
              ),
            ),

            //버튼 3개
            ControlButtons(
              isRunning: _isRunning, // 언더바 있는 실제 상태 변수 넘겨야 함
              isPaused: _isPaused,
              onReset: _resetSettings,
              onStartPause: _togglePauseResume,
              onStop: _stopWorkout,
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
            const BannerAdWidget(),

          ],
        ),
      ),
    );
  }
}