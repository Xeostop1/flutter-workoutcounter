import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showWorkoutCompletedDialog(
  BuildContext context, {
  Duration visibleFor = const Duration(milliseconds: 1400),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Semantics(
        button: true,
        label: '운동 완료 확인',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(dialogContext),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Stamp(),
                SizedBox(height: 20),
                Text(
                  '운동을 완수했어요!',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '달력에 도장을 찍어드렸어요',
                  style: TextStyle(color: Color(0xFF303030), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  final timer = Timer(visibleFor, () {
    if (open && navigator.mounted && navigator.canPop()) navigator.pop();
  });
  await dialog;
  open = false;
  timer.cancel();
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF8A66), width: 2),
            ),
            alignment: Alignment.center,
            child: Image.asset('assets/images/fire_stamp.png', width: 34),
          ),
          Positioned(
            right: 5,
            top: 0,
            child: Transform.rotate(
              angle: -0.72,
              child: const Icon(
                Icons.brush_rounded,
                color: Color(0xFF9B7964),
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
