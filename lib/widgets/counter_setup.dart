import 'package:flutter/material.dart';

class CounterSetup extends StatelessWidget {
  final int selectedReps;
  final int selectedSets;
  final ValueChanged<int?> onRepsChanged;
  final ValueChanged<int?> onSetsChanged;

  const CounterSetup({
    super.key,
    required this.selectedReps,
    required this.selectedSets,
    required this.onRepsChanged,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '세트 설정',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDropdown(
              value: selectedReps,
              items: List.generate(50, (i) => i + 1),
              unit: '회',
              onChanged: onRepsChanged,
            ),
            const SizedBox(width: 12),
            _buildDropdown(
              value: selectedSets,
              items: List.generate(10, (i) => i + 1),
              unit: '세트',
              onChanged: onSetsChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<int> items,
    required String unit,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButton<int>(
        value: value,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text('$item$unit'),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
