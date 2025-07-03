import 'package:flutter/material.dart';

class SavedRoutineTile extends StatelessWidget {
  final String title;
  final int sets;
  final int reps;
  final VoidCallback onTap;

  const SavedRoutineTile({
    super.key,
    required this.title,
    required this.sets,
    required this.reps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$sets세트 · $reps회'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
