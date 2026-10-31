import 'package:flutter/material.dart';
import '../flame_avatar.dart';

class BuddyHeader extends StatelessWidget {
  const BuddyHeader({
    super.key,
    required this.day,
    required this.flameStage,
    required this.nickname,
    required this.message,
    required this.onTap,
    this.compact = false,
  });
  final int day;
  final int flameStage;
  final String nickname;
  final String message;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final diameter = compact ? 90.0 : 110.0;
    return Semantics(
      button: true,
      label: '$nickname님의 불씨 보기',
      hint: '눌러서 성장과 이번 주 목표 보기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              SizedBox(
                width: diameter,
                height: diameter + 14,
                child: Stack(
                  children: [
                    _avatar(diameter),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: diameter),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF595959),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Day $day',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        '$nickname님의 불씨',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipPath(
                          clipper: _SpeechTail(),
                          child: const SizedBox(
                            width: 10,
                            height: 14,
                            child: ColoredBox(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.split('\n').first,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Color(0xFF626262),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 10, top: 4),
                      child: Text(
                        '성장·목표 보기 ›',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB8BBC4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(double diameter) {
    return SizedBox.square(
      key: const ValueKey('home-flame-avatar'),
      dimension: diameter,
      child: OverflowBox(
        maxWidth: diameter * 1.25,
        maxHeight: diameter * 1.25,
        child: FlameAvatar(
          key: flameStage == 0 ? const ValueKey('home-first-day-ember') : null,
          stage: flameStage,
          size: diameter * 1.25,
          characterScale: flameStage <= 0 ? 1.12 : 1,
        ),
      ),
    );
  }
}

class _SpeechTail extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(0, size.height / 2)
    ..lineTo(size.width, size.height)
    ..close();

  @override
  bool shouldReclip(_SpeechTail oldClipper) => false;
}
