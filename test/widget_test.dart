import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/widgets/free_workout_sheet.dart';

void main() {
  testWidgets('첫 운동 설정 튜토리얼이 입력 단계에서 시작 단계로 넘어간다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showFreeWorkoutSheet(context, tutorialMode: true),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('자유 운동 설정'), findsOneWidget);
    expect(find.text('내 방식대로\n운동을 입력해요'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '첫 운동');
    await tester.pump();

    expect(find.text('오늘은 간단하게\n1세트만 진행할까요?'), findsOneWidget);

    Navigator.of(tester.element(find.text('자유 운동 설정'))).pop();
    await tester.pumpAndSettle();
  });
}
