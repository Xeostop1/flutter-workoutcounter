import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/exercise.dart';
import '../../viewmodels/routines_viewmodel.dart';

/// 루틴 새로 만들기 페이지 (편집 아님)
class RoutineCreatePage extends StatefulWidget {
  const RoutineCreatePage({super.key});

  @override
  State<RoutineCreatePage> createState() => _RoutineCreatePageState();
}

class _RoutineCreatePageState extends State<RoutineCreatePage> {
  final _titleCtrl = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _setsCtrl  = TextEditingController(text: '3');
  final _repsCtrl  = TextEditingController(text: '20');
  final _secsCtrl  = TextEditingController(text: '2');

  final List<Exercise> _items = [];

  bool get _titleOk => _titleCtrl.text.trim().isNotEmpty;
  bool get _exOk =>
      _nameCtrl.text.trim().isNotEmpty &&
          (int.tryParse(_setsCtrl.text) ?? 0) > 0 &&
          (int.tryParse(_repsCtrl.text) ?? 0) > 0;

  void _addExercise() {
    if (!_exOk) return;
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _items.add(
        Exercise(
          id: 'EX-$nowId',
          name: _nameCtrl.text.trim(),
          sets: int.parse(_setsCtrl.text),
          reps: int.parse(_repsCtrl.text),
          repSeconds: int.tryParse(_secsCtrl.text) ?? 0,
        ),
      );
      // 입력칸은 이름만 비워주고 수치는 유지
      _nameCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_titleOk || _items.isEmpty) return;
    final id = await context.read<RoutinesViewModel>().createRoutine(
      title: _titleCtrl.text.trim(),
      items: _items,
    );
    if (!mounted) return;
    // 저장 후 루틴 상세로 이동하거나 목록으로 돌아가기 중 택1
    context.go('/routines/$id'); // 상세로 이동
    // context.pop(); // 목록으로만 돌아가고 싶다면 이거 사용
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _secsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // 1) 루틴명
          _pillInput(
            controller: _titleCtrl,
            hint: '루틴명을 정해주세요.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 2) 운동명
          _pillInput(
            controller: _nameCtrl,
            hint: '운동명을 알려주세요.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 3) 세트/횟수/초
          _numberRow('세트수', _setsCtrl, '개'),
          const SizedBox(height: 12),
          _numberRow('횟수', _repsCtrl, '회'),
          const SizedBox(height: 12),
          _numberRow('1회당 걸리는 시간', _secsCtrl, '초'),

          const SizedBox(height: 16),

          // 4) 큰 + 버튼
          Center(
            child: Material(
              color: Colors.white.withOpacity(0.15),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _exOk ? _addExercise : null,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.add,
                    color: _exOk ? Colors.white : Colors.white38,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Divider(color: Color(0x33FFFFFF), height: 32, thickness: 1),

          // 5) 운동 목록 타이틀
          Row(
            children: const [
              Text(
                '운동 목록',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.edit, size: 16, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),

          // 6) 현재 추가된 운동 리스트
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '아직 추가된 운동이 없어요.',
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
              ),
            )
          else
            ..._items.map((e) => Dismissible(
              key: ValueKey(e.id),
              background: Container(
                color: Colors.red.withOpacity(0.6),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() {
                _items.removeWhere((x) => x.id == e.id);
              }),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${e.sets}세트 • ${e.reps}회 • 1회 ${e.repSeconds}초'),
              ),
            )),

          const SizedBox(height: 24),

          // 7) 저장 버튼
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: (_titleOk && _items.isNotEmpty) ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 작은 위젯들 ────────────────────────────────────────────────

  Widget _pillInput({
    required TextEditingController controller,
    required String hint,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontWeight: FontWeight.w700,
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _numberRow(String label, TextEditingController c, String unit) {
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
          width: 92,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white.withOpacity(0.18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            unit,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
