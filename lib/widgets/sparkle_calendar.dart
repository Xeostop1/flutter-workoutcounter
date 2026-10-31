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
    final leading = first.weekday % 7;
    final weekCount =
        ((leading + DateTime(first.year, first.month + 1, 0).day) / 7).ceil();
    final days = List.generate(
      weekCount * 7,
      (index) => DateTime(first.year, first.month, 1 - leading + index),
    );
    final cellHeight =
        (MediaQuery.textScalerOf(context).scale(15) * 1.25).ceilToDouble() + 12;
    final dayHeight = cellHeight < 44 ? 44.0 : cellHeight;
    final markedDates = {
      for (final day in widget.completedDays)
        DateTime(day.year, day.month, day.day),
    };
    final compactButton = IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 308),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: '이전 달',
                  style: compactButton,
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left, size: 24),
                ),
                Expanded(
                  child: Text(
                    '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  style: compactButton,
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right, size: 24),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFFFF9B77),
                  ),
                  onPressed: () {
                    final today = DateTime.now();
                    setState(() => _month = DateTime(today.year, today.month));
                    widget.onSelected(today);
                  },
                  child: const Text('오늘', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  for (final label in ['일', '월', '화', '수', '목', '금', '토'])
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE1E1E1),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: weekCount * dayHeight,
              child: GridView.builder(
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: dayHeight,
                ),
                itemBuilder: (_, index) {
                  final day = days[index];
                  final selected = _sameDate(day, widget.selected);
                  final completed = markedDates.contains(day);
                  final today = _sameDate(day, DateTime.now());
                  final inMonth = day.month == _month.month;
                  final stampHeight = dayHeight - 8;

                  return Semantics(
                    key: ValueKey<DateTime>(day),
                    label:
                        '${day.year}년 ${day.month}월 ${day.day}일${today ? ', 오늘' : ''}${completed ? ', 운동 기록 있음' : ''}',
                    button: true,
                    selected: selected,
                    excludeSemantics: true,
                    onTap: () => widget.onSelected(day),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onSelected(day),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (today)
                            SizedBox.square(
                              key: ValueKey('calendar-today-$day'),
                              dimension: 40,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF777777),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          if (completed)
                            Image.asset(
                              'assets/images/fire_cal.png',
                              key: ValueKey('workout-stamp-$day'),
                              width: stampHeight * 25 / 27,
                              height: stampHeight,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              color: inMonth ? null : const Color(0xFFBDBDBD),
                              excludeFromSemantics: true,
                            ),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: completed || today || inMonth
                                  ? Colors.white
                                  : const Color(0xFF9B9EA8),
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (selected && !today)
                            Positioned(
                              bottom: 1,
                              child: Container(
                                key: ValueKey('calendar-selection-$day'),
                                width: 16,
                                height: 2,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF9B77),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
