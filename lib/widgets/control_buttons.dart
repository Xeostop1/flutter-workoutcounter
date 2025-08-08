import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final bool isRunning;

  const ControlButtons({
    super.key,
    required this.onReset,
    required this.onPlayPause,
    required this.onStop,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        _roundIconButton(
          icon: Icons.refresh,
          color: Colors.white,
          iconColor: Colors.orange,
          onPressed: onReset,
        ),
        const SizedBox(width: 20),

        // Play / Pause Button
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color:Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Stop Button
        _roundIconButton(
          icon: Icons.stop,
          color: Colors.white,
          iconColor: Colors.orange,
          onPressed: onStop,
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
