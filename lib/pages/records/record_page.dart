import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../models/workout_record.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final selected = vm.selectedDay;

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          TableCalendar<WorkoutRecord>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selected,
            selectedDayPredicate: (d) => isSameDay(d, selected),
            onDaySelected: (d, f) => vm.selectDay(d),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (vm.hasAnyOn(day)) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset('assets/images/flame.png', width: 16),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: Builder(
              builder: (_) {
                final list = vm.recordsOfSelected();
                if (list.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('진행한 운동이 없어요'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pushNamed('/counter'),
                        child: const Text('운동 카운터로 가기'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {}, // 직접 추가 폼(추가 예정)
                        child: const Text('운동 기록 직접 추가'),
                      ),
                    ]),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(list[i].routineTitle),
                    subtitle: Text('총 ${list[i].totalReps}회 • ${list[i].date.hour}:${list[i].date.minute.toString().padLeft(2,'0')}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
