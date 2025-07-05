import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_viewmodel.dart';

class RoutineList extends StatelessWidget {
  const RoutineList({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RoutineViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '저장된 루틴',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...viewModel.routines.map((routine) {
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(routine.name),
            subtitle: Text('${routine.sets}세트 · ${routine.reps}회'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        }).toList(),
      ],
    );
  }
}
