import 'package:flutter/material.dart';

import 'confirm_popup.dart';

Future<bool?> showEndWorkoutDialog(BuildContext context) =>
    showConfirmPopup(context, title: '운동을 끝낼까요?', message: '진행한 운동까지만 기록돼요');
