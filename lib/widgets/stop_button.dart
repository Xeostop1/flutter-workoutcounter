import 'package:flutter/material.dart';

/// 운동을 완전히 정지시키는 버튼
class StopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,            // *** 빨간색 강조 ***
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Stop',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
