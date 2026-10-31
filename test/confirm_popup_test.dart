import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/widgets/confirm_popup.dart';

void main() {
  testWidgets('확인 팝업은 안내 문구와 선택 결과를 반환한다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showConfirmPopup(
                context,
                title: '종료하시겠어요?',
                message: '기록중이던 루틴은 저장되지 않아요',
                cancelText: '취소',
                okText: '종료',
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('기록중이던 루틴은 저장되지 않아요'), findsOneWidget);

    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
