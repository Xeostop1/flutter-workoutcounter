// lib/widgets/repeat_count_buttons.dart
import 'package:flutter/material.dart';

class RepeatCountButtons extends StatelessWidget {
  final int selectedValue;
  final ValueChanged<int> onChanged;


  const RepeatCountButtons({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> countList = List.generate(20, (index) => (index + 1) * 5);

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
              children: countList.map((count) {
                bool isSelected = false;
                if (selectedValue == count) {
                  isSelected = true;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ElevatedButton(
                    onPressed: () {
                      onChanged(count); //바깥에서 준 함수 호출
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.black : Colors.grey,
                    ),
                    child: Text(
                      '$count회',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}