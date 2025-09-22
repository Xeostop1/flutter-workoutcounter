// lib/pages/routines/routine_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/routines_viewmodel.dart';
import '../../models/routine.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final rvm = context.watch<RoutinesViewModel>();
    final List<Routine> list = rvm.filteredItems; // ← 전역 필터 적용

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        centerTitle: true,
        actions: [
          // ⭐ 전역 즐겨찾기만 보기 토글
          IconButton(
            tooltip: rvm.favOnly ? '즐겨찾기만 보기 해제' : '즐겨찾기만 보기',
            icon: Icon(rvm.favOnly ? Icons.star_rounded : Icons.star_outline_rounded),
            color: rvm.favOnly ? const Color(0xFFFF6B35) : Colors.white70,
            onPressed: () => context.read<RoutinesViewModel>().toggleFavOnly(),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: list.isEmpty
          ? (rvm.favOnly ? const _FavoritesEmptyView() : const _RoutineEmptyView())
          : _RoutineList(modelList: list),

      floatingActionButton: _AddFab(
        onPressed: () async {
          final id = await context.read<RoutinesViewModel>().createDraft();
          // if (context.mounted) context.push('/routines/edit/$id');
          if (context.mounted) context.push('/routines/create');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.modelList});
  final List<Routine> modelList;

  String _dateText(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year % 100;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: modelList.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 24, thickness: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (context, i) {
        final r = modelList[i];
        final dateText = _dateText(r.updatedAt ?? r.createdAt);
        final summary = r.items.isEmpty
            ? '운동 없음'
            : '${r.items.first.name} 외 ${r.items.length - 1}개의 운동';

        return InkWell(
          onTap: () => context.push('/routines/${r.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ 즐겨찾기 토글
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 22,
                  onPressed: () =>
                      context.read<RoutinesViewModel>().toggleFavorite(r.id),
                  icon: Icon(
                    Icons.star_rounded,
                    color: r.favorite ? orange : const Color(0xFF6B6B6B),
                    size: 22,
                  ),
                  tooltip: r.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                ),
              ),
              const SizedBox(width: 8),

              // 텍스트들
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFCDCDCD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 빈 상태 (전체 루틴 없음)
class _RoutineEmptyView extends StatelessWidget {
  const _RoutineEmptyView();

  static const String _mascotPng = 'assets/images/routine_mascot.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
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
          left: -16,
          bottom: (bottomInset - 8).clamp(0.0, 100.0),
          child: IgnorePointer(
            child: Image.asset(
              _mascotPng,
              width: size.width * 0.45,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

/// 빈 상태 (즐겨찾기 필터에서 없음)
class _FavoritesEmptyView extends StatelessWidget {
  const _FavoritesEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '즐겨찾기한 루틴이 없어요.\n별 버튼으로 즐겨찾기를 추가해 보세요!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

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
          style: textStyle ??
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

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'routines_fab',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: const Icon(Icons.add, color: Color(0xFFFF6B35), size: 28),
    );
  }
}
