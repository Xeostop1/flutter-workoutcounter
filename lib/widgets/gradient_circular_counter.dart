// lib/widgets/gradient_circular_counter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class GradientCircularCounter extends StatelessWidget {
  const GradientCircularCounter({
    super.key,
    required this.progress,
    this.setNumber = 1,            // ← 기본값
    this.reps = 10,                // ← 기본값
    this.size = 240,
    this.thickness = 22,
    this.startAngle = -math.pi / 2,
    this.dim = false,
    this.trackColor = const Color(0xFFF3AE94),
    this.dimColor = const Color(0xFFBDBDBD),
    this.gradient1 = const Color(0xFFFFDEA9),
    this.gradient2 = const Color(0xFFFF6E38),
    this.gradient3 = const Color(0xFFEF7F4C),
    this.bgColor,                  // ← 호환용 alias (trackColor 대체)
    this.setLabel = 'Set',
    this.repsLabel = '회',
  });

  final double progress;

  // 선택 파라미터 + 기본값
  final int setNumber;
  final int reps;

  final double size;
  final double thickness;
  final double startAngle;
  final bool dim;

  final Color trackColor;
  final Color dimColor;
  final Color gradient1;
  final Color gradient2;
  final Color gradient3;

  // old API alias
  final Color? bgColor;

  final String setLabel;
  final String repsLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: clamped,
              thickness: thickness,
              startAngle: startAngle,
              dim: dim,
              trackColor: bgColor ?? trackColor, // alias 적용
              dimColor: dimColor,
              gradient1: gradient1,
              gradient2: gradient2,
              gradient3: gradient3,
            ),
          ),
          Container(
            width: size - thickness * 1.6,
            height: size - thickness * 1.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    text: '$setNumber',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: '  $setLabel',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: '$reps',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                    children: [
                      TextSpan(
                        text: '  $repsLabel',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.startAngle,
    required this.dim,
    required this.trackColor,
    required this.dimColor,
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
  });

  final double progress;
  final double thickness;
  final double startAngle;
  final bool dim;

  final Color trackColor;
  final Color dimColor;
  final Color gradient1;
  final Color gradient2;
  final Color gradient3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 배경 트랙
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = dim ? dimColor : trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (dim) return;

    final sweep = (math.pi * 2) * progress;
    if (sweep <= 0) return;

    // 3색 그라데이션
    final shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + math.pi * 2,
      colors: [gradient1, gradient2, gradient3, gradient1],
      stops: const [0.0, 0.45, 0.8, 1.0],
    ).createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);

    // 끝점 하이라이트
    final endAngle = startAngle + sweep;
    final end = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(end, thickness * 0.30, Paint()..color = gradient3.withOpacity(0.95));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
          old.thickness != thickness ||
          old.startAngle != startAngle ||
          old.dim != dim ||
          old.trackColor != trackColor ||
          old.dimColor != dimColor ||
          old.gradient1 != gradient1 ||
          old.gradient2 != gradient2 ||
          old.gradient3 != gradient3;
}
