import 'dart:math' as math;

import 'package:flutter/material.dart';

class GradientCircularCounter extends StatelessWidget {
  const GradientCircularCounter({
    super.key,
    required this.progress,
    this.setNumber = 1,
    this.reps = 10,
    this.size = 240,
    this.thickness = 23,
    this.center,
    this.startAngle = -math.pi / 2,
    this.dim = false,
    this.trackColor = const Color(0xFF30333A),
    this.dimColor = const Color(0xFFBDBDBD),
    this.gradient1 = const Color(0xFFFFE3B8),
    this.gradient2 = const Color(0xFFFFB783),
    this.gradient3 = const Color(0xFFFF784F),
    this.bgColor,
    this.setLabel = '\uC138\uD2B8',
    this.repsLabel = '\uD68C',
  });

  final Widget? center;
  final double progress;
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

  // 吏㏃? 二쇱꽍: 湲곗〈 ?몄텧 肄붾뱶 ?명솚??alias
  final Color? bgColor;

  final String setLabel;
  final String repsLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  thickness: thickness,
                  startAngle: startAngle,
                  dim: dim,
                  trackColor: bgColor ?? trackColor,
                  dimColor: dimColor,
                  gradient1: gradient1,
                  gradient2: gradient2,
                  gradient3: gradient3,
                ),
              ),
              Container(
                width: size - thickness * 2,
                height: size - thickness * 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1E23),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child:
                    center ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CounterLine(value: setNumber, label: setLabel),
                        const SizedBox(height: 9),
                        _CounterLine(value: reps, label: repsLabel),
                      ],
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CounterLine extends StatelessWidget {
  const _CounterLine({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$value',
        style: const TextStyle(
          color: Color(0xFFF4F4F6),
          fontSize: 40,
          fontWeight: FontWeight.w600,
          height: 1.0,
          letterSpacing: -0.8,
        ),
        children: [
          TextSpan(
            text: ' $label',
            style: const TextStyle(
              color: Color(0xFF9B9EA8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
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

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = dim ? dimColor : trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (dim) return;

    if (progress <= 0) return;
    final sweep = (math.pi * 2) * progress;

    final shader = SweepGradient(
      transform: GradientRotation(startAngle),
      colors: [gradient1, gradient2, gradient3],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = shader;

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
    // The round cap crosses the shader seam; keep it the starting color.
    canvas.drawCircle(
      center + Offset(math.cos(startAngle), math.sin(startAngle)) * radius,
      thickness / 2,
      Paint()..color = gradient1,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress ||
        old.thickness != thickness ||
        old.startAngle != startAngle ||
        old.dim != dim ||
        old.trackColor != trackColor ||
        old.dimColor != dimColor ||
        old.gradient1 != gradient1 ||
        old.gradient2 != gradient2 ||
        old.gradient3 != gradient3;
  }
}
