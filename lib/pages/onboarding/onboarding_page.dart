import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _auto;
  Timer? _typingDebounce;

  final _numCtrl = TextEditingController();
  int? _weeklyTarget;
  bool _isSaving = false;

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

    if (_step == 1 || _step == 2) {
      _auto = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        _goto(_step + 1);
      });
      return;
    }

    if (_step == 4) {
      _auto = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        _finish();
      });
    }
  }

  void _onTyped(String raw) {
    final parsed = int.tryParse(raw.trim());
    setState(() {
      _weeklyTarget = (parsed != null && parsed >= 1 && parsed <= 7)
          ? parsed
          : null;
    });

    _typingDebounce?.cancel();
    if (_weeklyTarget != null) {
      _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (_step == 3 && _weeklyTarget != null) {
          _goto(4);
        }
      });
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;

    final target = _weeklyTarget;
    if (target == null) {
      if (!mounted) return;
      _goto(3);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주간 운동 횟수를 입력해주세요.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AuthViewModel>().completeOnboarding(
        weeklyTarget: target,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _goto(3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: switch (_step) {
        1 => const _FullImage(image: 'assets/images/onboarding_1.jpg'),
        2 => const _FullImage(image: 'assets/images/onboarding_2.jpg'),
        3 => _Step3Input(
          controller: _numCtrl,
          onChanged: _onTyped,
          enabled: !_isSaving,
        ),
        _ => _Step4Confirm(target: _weeklyTarget, isSaving: _isSaving),
      },
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('이미지를 확인해주세요.', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _Step3Input extends StatelessWidget {
  const _Step3Input({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

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
          Positioned(
            top: 243,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '주에 ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 27,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SizedBox(
                    width: 74,
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        counterText: '',
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
                  ' 번 운동하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 27,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 449,
            left: 0,
            right: 0,
            child: Center(
              child: SpeechBubble(
                text: '목표가 있나요?',
                color: Colors.white,
                textColor: Colors.black87,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Confirm extends StatelessWidget {
  const _Step4Confirm({required this.target, required this.isSaving});

  final int? target;
  final bool isSaving;

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
          Positioned(
            top: 243,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '주에  $n 번  운동 하기',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 27,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 449,
            left: 0,
            right: 0,
            child: Center(
              child: SpeechBubble(
                text: '좋아요! 시작해볼까요?',
                color: Colors.white,
                textColor: Colors.black87,
                fontSize: 22,
              ),
            ),
          ),
          if (isSaving)
            const Align(
              alignment: Alignment(0, 0.78),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            ),
        ],
      ),
    );
  }
}

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.color = Colors.white,
    this.textColor = Colors.black87,
    this.radius = 10,
    this.tailWidth = 14,
    this.tailHeight = 10,
    this.tailAlignX = 0.0,
    this.fontSize = 16,
  });

  final String text;
  final Color color;
  final Color textColor;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailAlignX; // -1.0(왼쪽) ~ 1.0(오른쪽)
  final double fontSize;

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
        // 꼬리 높이만큼 아래 여백 추가
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + tailHeight),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.color,
    required this.radius,
    required this.tailWidth,
    required this.tailHeight,
    required this.tailAlignX,
  });

  final Color color;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailAlignX;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyHeight = size.height - tailHeight;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    final cx = (size.width / 2) + tailAlignX * (size.width / 2 - tailWidth);
    final left = cx - tailWidth / 2;
    final right = cx + tailWidth / 2;

    path.moveTo(left, bodyHeight);
    path.lineTo(cx, bodyHeight + tailHeight);
    path.lineTo(right, bodyHeight);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.25), 4, true);

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
