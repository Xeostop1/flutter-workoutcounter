import 'package:flutter/material.dart';

class StopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey.shade200,
      child: IconButton(
        icon: const Icon(Icons.stop),
        color: Colors.grey,
        onPressed: onPressed,
      ),
    );
  }
}
