// lib/pages/onboarding/onboarding_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1 -> 2 -> 3(입력) -> 4(확인)
  Timer? _auto; // 1,2,4 자동 진행
  Timer? _typingDebounce; // 3에서 "입력이 멈춤" 감지
  final _numCtrl = TextEditingController();
  int? _weeklyTarget;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void initState() {
    super.initState();
    _scheduleAutoIfNeeded();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _typingDebounce?.cancel();
    _numCtrl.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _goto(int step) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _fade.forward(from: 0);
    });
    _scheduleAutoIfNeeded();
  }

  void _scheduleAutoIfNeeded() {
    _auto?.cancel();

    // 1,2는 2초 후 자동 진행
    if (_step == 1 || _step == 2) {
      _auto = Timer(const Duration(seconds: 2), () {
        if (mounted) _goto(_step + 1);
      });
      return;
    }

    // 3은 입력 이벤트에서 디바운스로 처리 (여기서는 대기)
    // 4는 1.6초 보여주고 자동 종료
    if (_step == 4) {
      _auto = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        _finish();
      });
    }
  }

  void _onTyped(String v) {
    final n = int.tryParse(v.trim());
    setState(() => _weeklyTarget = (n != null && n > 0) ? n : null);

    _typingDebounce?.cancel();
    if (_weeklyTarget != null) {
      _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (_step == 3 && _weeklyTarget != null) _goto(4);
      });
    }
  }

  Future<void> _finish() async {
    context.read<AuthViewModel>().setOnboardingDone(true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: switch (_step) {
        1 => const _FullImage(image: 'assets/images/onboarding_1.jpg'),
        2 => const _FullImage(image: 'assets/images/onboarding_2.jpg'),
        3 => _Step3Input(controller: _numCtrl, onChanged: _onTyped),
        _ => _Step4Confirm(target: _weeklyTarget),
      },
    );
  }
}

/// 전체 화면 배경 이미지
class _FullImage extends StatelessWidget {
  final String image;
  const _FullImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('이미지를 확인하세요', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// Step 3: 입력 화면 (배경 + 중앙 입력 + 말풍선)
class _Step3Input extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _Step3Input({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding_3.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          // 중앙 "주에 [입력] 번 운동하기"
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '주에  ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outline.withOpacity(0.3)),
                  ),
                  child: SizedBox(
                    width: 68,
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '__',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ),
                const Text(
                  '  번  운동하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),

          // 말풍선 (텍스트 + 꼬리 포함)
      Align(
        alignment: const Alignment(0, 0.28),
        child: Container(
          margin: const EdgeInsets.only(top: 150), // 위쪽 마진
          child: const SpeechBubble(
            text: '목표가 있나요?',
            color: Colors.white,
            textColor: Colors.black87,
          ),
        ),
      ),
        ],
      ),
    );
  }
}

/// Step 4: 확인 화면 (버튼 없이 자동 진행) + 말풍선
class _Step4Confirm extends StatelessWidget {
  final int? target;
  const _Step4Confirm({required this.target});

  @override
  Widget build(BuildContext context) {
    final n = target ?? 3;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding_4.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          Align(
            alignment: const Alignment(0, -0.35),
            child: Text(
              '주에  $n  번  운동하기',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 0.6,
              ),
            ),
          ),

          Align(
            alignment: const Alignment(0, 0.28),
            child: const SpeechBubble(
              text: '좋아요! 시작해볼까요?',
              color: Colors.white,
              textColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 재사용 가능한 '말풍선 + 꼬리' 위젯
///  - 기본: 아래쪽 가운데 방향으로 꼬리
///  - 필요시 tailAlignX로 꼬리의 가로 위치(-1.0 ~ 1.0) 조절 가능
class SpeechBubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailAlignX; // -1.0(왼쪽) ~ 1.0(오른쪽), 0.0(가운데)

  const SpeechBubble({
    super.key,
    required this.text,
    this.color = Colors.white,
    this.textColor = Colors.black87,
    this.radius = 10,
    this.tailWidth = 14,
    this.tailHeight = 10,
    this.tailAlignX = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        color: color,
        radius: radius,
        tailWidth: tailWidth,
        tailHeight: tailHeight,
        tailAlignX: tailAlignX,
      ),
      child: Padding(
        // tailHeight만큼 여유를 줘서 전체 높이에 꼬리를 포함
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + tailHeight),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailAlignX;

  _BubblePainter({
    required this.color,
    required this.radius,
    required this.tailWidth,
    required this.tailHeight,
    required this.tailAlignX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyHeight = size.height - tailHeight;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    // 꼬리 위치 (가로)
    final cx = (size.width / 2) + tailAlignX * (size.width / 2 - tailWidth);
    final left = cx - tailWidth / 2;
    final right = cx + tailWidth / 2;

    // 아래쪽 가운데로 꼬리(삼각형)
    path.moveTo(left, bodyHeight);
    path.lineTo(cx, bodyHeight + tailHeight);
    path.lineTo(right, bodyHeight);
    path.close();

    // 살짝 그림자
    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 4, true);

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        tailWidth != oldDelegate.tailWidth ||
        tailHeight != oldDelegate.tailHeight ||
        tailAlignX != oldDelegate.tailAlignX;
  }
}
