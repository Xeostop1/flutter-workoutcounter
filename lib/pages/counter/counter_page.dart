import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../widgets/circular_counter.dart';
import '../routine/routine_edit_page.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.routine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutineEditPage(initial: vm.routine),
                ),
              );
              if (updated != null) {
                vm.routine = updated;
                vm.reset();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  vm.routine.name,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),

              // 원형 카운터
              CircularCounter(progress: vm.progress, resting: vm.isResting),

              const SizedBox(height: 24),
              Text(
                "${vm.currentSet} Set",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                "${vm.currentRep} / ${vm.routine.reps} 회",
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const Spacer(),

              // 컨트롤 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundBtn(icon: Icons.replay, onTap: vm.reset),
                  _RoundBtn(
                    icon: vm.isRunning && !vm.isPaused
                        ? Icons.pause
                        : Icons.play_arrow,
                    onTap: vm.isRunning && !vm.isPaused ? vm.pause : vm.start,
                  ),
                  _RoundBtn(icon: Icons.stop, onTap: vm.stop),
                ],
              ),
              const SizedBox(height: 12),

              // 루틴 미리보기 태그
              Wrap(
                spacing: 8,
                children: [
                  _Chip(
                    "${vm.routine.name}",
                    "${vm.routine.sets} set ${vm.routine.reps} 회",
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(icon, size: 28),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String title;
  final String sub;
  const _Chip(this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            sub,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
