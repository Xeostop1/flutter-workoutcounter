// lib/widgets/home/routine_list.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../viewmodels/routines_viewmodel.dart';

class RoutineList extends StatelessWidget {
  const RoutineList({
    super.key,
    required this.routines,
    required this.onPlay,
  });

  final List<Routine> routines;
  final void Function(Routine) onPlay;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return _emptyCard(
        context,
        text: '저장된 루틴이 없어요',
        onTap: () => context.push('/routines'),
      );
    }

    // 세로 리스트 + 항목 사이 Divider (홈 스샷 스타일)
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: routines.length,
      separatorBuilder: (_, __) => const Divider(
        height: 24,
        thickness: 1,
        color: Color(0x22FFFFFF),
      ),
      itemBuilder: (context, i) {
        final r = routines[i];
        final summary = r.items.isEmpty
            ? '운동 없음'
            : '${r.items.first.name} 외 ${r.items.length - 1}개의 운동';

        return InkWell(
          onTap: () => context.push('/routines/${r.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목/요약
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 우측 재생 버튼 (배경 없이 에셋만)
              _PlayButton(onPressed: () => onPlay(r)),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCard(BuildContext context,
      {required String text, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// play_icon 이미지(배경/원형 제거)
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Image.asset(
              'assets/images/play_icon.png', // 에셋 경로 맞춰주세요
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
