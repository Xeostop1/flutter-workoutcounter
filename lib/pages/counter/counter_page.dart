import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/gradient_circular_counter.dart';
import '../../widgets/counter_controls.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutinesViewModel>();
    final vm = context.watch<CounterViewModel>();

    final selected = routines.selected ?? routines.allRoutines.first;
    if (vm.routine == null || vm.routine!.id != selected.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CounterViewModel>().attachRoutine(selected);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(selected.title)),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text(vm.isResting ? '휴식' : selected.primary.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GradientCircularCounter(progress: vm.progress, size: 240),
                const SizedBox(height: 8),
                Text('${vm.setNow} Set / ${vm.totalSets}'),
                if (!vm.isResting) Text('${vm.repNow} / ${vm.repsPerSet} 회'),
              ]),
            ),
          ),
          CounterControls(
            onStartPause: () => context.read<CounterViewModel>().startPause(),
            onStop: () => context.read<CounterViewModel>().stop(),
            onReset: () => context.read<CounterViewModel>().reset(),
            isRunning: vm.isRunning,
            isResting: vm.isResting,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
