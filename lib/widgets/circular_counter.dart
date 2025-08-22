import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularCounter extends StatelessWidget {
  /// 0.0 ~ 1.0 (세트 내 누적 진행도)
  final double progress;

  /// 휴식 중이면 색상 스킴 변경
  final bool resting;
  final double size;

  const CircularCounter({
    super.key,
    required this.progress,
    required this.resting,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, resting: resting),
        child: Center(
          child: Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0~1
  final bool resting;

  _RingPainter({required this.progress, required this.resting});

  @override
  void paint(Canvas canvas, Size size) {
    final thickness = size.width * 0.10;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - thickness / 2;

    // 고정 시작각: 12시 방향
    const start = -math.pi / 2;

    // 1) 배경 트랙(항상 보임) — 다크 배경에서도 또렷하게
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.10);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      2 * math.pi - 0.001,
      false,
      track,
    );

    // 2) 진행 웨지(누적) — 휴식/운동 색상 구분
    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      final active = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = resting
            ? const Color(0xFF5CCB85)
            : Colors.deepOrange.shade400;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi * p,
        false,
        active,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.resting != resting;
}
