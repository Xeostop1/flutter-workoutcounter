import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/routines_viewmodel.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    final list = vm.allRoutines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: vm.order,
              items: const [
                DropdownMenuItem(value: '최근', child: Text('최근')),
                DropdownMenuItem(value: '즐겨찾기', child: Text('즐겨찾기 먼저')),
                DropdownMenuItem(value: '이름순', child: Text('이름순')),
              ],
              onChanged: (v) => vm.setOrder(v ?? '최근'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // 루틴 추가(추후)
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = list[i];
          return ListTile(
            leading: IconButton(
              icon: Icon(r.favorite ? Icons.star : Icons.star_border),
              onPressed: () => vm.toggleFavorite(r.id),
            ),
            title: Text(r.title),
            subtitle: Text('${r.items.first.name} 외 ${r.items.length - 1 >= 0 ? r.items.length - 1 : 0}개 운동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/routines/${r.id}'),
          );
        },
      ),
    );
  }
}
