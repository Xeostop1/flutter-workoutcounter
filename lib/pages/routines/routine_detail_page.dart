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
      appBar: AppBar(title: Text(r.title)),
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
              context.read<CounterViewModel>().attachRoutine(r); // ✅ 선택 반영
              context.push('/counter', extra: r);                // ✅ 카운터로 이동
            },
            child: const Text('이 루틴으로 운동 시작'),
          ),
        ],
      ),
    );
  }
}
