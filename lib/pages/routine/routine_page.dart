import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/routine_viewmodel.dart';
import 'routine_edit_page.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutineViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        actions: [
          PopupMenuButton<String>(
            initialValue: vm.sort,
            onSelected: (v) {
              vm.sort = v;
              vm.notifyListeners();
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'favorite', child: Text('즐겨찾기')),
              PopupMenuItem(value: 'name', child: Text('이름순')),
              PopupMenuItem(value: 'recent', child: Text('최근등록순')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoutineEditPage()),
          );
          if (r != null) await vm.upsert(r);
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: vm.sorted
            .map(
              (r) => Card(
                child: ListTile(
                  leading: Icon(
                    r.favorite ? Icons.star_rounded : Icons.star_border,
                  ),
                  title: Text(r.name),
                  subtitle: Text('총 ${r.sets}개의 운동 · ${r.reps}회'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineEditPage(initial: r),
                      ),
                    );
                    if (updated != null) await vm.upsert(updated);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
