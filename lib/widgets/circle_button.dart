import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const CircleButton({
    super.key,
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.size = 64,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
