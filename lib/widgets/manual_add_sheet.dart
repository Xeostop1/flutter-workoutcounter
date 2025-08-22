import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/record_viewmodel.dart';

class ManualAddRecordSheet {
  /// 수동 추가 바텀시트 열기
  static Future<void> show(
    BuildContext context, {
    required DateTime selectedDate,
    VoidCallback? onSaved,
  }) async {
    final rec = context.read<RecordViewModel>();
    final nameCtl = TextEditingController();
    final setCtl = TextEditingController(text: '1');
    final repCtl = TextEditingController(text: '10');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: _ManualForm(
            nameCtl: nameCtl,
            setCtl: setCtl,
            repCtl: repCtl,
            onSubmit: () {
              final name = nameCtl.text.trim();
              final sets = int.tryParse(setCtl.text) ?? 0;
              final reps = int.tryParse(repCtl.text) ?? 0;
              if (name.isEmpty || sets <= 0 || reps <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('이름/세트/횟수를 확인하세요')),
                );
                return;
              }
              if (sets > 100 || reps > 200) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(const SnackBar(content: Text('허용 범위를 초과했어요')));
                return;
              }

              Navigator.pop(ctx, true);

              // 선택 날짜의 현재 시간으로 기록
              final now = DateTime.now();
              final saveAt = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                now.hour,
                now.minute,
                now.second,
              );

              rec.saveWorkout(
                dateTime: saveAt,
                routineId: _slug(name),
                routineName: name,
                sets: sets,
                repsPerSet: reps,
              );
            },
          ),
        );
      },
    );

    if (ok == true) onSaved?.call();
  }

  static String _slug(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

class _ManualForm extends StatelessWidget {
  final TextEditingController nameCtl;
  final TextEditingController setCtl;
  final TextEditingController repCtl;
  final VoidCallback onSubmit;
  const _ManualForm({
    required this.nameCtl,
    required this.setCtl,
    required this.repCtl,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운동 수동 추가',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        _Field(label: '운동명', controller: nameCtl, hint: '예) 스쿼트', maxLen: 20),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumberField(label: '세트(최대 100)', controller: setCtl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(label: '횟수(최대 200)', controller: repCtl),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A2B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int? maxLen;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLen,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2B2B2B),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: label,
      controller: controller,
      hint: '숫자',
    ).copyWithNumberKeyboard();
  }
}

extension on _Field {
  Widget copyWithNumberKeyboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '숫자',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2B2B2B),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
