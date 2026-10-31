import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/widgets/free_workout_sheet.dart';

void main() {
  testWidgets('첫 운동 설정은 입력 후에도 시작 버튼을 누르기 전까지 유지된다', (tester) async {
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
    expect(find.text('처음에는 가볍게 1세트부터 시작해보세요.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '첫 운동');
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));

    Navigator.of(tester.element(find.text('자유 운동 설정'))).pop();
    await tester.pumpAndSettle();
  });
}
