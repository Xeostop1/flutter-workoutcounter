import 'package:counter_01/widgets/routine_favorite_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('즐겨찾기 저장 실패를 안내한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => saveRoutineFavorite(
                context,
                () async => throw StateError('저장 실패'),
              ),
              child: const Text('즐겨찾기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();

    expect(find.text('즐겨찾기를 저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
  });
}
