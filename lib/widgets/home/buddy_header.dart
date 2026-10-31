import 'package:flutter/material.dart';

class BuddyHeader extends StatelessWidget {
  const BuddyHeader({
    super.key,
    required this.day,
    required this.flameStage,
    required this.nickname,
    required this.message,
    required this.onTap,
  });

  final int day;
  final int flameStage;
  final String nickname;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.textScalerOf(context).scale(14);
    final height =
        ((fontSize * 1.2).ceilToDouble() + (fontSize * 1.4).ceilToDouble() + 36)
            .clamp(110.0, double.infinity);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: '$nickname님의 불씨 보기',
            child: GestureDetector(
              onTap: onTap,
              child: Image.asset(
                _stageAsset(flameStage),
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/charactor_first.png',
                  width: 110,
                  height: 110,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth / 2,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C5C5C),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Day $day',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                text: '님의 불씨',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Tooltip(
                        message: message,
                        child: Container(
                          width: 148,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF696969),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -8,
                        top: 12,
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: const SizedBox(
                            width: 12,
                            height: 12,
                            child: ColoredBox(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stageAsset(int stage) {
    if (stage == -2) return 'assets/images/flame_stage_m2.png';
    if (stage == -1) return 'assets/images/flame_stage_m1.png';
    return 'assets/images/flame_stage_${stage.clamp(0, 10)}.png';
  }
}
