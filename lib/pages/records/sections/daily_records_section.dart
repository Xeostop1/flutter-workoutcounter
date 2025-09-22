// lib/pages/records/sections/daily_records_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/records_viewmodel.dart';

class DailyRecordsSection extends StatelessWidget {
  const DailyRecordsSection({super.key, this.embed = false});
  final bool embed; // 부모 스크롤에 붙여 넣기 모드

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final list = vm.recordsOfSelected();

    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 배지 등 필요 UI ...
          const SizedBox(height: 12),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/mascot_gray.png',
                    width: 81, fit: BoxFit.contain),
                const SizedBox(height: 12),
                const Text('진행한 운동이 없어요',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed('/counter'),
                  child: const Text('운동 기록 직접 추가'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: list.length,
      shrinkWrap: embed,
      physics: embed ? const NeverScrollableScrollPhysics() : null,
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (_, i) {
        final r = list[i];
        return ListTile(
          title: Text(r.routineTitle, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '총 ${r.totalReps}회 • ${r.date.hour}:${r.date.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }
}
