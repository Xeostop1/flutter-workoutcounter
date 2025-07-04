import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../view_models/routine_viewmodel.dart';
import '../widgets/edit_routine_dialog.dart';


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
    await viewModel.loadRoutines();
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          EditRoutineDialog(
                            routine: r,
                            onConfirm: (updated) async {
                              await viewModel.updateRoutine(
                                  index, updated); // *** 수정 반영 ***
                              _loadRoutines(); // 리스트 다시 불러오기
                              Navigator.pop(context, true); // ✅ 수정 완료 후 true 반환
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('루틴이 수정되었습니다.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          AlertDialog(
                            title: const Text('루틴 삭제'),
                            content: const Text('이 루틴을 삭제할까요?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _deleteRoutine(index);
                                  Future.microtask(() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('루틴이 삭제되었습니다.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  });
                                },
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ), // *** Row 닫기 ***
          );
        },
      ),
    );
  }
}

