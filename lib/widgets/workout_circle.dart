import 'package:flutter/material.dart';

class WorkoutCircle extends StatelessWidget {
  final int totalSets;
  final int currentSet;
  final int repeatCount;
  final int restSeconds;
  final double progress;
  final void Function()? onStartPressed;
  final bool isRunning;
  final bool isPaused;
  final bool isResting;

  const WorkoutCircle({
    super.key,
    required this.totalSets,
    required this.currentSet,
    required this.repeatCount,
    required this.restSeconds,
    required this.progress,
    this.onStartPressed,
    required this.isRunning,
    required this.isPaused,
    required this.isResting,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(300, 300),
            painter: CirclePainter(
              progress: 1.0,
              color: Colors.grey.shade200,
            ),
          ),
          CustomPaint(
            size: const Size(300, 300),
            painter: CirclePainter(
              progress: progress,
              color: isResting ? Colors.grey : Colors.black,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '세트 $currentSet / $totalSets',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              isResting
                  ? Text(
                '휴식 ${restSeconds}초',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              )
                  : Text(
                '$repeatCount회 반복',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: Icon(
                  isRunning
                      ? (isPaused ? Icons.play_arrow : Icons.pause)
                      : Icons.play_arrow,
                ),
                onPressed: onStartPressed,
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
      -1.57,
      6.28 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
