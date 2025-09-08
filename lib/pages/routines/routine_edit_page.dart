// lib/pages/routines/routine_edit_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/routines_viewmodel.dart';

class RoutineEditPage extends StatefulWidget {
  const RoutineEditPage({super.key, this.routineId}); // ✅ optional param 추가
  final String? routineId; // ✅ 라우터에서 받을 선택적 ID

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final _titleCtrl = TextEditingController();
  final _routineNameCtrl = TextEditingController(); // 루틴 이름
  final _exerciseNameCtrl = TextEditingController(); // 운동 이름

  final _setsCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _secsCtrl = TextEditingController();

  final _titleFocus = FocusNode();

  final List<_ExerciseDraft> _items = [];
  int _selectedIndex = -1; // 하단 카드 선택 인덱스

  @override
  void dispose() {
    _titleCtrl.dispose();
    _routineNameCtrl.dispose();
    _exerciseNameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _secsCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _exerciseNameCtrl.text.trim();
    final sets = int.tryParse(_setsCtrl.text.trim()) ?? 0;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final secs = int.tryParse(_secsCtrl.text.trim()) ?? 0;

    if (name.isEmpty || sets <= 0 || reps <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('운동 이름/세트/횟수를 입력하세요.')));
      return;
    }

    setState(() {
      _items.add(
        _ExerciseDraft(name: name, sets: sets, reps: reps, secs: secs),
      );
      _selectedIndex = _items.length - 1; // 방금 추가한 카드 선택
    });

    _exerciseNameCtrl.clear();
    _setsCtrl.clear();
    _repsCtrl.clear();
    _secsCtrl.clear();
  }

  void _applyChange() {
    if (_selectedIndex < 0 || _selectedIndex >= _items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수정할 운동을 먼저 선택하세요.')));
      return;
    }

    final name = _exerciseNameCtrl.text.trim();
    final sets = int.tryParse(_setsCtrl.text.trim()) ?? 0;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final secs = int.tryParse(_secsCtrl.text.trim()) ?? 0;

    if (name.isEmpty || sets <= 0 || reps <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('운동 이름/세트/횟수를 올바르게 입력하세요.')));
      return;
    }

    setState(() {
      _items[_selectedIndex] = _ExerciseDraft(
        name: name,
        sets: sets,
        reps: reps,
        secs: secs,
      );
    });
  }

  void _selectCard(int i) {
    setState(() => _selectedIndex = i);
    final e = _items[i];
    _exerciseNameCtrl.text = e.name;
    _setsCtrl.text = e.sets.toString();
    _repsCtrl.text = e.reps.toString();
    _secsCtrl.text = e.secs.toString();
  }

  void _removeCard(int i) {
    setState(() {
      _items.removeAt(i);
      if (_items.isEmpty) {
        _selectedIndex = -1;
        _exerciseNameCtrl.clear();
        _setsCtrl.clear();
        _repsCtrl.clear();
        _secsCtrl.clear();
      } else {
        if (_selectedIndex >= _items.length) {
          _selectedIndex = _items.length - 1;
        }
      }
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim().isEmpty
        ? (_routineNameCtrl.text.trim().isEmpty
              ? '새 루틴'
              : _routineNameCtrl.text.trim())
        : _titleCtrl.text.trim();

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('운동을 1개 이상 추가해 주세요.')));
      return;
    }

    final vm = context.read<RoutinesViewModel>();
    final dyn = vm as dynamic;
    try {
      dyn.addRoutine?.call({
        'title': title,
        'items': _items.map((e) => e.toMap()).toList(),
      });
    } catch (_) {
      try {
        dyn.create?.call(title, _items.map((e) => e.toMap()).toList());
      } catch (_) {}
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF6B35);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(_titleCtrl.text.isEmpty ? '루틴 제목' : _titleCtrl.text),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              final scope = FocusScope.of(context);
              scope.unfocus();
              scope.requestFocus(_titleFocus);
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _save,
            child: const Text(
              '루틴 저장',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilledField(
              controller: _routineNameCtrl,
              hint: '루틴 이름',
              focusNode: _titleFocus,
            ),
            const SizedBox(height: 12),
            _FilledField(controller: _exerciseNameCtrl, hint: '운동 이름'),
            const SizedBox(height: 20),

            _LabeledRow(
              label: '세트 수',
              field: _MiniNumber(controller: _setsCtrl, hint: '0'),
              unitChip: const _UnitChip('개'),
            ),
            const SizedBox(height: 10),
            _LabeledRow(
              label: '횟수',
              field: _MiniNumber(controller: _repsCtrl, hint: '0'),
              unitChip: const _UnitChip('회'),
            ),
            const SizedBox(height: 10),
            _LabeledRow(
              label: '1회당 걸리는 시간',
              field: _MiniNumber(controller: _secsCtrl, hint: '0'),
              unitChip: const _UnitChip('초'),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _addItem,
                      child: const Text(
                        '추가',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                // const SizedBox(width: 10),
                // Expanded(
                //   child: SizedBox(
                //     height: 44,
                //     child: FilledButton(
                //       style: FilledButton.styleFrom(
                //         backgroundColor: Colors.white.withOpacity(0.22),
                //         foregroundColor: Colors.white,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(10),
                //         ),
                //       ),
                //       onPressed: _applyChange,
                //       child: const Text(
                //         '변경',
                //         style: TextStyle(fontWeight: FontWeight.w800),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Image.asset(
                  'assets/images/flame.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFFF6B35),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '운동 목록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_items.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _NoneCard(color: cs.surfaceVariant.withOpacity(0.25)),
              )
            else
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final e = _items[i];
                    final selected = i == _selectedIndex;
                    return _ExercisePillCard(
                      item: e,
                      selected: selected,
                      onTap: () => _selectCard(i),
                      onClose: () => _removeCard(i),
                    );
                  },
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDraft {
  _ExerciseDraft({
    required this.name,
    required this.sets,
    required this.reps,
    required this.secs,
  });

  final String name;
  final int sets;
  final int reps;
  final int secs;

  Map<String, dynamic> toMap() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'secs': secs,
  };
}

class _FilledField extends StatelessWidget {
  const _FilledField({
    required this.controller,
    required this.hint,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontWeight: FontWeight.w700,
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({
    required this.label,
    required this.field,
    required this.unitChip,
  });

  final String label;
  final Widget field;
  final Widget unitChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 100, child: field),
        const SizedBox(width: 8),
        unitChip,
      ],
    );
  }
}

class _MiniNumber extends StatelessWidget {
  const _MiniNumber({required this.controller, this.hint = '0'});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontWeight: FontWeight.w700,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoneCard extends StatelessWidget {
  const _NoneCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NONE',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '0',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExercisePillCard extends StatelessWidget {
  const _ExercisePillCard({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final _ExerciseDraft item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withOpacity(0.08);
    const orange = Color(0xFFFF6B35);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
              border: selected ? Border.all(color: orange, width: 2) : null,
              boxShadow: selected
                  ? [BoxShadow(color: orange.withOpacity(.35), blurRadius: 14)]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.sets} / ${item.reps}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
