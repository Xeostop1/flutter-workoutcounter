import 'package:flutter/material.dart';
import 'workout_circle.dart';
import 'counter_setup.dart';

class WorkoutCircleContainer extends StatelessWidget { // *** Stateless로 변경 ***
  final int totalSets; // ***
  final int currentSet; // ***
  final int repeatCount; // ***
  final int currentCount; // ***
  final int restSeconds; // ***
  final double progress; // ***
  final VoidCallback onStartPressed; // ***
  final bool isRunning; // ***
  final bool isPaused; // ***
  final bool isResting; // ***
  final Widget setupWidget; // ***

  const WorkoutCircleContainer({ // ***
    super.key,
    required this.totalSets, // ***
    required this.currentSet, // ***
    required this.repeatCount, // ***
    required this.currentCount, // ***
    required this.restSeconds, // ***
    required this.progress, // ***
    required this.onStartPressed, // ***
    required this.isRunning, // ***
    required this.isPaused, // ***
    required this.isResting, // ***
    required this.setupWidget, // ***
  }); // ***

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WorkoutCircle(
              totalSets: totalSets, // ***
              currentSet: currentSet, // ***
              currentCount: currentCount, // ***
              repeatCount: repeatCount, // ***
              restSeconds: restSeconds, // ***
              progress: progress, // ***
              onStartPressed: onStartPressed, // ***
              onStopPressed: null, // *** stop은 외부에서 처리 ***
              isRunning: isRunning, // ***
              isPaused: isPaused, // ***
              isResting: isResting, // ***
              isReady: !isRunning, // ***
              setupWidget: isRunning
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('세트: $currentSet / $totalSets', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('횟수: ${currentCount - 1} / $repeatCount', style: const TextStyle(fontSize: 18)),
                ],
              )
                  : setupWidget, // ***
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 버튼 제거: 외부에서 컨트롤하므로 내부 버튼 없음 ***
      ],
    );
  }
}
