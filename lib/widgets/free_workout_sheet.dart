import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../viewmodels/counter_viewmodel.dart';
import 'sheets/app_sheet.dart';

Future<void> showFreeWorkoutSheet(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final setsCtrl = TextEditingController(text: '3');
  final repsCtrl = TextEditingController(text: '20');
  final secsCtrl = TextEditingController(text: '2');

  bool valid() =>
      nameCtrl.text.trim().isNotEmpty &&
      (int.tryParse(setsCtrl.text) ?? 0) > 0 &&
      (int.tryParse(repsCtrl.text) ?? 0) > 0;

  void start() {
    if (!valid()) return;
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    final ex = Exercise(
      id: 'FREE-$nowId',
      name: nameCtrl.text.trim(),
      sets: int.parse(setsCtrl.text),
      reps: int.parse(repsCtrl.text),
      repSeconds: int.tryParse(secsCtrl.text) ?? 0,
    );
    final routine = Routine(
      id: 'FREE-$nowId',
      title: '자유 운동',
      categoryId: 'FREE',
      items: [ex],
    );
    final cvm = context.read<CounterViewModel>();
    cvm.attachRoutine(routine);
    Navigator.of(context).pop(); // 시트 닫기
    context.go('/counter', extra: routine);
  }

  await showAppSheet<void>(
    context,
    title: '자유 운동 설정',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _textField(nameCtrl, hint: '운동명을 입력해주세요.'),
        const SizedBox(height: 18),
        _numberRow('세트 수', setsCtrl, '개'),
        const SizedBox(height: 12),
        _numberRow('횟수', repsCtrl, '회'),
        const SizedBox(height: 12),
        _numberRow('1회당 걸리는 시간', secsCtrl, '초'),
      ],
    ),
    primaryButton: SizedBox(
      height: 48,
      width: 160,
      child: FilledButton(
        onPressed: () => start(),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '시작하기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );
}

Widget _textField(TextEditingController c, {required String hint}) {
  return TextField(
    controller: c,
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFBDBDBD),
        fontWeight: FontWeight.w600,
      ),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _numberRow(String label, TextEditingController c, String unit) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      SizedBox(
        width: 92,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            filled: true,
            fillColor: Colors.white.withOpacity(0.18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          unit,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
