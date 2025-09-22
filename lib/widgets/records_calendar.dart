import 'package:flutter/material.dart';

/// 캘린더 셀에 오버레이(완료 도장)를 띄울 날짜 집합과
/// 운동을 한 날짜(오렌지 원) 집합을 받아 UI로 그려주는 위젯.
/// - 요일 시작: 일요일
/// - 6주(7x6) 고정 그리드
class RecordsCalendar extends StatefulWidget {
  /// 오렌지 원으로 칠해질 날짜(해당 일에 운동 기록 존재)
  final Set<DateTime> workoutDays;

  /// 빨간 도장 오버레이(해당 일에 루틴 100% 완료)
  final Set<DateTime> fullyCompletedDays;

  /// 날짜 선택 콜백(선택 시 하단 리스트 등 갱신 용도)
  final ValueChanged<DateTime>? onDaySelected;

  const RecordsCalendar({
    super.key,
    this.workoutDays = const {},
    this.fullyCompletedDays = const {},
    this.onDaySelected,
  });

  @override
  State<RecordsCalendar> createState() => _RecordsCalendarState();
}

class _RecordsCalendarState extends State<RecordsCalendar> {
  DateTime _focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final firstOfMonth = DateTime(_focused.year, _focused.month, 1);
    final startOffset = firstOfMonth.weekday % 7; // Sun=7 -> 0
    final gridStart = firstOfMonth.subtract(Duration(days: startOffset));
    final days = List<DateTime>.generate(
      42,
          (i) => DateTime(gridStart.year, gridStart.month, gridStart.day + i),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 상단 헤더 (이전/다음, YYYY.MM, 오늘) =====
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focused = DateTime(_focused.year, _focused.month - 1, 1);
                });
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_focused.year}.${_two(_focused.month)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _focused = DateTime.now();
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('오늘'),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focused = DateTime(_focused.year, _focused.month + 1, 1);
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 4),
        Divider(color: Colors.white.withOpacity(0.12), height: 1),
        const SizedBox(height: 8),

        // ===== 요일 헤더 =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Weekday('일'), _Weekday('월'), _Weekday('화'), _Weekday('수'),
              _Weekday('목'), _Weekday('금'), _Weekday('토'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ===== 날짜 그리드 (7x6) =====
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (_, i) {
            final day = days[i];
            final isOutside = day.month != _focused.month;
            final isToday = _isSameDay(day, DateTime.now());

            final didWorkout = _contains(widget.workoutDays, day);
            final fullyDone = _contains(widget.fullyCompletedDays, day);

            return _DayCell(
              day: day,
              isOutside: isOutside,
              isToday: isToday,
              didWorkout: didWorkout,
              fullyDone: fullyDone,
              onTap: () => widget.onDaySelected?.call(day),
              colorScheme: cs,
            );
          },
        ),
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _contains(Set<DateTime> set, DateTime d) {
    for (final x in set) {
      if (_isSameDay(x, d)) return true;
    }
    return false;
  }
}

class _Weekday extends StatelessWidget {
  final String text;
  const _Weekday(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isOutside;
  final bool isToday;
  final bool didWorkout; // 오렌지 원
  final bool fullyDone;  // 빨간 도장
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _DayCell({
    required this.day,
    required this.isOutside,
    required this.isToday,
    required this.didWorkout,
    required this.fullyDone,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final orange = const Color(0xFFFF6B35);

    final textColor = isOutside
        ? Colors.white.withOpacity(0.35)
        : (didWorkout ? Colors.white : Colors.white.withOpacity(0.9));

    final border = isToday
        ? Border.all(color: Colors.white.withOpacity(0.7), width: 1.2)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 날짜 원(오렌지 채움 or 투명)
          Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: didWorkout ? orange : Colors.transparent,
                shape: BoxShape.circle,
                border: border == null ? null : Border.fromBorderSide(border.top),
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),

          // 완료-도장(빨간 이미지) 오버레이
          if (fullyDone)
            Positioned(
              right: -6,
              bottom: -10,
              child: IgnorePointer(
                child: Image.asset(
                  // 프로젝트 에셋에 맞게 파일만 교체하세요.
                  'assets/images/stamp_done_red.png',
                  width: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
