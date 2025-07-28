import 'package:counter_01/widgets/play_pause_button.dart';
import 'package:counter_01/widgets/reset_button.dart';
import 'package:counter_01/widgets/stop_button.dart';
import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onReset;
  final VoidCallback onStartPause;
  final VoidCallback onStop;

  const ControlButtons({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onReset,
    required this.onStartPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    print('[ControlButtons] isRunning=$isRunning, isPaused=$isPaused');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ResetButton(onPressed: onReset),
        PlayPauseButton(
          isRunning: isRunning,
          isPaused: isPaused,
          onPressed: onStartPause,
        ),
        StopButton(onPressed: onStop),
      ],
    );
  }
}
