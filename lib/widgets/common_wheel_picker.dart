import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommonWheelPicker extends StatelessWidget {
  final List<int> values;
  final int selectedValue;
  final ValueChanged<int> onChanged;
  final String unitLabel;


  const CommonWheelPicker({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onChanged,
    required this.unitLabel,

  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 100,
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(
          initialItem: values.indexOf(selectedValue),
        ),
        itemExtent: 40,
        onSelectedItemChanged:(index){
          onChanged(values[index]);
        },
        children: values
            .map((value) => Center(
          child: Text('$value$unitLabel',
              style: const TextStyle(fontSize: 20)),
        ))
            .toList(),
      ),
    );
  }
}