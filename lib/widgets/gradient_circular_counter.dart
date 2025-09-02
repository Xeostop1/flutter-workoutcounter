import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 자연스러운 원형 그라데이션 링
/// - progress: 0.0~1.0 (작을수록 더 연함)
/// - fromColor(연한) → toColor(진한) 으로, 끝 색을 progress에 따라 점점 진하게
class GradientCircularCounter extends StatelessWidget {
  final double progress;      // 0~1
  final double size;
  final double thickness;
  final double startAngle;    // 기본 12시(-pi/2)
  final bool dim;             // 휴식: 회색 단색
  final Color fromColor;      // 시작(연한 주황)
  final Color toColor;        // 끝(진한 주황)
  final Color bgColor;        // 배경 링
  final Color dimColor;       // 휴식 링

  const GradientCircularCounter({
    super.key,
    required this.progress,
    this.size = 240,
    this.thickness = 22,
    this.startAngle = -math.pi / 2,
    this.dim = false,
    this.fromColor = const Color(0xFFFFB391), // 연한 주황
    this.toColor   = const Color(0xFFFD4400), // 진한 주황
    this.bgColor   = const Color(0xFFF3AE94),
    this.dimColor  = const Color(0xFFBDBDBD),
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
          dim: dim,
          dimColor: dimColor,
          colorBg: bgColor,
          fromColor: fromColor,
          toColor: toColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double thickness;
  final double startAngle;
  final bool dim;
  final Color dimColor;
  final Color colorBg;
  final Color fromColor;
  final Color toColor;

  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.startAngle,
    required this.dim,
    required this.dimColor,
    required this.colorBg,
    required this.fromColor,
    required this.toColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - thickness) / 2;

    // 배경 링
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = dim ? dimColor : colorBg;
    canvas.drawCircle(center, radius, bg);

    if (dim) return; // 휴식 모드: 진행 링 없음

    // 진행 각도
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (progress <= 0) ? 0.0001 : (2 * math.pi * progress);

    // 🔑 핵심: progress가 작을 때는 endColor를 거의 연하게 유지
    // (지수로 완만하게: 초반엔 천천히, 후반에 급격히 진해짐)
    final eased = math.pow(progress, 1.6).toDouble(); // 1.6~2.0 권장
    final endColor = Color.lerp(fromColor, toColor, eased)!;

    // 시작은 항상 연한색 → 진행 끝으로 갈수록 endColor(진해짐)
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      colors: [fromColor, endColor],
      stops: const [0.0, 1.0],
      tileMode: TileMode.clamp,
    );

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweep, false, fg);

    // 끝점 하이라이트도 동일한 endColor 사용 (초반엔 연함)
    if (progress > 0) {
      final endAngle = startAngle + sweep;
      final end = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final head = Paint()..color = endColor.withOpacity(0.95);
      canvas.drawCircle(end, thickness * 0.30, head);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
          old.thickness != thickness ||
          old.startAngle != startAngle ||
          old.dim != dim ||
          old.dimColor != dimColor ||
          old.colorBg != colorBg ||
          old.fromColor != fromColor ||
          old.toColor != toColor;
}
