// lib/widgets/sparkle_calendar.dart
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
    final sel = widget.selected;
    _month = widget.initialMonth ?? DateTime(sel.year, sel.month, 1);
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
  void _goToday() {
    final now = DateTime.now();
    setState(() => _month = DateTime(now.year, now.month, 1));
    widget.onSelected(DateTime(now.year, now.month, now.day));
  }

  List<DateTime> _days42() {
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday % 7; // Sun=0
    final start = first.subtract(Duration(days: lead));
    return List.generate(42, (i) {
      final d = start.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  bool _inMonth(DateTime d) => d.month == _month.month;
  bool _isCompleted(DateTime d) =>
      widget.completedDays.any((e) => _sameDate(e, d));

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6B35);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                color: Colors.white70,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: _goToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  '오늘',
                  style: TextStyle(fontWeight: FontWeight.w800, height: 1.0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ===== Week labels =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekLabel('일'),
              _WeekLabel('월'),
              _WeekLabel('화'),
              _WeekLabel('수'),
              _WeekLabel('목'),
              _WeekLabel('금'),
              _WeekLabel('토'),
            ],
          ),

          const SizedBox(height: 12),

          // ===== Grid (square cells) =====
          LayoutBuilder(
            builder: (context, c) {
              const hGap = 10.0;
              const vGap = 18.0;
              final totalHGap = hGap * 6;
              final cell = (c.maxWidth - totalHGap) / 7;

              return SizedBox(
                height: cell * 6 + vGap * 5,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: hGap,
                    mainAxisSpacing: vGap,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (_, i) {
                    final d = _days42()[i];
                    final selected = _sameDate(d, widget.selected);
                    final inMonth = _inMonth(d);
                    final isToday = _sameDate(d, DateTime.now());
                    final done = _isCompleted(d);

                    return _DayCell(
                      day: d.day,
                      selected: selected,
                      inMonth: inMonth,
                      isToday: isToday,
                      done: done,
                      onTap: () => widget.onSelected(d),
                      orange: orange,
                      cellSize: cell, // <<< 셀 크기 전달(스탬프 사이즈 계산용)
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.inMonth,
    required this.isToday,
    required this.done,
    required this.onTap,
    required this.orange,
    required this.cellSize,
  });

  final int day;
  final bool selected, inMonth, isToday, done;
  final VoidCallback onTap;
  final Color orange;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? Colors.black
        : (inMonth ? Colors.white : Colors.white.withOpacity(0.45));

    // 불방울 스탬프 크기(셀 크기에 비례)
    final stampW = cellSize * 0.8;
    final stampH = cellSize * 0.8;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ✅ 완료 스탬프: "먼저" 그려서 숫자보다 아래 레이어에 위치
          if (done)
            Positioned(
              // bottom: -cellSize * 0.0, // 살짝 아래로 내려 깔기
              child: Image.asset(
                'assets/images/fire_stamp.png', // <- 너가 가진 불방울 이미지
                width: stampW,
                height: stampH,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),

          // 선택 배경(둥근 사각형, 숫자보다 아래)
          if (selected)
            Container(
              width: cellSize * 0.88,
              height: cellSize * 0.88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

          // 오늘 배경(연한 회색)
          if (!selected && isToday)
            Container(
              width: cellSize * 0.80,
              height: cellSize * 0.80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

          // ✅ 날짜 숫자: 항상 최상단에 배치 → 스탬프 위로 또렷하게 보임
          Text(
            '$day',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: cellSize * 0.42,
              height: 1.0,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w800,
          height: 1.0,
          fontSize: 14,
        ),
      ),
    );
  }
}
