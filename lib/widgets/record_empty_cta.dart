import 'package:flutter/material.dart';

class RecordEmptyCTA extends StatelessWidget {
  final VoidCallback onTap;
  const RecordEmptyCTA({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center),
            SizedBox(width: 8),
            Text("운동을 시작해주세요"),
          ],
        ),
      ),
    );
  }
}
