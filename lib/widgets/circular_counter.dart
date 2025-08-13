import 'package:flutter/material.dart';

class CircularCounter extends StatelessWidget {
  final double progress; // 0~1
  final bool resting; // 휴식 중 색 변경
  const CircularCounter({
    super.key,
    required this.progress,
    required this.resting,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme;
    final activeGradient = const SweepGradient(
      startAngle: -1.57,
      endAngle: 4.71,
      colors: [
        Color(0xFFFFE0CC), // 연한 deeporange
        Color(0xFFFFA366),
        Color(0xFFFF7A3D),
        Color(0xFFE65400), // 진해지는 deeporange
      ],
      stops: [0.0, 0.45, 0.75, 1.0],
    );
    final restColor = Colors.greenAccent.shade100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          size: const Size.square(220),
          painter: _RingPainter(
            value,
            resting ? restColor : null,
            activeGradient,
          ),
          child: Center(
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.displaySmall!,
              child: const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color? restColor;
  final Gradient gradient;
  _RingPainter(this.progress, this.restColor, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 24.0;

    final bg = Paint()
      ..color = const Color(0x22FF7A3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = restColor != null ? null : gradient.createShader(rect);

    if (restColor != null) fg.color = restColor!;

    // 배경 원
    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      -1.57,
      6.283,
      false,
      bg,
    );

    // 진행 원
    canvas.drawArc(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      -1.57,
      6.283 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.restColor != restColor;
}
