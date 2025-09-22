// lib/pages/routines/routine_detail_page.dart
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import 'package:flutter/material.dart';

class RoutineDetailPage extends StatelessWidget {
  final String routineId;
  const RoutineDetailPage({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    final r = vm.allRoutines.firstWhere((e) => e.id == routineId);

    return Scaffold(
      appBar: AppBar(
        title: Text(r.title),
        centerTitle: true,
        actions: [
          Consumer<RoutinesViewModel>(
            builder: (_, rvm, __) {
              final isFav = rvm.isFavorite(routineId);
              return IconButton(
                icon: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded),
                color: isFav ? const Color(0xFFFF6B35) : Colors.white70,
                onPressed: () => rvm.toggleFavorite(routineId),
                tooltip: isFav ? '즐겨찾기 해제' : '즐겨찾기',
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('운동 목록', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...r.items.map((e) => ListTile(
            title: Text(e.name),
            subtitle: Text('${e.sets}세트 • ${e.reps}회 • 1회 ${e.repSeconds}초'),
          )),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<CounterViewModel>().attachRoutine(r);
              context.push('/counter', extra: r);
            },
            child: const Text('이 루틴으로 운동 시작'),
          ),
        ],
      ),
    );
  }
}
