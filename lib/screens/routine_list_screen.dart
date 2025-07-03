import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../view_models/routine_viewmodel.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  final viewModel = RoutineViewModel(); // *** 뷰모델 인스턴스 ***
  List<Routine> routines = []; // *** 화면에 보여줄 루틴 리스트 ***

  @override
  void initState() {
    super.initState();
    _loadRoutines(); // *** 루틴 불러오기 ***
  }

  Future<void> _loadRoutines() async {
    await viewModel.loadRoutines(); // *** SharedPreferences에서 불러오기 ***
    setState(() {
      routines = viewModel.routines; // *** 뷰모델의 루틴 참조 ***
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("저장된 루틴")),
      body: routines.isEmpty
          ? const Center(child: Text("저장된 루틴이 없습니다."))
          : ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final r = routines[index];
          return ListTile(
            title: Text(r.name),
            subtitle: Text('${r.sets}세트 × ${r.reps}회'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 루틴 선택 시 동작 추가 가능
            },
          );
        },
      ),
    );
  }
}
