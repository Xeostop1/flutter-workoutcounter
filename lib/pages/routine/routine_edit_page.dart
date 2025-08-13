import 'package:flutter/material.dart';
import '../../models/routine.dart';

class RoutineEditPage extends StatefulWidget {
  final Routine? initial;
  const RoutineEditPage({super.key, this.initial});

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  late TextEditingController name;
  late int sets;
  late int reps;
  late double sec;

  @override
  void initState() {
    super.initState();
    final r =
        widget.initial ??
        Routine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '운동명',
        );
    name = TextEditingController(text: r.name);
    sets = r.sets;
    reps = r.reps;
    sec = r.secPerRep;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('편집')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Field(
              title: '운동명',
              child: TextField(controller: name),
            ),
            const SizedBox(height: 12),
            _StepperField(
              title: '세트 수',
              value: sets,
              onChanged: (v) => setState(() => sets = v),
            ),
            _StepperField(
              title: '횟수',
              value: reps,
              onChanged: (v) => setState(() => reps = v),
            ),
            _StepperField(
              title: '1회당 걸리는 시간(초)',
              value: sec.round(),
              onChanged: (v) => setState(() => sec = v.toDouble()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final r =
                    (widget.initial ??
                            Routine(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: '',
                            ))
                        .copyWith(
                          name: name.text,
                          sets: sets,
                          reps: reps,
                          secPerRep: sec,
                        );
                Navigator.pop(context, r);
              },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String title;
  final Widget child;
  const _Field({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(title)),
        Expanded(child: child),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  const _StepperField({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return _Field(
      title: title,
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(value > 1 ? value - 1 : 1),
            icon: const Icon(Icons.remove),
          ),
          Text('$value 회'),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
