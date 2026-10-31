import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/streak_viewmodel.dart';
import '../../widgets/flame_avatar.dart';
import '../../widgets/weekly_goal_card.dart';

class CharacterRoomPage extends StatefulWidget {
  const CharacterRoomPage({super.key});
  @override
  State<CharacterRoomPage> createState() => _CharacterRoomPageState();
}

class _CharacterRoomPageState extends State<CharacterRoomPage> {
  bool _expanded = false;
  bool _revealPending = false;
  final _growthKey = GlobalKey();

  void _toggleGrowth() {
    setState(() {
      _expanded = !_expanded;
      _revealPending = _expanded;
    });
    if (_expanded && MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealGrowth());
    }
  }

  void _revealGrowth() {
    if (!_revealPending || !_expanded || !mounted) return;
    _revealPending = false;
    final target = _growthKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = context.select<StreakViewModel, int>((vm) => vm.day);
    final stage = context.select<StreakViewModel, int>((vm) => vm.flameStage);
    final growth = _expanded
        ? Padding(
            key: _growthKey,
            padding: const EdgeInsets.only(top: 14),
            child: _GrowthStrip(stage: stage),
          )
        : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        leading: IconButton(
          tooltip: '돌아가기',
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 600;
            final heroSize = math.min(
              constraints.maxWidth - 32,
              compact ? 210.0 : 280.0,
            );
            return SingleChildScrollView(
              key: const ValueKey('character-room-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        const Text(
                          '나의 불씨',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D2D23),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Day $day',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9B77),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D4),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            '오늘도 함께 움직여볼까요?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF25211B),
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(18, 12),
                          painter: _BubbleTail(),
                        ),
                        Semantics(
                          image: true,
                          label: '현재 나의 불씨, Day $day',
                          child: FlameAvatar(
                            key: const ValueKey('room-current-flame'),
                            stage: stage,
                            size: heroSize,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 8 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WeeklyGoalCard(
                            footer: Semantics(
                              expanded: _expanded,
                              child: TextButton(
                                key: const ValueKey('toggle-growth'),
                                onPressed: _toggleGrowth,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  minimumSize: const Size(44, 52),
                                  foregroundColor: const Color(0xFFF4F4F6),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        '성장 과정 보기',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _expanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (MediaQuery.disableAnimationsOf(context))
                            growth
                          else
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              // The final scroll extent is committed after layout.
                              onEnd: () => WidgetsBinding.instance
                                  .addPostFrameCallback((_) => _revealGrowth()),
                              child: growth,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GrowthStrip extends StatefulWidget {
  const _GrowthStrip({required this.stage});
  final int stage;
  @override
  State<_GrowthStrip> createState() => _GrowthStripState();
}

class _GrowthStripState extends State<_GrowthStrip> {
  final _scroll = ScrollController();
  bool _centerPending = true;

  @override
  void didUpdateWidget(covariant _GrowthStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) _centerPending = true;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelHeight = MediaQuery.textScalerOf(context).scale(11) * 1.4;
    return SizedBox(
      height: 84 + labelHeight,
      child: LayoutBuilder(
        builder: (_, constraints) {
          if (_centerPending) {
            _centerPending = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_scroll.hasClients) return;
              _scroll.jumpTo(
                (FlameArtwork.index(widget.stage) * 84 -
                        (constraints.maxWidth - 84) / 2)
                    .clamp(0.0, _scroll.position.maxScrollExtent),
              );
            });
          }
          return ListView.builder(
            key: const ValueKey('flame-growth-list'),
            controller: _scroll,
            primary: false,
            scrollDirection: Axis.horizontal,
            itemExtent: 84,
            itemCount: FlameArtwork.stages.length,
            itemBuilder: (_, index) {
              final stage = FlameArtwork.stages[index];
              final current = stage == widget.stage.clamp(-2, 10);
              return Semantics(
                image: true,
                selected: current,
                label: '불씨 성장 모습 ${index + 1}${current ? ', 현재' : ''}',
                child: Column(
                  children: [
                    Container(
                      key: ValueKey('growth-stage-$stage'),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: current
                              ? const Color(0xFFFF895E)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: FlameAvatar(stage: stage, size: 72),
                    ),
                    const SizedBox(height: 4),
                    if (current)
                      const Text(
                        '현재',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF9B77),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = const Color(0xFFFFF0D4),
  );
  @override
  bool shouldRepaint(covariant _BubbleTail oldDelegate) => false;
}
