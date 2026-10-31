import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/routine.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({
    super.key,
    required this.routines,
    required this.onPlay,
    this.emptyTargetLink,
    this.compact = false,
  });

  final List<Routine> routines;
  final ValueChanged<Routine> onPlay;
  final LayerLink? emptyTargetLink;
  final bool compact;

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  int _page = 0;

  int get _pageCount => (widget.routines.length / 3).ceil();

  @override
  void didUpdateWidget(covariant RoutineList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= _pageCount) _page = (_pageCount - 1).clamp(0, 1 << 20);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routines.isEmpty) {
      Widget addButton = Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFF303030),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Color(0xFF777777), size: 40),
      );
      if (widget.emptyTargetLink case final link?) {
        addButton = CompositedTransformTarget(link: link, child: addButton);
      }

      return InkWell(
        onTap: () => context.push('/routines'),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 184),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              addButton,
              const SizedBox(height: 20),
              const Text(
                '루틴이 비어있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB8BBC5),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '루틴을 등록하고 운동을 시작해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9B9EA8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final visibleRows = widget.routines.length >= 3
        ? 3
        : widget.routines.length;
    final textScaler = MediaQuery.textScalerOf(context);
    final rowHeight =
        ((textScaler.scale(22) * 1.2).ceilToDouble() +
                (textScaler.scale(15) * 1.2).ceilToDouble() +
                25)
            .clamp(widget.compact ? 72.0 : 98.0, double.infinity);
    final listHeight = visibleRows * rowHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            height: listHeight,
            child: PageView.builder(
              itemCount: _pageCount,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, page) {
                final start = page * 3;
                final end = (start + 3).clamp(0, widget.routines.length);
                final routines = widget.routines.sublist(start, end);
                return Column(
                  children: [
                    for (var index = 0; index < routines.length; index++)
                      _RoutineRow(
                        routine: routines[index],
                        height: rowHeight,
                        showDivider: index < routines.length - 1,
                        onPlay: () => widget.onPlay(routines[index]),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_pageCount > 1) ...[
            SizedBox(height: widget.compact ? 12 : 17),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? Colors.white
                        : const Color(0xFF737373),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.routine,
    required this.height,
    required this.showDivider,
    required this.onPlay,
  });

  final Routine routine;
  final double height;
  final bool showDivider;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          InkWell(
            onTap: () => context.push('/routines/edit/${routine.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _summary(routine),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '${routine.title} 시작',
                    onPressed: onPlay,
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFFFF642D),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 40),
                  ),
                ],
              ),
            ),
          ),
          if (showDivider)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(height: 1, color: Color(0xFF30333A)),
            ),
        ],
      ),
    );
  }
}

String _summary(Routine routine) {
  if (routine.items.isEmpty) return '운동 없음';
  if (routine.items.length == 1) return routine.items.first.name;
  return '${routine.items.first.name} 외 ${routine.items.length - 1}개의 운동';
}
