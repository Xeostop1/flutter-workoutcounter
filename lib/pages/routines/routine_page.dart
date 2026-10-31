import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/routine_favorite_action.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool _selecting = false;
  bool _deleting = false;
  final Set<String> _selected = {};
  String? _selectionOwner;

  Future<void> _delete({required bool all}) async {
    if (_deleting) return;
    final vm = context.read<RoutinesViewModel>();
    final owner = vm.deletionAccountId;
    if (!all && owner != _selectionOwner) {
      setState(() {
        _selecting = false;
        _selected.clear();
      });
      return;
    }
    final ids = vm.items
        .where((r) => all || _selected.contains(r.id))
        .map((r) => r.id)
        .toSet();
    if (ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(all ? '루틴 전체 삭제' : '선택한 루틴 삭제'),
        content: Text(
          '${all ? "저장된" : "선택한"} 루틴 ${ids.length}개를 ${all ? "모두 " : ""}삭제할까요?\n운동 기록과 계정은 유지됩니다.\n삭제한 루틴은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              all ? '전체 삭제' : '삭제',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _deleting = false);
      return;
    }
    setState(() => _deleting = true);
    try {
      await vm.deleteRoutines(ids, ownerUid: owner);
      if (!mounted) return;
      setState(() {
        _selecting = false;
        _selected.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('루틴 ${ids.length}개를 삭제했어요.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제를 완료하지 못했어요. 남은 루틴을 확인하고 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoutinesViewModel>();
    final routines = vm.items;
    final selected = routines.where((r) => _selected.contains(r.id)).length;
    final ready = vm.loadError == null && !vm.isLoading;
    return PopScope(
      canPop: !_selecting && !_deleting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_deleting) {
          setState(() {
            _selecting = false;
            _selected.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101114),
        appBar: _selecting
            ? null
            : AppBar(
                title: const Text(
                  '루틴',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                centerTitle: false,
                titleSpacing: 20,
                toolbarHeight: 72,
                actions: [
                  if (ready && routines.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: '루틴 관리',
                      enabled: !_deleting,
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'all') {
                          _delete(all: true);
                        } else {
                          setState(() {
                            _selecting = true;
                            _selectionOwner = vm.deletionAccountId;
                            _selected.clear();
                          });
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'select',
                          child: Text('여러 개 선택 삭제'),
                        ),
                        PopupMenuItem(value: 'all', child: Text('루틴 전체 삭제')),
                      ],
                    ),
                  const SizedBox(width: 8),
                ],
              ),
        body: Stack(
          children: [
            if (_selecting)
              SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: _deleting
                              ? null
                              : () => setState(() {
                                  _selecting = false;
                                  _selected.clear();
                                }),
                          child: const Text('취소'),
                        ),
                        Expanded(
                          child: Text(
                            '$selected개 선택',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: _deleting || !ready
                              ? null
                              : () => setState(() {
                                  if (selected == routines.length) {
                                    _selected.clear();
                                  } else {
                                    _selected.addAll(routines.map((r) => r.id));
                                  }
                                }),
                          child: Text(
                            selected == routines.length ? '선택 해제' : '전체 선택',
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final r in routines)
                            CheckboxListTile(
                              key: ValueKey('select-${r.id}'),
                              value: _selected.contains(r.id),
                              title: Text(r.title),
                              subtitle: Text(_summaryText(r)),
                              onChanged: _deleting || !ready
                                  ? null
                                  : (value) => setState(() {
                                      value == true
                                          ? _selected.add(r.id)
                                          : _selected.remove(r.id);
                                    }),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _deleting || !ready || selected == 0
                              ? null
                              : () => _delete(all: false),
                          child: Text(
                            _deleting ? '삭제 중…' : '선택한 $selected개 삭제',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Positioned.fill(
                child: vm.loadError != null
                    ? _RoutineLoadError(onRetry: vm.retryLoad)
                    : vm.isLoading && routines.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : routines.isEmpty
                    ? const _RoutineEmptyView()
                    : SafeArea(
                        bottom: false,
                        child: _RoutineList(routines: routines),
                      ),
              ),
            ],
            if (_deleting)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: ready && !_selecting && !_deleting
            ? Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: _AddRoutineButton(
                  onTap: () => context.push('/routines/create'),
                ),
              )
            : null,
      ),
    );
  }
}

class _RoutineLoadError extends StatelessWidget {
  const _RoutineLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('루틴을 불러오지 못했어요.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (routines.length == 1)
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 8, right: 24),
              child: Text(
                '최신순',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey('routine_list'),
            padding: EdgeInsets.only(
              top: routines.length == 1 ? 16 : 12,
              bottom: 120,
            ),
            itemCount: routines.length,
            itemBuilder: (_, index) => _RoutineRow(
              routine: routines[index],
              showDivider: index < routines.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.routine, required this.showDivider});

  final Routine routine;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF784F);
    final textScaler = MediaQuery.textScalerOf(context);
    final height =
        ((textScaler.scale(22) * 1.4).ceilToDouble() +
                (textScaler.scale(14) * 1.4).ceilToDouble() +
                (textScaler.scale(13) * 1.4).ceilToDouble() +
                45)
            .clamp(115.0, double.infinity);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 20),
                    onPressed: () => saveRoutineFavorite(
                      context,
                      () => context.read<RoutinesViewModel>().toggleFavorite(
                        routine.id,
                      ),
                    ),
                    icon: Icon(
                      Icons.star_rounded,
                      size: 22,
                      color: routine.favorite
                          ? orange
                          : const Color(0xFFBDBDBD),
                    ),
                    tooltip: routine.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/routines/edit/${routine.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _summaryText(routine),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _dateText(routine.updatedAt ?? routine.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: () =>
                        context.push('/routines/edit/${routine.id}'),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    tooltip: '${routine.title} 수정',
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 13,
              child: Divider(height: 1, color: Color(0xFF30333A)),
            ),
        ],
      ),
    );
  }
}

class _RoutineEmptyView extends StatelessWidget {
  const _RoutineEmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1E23),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 36,
              color: Color(0xFFFF784F),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '나만의 루틴을 만들어보세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            '자주 하는 운동을 모아두면\n다음 운동을 더 가볍게 시작할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9B9EA8),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AddRoutineButton extends StatelessWidget {
  const _AddRoutineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '루틴 추가',
      child: Material(
        color: const Color(0xFFFF784F),
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ),
    );
  }
}

String _dateText(DateTime? date) {
  if (date == null) return '';
  final year = (date.year % 100).toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

String _summaryText(Routine routine) {
  if (routine.items.isEmpty) return '운동 없음';
  if (routine.items.length == 1) return routine.items.first.name;
  return '${routine.items.first.name} 외 ${routine.items.length - 1}개의 운동';
}
