import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../view_models/routine_viewmodel.dart';

class RoutineAddScreen extends StatefulWidget {
  const RoutineAddScreen({super.key});

  @override
  State<RoutineAddScreen> createState() => _RoutineAddScreenState();
}

class _RoutineAddScreenState extends State<RoutineAddScreen> {
  final _nameController = TextEditingController();
  int _sets = 3;
  int _reps = 10;

  final viewModel = RoutineViewModel();

  void _saveRoutine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("루틴 이름을 입력해주세요")),
      );
      return;
    }

    final newRoutine = Routine(name: name, sets: _sets, reps: _reps);
    await viewModel.saveRoutine(newRoutine);

    if (mounted) {
      Navigator.pop(context); // 저장 후 이전 화면으로
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '루틴 이름'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('세트 수'),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: _sets,
                  onChanged: (value) => setState(() => _sets = value!),
                  items: List.generate(10, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('반복 횟수'),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: _reps,
                  onChanged: (value) => setState(() => _reps = value!),
                  items: List.generate(20, (i) => (i + 1) * 5)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveRoutine,
              child: const Text('저장'),
            )
          ],
        ),
      ),
    );
  }
}
