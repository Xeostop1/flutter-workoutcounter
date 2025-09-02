import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../viewmodels/routines_viewmodel.dart';
import '../../widgets/gradient_circular_counter.dart';

/// 한 페이지에서
/// - CounterViewModel: 카운터 진행
/// - RoutinesViewModel: 루틴 목록/그룹(큰 루틴, 하부 루틴들)
/// 을 같이 씁니다.
///
/// ※ RoutinesViewModel 에 아래 3개 API만 있으면 됩니다.
///   - String get selectedGroupId;
///   - String groupName(String id);
///   - List<Routine> routinesByGroup(String id);
/// 없다면 임시로 allRoutines 를 그대로 쓰면 됩니다(아래에 fallback 처리 있음).
class CounterPage extends StatefulWidget {
  final Routine? routine; // (옵션) 라우터 extra로 선택 루틴 전달 가능
  const CounterPage({super.key, this.routine});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  Routine? _attachedOnce; // 선택 루틴 1회만 붙였는지 확인용

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<CounterViewModel>();
    // 라우트로 들어온 선택 루틴이 있으면 최초 1회 attach
    final incoming = widget.routine;
    if (incoming != null &&
        (_attachedOnce == null || _attachedOnce!.id != incoming.id)) {
      vm.attachRoutine(incoming);
      _attachedOnce = incoming;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterViewModel>();
    final routines = context.watch<RoutinesViewModel>();
    final cs = Theme.of(context).colorScheme;

    final rest = counter.isResting;
    final currentRoutine = counter.routine ?? widget.routine;

    // ====== 큰 루틴(그룹) & 하부 루틴 목록 ======
    // RoutinesViewModel에 group API가 있으면 사용, 없으면 allRoutines fallback
    final groupId = _safeGroupId(routines);
    final groupName = _safeGroupName(routines, groupId);
    final subRoutines = _safeSubRoutines(routines, groupId);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRoutine?.title ?? groupName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 상단 흰색 Pill : 휴식/현재 동작명
            _pill(
              text: rest ? '휴식' : (currentRoutine?.primary.name ?? groupName),
              color: rest ? cs.onSurface.withOpacity(0.85) : cs.onSurface,
            ),

            const SizedBox(height: 16),

            // ===== 중앙: 원형 링 + 텍스트 =====
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GradientCircularCounter(
                      progress: rest ? 0 : counter.progress,
                      size: 240,
                      thickness: 22,
                      dim: rest, // 휴식이면 회색 단색
                      bgColor: cs.onSurface.withOpacity(0.12),
                      dimColor: cs.onSurface.withOpacity(0.35),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _numberWithUnit(
                          value: '${counter.setNow}',
                          unit: 'Set',
                          valueStyle: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: rest
                                ? cs.onSurface.withOpacity(0.35)
                                : cs.onSurface,
                          ),
                          unitStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: rest
                                ? cs.onSurface.withOpacity(0.35)
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _numberWithUnit(
                          value: rest
                              ? '${counter.repsPerSet}'
                              : '${counter.repNow}',
                          unit: '회',
                          valueStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: rest
                                ? cs.onSurface.withOpacity(0.35)
                                : cs.onSurface,
                          ),
                          unitStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: rest
                                ? cs.onSurface.withOpacity(0.35)
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== 하부 루틴 선택 영역 (큰 루틴 아래에 위치) =====
            _SubRoutineSection(
              title: groupName,
              routines: subRoutines,
              selectedId: currentRoutine?.id,
              onTap: (Routine r) {
                // 하부 루틴 탭 → 카운터에 바로 적용
                context.read<CounterViewModel>().attachRoutine(r);
              },
            ),

            const SizedBox(height: 8),

            // ===== 하단: 리셋 / 재생(일시정지) / 음성 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _circleBtn(
                    icon: Icons.replay,
                    onTap: () => counter.reset(),
                    bg: cs.onSurface.withOpacity(0.25),
                    fg: cs.onSurface.withOpacity(0.7),
                  ),
                  _circleBtn(
                    size: 64,
                    icon: counter.isRunning ? Icons.pause : Icons.play_arrow,
                    onTap: () => counter.startPause(),
                    bg: rest ? cs.onSurface.withOpacity(0.25) : Colors.white,
                    fg: rest ? cs.onSurface.withOpacity(0.8) : Colors.black,
                    elevation: 6,
                  ),
                  _circleBtn(
                    icon: Icons.volume_up,
                    onTap: () => counter.setTts(!counter.ttsOn),
                    bg: cs.onSurface.withOpacity(0.25),
                    fg: cs.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // -------- 보조: 그룹/서브루틴 Fallback --------
  String _safeGroupId(RoutinesViewModel vm) {
    // vm.selectedGroupId 가 있으면 사용, 없으면 'lower'(하체) 가정 or 임시값
    try {
      // ignore: avoid_dynamic_calls
      final id = (vm as dynamic).selectedGroupId as String?;
      return id ?? 'lower';
    } catch (_) {
      return 'lower';
    }
  }

  String _safeGroupName(RoutinesViewModel vm, String id) {
    try {
      // ignore: avoid_dynamic_calls
      return (vm as dynamic).groupName(id) as String;
    } catch (_) {
      // 모델에 그룹명이 없으면 임시로 한글 사용
      return id == 'lower' ? '하체' : id;
    }
  }

  List<Routine> _safeSubRoutines(RoutinesViewModel vm, String id) {
    try {
      // ignore: avoid_dynamic_calls
      return ((vm as dynamic).routinesByGroup(id) as List<Routine>);
    } catch (_) {
      // 그룹 API가 없으면 전체 목록을 그대로 노출
      return vm.allRoutines;
    }
  }

  // -------- 공통: 작은 위젯 함수들 --------

  // 상단 흰색 Pill
  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(text,
          style:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    );
  }

  // 둥근 아이콘 버튼(리셋/재생/음성 공용)
  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    double size = 56,
    Color? bg,
    Color? fg,
    double elevation = 2,
  }) {
    return Material(
      color: bg ?? Colors.white,
      shape: const CircleBorder(),
      elevation: elevation,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.42, color: fg ?? Colors.black),
        ),
      ),
    );
  }

  // 중앙 텍스트 한 줄(큰 숫자 + 단위) 베이스라인 정렬
  Widget _numberWithUnit({
    required String value,
    required String unit,
    required TextStyle valueStyle,
    required TextStyle unitStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(width: 6),
        Text(unit, style: unitStyle),
      ],
    );
  }
}

/// 하부 루틴 섹션 (큰 루틴 아래에 보여주는 가로 스크롤 칩)
class _SubRoutineSection extends StatelessWidget {
  final String title;             // 큰 루틴 이름 (예: 하체)
  final List<Routine> routines;   // 하부 루틴들 (예: 스쿼트, 런지 ...)
  final String? selectedId;       // 현재 카운터에 붙은 루틴 id
  final ValueChanged<Routine> onTap;

  const _SubRoutineSection({
    required this.title,
    required this.routines,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('$title 하부 루틴',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        // 가로 스크롤 칩들
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final r = routines[i];
              final selected = r.id == selectedId;
              return ChoiceChip(
                label: Text(r.primary.name),
                selected: selected,
                onSelected: (_) => onTap(r),
                selectedColor: const Color(0xFFFF6B35).withOpacity(0.15),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFFFF6B35) : cs.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: cs.surface,
                side: BorderSide(
                  color: selected
                      ? const Color(0xFFFF6B35)
                      : cs.onSurface.withOpacity(0.12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
