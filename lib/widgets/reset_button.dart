import 'package:flutter/material.dart';

class ResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ResetButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey.shade200,
      child: IconButton(
        icon: const Icon(Icons.refresh),
        color: Colors.grey,
        onPressed: onPressed,
      ),
    );
  }
}

