import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/widgets/workout_completed_dialog.dart';

void main() {
  testWidgets('운동 완료 카드는 기록 안내를 보여주고 탭하면 닫힌다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showWorkoutCompletedDialog(
              context,
              visibleFor: const Duration(minutes: 1),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('운동을 완수했어요!'), findsOneWidget);
    expect(find.text('달력에 도장을 찍어드렸어요'), findsOneWidget);

    await tester.tap(find.text('운동을 완수했어요!'));
    await tester.pumpAndSettle();
    expect(find.text('운동을 완수했어요!'), findsNothing);
  });
}
