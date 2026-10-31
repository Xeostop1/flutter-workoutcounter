import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/models/routine.dart';
import 'package:counter_01/widgets/home/routine_list.dart';

void main() {
  testWidgets('빈 홈 루틴은 등록 버튼과 안내를 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineList(routines: const [], onPlay: (_) {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('루틴이 비어있어요!'), findsOneWidget);
    expect(find.text('루틴을 등록하고 운동을 시작해보세요.'), findsOneWidget);
  });

  testWidgets('홈 루틴은 세 개씩 페이지로 나뉜다', (tester) async {
    final routines = List.generate(
      4,
      (index) =>
          Routine(id: '$index', title: '루틴 ${index + 1}', categoryId: 'test'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineList(routines: routines, onPlay: (_) {}),
        ),
      ),
    );

    expect(find.text('루틴 1'), findsOneWidget);
    expect(find.text('루틴 4'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('루틴 4'), findsOneWidget);
  });
}
