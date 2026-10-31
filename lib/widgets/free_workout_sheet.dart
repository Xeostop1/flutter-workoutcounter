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
  final nameCtrl = TextEditingController();
  final setsCtrl = TextEditingController(text: tutorialMode ? '1' : '');
  final repsCtrl = TextEditingController(text: tutorialMode ? '5' : '');
  final secsCtrl = TextEditingController(text: tutorialMode ? '2' : '');

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
    final media = MediaQuery.of(context);
    final bodyHeight = (media.size.height - media.viewInsets.bottom - 220)
        .clamp(360.0, 592.0);

    return SizedBox(
      height: bodyHeight,
      child: ValueListenableBuilder<int>(
        valueListenable: tutorialStep,
        builder: (context, step, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: tutorialMode ? 104 : 0),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _textField(
                        nameCtrl,
                        hint: '운동명',
                        focusNode: nameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => setsFocus.requestFocus(),
                      ),
                      const SizedBox(height: 33),
                      _numberRow(
                        '세트 수',
                        setsCtrl,
                        '개',
                        focusNode: setsFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => repsFocus.requestFocus(),
                      ),
                      const SizedBox(height: 24),
                      _numberRow(
                        '횟수',
                        repsCtrl,
                        '회',
                        focusNode: repsFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => secsFocus.requestFocus(),
                      ),
                      const SizedBox(height: 24),
                      _numberRow(
                        '1회당 걸리는 시간',
                        secsCtrl,
                        '초',
                        focusNode: secsFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onStart(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 54,
                        width: 137,
                        child: FilledButton(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6335),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '시작하기',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tutorialMode) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 120,
                  child: Center(
                    child: _GuideBubble(
                      text: step == 0
                          ? '내 방식대로\n운동을 입력해요'
                          : '오늘은 간단하게\n1세트만 진행할까요?',
                    ),
                  ),
                ),
                if (step == 1)
                  const Positioned(
                    right: 54,
                    bottom: 98,
                    child: _TapHandIcon(),
                  ),
                const Positioned(
                  right: -30,
                  bottom: -90,
                  child: _Mascot(size: 210),
                ),
              ],
            ],
          );
        },
      ),
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
    textAlign: TextAlign.center,
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
      fillColor: const Color(0xFFFAFAFA),
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
            fontWeight: FontWeight.w700,
            fontSize: 18,
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            filled: true,
            fillColor: const Color(0xFFD2D2D2),
            suffixText: unit,
            suffixStyle: const TextStyle(
              color: Color(0xFF666666),
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

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF373737),
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(width: 12, height: 12, color: Colors.white),
        ),
      ],
    );
  }
}

class _TapHandIcon extends StatelessWidget {
  const _TapHandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.touch_app_rounded,
        color: Color(0xFF2E2E2E),
        size: 22,
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  const _Mascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Image.asset(
        'assets/images/charactor_login.png',
        width: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
