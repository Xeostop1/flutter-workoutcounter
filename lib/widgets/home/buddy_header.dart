import 'package:flutter/material.dart';

class BuddyHeader extends StatelessWidget {
  final int day;
  final String nickname;
  final String message;
  final VoidCallback onTap;

  const BuddyHeader({
    super.key,
    required this.day,
    required this.nickname,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D5D5D),
                    shape: BoxShape.circle,
                  ),
                ),
                Image.asset(
                  'assets/images/charactor_first.png',
                  width: 42,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DayPill(day: day),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: nickname,
                          style: const TextStyle(
                            fontSize: 20, // 닉네임은 더 큼
                            fontWeight: FontWeight.w800, // 더 굵게
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: '님의 불씨',
                          style: TextStyle(
                            fontSize: 13, // 뒤 문구는 더 작게
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5D5D5D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  final int day;
  const _DayPill({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5E5E5E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Day $day',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
