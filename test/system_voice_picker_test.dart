import 'package:counter_01/models/system_voice.dart';
import 'package:counter_01/widgets/system_voice_picker.dart';
import 'package:counter_01/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const voices = [
  SystemVoice(
    id: 'ko-a',
    name: '한국어 A',
    locale: 'ko-KR',
    gender: 'male',
    quality: 'enhanced',
  ),
  SystemVoice(id: 'ko-b', name: '한국어 B', locale: 'ko-KR', gender: 'female'),
];
void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('voice sheet identifies the actual $platform device', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getVoices') return [];
            return 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSystemVoicePicker(context),
                child: const Text('목소리 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('목소리 열기'));
      await tester.pumpAndSettle();
      expect(
        find.text(platform == TargetPlatform.android ? '안드로이드 목소리' : '아이폰 목소리'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('이 목소리로 선택'));
      await tester.tap(find.text('이 목소리로 선택'));
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });
  }
  test('Korean exercise counts cover ones, tens, hundreds', () {
    expect(
      [
        1,
        2,
        3,
        4,
        10,
        11,
        15,
        20,
        21,
        30,
        99,
        100,
        101,
        115,
        200,
      ].map(koreanCount),
      [
        '하나',
        '둘',
        '셋',
        '넷',
        '열',
        '열하나',
        '열다섯',
        '스물',
        '스물하나',
        '서른',
        '아흔아홉',
        '백',
        '백하나',
        '백열다섯',
        '이백',
      ],
    );
  });
  testWidgets('actual installed voices preview independently and apply by id', (
    tester,
  ) async {
    final previews = <String>[];
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SystemVoicePicker(
              selected: 'ko-a',
              load: () async => voices,
              preview: (voice) async => previews.add(voice.id),
              onApply: (voice) => selected = voice.id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('한국어 B 미리듣기'));
    await tester.tap(find.text('한국어 B 미리듣기'));
    await tester.pumpAndSettle();
    expect(previews, ['ko-b']);
    expect(selected, isNull);
    await tester.tap(find.text('한국어 B'));
    await tester.pump();
    await tester.ensureVisible(find.text('이 목소리로 선택'));
    await tester.tap(find.text('이 목소리로 선택'));
    expect(selected, 'ko-b');
  });
  testWidgets(
    'missing saved voice falls back to automatic without inventing voices',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SystemVoicePicker(
              selected: 'removed',
              load: () async => [],
              preview: (_) async {},
              onApply: (voice) => selected = voice.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('자동 선택'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsNothing);
      expect(find.text('이 기기의 음성 엔진에서 제공하는 목소리입니다.'), findsOneWidget);
      await tester.tap(find.text('이 목소리로 선택'));
      expect(selected, '');
    },
  );
}
