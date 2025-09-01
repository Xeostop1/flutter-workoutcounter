import 'dart:math' as math;
import 'package:flutter/material.dart';

class GradientCircularCounter extends StatelessWidget {
  final double progress; // 0~1
  final double size;
  const GradientCircularCounter({super.key, required this.progress, this.size = 220});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(progress),
      child: Center(child: SizedBox.square(dimension: size)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 22.0;
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke/2;

    final bg = Paint()
      ..color = const Color(0x22FF6A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * progress,
      colors: const [Color(0xFFFFB3A8), Color(0xFFFF4A3A)],
    );
    final fg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
