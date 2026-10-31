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

    return Container(
      constraints: const BoxConstraints(minHeight: 201),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF5A5A5A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _formatDate(vm.selectedDay),
                style: const TextStyle(fontSize: 17, color: Color(0xFFF2F2F2)),
              ),
              const Spacer(),
              if (records.isNotEmpty)
                InkWell(
                  onTap: () => _openAddSheet(context, vm.selectedDay),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.add, size: 25, color: Color(0xFFD0D0D0)),
                  ),
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
              Text(
                record.routineTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                child: Image.asset(
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
                detail: '${exercise.sets} set / ${exercise.reps} 회',
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
        Text(
          detail,
          style: const TextStyle(fontSize: 16, color: Color(0xFFF0F0F0)),
        ),
      ],
    );
  }
}
