
import 'dart:async';
import 'package:counter_01/widgets/reset_button.dart';
import 'package:counter_01/widgets/save_button.dart';
import 'package:flutter/material.dart';
import '../view_models//workout_viewmodel.dart'; // ViewModel import
import '../widgets/repeat_count_buttons.dart';
import '../widgets/common_wheel_picker.dart';
import '../widgets/workout_circle.dart';
import 'settings_screen.dart'; // 상대 경로로 추가



class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final viewModel = WorkoutViewModel();
  Timer? _timer; // *** 타이머 객체
  int _currentSet = 1; // *** 현재 세트
  int _currentCount = 1; // *** 현재 반복 회수
  double _progress = 0.0; // *** 원형 진행률
  bool _isRunning = false; // *** 타이머 실행 여부








  void _startTimer() {
    if (_isRunning) return;

    final totalReps = viewModel.settings.repeatCount;
    final totalSets = viewModel.settings.totalSets;
    final restSeconds = viewModel.settings.breakTime.inSeconds;

    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _currentSet = _currentSet == 0 ? 1 : _currentSet; // 시작 시 1세트부터
      _currentCount = _currentCount == 0 ? 1 : _currentCount;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _progress = _currentCount / totalReps;

        if (_currentCount < totalReps) {
          _currentCount++;
        } else {
          // ✅ 1세트 끝
          if (_currentSet < totalSets) {
            // 타이머 종료
            timer.cancel();
            _isRunning = false;

            // ✅ 휴식 후 다음 세트 시작
            Future.delayed(Duration(seconds: restSeconds), () {
              setState(() {
                _currentSet++;
                _currentCount = 1;
                _progress = 0.0;
              });
              _startTimer(); // 다시 시작
            });
          } else {
            // ✅ 전체 세트 완료
            timer.cancel();
            _isRunning = false;
            _progress = 1.0;
          }
        }
      });
    });
  }






  void _updateRepeatCount(int newValue) {
    setState(() {
      viewModel.updateRepeatCount(newValue);
    });
  }

  void _resetSettings() {
    setState(() {
      viewModel.resetSettings();
    }); // *** 수정됨: setState로 감싸줘야 화면이 갱신됨
  }

  void _updateTotalSet(int newValue) {
    setState(() {
      viewModel.updateTotalSet(newValue);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 화면 닫을 때 타이머 종료
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

            // 버튼 방식 회수 선택
            RepeatCountButtons(
              selectedValue: settings.repeatCount,
              onChanged: _updateRepeatCount,
            ),

            const SizedBox(height: 20),

            // 원형 UI
            WorkoutCircle(
              totalSets: settings.totalSets,
              repeatCount: settings.repeatCount,
              restSeconds: settings.breakTime.inSeconds,
              progress: _progress, // 수정됨
              onStartPressed: _startTimer, // 추가됨
            ),

            const SizedBox(height: 20),

            // 휠피커 2개
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CommonWheelPicker(
                  values: List.generate(10, (i) => i + 1),
                  selectedValue: settings.totalSets,
                  onChanged: _updateTotalSet,
                  unitLabel: '세트',
                ),
                const SizedBox(width: 20),
                CommonWheelPicker(
                  values: List.generate(20, (i) => (i + 1) * 5),
                  selectedValue: settings.repeatCount,
                  onChanged: _updateRepeatCount,
                  unitLabel: '회',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 리셋, 세이브 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResetButton(onPressed: _resetSettings),
                const SizedBox(width: 16),
                SaveButton(
                  onPressed: () {
                    // 저장 기능은 추후 추가 예정
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

