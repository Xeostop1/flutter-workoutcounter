// lib/pages/home/sections/saved_routines_strip.dart  ← 새 파일로 두면 깔끔
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/routine.dart';
import '../../../viewmodels/routines_viewmodel.dart' as rvm;

class SavedRoutinesStrip extends StatelessWidget {
  const SavedRoutinesStrip({super.key, this.onlyFavorites = false});

  /// true면 즐겨찾기만 노출(전역 필터와 별개로, 홈 섹션만 따로 제한하고 싶을 때)
  final bool onlyFavorites;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<rvm.RoutinesViewModel>();

    // 전역 필터 적용된 리스트에서 홈 섹션 정책만 추가로 걸러도 되고
    // 필요 없으면 그냥 vm.filteredItems 그대로 사용해도 됨.
    List<Routine> list = vm.filteredItems;
    if (onlyFavorites) {
      list = list.where((r) => r.favorite).toList();
    }

    if (list.isEmpty) {
      return _emptyCard(
        context,
        text: onlyFavorites ? '즐겨찾기한 루틴이 없어요' : '저장된 루틴이 없어요',
        onAdd: () => context.push('/routines'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀 + 즐겨찾기 토글(전역)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '저장된 루틴',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              // 전역 “즐겨찾기만 보기” 토글 버튼(홈에서도 동일하게)
              IconButton(
                tooltip: vm.favOnly ? '즐겨찾기만 보기 해제' : '즐겨찾기만 보기',
                icon: Icon(vm.favOnly ? Icons.star_rounded : Icons.star_outline_rounded),
                color: vm.favOnly ? const Color(0xFFFF6B35) : Colors.white70,
                onPressed: () => context.read<rvm.RoutinesViewModel>().toggleFavOnly(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 가로 스크롤 카드 리스트
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RoutineCard(routine: list[i]),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(BuildContext context, {required String text, VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onAdd,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);

    return Material(
      color: Colors.white, // 카드 흰색
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/routines/${routine.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // 뒤 배경에 살짝 그라데이션 느낌 추가하고 싶으면 아래 주석 해제
            // gradient: const LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [Color(0xFFFFE1CF), Color(0xFFFFC2B0)],
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 행: 제목 + ⭐ 토글
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    tooltip: routine.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                    onPressed: () => context.read<rvm.RoutinesViewModel>().toggleFavorite(routine.id),
                    icon: Icon(
                      Icons.star_rounded,
                      color: routine.favorite ? orange : const Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 요약
              Text(
                routine.items.isEmpty
                    ? '운동 없음'
                    : '${routine.items.first.name} 외 ${routine.items.length - 1}개',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6C6C6C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // 시작 버튼
              Align(
                alignment: Alignment.bottomRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    minimumSize: const Size(88, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.push('/routines/${routine.id}'),
                  child: const Text(
                    '보기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
