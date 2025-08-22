import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RecordCalendarCard extends StatelessWidget {
  final DateTime focused;
  final DateTime selected;
  final void Function(DateTime selected, DateTime focused) onSelected;
  final Color cardColor;
  final Color accent;
  final bool Function(DateTime) didWorkout; // VM의 didWorkout 전달
  const RecordCalendarCard({
    super.key,
    required this.focused,
    required this.selected,
    required this.onSelected,
    required this.cardColor,
    required this.accent,
    required this.didWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focused,
        selectedDayPredicate: (d) => isSameDay(d, selected),
        onDaySelected: (d, f) => onSelected(d, f),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          todayDecoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (!didWorkout(day)) return null;
            return const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Image(
                  image: AssetImage('assets/images/fire_stamp.png'),
                  width: 14,
                  height: 14,
                  filterQuality: FilterQuality.high,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
