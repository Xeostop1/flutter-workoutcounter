import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/routine.dart';
import '../view_models/routine_viewmodel.dart';

class SaveButton extends StatelessWidget {
  final int sets; // ✅ 세트 수
  final int reps; // ✅ 반복 횟수

  const SaveButton({
    super.key,
    required this.sets,
    required this.reps,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final nameController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('루틴 저장'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '루틴 이름'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final routine = Routine(name: name, sets: sets, reps: reps);
                  await RoutineViewModel().saveRoutine(routine);

                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context, true); // ✅ 이전 화면으로 true 전달
                },
                child: const Text('저장'),
              ),
            ],
          ),
        );
      },
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
