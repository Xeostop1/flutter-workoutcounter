// lib/widgets/gradient_circular_counter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 원형 그라데이션 프로그레스 링
/// - progress: 0.0 ~ 1.0
/// - thickness: 링 두께
/// - startAngle: 12시 방향이 기본(-pi/2)
class GradientCircularCounter extends StatelessWidget {
  final double progress;
  final double size;
  final double thickness;
  final double startAngle;

  const GradientCircularCounter({
    super.key,
    required this.progress,
    this.size = 240,
    this.thickness = 20,
    this.startAngle = -math.pi / 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          thickness: thickness,
          startAngle: startAngle,
          colorBg: const Color(0x22FFFFFF), // 은은한 배경 링
          // 연한 → 중간 → 진한 오렌지
          gradientColors: const [
            Color(0xFFFFB391),
            Color(0xFFFF8A5B),
            Color(0xFFFF6B35),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double thickness;
  final double startAngle;
  final Color colorBg;
  final List<Color> gradientColors;

  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.startAngle,
    required this.colorBg,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - thickness) / 2;

    // 1) 배경 링
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = colorBg;
    canvas.drawCircle(center, radius, bg);

    // 2) 진행 링(그라데이션 + 둥근 끝)
    final rect = Rect.fromCircle(center: center, radius: radius);
    // progress==0이면 arc가 안 보이는 문제 방지
    final sweep = (progress <= 0) ? 0.0001 : (2 * math.pi * progress);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      colors: gradientColors,
      stops: const [0.0, 0.65, 1.0],
    );

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0); // 살짝 블러

    canvas.drawArc(rect, startAngle, sweep, false, fg);

    // 3) 끝점 하이라이트(작은 동그라미)
    if (progress > 0) {
      final endAngle = startAngle + sweep;
      final endOffset = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final head = Paint()..color = gradientColors.last;
      canvas.drawCircle(endOffset, thickness * 0.35, head);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress ||
        old.thickness != thickness ||
        old.startAngle != startAngle ||
        old.colorBg != colorBg;
    // gradientColors는 const 리스트라 동일 참조일 가능성이 높아 비교 생략
  }
}
