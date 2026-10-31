import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/pages/records/sections/daily_records_section.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('중간 종료 기록은 전체 계획 대신 실제 총 횟수를 표시한다', (tester) async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    await records.addRecord(
      WorkoutRecord(
        date: DateTime.now(),
        routineId: 'partial-routine',
        routineTitle: '하체 운동',
        totalReps: 3,
        exercises: const [
          Exercise(id: 'squat', name: '스쿼트', sets: 2, reps: 10, repSeconds: 1),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: records,
          child: const Scaffold(body: DailyRecordsSection()),
        ),
      ),
    );

    expect(find.text('진행한 운동'), findsOneWidget);
    expect(find.text('총 3회'), findsOneWidget);
    expect(find.text('2세트 · 10회'), findsNothing);
  });

  testWidgets('완료한 기록은 실제 총 횟수와 운동 수 및 세트 내역을 표시한다', (tester) async {
    final records = RecordsViewModel(InMemoryRecordRepository());
    addTearDown(records.dispose);
    await records.addRecord(
      WorkoutRecord(
        date: DateTime.now(),
        routineId: 'legs',
        routineTitle: '하체 운동',
        totalReps: 60,
        exercises: const [
          Exercise(id: 'squat', name: '스쿼트', sets: 2, reps: 10, repSeconds: 1),
          Exercise(id: 'lunge', name: '런지', sets: 2, reps: 10, repSeconds: 1),
          Exercise(
            id: 'calf',
            name: '카프 레이즈',
            sets: 2,
            reps: 10,
            repSeconds: 1,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: records,
          child: const Scaffold(body: DailyRecordsSection(embed: true)),
        ),
      ),
    );
    expect(find.text('총 60회 · 3개 운동'), findsOneWidget);
    expect(find.text('2세트 · 10회'), findsNWidgets(3));
    expect(find.text('기록 추가'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
