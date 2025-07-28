import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';


class WorkoutCircle extends StatelessWidget {
  final int totalSets;
  final int currentSet;
  final int currentCount;
  final int repeatCount;
  final int restSeconds;
  final double progress;
  final VoidCallback? onStartPressed;
  final VoidCallback? onStopPressed;
  final bool isRunning;
  final bool isPaused;
  final bool isResting;
  final bool isReady;
  final Widget? setupWidget;

  const WorkoutCircle({
    super.key,
    required this.totalSets,
    required this.currentSet,
    required this.currentCount,
    required this.repeatCount,
    required this.restSeconds,
    required this.progress,
    this.onStartPressed,
    this.onStopPressed,
    required this.isRunning,
    required this.isPaused,
    required this.isResting,
    required this.isReady,
    this.setupWidget,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      builder: (context, animatedProgress, child) {
        final angle = 2 * pi * animatedProgress - pi / 2;
        final radius = 150.0;
        final flameX = radius + radius * cos(angle);
        final flameY = radius + radius * sin(angle);

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: radius * 2,
                  height: radius * 2,
                  child: CircularPercentIndicator(
                    radius: radius,
                    lineWidth: 20.0,
                    percent: animatedProgress,
                    animation: false,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: Colors.grey.shade200,
                    progressColor: isResting ? Colors.grey : Colors.redAccent,
                    center: isReady
                        ? setupWidget ?? const SizedBox()
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          '세트 $currentSet / $totalSets',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        isResting
                            ? Text(
                          '휴식 $restSeconds초',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        )
                            : Text(
                          '${currentCount - 1}회',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: flameX - 12,
                  top: flameY - 12,
                  child: const Text('🔥', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
            //시작 멈춤 버튼
            // const SizedBox(height: 20),
            // IconButton(
            //   icon: Icon(
            //     isRunning
            //         ? (isPaused ? Icons.play_arrow : Icons.pause)
            //         : Icons.play_arrow,
            //   ),
            //   onPressed: onStartPressed,
            // ),
            // if (onStopPressed != null)
            //   IconButton(
            //     icon: const Icon(Icons.stop),
            //     onPressed: onStopPressed,
            //   ),
          ],
        );
      },
    );
  }
}
