// lib/pages/routines/routine_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/routines_viewmodel.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  /// (남겨둠) 뷰모델 구조 몰라도 안전하게 꺼내는 헬퍼
  Iterable<dynamic> _extractListSafely(RoutinesViewModel vm) {
    final dyn = vm as dynamic;
    try {
      final candidate =
          dyn.routines ??
          dyn.items ??
          dyn.all ??
          dyn.list ??
          dyn.data ??
          dyn.routinesList;
      if (candidate is Iterable) return candidate;
    } catch (_) {}
    return const <dynamic>[];
  }

  // 하드코딩 목록(나중에 뷰모델 리스트로 교체하면 됨)
  static const _dummy = <_RoutineListItem>[
    _RoutineListItem(
      id: 'lower',
      title: '하체',
      summary: '스쿼트 외 4개의 운동',
      date: '25.06.19',
      favorite: true,
    ),
    _RoutineListItem(
      id: 'back',
      title: '등',
      summary: '데드리프트 외 4개의 운동',
      date: '25.06.17',
      favorite: true,
    ),
    _RoutineListItem(
      id: 'burpee',
      title: '버피',
      summary: '버피테스트 외 1개의 운동',
      date: '25.06.01',
      favorite: true,
    ),
    _RoutineListItem(
      id: 'shoulder',
      title: '어깨',
      summary: '사레레 외 2개의 운동',
      date: '25.06.19',
      favorite: false,
    ),
    _RoutineListItem(
      id: 'free',
      title: '자유 운동',
      summary: '러닝',
      date: '25.06.17',
      favorite: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // createDraft() 때문에 watch 유지
    context.watch<RoutinesViewModel>();
    const orange = Color(0xFFFF6B35);

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                final id = context.read<RoutinesViewModel>().createDraft();
                context.push('/routines/edit/$id');
              },
            ),
          ),
        ],
      ),

      // ▶ 스크린샷처럼 리스트로 표현
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _dummy.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 24, thickness: 1, color: Color(0x22FFFFFF)),
        itemBuilder: (context, i) {
          final item = _dummy[i];
          return InkWell(
            onTap: () => context.push('/routines/${item.id}'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 즐겨찾기 아이콘
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.star_rounded,
                    color: item.favorite ? orange : const Color(0xFF6B6B6B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),

                // 제목/요약/날짜
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCDCDCD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 오른쪽 chevron
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.chevron_right, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// (빈 상태용) “루틴을 등록하고 운동을 시작 해보세요”
class _RoutineEmptyView extends StatelessWidget {
  const _RoutineEmptyView();

  static const String _mascotPng = 'assets/images/routine_mascot.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final mascotWidth = (size.width * 0.08).clamp(200.0, 340.0).toDouble();

    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.05),
          child: _SpeechBubble(
            text: '루틴을 등록하고\n운동을 시작 해보세요',
            bubbleColor: const Color(0xFF9E9E9E),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ),
        Positioned(
          right: -16,
          bottom: -8 + bottomInset,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                _mascotPng,
                width: mascotWidth,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 220, height: 220),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 말풍선(꼬리 포함)
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.text,
    this.bubbleColor = const Color(0xFF9E9E9E),
    this.textStyle,
  });

  final String text;
  final Color bubbleColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color: bubbleColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style:
              textStyle ??
              const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, paint);

    final path = Path()
      ..moveTo(size.width / 2 - 10, size.height - 8)
      ..lineTo(size.width / 2 + 10, size.height - 8)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── 내부 전용 하드코딩 모델 ──
class _RoutineListItem {
  final String id;
  final String title;
  final String summary;
  final String date;
  final bool favorite;

  const _RoutineListItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.date,
    required this.favorite,
  });
}
