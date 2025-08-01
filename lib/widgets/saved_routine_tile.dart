import 'package:flutter/material.dart';

class SavedRoutineTile extends StatelessWidget {
  final String title;
  final int sets;
  final int reps;
  final VoidCallback onTap;
  final Color headerColor; // 타이틀 배경 색

  const SavedRoutineTile({
    super.key,
    required this.title,
    required this.sets,
    required this.reps,
    required this.onTap,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // 카드 크기
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Text(
                title.length > 6 ? '${title.substring(0, 6)}...' : title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 세트 & 횟수
            Text(
              "$sets세트 $reps회",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
