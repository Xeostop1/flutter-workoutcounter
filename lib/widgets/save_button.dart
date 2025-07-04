import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/routine.dart';
import '../view_models/routine_viewmodel.dart';

class SaveButton extends StatelessWidget {
  final int sets; // ✅ 세트 수
  final int reps; // ✅ 반복 횟수
  final VoidCallback? onPressed; // *** 외부에서 저장 로직 전달받음 ***

  const SaveButton({
    super.key,
    required this.sets,
    required this.reps,
    this.onPressed, // *** 저장 동작은 외부에서 정의 ***
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // *** 외부에서 전달된 함수 실행 ***
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        "Save",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
