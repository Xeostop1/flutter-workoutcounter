import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../viewmodels/record_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/record_empty_cta.dart';
import '../counter/counter_page.dart';

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
    final rec = context.watch<RecordViewModel>();
    final auth = context.watch<AuthViewModel>();

    final list = auth.isLoggedIn ? rec.byDate(_selected) : <dynamic>[];

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // 프로필/안내
          ListTile(
            leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
            title: Text(auth.isLoggedIn ? '닉네임' : '게스트 모드'),
            subtitle: Text(
              auth.isLoggedIn
                  ? "지난달 보다 ${list.isEmpty ? '0' : list.length}일 더 운동했어요"
                  : "로그인하면 운동 기록이 달력에 저장돼요",
            ),
            trailing: auth.isLoggedIn
                ? null
                : TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/landing'),
                    child: const Text('로그인'),
                  ),
          ),

          // 달력: 게스트는 마커 표시 안 함
          TableCalendar(
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
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFFFE0CC),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFFF7A3D),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (!auth.isLoggedIn) return null; // ★ 게스트: 마커 없음
                final did = rec.didWorkout(day);
                if (!did) return null;
                return const Align(
                  alignment: Alignment.bottomCenter,
                  child: Text("🔥", style: TextStyle(fontSize: 12)),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 본문: 게스트면 안내 CTA, 로그인 사용자면 리스트
          Expanded(
            child: !auth.isLoggedIn
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: RecordEmptyCTA(
                      // 게스트에게는 "운동 시작"으로 카운터만 열어줌
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CounterPage(),
                          ),
                        );
                      },
                    ),
                  )
                : (list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: RecordEmptyCTA(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CounterPage(),
                                ),
                              );
                            },
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (_, i) {
                            final r = list[i];
                            return ListTile(
                              leading: const Icon(Icons.local_fire_department),
                              title: Text(r.routineName),
                              subtitle: Text(
                                "${r.doneSets} set · ${r.doneRepsTotal}회",
                              ),
                              trailing: Text(
                                "${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}",
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(),
                          itemCount: list.length,
                        )),
          ),

          // 하단 "운동 기록 추가": 게스트에겐 비노출
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: () {
                  // 수동 추가(실제 앱에서는 입력 다이얼로그로 확장)
                  // ...
                },
                icon: const Icon(Icons.add),
                label: const Text('운동 기록 추가'),
              ),
            ),
        ],
      ),
    );
  }
}
