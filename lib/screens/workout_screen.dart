import 'package:counter_01/widgets/reset_button.dart';
import 'package:counter_01/widgets/save_button.dart';
import 'package:flutter/material.dart';
import '../view_models//workout_viewmodel.dart'; // ViewModel import
import '../widgets/action_buttons.dart';
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


  void _increaseRepeatCount() {
    setState(() {
      viewModel.increaseRepeatCount(); // ✅ 로직은 ViewModel에게 맡김
    });
  }
  void _updateRepeatCount(int newValue){
    setState(() {
      viewModel.updateRepeatCount(newValue);
    });
  }

  void _resetSettings() {
    setState(() {
      viewModel.resetSettings();
    }); // *** 수정됨: setState로 감싸줘야 화면이 갱신됨
  }

  void _updateTotalSet(int newValue){
    setState(() {
      viewModel.updateTotalSet(newValue);
    });
  }


  @override
  Widget build(BuildContext context) {
    final settings = viewModel.settings; // 더 짧게 쓰기 위해 변수로

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),

            ),
            const SizedBox(height: 30),

            // ✅ 기존 회수 버튼
            RepeatCountButtons(
              selectedValue: settings.repeatCount,
              onChanged: _updateRepeatCount,
            ),

            WorkoutCircle(
              totalSets: viewModel.settings.totalSets,
              repeatCount: viewModel.settings.repeatCount,
              restSeconds: viewModel.settings.breakTime.inSeconds,
              progress: 0.80, // 예시: 25% 진행됨
            ),

            const SizedBox(height: 20),
            // ✅ 휠피커 두 개
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CommonWheelPicker(
                  values: List.generate(10, (i) => i + 1), // 1~10세트
                  selectedValue: settings.totalSets,
                  onChanged: _updateTotalSet,
                  unitLabel: '세트',
                ),
                const SizedBox(width: 20),
                CommonWheelPicker(
                  values: List.generate(20, (i) => (i + 1) * 5), // 5~100회
                  selectedValue: settings.repeatCount,
                  onChanged: _updateRepeatCount,
                  unitLabel: '회',
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ✅ Reset, Save 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResetButton(onPressed: _resetSettings),
                const SizedBox(width: 16),
                SaveButton(onPressed: () {
                  // 추후 저장 기능 구현
                }),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
