// lib/widgets/day_records_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_record.dart';
import '../viewmodels/records_viewmodel.dart';
import 'add_record_bottom_sheet.dart';

class DayRecordsBottomSheet extends StatelessWidget {
  const DayRecordsBottomSheet({
    super.key,
    required this.date,
    required this.records,
    this.onAddMemo,
  });

  final DateTime date;
  final List<WorkoutRecord> records;
  final VoidCallback? onAddMemo;

  @override
  Widget build(BuildContext context) {
    final memos = records.where((r) => r.kind == RecordKind.memo).toList();
    final workouts = records.where((r) => r.kind != RecordKind.memo).toList();

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    String dateLabel =
        '${date.year % 100}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF3F3F3F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // 날짜
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0x33FFFFFF)),
                const SizedBox(height: 12),

                // ===== 메모 섹션 =====
                Row(
                  children: [
                    const _SectionTitle('메모'),
                    const Spacer(),
                    if (onAddMemo != null)
                      TextButton.icon(
                        onPressed: onAddMemo,
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          '추가',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (memos.isEmpty)
                  const Text(
                    '메모가 없습니다.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  )
                else
                  Column(
                    children: memos.map((m) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 제목 + 수정 아이콘
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.routineTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      // 연필 아이콘 (편집)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.white70,
                                        ),
                                        splashRadius: 18,
                                        onPressed: () => _openEditMemoSheet(
                                          context,
                                          target: m,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((m.memo ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        m.memo!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0x22FFFFFF)),
                const SizedBox(height: 12),

                // ===== 운동 섹션 =====
                const _SectionTitle('운동'),
                const SizedBox(height: 8),
                if (workouts.isEmpty)
                  const Text(
                    '운동 기록이 없습니다.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  )
                else
                  Column(
                    children: workouts.map((r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.routineTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '총 ${r.totalReps}회',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF784F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditMemoSheet(
    BuildContext context, {
    required WorkoutRecord target,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddRecordBottomSheet(
          headerLabel: '기록 수정',
          submitLabel: '수정하기',
          initialTitle: target.routineTitle,
          initialContent: target.memo ?? '',
          onSubmit: (title, content) async {
            final records = context.read<RecordsViewModel>();
            final messenger = ScaffoldMessenger.of(context);
            await records.updateManualRecord(
              target,
              title: title,
              memo: content,
            );
            messenger.showSnackBar(
              const SnackBar(content: Text('메모가 수정되었습니다.')),
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}
