import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('만든이들'),
        centerTitle: true,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: _CreditsBody()),
    );
  }
}

class _CreditsBody extends StatelessWidget {
  const _CreditsBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        // 하단 "마스코트 존" 높이: 기기 비율에 따라 안전 범위로 산정
        final mascotZoneH = _mascotZoneHeight(w, h);
        final bubbleMaxW = w * 0.78;

        return Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: bubbleMaxW),
                        child: const _SpeechBubble(child: _BubbleText()),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 좌/우 이름 블록
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _PersonBlock(
                              roleLabel: '개발',
                              name: '하나',
                              email: 'hana@naver.com',
                              alignLeft: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _PersonBlock(
                              roleLabel: '디자인',
                              name: '나라',
                              email: 'lucy12q@naver.com',
                              alignLeft: false,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 👇 이름/이메일과 마스코트 사이: 정확히 100px 간격
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ===== 하단 마스코트 존 (화면 맨 아래에 붙임) =====
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // 맨 아래 고정
              height: mascotZoneH, // 계산된 높이
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 배경은 마스코트 존 내부에만
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bg_mascots.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),

                  // 상단으로 자연스럽게 어두워지는 그라디언트(위 컨텐츠와 연결)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 좌/우 마스코트 (하단에 '딱' 붙임: bottom padding 제거)
                  Positioned(
                    left: 0,
                    bottom: -50, // 👈 음수로 내려서 하단에서 잘리게
                    child: Image.asset(
                      'assets/images/development_mascots.png',
                      width: w * 0.48,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: -50, // 👈 동일하게 적용
                    child: Image.asset(
                      'assets/images/designer_mascots.png',
                      width: w * 0.48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 기기별로 마스코트가 '중간에서 잘리는' 문제 방지용 높이 계산
  double _mascotZoneHeight(double w, double h) {
    // 가로 기준 크기, 세로 기준 상한/하한을 두어 안전 영역 확보
    final byWidth = w * 0.86; // 기본 비율
    final minH = 240.0; // 너무 작지 않게
    final maxH = h * 0.46; // 너무 커서 잘리지 않게 (화면의 46% 이내)
    return byWidth.clamp(minH, maxH);
  }
}

/// 말풍선(하얀 배경 + 꼬리 + 그림자)
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 12.0;
    const tailW = 14.0;
    const tailH = 10.0;

    final r = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height - tailH),
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: const Radius.circular(radius),
      bottomRight: const Radius.circular(radius),
    );

    final path = Path()..addRRect(r);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 6, false);

    final paint = Paint()..color = Colors.white;
    canvas.drawRRect(r, paint);

    final tailPath = Path()
      ..moveTo(size.width / 2 - tailW / 2, size.height - tailH)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + tailW / 2, size.height - tailH)
      ..close();
    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 말풍선 내부 텍스트
class _BubbleText extends StatelessWidget {
  const _BubbleText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          color: Colors.black87,
          height: 1.4,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: '우린 당신의 '),
          TextSpan(
            text: '첫 운동 파트너',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: '이자\n가장 오래가는 '),
          TextSpan(
            text: '응원팀',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: '이에요'),
        ],
      ),
    );
  }
}

/// 역할칩 + 이름(같은 줄) + 이메일(아래 줄)
class _PersonBlock extends StatelessWidget {
  const _PersonBlock({
    required this.roleLabel,
    required this.name,
    required this.email,
    required this.alignLeft,
  });

  final String roleLabel;
  final String name;
  final String email;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final cross = alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Column(
      crossAxisAlignment: cross,
      children: [
        // 1줄: 역할칩 + 이름
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: alignLeft ? TextDirection.ltr : TextDirection.rtl,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 2줄: 이메일
        Text(
          email,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
