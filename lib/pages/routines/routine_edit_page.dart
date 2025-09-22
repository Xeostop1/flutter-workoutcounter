// lib/pages/routines/routine_create_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/exercise.dart';
import '../../viewmodels/routines_viewmodel.dart';

class RoutineCreatePage extends StatefulWidget {
  const RoutineCreatePage({super.key});

  @override
  State<RoutineCreatePage> createState() => _RoutineCreatePageState();
}

class _RoutineCreatePageState extends State<RoutineCreatePage> {
  // 상단: 루틴명
  final _routineNameCtrl = TextEditingController();

  // 운동 입력 영역
  final _exerciseNameCtrl = TextEditingController();
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '20');
  final _secsCtrl = TextEditingController(text: '2');

  final List<Exercise> _items = [];

  bool get _canAddExercise {
    final name = _exerciseNameCtrl.text.trim();
    final sets = int.tryParse(_setsCtrl.text) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    return name.isNotEmpty && sets > 0 && reps > 0;
  }

  bool get _canSave {
    final titleOk = _routineNameCtrl.text.trim().isNotEmpty;
    return titleOk && _items.isNotEmpty;
  }

  void _addExercise() {
    if (!_canAddExercise) return;
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    final ex = Exercise(
      id: 'EX-$nowId',
      name: _exerciseNameCtrl.text.trim(),
      sets: int.parse(_setsCtrl.text),
      reps: int.parse(_repsCtrl.text),
      repSeconds: int.tryParse(_secsCtrl.text) ?? 0,
    );
    setState(() {
      _items.add(ex);
      _exerciseNameCtrl.clear();
      // 수치들은 유지해 주는 편이 반복 입력에 편함
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final title = _routineNameCtrl.text.trim();
    await context.read<RoutinesViewModel>().createRoutine(
      title: title,
      items: _items,
    );
    if (!mounted) return;
    context.pop(); // 저장 후 뒤로
  }

  @override
  void dispose() {
    _routineNameCtrl.dispose();
    _exerciseNameCtrl.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('루틴 만들기'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 루틴명
          _whiteField(
            controller: _routineNameCtrl,
            hint: '루틴명을 정해주세요.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF)),

          // 운동명
          const SizedBox(height: 12),
          _whiteField(
            controller: _exerciseNameCtrl,
            hint: '운동명을 알려주세요.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),

          // 수치 입력 3종
          _numberRow('세트수', _setsCtrl, '개'),
          const SizedBox(height: 12),
          _numberRow('횟수', _repsCtrl, '회'),
          const SizedBox(height: 12),
          _numberRow('1회당 걸리는 시간', _secsCtrl, '초'),
          const SizedBox(height: 18),

          // 큰 + 버튼
          Center(
            child: IconButton.filled(
              onPressed: _canAddExercise ? _addExercise : null,
              style: IconButton.styleFrom(
                backgroundColor: _canAddExercise
                    ? cs.secondary
                    : Colors.white.withOpacity(0.15),
                disabledBackgroundColor: Colors.white.withOpacity(0.12),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.add, size: 28, color: Colors.white),
              iconSize: 56,
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0x22FFFFFF)),

          // 섹션 타이틀
          Row(
            children: const [
              Text(
                '운동 목록',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.edit, size: 14, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 10),

          // 등록된 운동 리스트
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.centerLeft,
              child: const Text(
                '아직 추가된 운동이 없어요.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ..._items.map(
                  (e) => _exerciseTile(
                e,
                onRemove: () {
                  setState(() => _items.removeWhere((x) => x.id == e.id));
                },
              ),
            ),

          const SizedBox(height: 18),

          // 저장 버튼
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                _canSave ? const Color(0xFFFF6B35) : Colors.white12,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── UI 작은 위젯들 ─────────────────

  Widget _whiteField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontWeight: FontWeight.w600,
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
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

  Widget _exerciseTile(Exercise e, {required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${e.name} • ${e.sets}세트 • ${e.reps}회 • 1회 ${e.repSeconds}초',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: '삭제',
          ),
        ],
      ),
    );
  }
}
