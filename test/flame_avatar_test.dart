import 'dart:ui' as ui;

import 'package:counter_01/widgets/flame_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('기존 -2..10 단계는 승인된 13개 파일에 순서대로 연결된다', () {
    expect(FlameArtwork.stages.length, 13);
    expect(FlameArtwork.stages.map(FlameArtwork.asset).toSet().length, 13);
    for (var i = 0; i < 13; i++) {
      expect(FlameArtwork.index(FlameArtwork.stages[i]), i);
      expect(
        FlameArtwork.asset(FlameArtwork.stages[i]),
        'assets/images/flames_v2/stage-${(i + 1).toString().padLeft(2, '0')}.png',
      );
    }
    expect(FlameArtwork.asset(-999), FlameArtwork.asset(-2));
    expect(FlameArtwork.asset(999), FlameArtwork.asset(10));
  });

  testWidgets('13개 고해상도 PNG가 번들에 있고 투명 배경을 보존한다', (tester) async {
    await tester.runAsync(() async {
      for (final stage in FlameArtwork.stages) {
        final bytes = await rootBundle.load(FlameArtwork.asset(stage));
        final descriptor = await ui.ImmutableBuffer.fromUint8List(
          bytes.buffer.asUint8List(),
        );
        final imageDescriptor = await ui.ImageDescriptor.encoded(descriptor);
        expect(imageDescriptor.width, greaterThanOrEqualTo(1000));
        expect(imageDescriptor.height, imageDescriptor.width);
        final codec = await imageDescriptor.instantiateCodec(targetWidth: 64);
        expect(codec.frameCount, 1);
        final frame = await codec.getNextFrame();
        final pixels = (await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        expect(pixels[3], 0);
        expect(
          [
            for (var i = 3; i < pixels.length; i += 4) pixels[i],
          ].any((alpha) => alpha > 128),
          isTrue,
        );
        frame.image.dispose();
        codec.dispose();
        imageDescriptor.dispose();
        descriptor.dispose();
      }
    });
  });

  testWidgets('숨쉬기 동작은 한 주기로 자연스럽게 반복한다', (tester) async {
    await _pump(tester);
    final initial = _scale(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect((_scale(tester) - initial).abs(), greaterThan(.005));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(_scale(tester), closeTo(initial, .001));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('움직임 줄이기와 비활성 경로에서는 반복을 멈춘다', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await _pump(tester, reduced: true);
    final still = _scale(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_scale(tester), still);
    expect(tester.binding.transientCallbackCount, 0);
    await _pump(tester, ticker: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_scale(tester), closeTo(1, .001));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('앱 백그라운드에서 멈추고 돌아오면 다시 움직인다', (tester) async {
    await _pump(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_scale(tester), closeTo(1, .001));
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect((_scale(tester) - 1).abs(), greaterThan(.005));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('고밀도 화면에서도 불필요한 초대형 디코딩을 제한한다', (tester) async {
    await _pump(tester, reduced: true, ratio: 8);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as ResizeImage).width, 1024);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pump(
  WidgetTester tester, {
  bool reduced = false,
  bool ticker = true,
  double ratio = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduced,
          devicePixelRatio: ratio,
        ),
        child: TickerMode(
          enabled: ticker,
          child: const Center(child: FlameAvatar(stage: 3, size: 160)),
        ),
      ),
    ),
  );
}

double _scale(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(FlameAvatar),
        matching: find.byType(Transform),
      ),
    )
    .last
    .transform
    .entry(0, 0);
