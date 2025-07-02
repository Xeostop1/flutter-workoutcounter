import 'package:flutter/material.dart';

class WorkoutCircle extends StatelessWidget {
  final int totalSets;
  final int repeatCount;
  final int restSeconds;
  final double progress;

  const WorkoutCircle({
    super.key,
    required this.totalSets,
    required this.repeatCount,
    required this.restSeconds,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // ✅ 실제 원형 크기 지정
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ 배경 원형
          CustomPaint(
            size: const Size(300, 300),
            painter: CirclePainter(
              progress: 1.0,
              color: Colors.grey.shade200,
            ),
          ),
          // ✅ 진행 원형
          CustomPaint(
            size: const Size(300, 300),
            painter: CirclePainter(
              progress: progress,
              color: Colors.black,
            ),
          ),
          // ✅ 중앙 텍스트 및 버튼
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalSets세트 $repeatCount회',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '휴식 ${restSeconds}초',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  // TODO: 타이머 기능 연결
                },
                icon: const Icon(Icons.play_circle_outline),
                iconSize: 48,
                color: Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 20.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // 시작 위치 (12시 방향)
      6.28 * progress, // 전체 원의 비율 (2 * pi * 진행도)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
