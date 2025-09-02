// lib/widgets/sparkle_calendar.dart
import 'package:flutter/material.dart';

/// 날짜만 비교(시간 무시)
bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// UI를 스샷처럼 만든 커스텀 달력 위젯
class SparkleCalendar extends StatefulWidget {
  const SparkleCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.initialMonth,
    this.completedDays = const {}, // 완료일(오버레이)
  });

  final DateTime selected;                  // 선택된 날짜
  final ValueChanged<DateTime> onSelected;  // 날짜 탭 콜백
  final DateTime? initialMonth;             // 처음 표시할 달
  final Set<DateTime> completedDays;        // 완료된 날짜들(날짜 단위)

  @override
  State<SparkleCalendar> createState() => _SparkleCalendarState();
}

class _SparkleCalendarState extends State<SparkleCalendar> {
  late DateTime _month; // 현재 화면에 표시 중인 "달"(해당 달의 1일)

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
    // Dart weekday: Mon=1..Sun=7, 우리는 Sun부터 시작 → Sun=0으로 만들기
    final lead = first.weekday % 7; // Sun:0, Mon:1, ... Sat:6
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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: <  2025.07   >   [오늘]
          Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Text(
                '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              TextButton(
                onPressed: _goToday,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '오늘',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 요일 행 (일~토)
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

          const SizedBox(height: 10),

          // 날짜 6x7
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            children: _days42().map((d) {
              final selected = _sameDate(d, widget.selected);
              final inMonth = _inMonth(d);
              final done = _isCompleted(d);

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => widget.onSelected(d),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1) 선택 원(가장 뒤)
                    if (selected)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                        ),
                      ),

                    // 2) 완료 스탬프 (숫자 뒤에 가리지 않도록 숫자보다 먼저 그림)
                    if (done)
                      Positioned(
                        bottom: -2, // 살짝 아래로
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.95,
                            child: Image.asset(
                              'assets/images/fire_stamp.png',
                              width: 18, // 너무 크면 숫자와 겹치니 작게
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                    // 3) 날짜 숫자 (항상 맨 위)
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (inMonth
                            ? Colors.white
                            : Colors.white.withOpacity(0.4)),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
