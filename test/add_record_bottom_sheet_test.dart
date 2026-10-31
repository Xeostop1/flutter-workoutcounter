import 'dart:async';

import 'package:counter_01/widgets/add_record_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps input open when saving a manual record fails', (
    tester,
  ) async {
    final save = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    AddRecordBottomSheet(onSubmit: (_, _) => save.future),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '스쿼트');
    await tester.pump();
    await tester.tap(find.text('등록하기'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('직접 기록'), findsOneWidget);

    save.completeError(Exception('save failed'));
    await tester.pumpAndSettle();

    expect(find.text('직접 기록'), findsOneWidget);
    expect(find.text('스쿼트'), findsOneWidget);
    expect(find.text('등록하기'), findsOneWidget);
    expect(find.text('기록을 저장하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
  });
}
