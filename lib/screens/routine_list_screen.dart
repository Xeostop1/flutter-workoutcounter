import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../view_models/routine_viewmodel.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  final viewModel = RoutineViewModel();
  List<Routine> routines = [];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final loaded = await viewModel.getRoutines();
    setState(() {
      routines = loaded;
    });
  }

  Future<void> _deleteRoutine(int index) async {
    await viewModel.deleteRoutine(index);
    _loadRoutines(); // 삭제 후 리스트 다시 불러오기
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
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('루틴 삭제'),
                    content: const Text('이 루틴을 삭제할까요?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteRoutine(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('루틴이 삭제되었습니다.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
