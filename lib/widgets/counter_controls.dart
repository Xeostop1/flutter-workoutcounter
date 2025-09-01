import 'package:flutter/material.dart';

class CounterControls extends StatelessWidget {
  final VoidCallback onStartPause;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final bool isRunning;
  final bool isResting;

  const CounterControls({
    super.key,
    required this.onStartPause,
    required this.onStop,
    required this.onReset,
    required this.isRunning,
    required this.isResting,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(iconSize: 36, onPressed: onReset, icon: const Icon(Icons.refresh)),
        FloatingActionButton(
          onPressed: isResting ? null : onStartPause,
          child: Icon(isRunning ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(iconSize: 36, onPressed: onStop, icon: const Icon(Icons.stop)),
      ],
    );
  }
}
