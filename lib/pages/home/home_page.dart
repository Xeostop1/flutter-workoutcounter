import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/routines_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('운동')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => context.go('/counter'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('루틴 없이 운동하기'),
          ),
          const SizedBox(height: 16),
          const Text('저장된 루틴'),
          const SizedBox(height: 8),
          ...vm.allRoutines.map((r) => Card(
            child: ListTile(
              title: Text(r.title),
              subtitle: Text('${r.items.first.name} 외 ${r.items.length - 1 >= 0 ? r.items.length - 1 : 0}개'),
              trailing: IconButton(
                icon: Icon(r.favorite ? Icons.star : Icons.star_border),
                onPressed: () => vm.toggleFavorite(r.id),
              ),
              onTap: () { vm.select(r); context.go('/counter'); },
            ),
          )),
        ],
      ),
    );
  }
}
