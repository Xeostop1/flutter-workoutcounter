import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/routines_viewmodel.dart'; // RoutineOrder, VM

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();

    // 선택된 카테고리(UUID) 기준으로 정렬까지 적용된 목록을 가져온다.
    final String? catId =
        vm.selectedCategoryId ?? (vm.categories.isNotEmpty ? vm.categories.first.id : null);
    final list = (catId == null)
        ? vm.allRoutines
        : vm.routinesByCategoryIdOrdered(catId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        actions: [
          // 정렬 드롭다운
          DropdownButtonHideUnderline(
            child: DropdownButton<RoutineOrder>(
              value: vm.order,
              onChanged: (o) {
                if (o != null) vm.setOrder(o);
              },
              items: const [
                DropdownMenuItem(
                  value: RoutineOrder.recent,
                  child: Text('최근'),
                ),
                DropdownMenuItem(
                  value: RoutineOrder.favoriteFirst,
                  child: Text('즐겨찾기 먼저'),
                ),
                DropdownMenuItem(
                  value: RoutineOrder.titleAsc,
                  child: Text('이름순'),
                ),
                DropdownMenuItem(
                  value: RoutineOrder.titleDesc,
                  child: Text('이름역순'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 루틴 추가 화면으로 이동
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = list[i];
          final fav = vm.isFavorite(r.id);
          final firstName = r.items.isNotEmpty ? r.items.first.name : '운동';
          final restCount = (r.items.length - 1).clamp(0, 999);

          return ListTile(
            leading: IconButton(
              icon: Icon(fav ? Icons.star : Icons.star_border),
              onPressed: () => vm.toggleFavorite(r.id),
            ),
            title: Text(r.title),
            subtitle: Text('$firstName 외 $restCount개 운동'),
            trailing: const Icon(Icons.chevron_right),
            // 루틴을 선택하면 카운터 페이지로 바로 이동 (extra로 루틴 전달)
            onTap: () => context.push('/counter', extra: r),
          );
        },
      ),
    );
  }
}
