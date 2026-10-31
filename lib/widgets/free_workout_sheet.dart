import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import 'sheets/app_sheet.dart';

Future<bool> showFreeWorkoutSheet(
  BuildContext context, {
  bool tutorialMode = false,
}) async {
  final nameCtrl = TextEditingController(text: tutorialMode ? '' : '스쿼트');
  final setsCtrl = TextEditingController(text: tutorialMode ? '1' : '3');
  final repsCtrl = TextEditingController(text: tutorialMode ? '5' : '15');
  final secsCtrl = TextEditingController(text: '2');

  final nameFocus = FocusNode();
  final setsFocus = FocusNode();
  final repsFocus = FocusNode();
  final secsFocus = FocusNode();

  final tutorialStep = ValueNotifier<int>(tutorialMode ? 0 : -1);

  bool valid() {
    return nameCtrl.text.trim().isNotEmpty &&
        (int.tryParse(setsCtrl.text) ?? 0) > 0 &&
        (int.tryParse(repsCtrl.text) ?? 0) > 0 &&
        (int.tryParse(secsCtrl.text) ?? 0) > 0;
  }

  FocusNode? firstInvalidFocus() {
    if (nameCtrl.text.trim().isEmpty) return nameFocus;
    if ((int.tryParse(setsCtrl.text) ?? 0) <= 0) return setsFocus;
    if ((int.tryParse(repsCtrl.text) ?? 0) <= 0) return repsFocus;
    if ((int.tryParse(secsCtrl.text) ?? 0) <= 0) return secsFocus;
    return null;
  }

  void syncState() {
    final ok = valid();
    if (tutorialMode && ok && tutorialStep.value == 0) {
      tutorialStep.value = 1;
    }
  }

  for (final controller in [nameCtrl, setsCtrl, repsCtrl, secsCtrl]) {
    controller.addListener(syncState);
  }
  syncState();

  Routine buildRoutine() {
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();

    final ex = Exercise(
      id: 'FREE-$nowId',
      name: nameCtrl.text.trim(),
      sets: int.parse(setsCtrl.text),
      reps: int.parse(repsCtrl.text),
      repSeconds: int.parse(secsCtrl.text),
    );

    return Routine(
      id: 'FREE-$nowId',
      title: '자유 운동',
      categoryId: 'FREE',
      items: [ex],
    );
  }

  final routine = await showAppSheet<Routine>(
    context,
    title: '자유 운동 설정',
    child: _FreeWorkoutSheetBody(
      nameCtrl: nameCtrl,
      setsCtrl: setsCtrl,
      repsCtrl: repsCtrl,
      secsCtrl: secsCtrl,
      nameFocus: nameFocus,
      setsFocus: setsFocus,
      repsFocus: repsFocus,
      secsFocus: secsFocus,
      tutorialMode: tutorialMode,
      tutorialStep: tutorialStep,
      onStart: () {
        final invalidFocus = firstInvalidFocus();
        if (invalidFocus != null) {
          invalidFocus.requestFocus();
          return;
        }
        Navigator.of(context).pop(buildRoutine());
      },
    ),
  );

  for (final controller in [nameCtrl, setsCtrl, repsCtrl, secsCtrl]) {
    controller.removeListener(syncState);
    controller.dispose();
  }
  nameFocus.dispose();
  setsFocus.dispose();
  repsFocus.dispose();
  secsFocus.dispose();
  tutorialStep.dispose();

  if (routine == null) return false;

  if (context.mounted) {
    context.go('/counter', extra: routine);
  }
  return true;
}

class _FreeWorkoutSheetBody extends StatelessWidget {
  const _FreeWorkoutSheetBody({
    required this.nameCtrl,
    required this.setsCtrl,
    required this.repsCtrl,
    required this.secsCtrl,
    required this.nameFocus,
    required this.setsFocus,
    required this.repsFocus,
    required this.secsFocus,
    required this.tutorialMode,
    required this.tutorialStep,
    required this.onStart,
  });

  final TextEditingController nameCtrl;
  final TextEditingController setsCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController secsCtrl;
  final FocusNode nameFocus;
  final FocusNode setsFocus;
  final FocusNode repsFocus;
  final FocusNode secsFocus;
  final bool tutorialMode;
  final ValueNotifier<int> tutorialStep;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tutorialMode) ...[
          const Text(
            '처음에는 가볍게 1세트부터 시작해보세요.',
            style: TextStyle(color: Color(0xFF9B9EA8), fontSize: 14),
          ),
          const SizedBox(height: 20),
        ],
        _textField(
          nameCtrl,
          hint: '운동명',
          focusNode: nameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => setsFocus.requestFocus(),
        ),
        const SizedBox(height: 24),
        _numberRow(
          '세트 수',
          setsCtrl,
          '개',
          focusNode: setsFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => repsFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _numberRow(
          '횟수',
          repsCtrl,
          '회',
          focusNode: repsFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => secsFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _numberRow(
          '1회당 걸리는 시간',
          secsCtrl,
          '초',
          focusNode: secsFocus,
          onSubmitted: (_) => secsFocus.unfocus(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onStart, child: const Text('시작하기')),
        ),
      ],
    );
  }
}

Widget _textField(
  TextEditingController controller, {
  required String hint,
  FocusNode? focusNode,
  TextInputAction textInputAction = TextInputAction.done,
  ValueChanged<String>? onSubmitted,
}) {
  return TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    onTap: () => controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    ),
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFBDBDBD),
        fontWeight: FontWeight.w600,
      ),
      fillColor: const Color(0xFF272A30),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _numberRow(
  String label,
  TextEditingController c,
  String unit, {
  FocusNode? focusNode,
  TextInputAction textInputAction = TextInputAction.done,
  ValueChanged<String>? onSubmitted,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
      SizedBox(
        width: 79,
        height: 38,
        child: TextField(
          controller: c,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onTap: () => c.selection = TextSelection(
            baseOffset: 0,
            extentOffset: c.text.length,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFFE8E9EC),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            filled: true,
            fillColor: const Color(0xFF272A30),
            suffixText: unit,
            suffixStyle: const TextStyle(
              color: Color(0xFFE8E9EC),
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    ],
  );
}
