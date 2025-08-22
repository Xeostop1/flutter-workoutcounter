import 'package:flutter/material.dart';

class NextRoutineChip extends StatelessWidget {
  final String title;
  final int sets;
  final int reps;
  final bool selected;
  final bool done; // 오늘 완료 표시
  final VoidCallback onTap;
  final String? stampAsset; // 완료 도장 이미지 경로

  const NextRoutineChip({
    super.key,
    required this.title,
    required this.sets,
    required this.reps,
    required this.selected,
    required this.onTap,
    this.done = false,
    this.stampAsset = 'assets/images/stamp_done.png',
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? Colors.white : const Color(0xFF6F6F6F);
    final Color fg = selected ? Colors.black : Colors.white;
    final BorderRadius radius = BorderRadius.circular(28);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: 180,
            height: 118,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: done && !selected ? const Color(0xFF3A3A3A) : bg,
              borderRadius: radius,
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Opacity(
              opacity: done && !selected ? 0.55 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sets} / $reps', // “세트 / 횟수”
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 완료 도장
        if (done && stampAsset != null)
          Positioned(
            left: 12,
            top: 20,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.15,
                child: Image.asset(stampAsset!, width: 92, fit: BoxFit.contain),
              ),
            ),
          ),
      ],
    );
  }
}
