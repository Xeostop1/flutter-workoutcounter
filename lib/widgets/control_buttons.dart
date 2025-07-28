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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRoundButton(
          icon: Icons.refresh,
          backgroundColor: Colors.black12,
          iconColor: Colors.grey,
          onPressed: onReset,
          size: 56,
        ),
        const SizedBox(width: 25), // 버튼 간 간격
        _buildRoundButton(
          icon: isRunning && !isPaused ? Icons.pause : Icons.play_arrow,
          backgroundColor: Colors.redAccent,
          iconColor: Colors.white,
          onPressed: onStartPause,
          size: 72,
        ),
        const SizedBox(width: 25), // 버튼 간 간격
        _buildRoundButton(
          icon: Icons.stop,
          backgroundColor: Colors.black12,
          iconColor: Colors.grey,
          onPressed: onStop,
          size: 56,
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: size * 0.5,
        color: iconColor,
        onPressed: onPressed,
      ),
    );
  }
}
