import 'package:flutter/material.dart';

Future<bool?> showEndWorkoutDialog(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // 바깥 터치로 닫히지 않게
    builder: (ctx) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                const Text(
                  '운동을 끝낼까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        '아니요',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        '네',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
