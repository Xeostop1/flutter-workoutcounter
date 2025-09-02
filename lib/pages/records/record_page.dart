// lib/pages/records/record_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/records_viewmodel.dart';
import '../../models/workout_record.dart';
import '../../widgets/sparkle_calendar.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  /// VM의 기록을 바탕으로 완료된 날짜 Set 생성
  Set<DateTime> _completedFromVm(RecordsViewModel vm, DateTime center) {
    final out = <DateTime>{};
    DateTime monthAt(int off) => DateTime(center.year, center.month + off, 1);

    for (int m = -3; m <= 3; m++) {
      final month = monthAt(m);
      final days = DateUtils.getDaysInMonth(month.year, month.month);
      for (int d = 1; d <= days; d++) {
        final day = DateTime(month.year, month.month, d);
        if (vm.hasAnyOn(day)) {
          out.add(DateTime(day.year, day.month, day.day));
        }
      }
    }
    return out;
  }

  /// 기록이 하나도 없을 때 보여줄 “더미 마커”
  Set<DateTime> _demoMarkers(DateTime today) {
    final y = today.year, m = today.month, d = today.day;
    // 화면에 보기 좋게 흩뿌려서 표시
    final candidates = <DateTime>{
      DateTime(y, m, 1),
      DateTime(y, m, 3),
      DateTime(y, m, 7),
      DateTime(y, m, 12),
      DateTime(y, m, 15),
      DateTime(y, m, d),            // 오늘
      DateTime(y, m, d - 2),
      DateTime(y, m, d + 2),
      DateTime(y, m, 28),
    };
    // 달 범위를 벗어나는 날짜는 제거
    return candidates
        .where((dt) => dt.month == m && dt.day >= 1)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final selected = vm.selectedDay;

    // 1) VM에서 마커 수집
    var completedDays = _completedFromVm(vm, selected);

    // 2) 아무 기록도 없으면 “더미 마커” 주입
    if (completedDays.isEmpty) {
      completedDays = _demoMarkers(DateTime.now());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // ⭐ 커스텀 달력 (완료 마커 전달)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SparkleCalendar(
              selected: selected,
              completedDays: completedDays,
              onSelected: (d) => vm.selectDay(d),
            ),
          ),

          const Divider(height: 1),

          // 선택된 날짜의 기록 리스트
          Expanded(
            child: Builder(
              builder: (_) {
                final List<WorkoutRecord> list = vm.recordsOfSelected();
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('진행한 운동이 없어요'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/counter'),
                          child: const Text('운동 카운터로 가기'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            // TODO: 직접 추가 폼으로 이동
                          },
                          child: const Text('운동 기록 직접 추가'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = list[i];
                    final hh = r.date.hour.toString().padLeft(2, '0');
                    final mm = r.date.minute.toString().padLeft(2, '0');
                    return ListTile(
                      title: Text(r.routineTitle),
                      subtitle: Text('총 ${r.totalReps}회 • $hh:$mm'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
