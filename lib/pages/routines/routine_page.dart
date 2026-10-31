import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/routine_favorite_action.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    final routines = vm.items;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: vm.loadError != null
          ? _RoutineLoadError(onRetry: vm.retryLoad)
          : vm.isLoading && routines.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : routines.isEmpty
          ? const _RoutineEmptyView()
          : SafeArea(bottom: false, child: _RoutineList(routines: routines)),
      floatingActionButton: vm.loadError == null && !vm.isLoading
          ? Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: _AddRoutineButton(
                onTap: () => context.push('/routines/create'),
              ),
            )
          : null,
    );
  }
}

class _RoutineLoadError extends StatelessWidget {
  const _RoutineLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('루틴을 불러오지 못했어요.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (routines.length == 1)
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 28, right: 43),
              child: Text(
                '최신순',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey('routine_list'),
            padding: EdgeInsets.only(
              top: routines.length == 1 ? 24 : 37,
              bottom: 120,
            ),
            itemCount: routines.length,
            itemBuilder: (_, index) => _RoutineRow(
              routine: routines[index],
              showDivider: index < routines.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.routine, required this.showDivider});

  final Routine routine;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6633);
    final textScaler = MediaQuery.textScalerOf(context);
    final height =
        ((textScaler.scale(22) * 1.4).ceilToDouble() +
                (textScaler.scale(14) * 1.4).ceilToDouble() +
                (textScaler.scale(13) * 1.4).ceilToDouble() +
                45)
            .clamp(115.0, double.infinity);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 20),
                    onPressed: () => saveRoutineFavorite(
                      context,
                      () => context.read<RoutinesViewModel>().toggleFavorite(
                        routine.id,
                      ),
                    ),
                    icon: Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: routine.favorite
                          ? orange
                          : const Color(0xFFBDBDBD),
                    ),
                    tooltip: routine.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/routines/edit/${routine.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _summaryText(routine),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _dateText(routine.updatedAt ?? routine.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: () =>
                        context.push('/routines/edit/${routine.id}'),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                    tooltip: '${routine.title} 수정',
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 13,
              child: Divider(height: 1, color: Color(0xFF515151)),
            ),
        ],
      ),
    );
  }
}

class _RoutineEmptyView extends StatelessWidget {
  const _RoutineEmptyView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final bubbleWidth = (229 * textScaler.scale(22) / 22).clamp(
          0.0,
          constraints.maxWidth - 32,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: _SpeechBubble.message,
            style: DefaultTextStyle.of(
              context,
            ).style.merge(_SpeechBubble.textStyle),
          ),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        )..layout(maxWidth: bubbleWidth - 16);
        final bubbleHeight = (textPainter.height + 33).clamp(
          107.0,
          double.infinity,
        );
        textPainter.dispose();
        final safeTop = MediaQuery.paddingOf(context).top;
        final contentHeight = (bubbleHeight + safeTop + 120).clamp(
          constraints.maxHeight,
          double.infinity,
        );
        final maxTop = (contentHeight - bubbleHeight - 120).clamp(
          safeTop,
          double.infinity,
        );
        final bubbleTop = (contentHeight / 2).clamp(safeTop, maxTop);

        return SingleChildScrollView(
          child: SizedBox(
            height: contentHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: (constraints.maxWidth - bubbleWidth) / 2,
                  top: bubbleTop,
                  width: bubbleWidth,
                  child: const _SpeechBubble(),
                ),
                const Positioned(
                  left: 0,
                  bottom: -80,
                  child: IgnorePointer(
                    child: Image(
                      image: AssetImage('assets/images/routine_mascot.png'),
                      width: 248,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  static const message = '루틴을 등록하고\n운동을 시작 해보세요';
  static const textStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.65,
  );

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BubblePainter(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 107),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(8, 11, 8, 22),
          child: Text(message, textAlign: TextAlign.center, style: textStyle),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7A7A7A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height - 11),
        const Radius.circular(11),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2 - 8, size.height - 11)
        ..lineTo(size.width / 2 + 8, size.height - 11)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddRoutineButton extends StatelessWidget {
  const _AddRoutineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '루틴 추가',
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 72,
            height: 72,
            child: Icon(Icons.add, color: Color(0xFFFF6633), size: 48),
          ),
        ),
      ),
    );
  }
}

String _dateText(DateTime? date) {
  if (date == null) return '';
  final year = (date.year % 100).toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

String _summaryText(Routine routine) {
  if (routine.items.isEmpty) return '운동 없음';
  if (routine.items.length == 1) return routine.items.first.name;
  return '${routine.items.first.name} 외 ${routine.items.length - 1}개의 운동';
}
