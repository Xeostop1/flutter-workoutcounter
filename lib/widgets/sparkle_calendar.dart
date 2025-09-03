// lib/widgets/sparkle_calendar.dart
import 'package:flutter/material.dart';

/// 날짜만 비교(시간 무시)
bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 스샷 느낌의 커스텀 달력
class SparkleCalendar extends StatefulWidget {
  const SparkleCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.initialMonth,
    this.completedDays = const {},
    this.scale = 0.92, // 달력 전체 크기 스케일
    this.stampAsset = 'assets/images/fire_stamp.png',
    this.stampScale = 1.0, // 불꽃(스탬프) 크기 스케일
    this.showTodayButton = true,
  });

  final DateTime selected; // 선택된 날짜
  final ValueChanged<DateTime> onSelected; // 날짜 탭 콜백
  final DateTime? initialMonth; // 처음 표시할 달
  final Set<DateTime> completedDays; // 완료된 날짜들 (날짜 단위만 사용)
  final double scale; // 달력 크기 스케일
  final String stampAsset; // 완료 스탬프 에셋 경로
  final double stampScale; // 완료 스탬프 크기 스케일
  final bool showTodayButton; // '오늘' 버튼 표시 여부

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
    final int lead = first.weekday % 7; // Sun:0, Mon:1, ... Sat:6
    final DateTime start = first.subtract(Duration(days: lead));
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
    const Color orange = Color(0xFFFF6B35);
    final double scale = widget.scale.clamp(0.7, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        14 * scale,
        16 * scale,
        16 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 헤더: <  2025.07   >   [오늘]
          Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Text(
                '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
                color: Colors.white.withOpacity(0.9),
              ),
              const Spacer(),
              if (widget.showTodayButton)
                TextButton(
                  onPressed: _goToday,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale,
                      vertical: 6 * scale,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                  ),
                  child: Text(
                    '오늘',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14 * scale,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8 * scale),

          // ===== 요일 행 (일~토)
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

          SizedBox(height: 10 * scale),

          // ===== 날짜 6x7 (레이아웃에 맞춰 셀 크기 계산)
          LayoutBuilder(
            builder: (context, constraints) {
              final double gap = 8.0 * scale;
              final double gridW = constraints.maxWidth;
              final double cellSize = (gridW - gap * 6) / 7;

              // 셀 내부에서 쓰는 수치들(전부 double 타입)
              final double selectDia = cellSize * 0.88;
              final double stampW = cellSize * (0.92 * widget.stampScale);
              final double stampH = stampW * 1.05;

              return GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12 * scale,
                crossAxisSpacing: gap,
                children: _days42().map((d) {
                  final bool selected = _sameDate(d, widget.selected);
                  final bool inMonth = _inMonth(d);
                  final bool done = _isCompleted(d);

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.onSelected(d),
                    child: SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // 완료 스탬프(가장 아래)
                          if (done)
                            Image.asset(
                              widget.stampAsset,
                              width: stampW,
                              height: stampH,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),

                          // 선택 원 (스탬프 위, 텍스트 아래)
                          if (selected)
                            Container(
                              width: selectDia,
                              height: selectDia,
                              decoration: const BoxDecoration(
                                color: orange,
                                shape: BoxShape.circle,
                              ),
                            ),

                          // 날짜 텍스트(맨 위, 항상 보이게)
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : (inMonth
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4)),
                              fontWeight: FontWeight.w800,
                              fontSize: 14 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
