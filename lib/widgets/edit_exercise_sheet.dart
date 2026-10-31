import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import 'sheets/app_sheet.dart';

Future<Exercise?> showEditExerciseSheet(
  BuildContext context, {
  required Exercise initial,
}) async {
  final nameCtrl = TextEditingController(text: initial.name);
  final setsCtrl = TextEditingController(text: '${initial.sets}');
  final repsCtrl = TextEditingController(text: '${initial.reps}');
  final secsCtrl = TextEditingController(text: '${initial.repSeconds}');

  final nameFocus = FocusNode();
  final setsFocus = FocusNode();
  final repsFocus = FocusNode();
  final secsFocus = FocusNode();
  final canSubmit = ValueNotifier<bool>(false);

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
    canSubmit.value = valid();
  }

  for (final c in [nameCtrl, setsCtrl, repsCtrl, secsCtrl]) {
    c.addListener(syncState);
  }
  syncState();

  final result = await showAppSheet<Exercise>(
    context,
    title: '\uC790\uC720 \uC6B4\uB3D9 \uC124\uC815',
    child: _EditExerciseSheetBody(
      nameCtrl: nameCtrl,
      setsCtrl: setsCtrl,
      repsCtrl: repsCtrl,
      secsCtrl: secsCtrl,
      nameFocus: nameFocus,
      setsFocus: setsFocus,
      repsFocus: repsFocus,
      secsFocus: secsFocus,
      canSubmit: canSubmit,
      onSubmit: () {
        final invalid = firstInvalidFocus();
        if (invalid != null) {
          invalid.requestFocus();
          return;
        }
        Navigator.of(context).pop(
          initial.copyWith(
            name: nameCtrl.text.trim(),
            sets: int.parse(setsCtrl.text),
            reps: int.parse(repsCtrl.text),
            repSeconds: int.parse(secsCtrl.text),
          ),
        );
      },
    ),
  );

  for (final c in [nameCtrl, setsCtrl, repsCtrl, secsCtrl]) {
    c.removeListener(syncState);
    c.dispose();
  }
  nameFocus.dispose();
  setsFocus.dispose();
  repsFocus.dispose();
  secsFocus.dispose();
  canSubmit.dispose();

  return result;
}

class _EditExerciseSheetBody extends StatelessWidget {
  const _EditExerciseSheetBody({
    required this.nameCtrl,
    required this.setsCtrl,
    required this.repsCtrl,
    required this.secsCtrl,
    required this.nameFocus,
    required this.setsFocus,
    required this.repsFocus,
    required this.secsFocus,
    required this.canSubmit,
    required this.onSubmit,
  });

  final TextEditingController nameCtrl;
  final TextEditingController setsCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController secsCtrl;
  final FocusNode nameFocus;
  final FocusNode setsFocus;
  final FocusNode repsFocus;
  final FocusNode secsFocus;
  final ValueNotifier<bool> canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: canSubmit,
      builder: (context, enabled, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _nameField(
              nameCtrl,
              focusNode: nameFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => setsFocus.requestFocus(),
            ),
            const SizedBox(height: 18),
            _numberRow(
              '\uC138\uD2B8 \uC218',
              setsCtrl,
              '\uAC1C',
              focusNode: setsFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => repsFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            _numberRow(
              '\uD69F\uC218',
              repsCtrl,
              '\uD68C',
              focusNode: repsFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => secsFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            _numberRow(
              '1\uD68C\uB2F9 \uAC78\uB9AC\uB294 \uC2DC\uAC04',
              secsCtrl,
              '\uCD08',
              focusNode: secsFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: 136,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: enabled
                      ? const Color(0xFFFF784F)
                      : const Color(0xFF7A7A7A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '\uC218\uC815',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

Widget _nameField(
  TextEditingController controller, {
  FocusNode? focusNode,
  TextInputAction textInputAction = TextInputAction.done,
  ValueChanged<String>? onSubmitted,
}) {
  return TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xFF262626),
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
    decoration: InputDecoration(
      fillColor: const Color(0xFFF2F2F2),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      SizedBox(
        width: 72,
        child: TextField(
          controller: c,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            filled: true,
            fillColor: const Color(0xFFE6E6E6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          unit,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}
