import 'package:flutter/material.dart';
import '../models/routine.dart';

class EditRoutineDialog extends StatefulWidget {
  final Routine routine;
  final void Function(Routine updatedRoutine) onConfirm;

  const EditRoutineDialog({
    super.key,
    required this.routine,
    required this.onConfirm,
  });

  @override
  State<EditRoutineDialog> createState() => _EditRoutineDialogState();
}

class _EditRoutineDialogState extends State<EditRoutineDialog> {
  late TextEditingController _nameController;
  late int _sets;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _sets = widget.routine.sets;
    _reps = widget.routine.reps;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('루틴 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '루틴 이름'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("세트 수:"),
              const SizedBox(width: 10),
              DropdownButton<int>(
                value: _sets,
                items: List.generate(10, (i) => i + 1)
                    .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _sets = value);
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text("반복 수:"),
              const SizedBox(width: 10),
              DropdownButton<int>(
                value: _reps,
                items: List.generate(10, (i) => (i + 1) * 5)
                    .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _reps = value);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final updated = Routine(
              name: _nameController.text.trim(),
              sets: _sets,
              reps: _reps,
            );
            widget.onConfirm(updated);
            Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
