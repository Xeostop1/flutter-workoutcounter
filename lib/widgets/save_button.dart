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
      // onPressed: () {
      //   final nameController = TextEditingController();
      //
      //   showDialog(
      //     context: context,
      //     builder: (context) => AlertDialog(
      //       title: const Text('루틴 저장'),
      //       content: TextField(
      //         controller: nameController,
      //         decoration: const InputDecoration(labelText: '루틴 이름'),
      //       ),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Navigator.pop(context),
      //           child: const Text('취소'),
      //         ),
      //         TextButton(
      //           onPressed: () async {
      //             final name = nameController.text.trim();
      //             print('입력된 이름확인: $name');
      //             if (name.isEmpty) return;
      //             print('❌ 이름이 비어있어서 저장하지 않음');
      //             final routine = Routine(name: name, sets: sets, reps: reps);
      //             print('📦 저장할 루틴: ${routine.name}, ${routine.sets}세트, ${routine.reps}회'); // 디버깅 로그 2
      //
      //             await RoutineViewModel().saveRoutine(routine);
      //             print('✅ 루틴 저장 완료'); // 디버깅 로그 3
      //
      //             Navigator.pop(context); // 다이얼로그 닫기
      //             Navigator.pop(context, true); // ✅ 이전 화면으로 true 전달
      //             print('🚀 루틴 화면으로 true 전달하며 복귀');
      //           },
      //           child: const Text('저장'),
      //         ),
      //       ],
      //     ),
      //   );
      // },
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
