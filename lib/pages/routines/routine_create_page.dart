import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/confirm_popup.dart';

class RoutineCreatePage extends StatefulWidget {
  const RoutineCreatePage({super.key, this.routineId});

  final String? routineId;

  @override
  State<RoutineCreatePage> createState() => _RoutineCreatePageState();
}

class _RoutineCreatePageState extends State<RoutineCreatePage> {
  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _secondsController = TextEditingController();
  final _items = <Exercise>[];

  bool _saving = false;
  bool _allowPop = false;
  bool _checkingExit = false;
  bool _editingList = false;
  String? _editingExerciseId;
  String _initialTitle = '';
  List<Exercise> _initialItems = const [];

  bool get _isEditing => widget.routineId != null;

  bool get _canSave =>
      !_saving &&
      _titleController.text.trim().isNotEmpty &&
      _items.isNotEmpty &&
      (!_isEditing || _hasUnsavedChanges);

  @override
  void initState() {
    super.initState();
    final id = widget.routineId;
    if (id == null) return;
    final routine = context.read<RoutinesViewModel>().getById(id);
    if (routine == null) return;
    _titleController.text = routine.title;
    _items.addAll(routine.items);
    _initialTitle = routine.title;
    _initialItems = List.of(routine.items);
    _editingList = true;
    if (_items.isNotEmpty) _loadEditor(_items.first);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int? _positiveInt(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    return value != null && value > 0 ? value : null;
  }

  Exercise? get _editingExercise {
    for (final exercise in _items) {
      if (exercise.id == _editingExerciseId) return exercise;
    }
    return null;
  }

  bool get _hasEditorInput => [
    _nameController,
    _setsController,
    _repsController,
    _secondsController,
  ].any((controller) => controller.text.trim().isNotEmpty);

  bool _editorMatches(Exercise exercise) =>
      _nameController.text.trim() == exercise.name &&
      _positiveInt(_setsController) == exercise.sets &&
      _positiveInt(_repsController) == exercise.reps &&
      _positiveInt(_secondsController) == exercise.repSeconds;

  void _loadEditor(Exercise exercise) {
    _editingExerciseId = exercise.id;
    _nameController.text = exercise.name;
    _setsController.text = '${exercise.sets}';
    _repsController.text = '${exercise.reps}';
    _secondsController.text = '${exercise.repSeconds}';
  }

  void _clearEditor() {
    _editingExerciseId = null;
    _nameController.clear();
    _setsController.clear();
    _repsController.clear();
    _secondsController.clear();
  }

  Exercise? _exerciseFromInput(Exercise? original) {
    final name = _nameController.text.trim();
    final sets = _positiveInt(_setsController);
    final reps = _positiveInt(_repsController);
    final seconds = _positiveInt(_secondsController);
    if (name.isEmpty || sets == null || reps == null || seconds == null) {
      return null;
    }
    return Exercise(
      id: original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      sets: sets,
      reps: reps,
      repSeconds: seconds,
      isTransient: original?.isTransient ?? false,
    );
  }

  bool _commitEditor() {
    if (_editingExerciseId == null) {
      if (_hasEditorInput) {
        _showMessage('입력 중인 운동을 + 버튼으로 추가한 뒤 진행해주세요.');
        return false;
      }
      return true;
    }
    final original = _editingExercise;
    if (original == null) return false;
    if (_editorMatches(original)) return true;
    final updated = _exerciseFromInput(original);
    if (updated == null) {
      _showMessage('운동명과 숫자를 모두 입력해주세요.');
      return false;
    }
    _items[_items.indexOf(original)] = updated;
    return true;
  }

  bool get _hasUnsavedChanges {
    if (_titleController.text.trim() != _initialTitle.trim() ||
        _items.length != _initialItems.length) {
      return true;
    }
    for (var index = 0; index < _items.length; index++) {
      final current = _items[index];
      final initial = _initialItems[index];
      if (current.id != initial.id ||
          current.name != initial.name ||
          current.sets != initial.sets ||
          current.reps != initial.reps ||
          current.repSeconds != initial.repSeconds ||
          current.isTransient != initial.isTransient) {
        return true;
      }
    }

    if (_editingExerciseId == null) return _hasEditorInput;
    final editing = _editingExercise;
    return editing == null || !_editorMatches(editing);
  }

  Future<void> _close() async {
    if (_saving || _checkingExit) return;
    if (!_hasUnsavedChanges) {
      _leave();
      return;
    }

    _checkingExit = true;
    final confirmed = await showConfirmPopup(
      context,
      title: '종료하시겠어요?',
      message: '기록중이던 루틴은 저장되지 않아요',
      cancelText: '취소',
      okText: '종료',
    );
    _checkingExit = false;
    if (confirmed == true) _leave();
  }

  void _leave() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _addExercise() {
    if (_saving) return;
    final original = _editingExercise;
    final exercise = _exerciseFromInput(original);
    if (exercise == null) {
      _showMessage('운동명과 숫자를 모두 입력해주세요.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      final index = _items.indexWhere((item) => item.id == _editingExerciseId);
      if (index == -1) {
        _items.add(exercise);
      } else if (original == null || !_editorMatches(original)) {
        _items[index] = exercise;
      }
      if (_isEditing && original != null) {
        _loadEditor(_items[index]);
      } else {
        _clearEditor();
      }
    });
  }

  void _editExercise(Exercise exercise) {
    if (_saving || !_commitEditor()) return;
    setState(() {
      if (_editingExerciseId == exercise.id) {
        _clearEditor();
      } else {
        _loadEditor(exercise);
      }
    });
  }

  void _removeExercise(Exercise exercise) {
    setState(() {
      _items.removeWhere((item) => item.id == exercise.id);
      if (_editingExerciseId == exercise.id) {
        _clearEditor();
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave || !_commitEditor()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final vm = context.read<RoutinesViewModel>();
      if (_isEditing) {
        await vm.updateRoutine(
          widget.routineId!,
          title: _titleController.text,
          items: _items,
        );
      } else {
        await vm.createRoutine(title: _titleController.text, items: _items);
      }
      _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('루틴을 저장하지 못했어요. 다시 시도해주세요.');
    }
  }

  Future<void> _deleteRoutine() async {
    if (!_isEditing || _saving) return;
    final confirmed = await showConfirmPopup(
      context,
      title: '정말 삭제 하시겠어요?',
      message: '운동 루틴이 영구히 사라져요',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await context.read<RoutinesViewModel>().deleteRoutine(widget.routineId!);
      _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('루틴을 삭제하지 못했어요. 다시 시도해주세요.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF101114),
        body: AbsorbPointer(
          absorbing: _saving,
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileScale =
                    MediaQuery.textScalerOf(context).scale(24) / 24;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: '뒤로',
                                  onPressed: _close,
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const Spacer(),
                                if (_isEditing)
                                  IconButton(
                                    tooltip: '루틴 삭제',
                                    onPressed: _saving ? null : _deleteRoutine,
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, right: 27),
                            child: _MainInput(
                              controller: _titleController,
                              hint: '루틴명을 정해주세요.',
                              height: 68,
                              fontSize: 22,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFF626262)),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, right: 27),
                            child: _MainInput(
                              controller: _nameController,
                              hint: '운동명을 알려주세요.',
                              onChanged: (_) => setState(() {}),
                              height: 54,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, right: 27),
                            child: Column(
                              children: [
                                _NumberRow(
                                  label: '세트수',
                                  onChanged: (_) => setState(() {}),
                                  unit: '개',
                                  controller: _setsController,
                                ),
                                const SizedBox(height: 24),
                                _NumberRow(
                                  label: '횟수',
                                  onChanged: (_) => setState(() {}),
                                  unit: '회',
                                  controller: _repsController,
                                ),
                                const SizedBox(height: 24),
                                _NumberRow(
                                  label: '1회당 걸리는 시간',
                                  onChanged: (_) => setState(() {}),
                                  unit: '초',
                                  controller: _secondsController,
                                  onSubmitted: (_) => _addExercise(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Align(
                            alignment: Alignment.center,
                            child: _AddExerciseButton(onTap: _addExercise),
                          ),
                          const SizedBox(height: 22),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFF626262)),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _saving
                                    ? null
                                    : () => setState(
                                        () => _editingList = !_editingList,
                                      ),
                                iconAlignment: IconAlignment.end,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 48),
                                  foregroundColor: Colors.white,
                                ),
                                icon: Image.asset(
                                  'assets/icons/icon-edit.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  '운동 목록',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            height: 92 * tileScale,
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                              ),
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (_, index) {
                                final exercise = _items[index];
                                return _ExerciseTile(
                                  key: ValueKey(exercise.id),
                                  exercise: exercise,
                                  selected: exercise.id == _editingExerciseId,
                                  showRemove: _editingList,
                                  single: _items.length == 1,
                                  onTap: () => _editExercise(exercise),
                                  onRemove: () => _removeExercise(exercise),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 23),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 61),
                              child: FilledButton(
                                onPressed: _canSave ? _save : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF784F),
                                  disabledBackgroundColor: const Color(
                                    0xFF7A7A7A,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  _saving ? '저장 중...' : '저장',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 31),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MainInput extends StatelessWidget {
  const _MainInput({
    required this.controller,
    required this.hint,
    required this.height,
    required this.fontSize,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final double height;
  final double fontSize;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final inputHeight =
        (MediaQuery.textScalerOf(context).scale(fontSize) * 1.4 + 20).clamp(
          height,
          double.infinity,
        );
    final scaledFont = MediaQuery.textScalerOf(context).scale(fontSize);
    return SizedBox(
      height: inputHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          constraints: BoxConstraints.tightFor(height: inputHeight),
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF929292),
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFF272A30),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: (inputHeight - scaledFont) / 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.unit,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(18) / 18;
    final inputHeight = (MediaQuery.textScalerOf(context).scale(18) * 1.3 + 10)
        .clamp(38.0, double.infinity);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: (79 * textScale).clamp(
            79.0,
            (MediaQuery.sizeOf(context).width - 55) / 2,
          ),
          height: inputHeight,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              constraints: BoxConstraints.tightFor(height: inputHeight),
              isDense: true,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 24),
              contentPadding: EdgeInsets.fromLTRB(
                12,
                (inputHeight - textScale * 18) / 2,
                0,
                (inputHeight - textScale * 18) / 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF666666)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF666666)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF784F)),
              ),
            ),
            keyboardType: TextInputType.number,
            textInputAction: onSubmitted == null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: onSubmitted,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '운동 추가',
      child: Material(
        color: const Color(0xFF1C1E23),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 49,
            height: 49,
            child: Icon(Icons.add, color: Color(0xFFBDBDBD), size: 40),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.selected,
    required this.showRemove,
    required this.single,
    required this.onTap,
    required this.onRemove,
  });

  final Exercise exercise;
  final bool selected;
  final bool showRemove;
  final bool single;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? const Color(0xFF222222) : Colors.white;
    final scale = MediaQuery.textScalerOf(context).scale(24) / 24;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected && single
                ? const [BoxShadow(color: Color(0xAAFF6633), blurRadius: 6)]
                : const [],
          ),
          child: Material(
            color: selected ? Colors.white : const Color(0xFF272A30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: selected && single
                    ? const Color(0xFFFF784F)
                    : Colors.transparent,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                width: 91 * scale,
                height: 91 * scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: selected && !single ? 4 : 8,
                      ),
                      child: Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: selected && !single ? 16 : 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${exercise.sets}/${exercise.reps}',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showRemove)
          Positioned(
            left: -12,
            top: -12,
            child: GestureDetector(
              onTap: onRemove,
              child: Semantics(
                button: true,
                label: '${exercise.name} 삭제',
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFD6D6D6),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF333333),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
