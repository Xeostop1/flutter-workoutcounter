import 'package:counter_01/theme/app_theme.dart';
import 'package:counter_01/widgets/trainer_voice_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('미리듣기는 저장하지 않고 선택 버튼에서만 확정한다', (tester) async {
    final previews = <TrainerVoice>[];
    TrainerVoice? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TrainerVoicePicker(
            initialSelection: TrainerVoice.male,
            preview: (voice) async => previews.add(voice),
            onApply: (voice) => applied = voice,
          ),
        ),
      ),
    );
    await tester.tap(find.text('여성 트레이너 미리듣기'));
    await tester.pumpAndSettle();
    expect(previews, [TrainerVoice.female]);
    expect(applied, isNull);
    await tester.tap(find.text('여성 트레이너'));
    await tester.pump();
    await tester.tap(find.text('이 목소리로 선택'));
    expect(applied, TrainerVoice.female);
  });

  testWidgets('미리듣기 실패를 안내하고 다시 재생할 수 있다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TrainerVoicePicker(
            initialSelection: null,
            preview: (_) async {
              calls++;
              throw StateError('missing sample');
            },
            onApply: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('남성 트레이너 미리듣기'));
    await tester.pumpAndSettle();
    expect(find.text('미리듣기를 재생하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.text('남성 트레이너 미리듣기'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}
