import 'package:counter_01/widgets/reset_button.dart';
import 'package:counter_01/widgets/save_button.dart';
import 'package:flutter/material.dart';
import '../view_models//workout_viewmodel.dart'; // ViewModel import
import '../widgets/action_buttons.dart';
import '../widgets/repeat_count_buttons.dart';

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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '선택된 반복 횟수: ${viewModel.settings.repeatCount}회',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            RepeatCountButtons(
              selectedValue: viewModel.settings.repeatCount,
              onChanged: _updateRepeatCount,
            ),
            Row(
              children: [
                ResetButton(
                  onPressed: () {
                    setState(() {
                      viewModel.resetSettings(); // ✅ 상태 리셋 후 UI 갱신 ***
                    });
                  },
                ),
                SaveButton(onPressed: (){
                },),
              ],
            )

          ],
        ),
      ),
    );
  }
}
