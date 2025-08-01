import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class WorkoutCircle extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final int currentCount;
  final int totalCount;
  final double progress; // 0.0 ~ 1.0

  const WorkoutCircle({
    super.key,
    required this.currentSet,
    required this.totalSets,
    required this.currentCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 113, // **** 외곽 원(226px) 기준 절반 → 113
      lineWidth: 32, // **** Figma Border 값 적용
      percent: progress.clamp(0.0, 1.0),
      animation: true,
      animationDuration: 300,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.orange.withOpacity(0.2),
      progressColor: Colors.orange,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$currentSet / $totalSets Set",
            style: const TextStyle(
              fontSize: 20, // **** 세트 폰트 크기 조정
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6), // **** 여백 늘림
          Text(
            "$currentCount / $totalCount 회",
            style: const TextStyle(
              fontSize: 26, // **** 횟수 강조
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
