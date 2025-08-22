// lib/pages/record/record_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/record_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final rec = context.watch<RecordViewModel>();
    final items = rec.byDate(_selected);

    const bg = Color(0xFF191919);
    const card = Color(0xFF222222);
    const accent = Color(0xFFFF6A2B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('기록', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 상단 프로필/카피
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF2C2C2C),
                      child: Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isLoggedIn ? '나라' : '게스트',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '프로필 수정',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '“주 3회 운동하기”',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // 달력
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              onDaySelected: (d, f) {
                setState(() {
                  _selected = d;
                  _focused = f;
                });
              },
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.white70,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                ),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                outsideTextStyle: const TextStyle(color: Colors.white24),
                todayDecoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final did = rec.didWorkout(day);
                  if (!did) return null;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Image.asset(
                        'assets/images/fire_stamp.png',
                        width: 14,
                        height: 14,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 선택 날짜
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF303030),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _yyyyMMdd(_selected),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 리스트 or 빈상태
          Expanded(
            child: items.isEmpty
                ? _EmptyState(
                    onAdd: () => _openManualAdd(
                      context,
                      onSaved: () {
                        setState(() {});
                      },
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.routineName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.doneSets} set · ${r.doneRepsTotal}회',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: items.length,
                  ),
          ),

          // 직접 추가 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openManualAdd(
                  context,
                  onSaved: () {
                    setState(() {});
                  },
                ),
                child: const Text(
                  '운동 기록 직접 추가',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 수동 추가 ==========
  Future<void> _openManualAdd(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    final rec = context.read<RecordViewModel>();
    final nameCtl = TextEditingController();
    final setCtl = TextEditingController(text: '1');
    final repCtl = TextEditingController(text: '10');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '운동 수동 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: '운동명',
                controller: nameCtl,
                hint: '예) 스쿼트',
                maxLen: 20,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      label: '세트(최대 100)',
                      controller: setCtl,
                      max: 100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      label: '횟수(최대 200)',
                      controller: repCtl,
                      max: 200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameCtl.text.trim();
                    final sets = int.tryParse(setCtl.text) ?? 0;
                    final reps = int.tryParse(repCtl.text) ?? 0;
                    if (name.isEmpty || sets <= 0 || reps <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('이름/세트/횟수를 확인하세요')),
                      );
                      return;
                    }
                    if (sets > 100 || reps > 200) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('허용 범위를 초과했어요')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);

                    // 선택 날짜의 현재 시각으로 저장
                    final now = DateTime.now();
                    final saveAt = DateTime(
                      _selected.year,
                      _selected.month,
                      _selected.day,
                      now.hour,
                      now.minute,
                      now.second,
                    );
                    rec.saveWorkout(
                      dateTime: saveAt,
                      routineId: _slug(name),
                      routineName: name,
                      sets: sets,
                      repsPerSet: reps,
                      durationSec: 0,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A2B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (ok == true) {
      onSaved?.call();
    }
  }

  String _yyyyMMdd(DateTime d) =>
      '${d.year.toString().substring(2)}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _slug(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

// ====== 빈상태 위젯 ======
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6A2B);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Icon(
            Icons.emoji_emotions_outlined,
            size: 84,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          const Text('진행한 운동이 없어요', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAdd,
            child: const Text(
              '운동 기록 직접 추가',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== 작은 입력 위젯들 ======
class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int? maxLen;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLen,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2B2B2B),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int max;
  const _NumberField({
    required this.label,
    required this.controller,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '숫자',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2B2B2B),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
