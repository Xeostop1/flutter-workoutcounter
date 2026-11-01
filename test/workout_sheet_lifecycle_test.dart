import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/widgets/edit_exercise_sheet.dart';
import 'package:counter_01/widgets/free_workout_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final tutorial in [false, true]) {
    for (final save in [false, true]) {
      testWidgets(
        '실제 자유 운동 설정 ${tutorial ? '튜토리얼' : '일반'} 입력 후 ${save ? '시작' : '취소'}',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          Routine? received;
          final router = GoRouter(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) => Scaffold(
                  body: FilledButton(
                    onPressed: () =>
                        showFreeWorkoutSheet(context, tutorialMode: tutorial),
                    child: const Text('설정 열기'),
                  ),
                ),
              ),
              GoRoute(
                path: '/counter',
                builder: (_, state) {
                  received = state.extra! as Routine;
                  return const Scaffold(body: Text('운동 화면'));
                },
              ),
            ],
          );
          await tester.pumpWidget(MaterialApp.router(routerConfig: router));
          await tester.pumpAndSettle();
          await tester.tap(find.text('설정 열기'));
          await tester.pumpAndSettle();
          final fields = find.byType(TextField);
          expect(fields, findsNWidgets(4));
          for (var index = 0; index < 4; index++) {
            await tester.ensureVisible(fields.at(index));
            await tester.enterText(
              fields.at(index),
              ['QA 운동', '2', '3', '1'][index],
            );
          }
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          if (save) {
            await tester.ensureVisible(find.text('시작하기'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('시작하기'));
          } else {
            Navigator.of(tester.element(fields.first)).pop();
          }
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(milliseconds: 60));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsNothing);
          if (save) {
            expect(received!.items.single.name, 'QA 운동');
            expect(received!.items.single.sets, 2);
            expect(received!.items.single.reps, 3);
            expect(received!.items.single.repSeconds, 1);
          } else {
            expect(received, isNull);
            expect(find.text('설정 열기'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
        },
      );
    }
  }

  for (final save in [false, true]) {
    testWidgets('실제 운동 수정창에서 키보드 입력 후 ${save ? '적용' : '취소'}', (tester) async {
      Exercise? received;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  received = await showEditExerciseSheet(
                    context,
                    initial: const Exercise(
                      id: 'qa',
                      name: '스쿼트',
                      sets: 2,
                      reps: 3,
                      repSeconds: 1,
                    ),
                  );
                },
                child: const Text('수정 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('수정 열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'QA 수정');
      if (save) {
        await tester.tap(find.widgetWithText(FilledButton, '수정'));
      } else {
        Navigator.of(tester.element(find.byType(TextField).first)).pop();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(save ? received?.name : received, save ? 'QA 수정' : null);
    });
  }
}
