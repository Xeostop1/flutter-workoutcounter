import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/workout_record.dart';
import '../../../viewmodels/records_viewmodel.dart';
import '../../../widgets/add_record_bottom_sheet.dart';

class DailyRecordsSection extends StatelessWidget {
  const DailyRecordsSection({super.key, this.embed = false});

  final bool embed;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final records = vm.recordsOfSelected();

    if (embed && records.isEmpty) {
      return Container(
        key: const ValueKey('empty-day-records'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E23),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(vm.selectedDay),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB8BBC4),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text('진행한 운동이 없어요.', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _openAddSheet(context, vm.selectedDay),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFFFF9B77),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('기록 추가', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: embed ? null : const BoxConstraints(minHeight: 201),
      padding: embed
          ? const EdgeInsets.all(12)
          : const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: embed ? const Color(0xFF1C1E23) : const Color(0xFF5A5A5A),
        borderRadius: embed
            ? BorderRadius.circular(14)
            : const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(vm.selectedDay),
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFFF2F2F2),
                  ),
                ),
              ),
              if (records.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openAddSheet(context, vm.selectedDay),
                  icon: const Icon(Icons.add, size: 18),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9B77),
                  ),
                  label: const Text('기록 추가', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFF9A9A9A)),
          const SizedBox(height: 10),
          if (records.isEmpty)
            _EmptyRecords(onAdd: () => _openAddSheet(context, vm.selectedDay))
          else
            for (var index = 0; index < records.length; index++) ...[
              if (index > 0) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFF8A8A8A)),
                const SizedBox(height: 10),
              ],
              _RecordBlock(
                record: records[index],
                onEdit: records[index].kind == RecordKind.memo
                    ? () => _openEditSheet(context, records[index])
                    : null,
              ),
            ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime day) {
    final year = (day.year % 100).toString().padLeft(2, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year.$month.$date';
  }

  static void _openAddSheet(BuildContext context, DateTime date) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecordBottomSheet(
        onSubmit: (title, content) async {
          await context.read<RecordsViewModel>().addManualRecord(
            date: date,
            title: title,
            memo: content,
          );
        },
      ),
    );
  }

  static void _openEditSheet(BuildContext context, WorkoutRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecordBottomSheet(
        headerLabel: '기록 수정',
        submitLabel: '수정하기',
        initialTitle: record.routineTitle,
        initialContent: record.memo,
        onSubmit: (title, content) async {
          await context.read<RecordsViewModel>().updateManualRecord(
            record,
            title: title,
            memo: content,
          );
        },
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '진행한 운동이 없어요.',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 38),
        Center(
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(28),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '기록 수동 추가',
                  style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 19),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF555555),
                  child: Icon(Icons.add, color: Color(0xFFB8B8B8), size: 32),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordBlock extends StatelessWidget {
  const _RecordBlock({required this.record, this.onEdit});

  final WorkoutRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (record.kind == RecordKind.memo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.routineTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '기록 수정',
                onPressed: onEdit,
                icon: Image.asset(
                  'assets/icons/icon-edit.png',
                  width: 18,
                  height: 18,
                  color: const Color(0xFFCFCFCF),
                ),
              ),
            ],
          ),
          if ((record.memo ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '  •   ${record.memo}',
              style: const TextStyle(fontSize: 16, color: Color(0xFFE1E1E1)),
            ),
          ],
        ],
      );
    }

    final plannedReps = record.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets * exercise.reps,
    );
    final showTotalOnly =
        record.exercises.isEmpty || record.totalReps != plannedReps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          record.routineTitle,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        if (!showTotalOnly) ...[
          const SizedBox(height: 6),
          Text(
            '총 ${record.totalReps}회 · ${record.exercises.length}개 운동',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBABDC6)),
          ),
        ],
        const SizedBox(height: 14),
        if (showTotalOnly)
          _ExerciseRow(
            name: record.exercises.isEmpty ? '운동' : '진행한 운동',
            detail: '총 ${record.totalReps}회',
          )
        else
          for (final exercise in record.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ExerciseRow(
                name: exercise.name,
                detail: '${exercise.sets}세트 · ${exercise.reps}회',
              ),
            ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, color: Color(0xFFE8E8E8)),
          ),
        ),
        Flexible(
          child: Text(
            detail,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: Color(0xFFF0F0F0)),
          ),
        ),
      ],
    );
  }
}
