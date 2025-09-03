// lib/pages/records/sections/calendar_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/records_viewmodel.dart';
import '../../../widgets/sparkle_calendar.dart';

/// 캘린더 섹션: 상단 헤더 + SparkleCalendar
class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final selected = vm.selectedDay;

    // 현재 달의 42칸 구간 계산
    final month = DateTime(selected.year, selected.month, 1);
    final lead = month.weekday % 7; // Sun=0
    final start = month.subtract(Duration(days: lead));
    final days42 = List.generate(
      42,
      (i) => DateTime(start.year, start.month, start.day + i),
    );

    // 완료된 날짜만 Set으로 전달(날짜 단위만 비교)
    final completed = <DateTime>{
      for (final d in days42)
        if (vm.hasAnyOn(d)) DateTime(d.year, d.month, d.day),
    };

    return SparkleCalendar(
      selected: selected,
      initialMonth: month,
      completedDays: completed,
      onSelected: vm.selectDay,

      // ⬇️ density 대신 scale로 달력 전체 크기 조절 (0.7~1.2 권장)
      scale: 0.88, // 조금 더 컴팩트하게
      stampScale: 1.15, // 불꽃 마커는 살짝 크게
    );
  }
}
