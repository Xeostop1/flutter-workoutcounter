import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/records_viewmodel.dart';
import '../../../widgets/sparkle_calendar.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final selected = vm.selectedDay;
    final month = DateTime(selected.year, selected.month, 1);
    final days = _visibleDays(month);
    final completedDays = _completedDays(vm, days);

    return SparkleCalendar(
      selected: selected,
      initialMonth: month,
      completedDays: completedDays,
      onSelected: vm.selectDay,
    );
  }

  List<DateTime> _visibleDays(DateTime month) {
    final leadingDays = month.weekday % 7; // 일요일 시작
    final start = month.subtract(Duration(days: leadingDays));
    return List.generate(
      42,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  Set<DateTime> _completedDays(RecordsViewModel vm, List<DateTime> days) {
    return {
      for (final day in days)
        if (vm.hasAnyOn(day)) DateTime(day.year, day.month, day.day),
    };
  }
}
