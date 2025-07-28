import 'package:flutter/material.dart';
import 'workout_circle.dart';
import 'counter_setup.dart';

class WorkoutCircleContainer extends StatefulWidget {
  final int totalSets;
  final int currentSet;
  final int repeatCount;
  final int currentCount;
  final int restSeconds; // **** 추가됨 ****
  final double progress;
  final VoidCallback onStartPressed;
  final bool isRunning;
  final bool isPaused;
  final bool isResting;
  final Widget setupWidget;

  const WorkoutCircleContainer({
    super.key,
    required this.totalSets,
    required this.currentSet,
    required this.repeatCount,
    required this.currentCount,
    required this.restSeconds, // **** 추가됨 ****
    required this.progress,
    required this.onStartPressed,
    required this.isRunning,
    required this.isPaused,
    required this.isResting,
    required this.setupWidget,
  });

  @override
  State<WorkoutCircleContainer> createState() => _WorkoutCircleContainerState();
}

class _WorkoutCircleContainerState extends State<WorkoutCircleContainer> {
  late int selectedReps;
  late int selectedSets;

  @override
  void initState() {
    super.initState();
    selectedReps = widget.repeatCount;
    selectedSets = widget.totalSets;
  }

  void updateReps(int? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedReps = newValue;
    });
  }

  void updateSets(int? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedSets = newValue;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WorkoutCircle(
              totalSets: selectedSets, // ***
              currentSet: widget.currentSet, // ***
              currentCount: widget.currentCount, // ***
              repeatCount: selectedReps, // ***
              restSeconds: 0, // 필요 시 조정 ***
              progress: widget.progress, // ***
              onStartPressed: widget.onStartPressed, // ***
              onStopPressed: null, // 외부에서 처리 ***
              isRunning: widget.isRunning, // ***
              isPaused: widget.isPaused, // ***
              isResting: widget.isResting, // ***
              isReady: !widget.isRunning, // ***
              setupWidget: widget.isRunning
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('세트: ${widget.currentSet} / $selectedSets',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('횟수: ${widget.currentCount - 1} / $selectedReps',
                      style: const TextStyle(fontSize: 18)),
                ],
              )
                  : Center(
                // *** 중앙 정렬 ***
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '세트설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CounterSetup(
                      selectedReps: selectedReps,
                      selectedSets: selectedSets,
                      onRepsChanged: updateReps,
                      onSetsChanged: updateSets,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
