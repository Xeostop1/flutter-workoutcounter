import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/workout_record.dart';
import '../../../viewmodels/records_viewmodel.dart';
import '../../../widgets/sparkle_calendar.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final selected = vm.selectedDay;
    final month = DateTime(selected.year, selected.month, 1);
    // Keep markers available when the calendar browses beyond the selected month.
    final completedDays = {
      for (final record in vm.records)
        if (record.kind == RecordKind.workout && record.totalReps > 0)
          DateTime(record.date.year, record.date.month, record.date.day),
    };

    return SparkleCalendar(
      selected: selected,
      initialMonth: month,
      completedDays: completedDays,
      onSelected: vm.selectDay,
    );
  }
}
