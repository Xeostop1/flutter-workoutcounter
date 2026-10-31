import 'package:flutter/material.dart';

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class SparkleCalendar extends StatefulWidget {
  const SparkleCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.initialMonth,
    this.completedDays = const {},
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final DateTime? initialMonth;
  final Set<DateTime> completedDays;

  @override
  State<SparkleCalendar> createState() => _SparkleCalendarState();
}

class _SparkleCalendarState extends State<SparkleCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final selected = widget.selected;
    _month = widget.initialMonth ?? DateTime(selected.year, selected.month);
  }

  @override
  void didUpdateWidget(covariant SparkleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.year != widget.selected.year ||
        oldWidget.selected.month != widget.selected.month) {
      _month = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month);
    final start = first.subtract(Duration(days: first.weekday % 7));
    final days = List.generate(42, (index) => start.add(Duration(days: index)));

    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFF686868)),
        SizedBox(
          height: 61,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left, size: 36),
              ),
              const SizedBox(width: 8),
              Text(
                '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right, size: 36),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: Row(
            children: [
              for (final label in ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE1E1E1),
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 294,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final day = days[index];
              final selected = _sameDate(day, widget.selected);
              final completed = widget.completedDays.any(
                (value) => _sameDate(value, day),
              );
              final today = _sameDate(day, DateTime.now());
              final inMonth = day.month == _month.month;

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onSelected(day),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (completed)
                      Image.asset(
                        'assets/images/fire_stamp.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      )
                    else if (selected || today)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF777777),
                          borderRadius: BorderRadius.circular(
                            selected ? 9 : 20,
                          ),
                        ),
                      ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: inMonth ? Colors.white : const Color(0xFFAAAAAA),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
