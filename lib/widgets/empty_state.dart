import 'package:flutter/material.dart';

class RecordEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const RecordEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6A2B);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_emotions_outlined,
            size: 84,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          const Text('진행한 운동이 없어요', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAdd,
            child: const Text(
              '운동 기록 직접 추가',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
