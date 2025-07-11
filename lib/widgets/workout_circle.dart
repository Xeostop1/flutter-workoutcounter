// lib/widgets/workout_circle.dart
import 'package:flutter/material.dart';

class WorkoutCircle extends StatefulWidget {
  final int totalSets;
  final int currentSet;
  final int currentCount;
  final int repeatCount;
  final int restSeconds;
  final double progress;
  final VoidCallback? onStartPressed;
  final VoidCallback? onStopPressed;
  final bool isRunning;
  final bool isPaused;
  final bool isResting;
  final Duration animationDuration;

  const WorkoutCircle({
    super.key,
    required this.totalSets,
    required this.currentSet,
    required this.currentCount,
    required this.repeatCount,
    required this.restSeconds,
    required this.progress,
    this.onStartPressed,
    this.onStopPressed,
    required this.isRunning,
    required this.isPaused,
    required this.isResting,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  _WorkoutCircleState createState() => _WorkoutCircleState();
}

class _WorkoutCircleState extends State<WorkoutCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // controller 초기값을 widget.progress로 세팅
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      duration: widget.animationDuration,
      value: widget.progress,
    );
  }

  @override
  void didUpdateWidget(covariant WorkoutCircle old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      // 이전 값에서 새 값으로 부드럽게 애니메이트
      _controller.animateTo(
        widget.progress,
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animValue = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 배경 원형
              CustomPaint(
                size: const Size(300, 300),
                painter: CirclePainter(
                  progress: 1.0,
                  color: Colors.grey.shade200,
                ),
              ),
              // 진행 원형
              CustomPaint(
                size: const Size(300, 300),
                painter: CirclePainter(
                  progress: animValue,
                  color: widget.isResting ? Colors.grey : Colors.black,
                ),
              ),
              // 중앙 UI
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '세트 ${widget.currentSet} / ${widget.totalSets}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  widget.isResting
                      ? Text(
                    '휴식 ${widget.restSeconds}초',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  )
                      : Text(
                    '${widget.currentCount-1}회',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: Icon(
                      widget.isRunning
                          ? (widget.isPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_arrow,
                    ),
                    onPressed: widget.onStartPressed,
                  ),
                  if (widget.onStopPressed != null)
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: widget.onStopPressed,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      -1.57, // 12시 방향부터 시작
      2 * 3.1415926535 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CirclePainter old) =>
      old.progress != progress || old.color != color;
}
