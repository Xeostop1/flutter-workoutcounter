import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/record_viewmodel.dart';
import '../../widgets/record_empty_cta.dart';
import '../counter/counter_page.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../services/tts_service.dart';
import '../../viewmodels/settings_viewmodel.dart';

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
    final settings = context.read<SettingsViewModel>();

    final list = rec.byDate(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // 프로필 + 통계 (로그인X면 디폴트)
          ListTile(
            leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
            title: const Text('닉네임'),
            subtitle: Text(
              "지난달 보다 ${list.isEmpty ? '0' : list.length}일 더 운동했어요",
            ),
          ),
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
          Expanded(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: RecordEmptyCTA(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => CounterViewModel(
                                tts: TtsService()
                                  ..init(voice: settings.voiceId),
                                settings: settings,
                                records: rec,
                              ),
                              child: const CounterPage(),
                            ),
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
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () {
                // 수동 추가(간단: 오늘 완료 1세트 기록)
                // 실제 앱에서는 입력 다이얼로그로 확장
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
