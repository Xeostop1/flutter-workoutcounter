// lib/pages/records/sections/daily_records_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/records_viewmodel.dart';
import '../../../models/workout_record.dart';

class DailyRecordsSection extends StatelessWidget {
  const DailyRecordsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final List<WorkoutRecord> list = vm.recordsOfSelected();

    // 🔴 Expanded 제거! (부모에서 Expanded로 감싸세요)
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: list.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  _RecordTile(record: list[i]),
                  if (i != list.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('진행한 운동이 없어요'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/counter'),
              child: const Text('운동 카운터로 가기'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: 직접 추가 폼 연결
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              child: const Text('운동 기록 직접 추가'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final WorkoutRecord record;

  @override
  Widget build(BuildContext context) {
    final t = record.date;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      title: Text(
        record.routineTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('총 ${record.totalReps}회 • $hh:$mm'),
      onTap: () {
        // TODO: 기록 상세로 이동 연결 가능
      },
    );
  }
}
