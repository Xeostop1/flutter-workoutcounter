import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pc = PageController();
  int weeklyGoal = 3;

  void _next() {
    if (_pc.page == null) return;
    final p = _pc.page!.round();
    if (p >= 2) {
      // 온보딩 종료 → 홈
      context.go('/');
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pc,
              children: [
                // 1) Burning START (onboarding_3.jpg)
                _FullImagePage(
                  imagePath: 'assets/images/onboarding_3.jpg',
                  overlay: const Text(
                    'Burning\nSTART',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                // 2) 주에 N번 운동하기 + 말풍선 "좋아요! 시작해볼까요?"
                _GoalPickPage(
                  title: '주에  ',
                  weeklyGoal: weeklyGoal,
                  onChanged: (v) => setState(() => weeklyGoal = v),
                  bubbleText: '좋아요! 시작해볼까요?',
                ),
                // 3) 최종 문구 + 말풍선 "목표가 있나요?"
                _ConfirmGoalPage(
                  weeklyGoal: weeklyGoal,
                  bubbleText: '목표가 있나요?',
                ),
              ],
            ),

            // 하단 고정: 다음/시작 버튼
            Positioned(
              left: 16, right: 16, bottom: 20,
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 풀스크린 이미지 + 중앙 오버레이
class _FullImagePage extends StatelessWidget {
  final String imagePath;
  final Widget? overlay;
  const _FullImagePage({required this.imagePath, this.overlay});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        if (overlay != null)
          Positioned.fill(
            child: Center(child: overlay),
          ),
      ],
    );
  }
}

/// 주당 횟수 선택 페이지 (onboarding_2.jpg 느낌)
class _GoalPickPage extends StatelessWidget {
  final String title;
  final int weeklyGoal;
  final ValueChanged<int> onChanged;
  final String bubbleText;
  const _GoalPickPage({
    required this.title,
    required this.weeklyGoal,
    required this.onChanged,
    required this.bubbleText,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black),
        ),
        // 상단 캐릭터 살짝 보이게(원본 느낌 살림)
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset('assets/images/onboarding_1.jpg', fit: BoxFit.cover),
          ),
        ),
        // 상단 문구
        Positioned(
          top: 120, left: 0, right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('주에 ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$weeklyGoal 번',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const Text('  운동하기', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        // 말풍선
        Positioned(
          left: 0, right: 0, bottom: 170,
          child: Center(child: _SpeechBubble(text: bubbleText)),
        ),
        // 아래 조절 스텝퍼
        Positioned(
          left: 0, right: 0, bottom: 92,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundIcon(
                icon: Icons.remove,
                onTap: () => onChanged((weeklyGoal - 1).clamp(1, 7)),
              ),
              const SizedBox(width: 24),
              Text(
                '$weeklyGoal',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 24),
              _RoundIcon(
                icon: Icons.add,
                onTap: () => onChanged((weeklyGoal + 1).clamp(1, 7)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 최종 확인 페이지(onboarding_4.jpg 느낌)
class _ConfirmGoalPage extends StatelessWidget {
  final int weeklyGoal;
  final String bubbleText;
  const _ConfirmGoalPage({required this.weeklyGoal, required this.bubbleText});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.black)),
        Positioned(
          top: 120, left: 0, right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('주에 ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E3E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$weeklyGoal 번',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const Text('  운동하기', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 170,
          child: Center(child: _SpeechBubble(text: bubbleText)),
        ),
        // 좌하단 캐릭터(원본 느낌)
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Image.asset('assets/images/onboarding_4.jpg', fit: BoxFit.cover),
        ),
      ],
    );
  }
}

/// 말풍선(간단 구현)
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 16)),
        ),
        Positioned(
          bottom: -6, left: 20,
          child: Transform.rotate(
            angle: 0.7854, // 45도
            child: Container(width: 12, height: 12, color: Colors.white),
          ),
        )
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5E5E5E),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44, height: 44,
          child: Icon(Icons.add, color: Colors.white), // placeholder
        ),
      ),
    );
  }
}
