import 'package:flutter/material.dart';

class PlayPauseButton extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onPressed;

  const PlayPauseButton({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // *** 상태에 따라 아이콘 결정 ***
    IconData icon;
    if (isRunning) {
      icon = isPaused ? Icons.play_arrow : Icons.pause;
    } else {
      icon = Icons.play_arrow;
    }


    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.redAccent,
      child: IconButton(
        icon: Icon(icon, size: 32),
        color: Colors.white,
        onPressed: onPressed,
      ),
    );
  }
}
