import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/routine_favorite_action.dart';

class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    final routine = vm.getById(routineId);
    final isFavorite = vm.isFavorite(routineId);

    if (routine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('루틴')),
        body: const Center(child: Text('루틴을 찾을 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            ),
            color: isFavorite ? const Color(0xFFFF6B35) : Colors.white70,
            onPressed: () => saveRoutineFavorite(
              context,
              () => vm.toggleFavorite(routineId),
            ),
            tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('운동 목록', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...routine.items.map(
            (exercise) => ListTile(
              title: Text(exercise.name),
              subtitle: Text(
                '${exercise.sets}세트 • ${exercise.reps}회 • 1회 ${exercise.repSeconds}초',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<CounterViewModel>().attachRoutine(routine);
              context.push('/counter', extra: routine);
            },
            child: const Text('이 루틴으로 운동 시작'),
          ),
        ],
      ),
    );
  }
}
