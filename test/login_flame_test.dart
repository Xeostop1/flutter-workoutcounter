import 'dart:ui' as ui;

import 'package:counter_01/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved halo and shadow animation loops smoothly at 50fps', () async {
    final bytes = await rootBundle.load(
      'assets/images/login_flame_approved.webp',
    );
    expect(bytes.lengthInBytes, lessThan(4000000));
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: 64,
    );
    addTearDown(codec.dispose);
    expect(codec.frameCount, 300);
    expect(codec.repetitionCount, -1);
    var duration = Duration.zero;
    final brightness = <int>[];
    for (var i = 0; i < codec.frameCount; i++) {
      final frame = await codec.getNextFrame();
      expect(frame.duration, const Duration(milliseconds: 20));
      duration += frame.duration;
      final pixels = (await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var light = 0;
      for (var pixel = 0; pixel < pixels.lengthInBytes; pixel += 4) {
        light +=
            pixels.getUint8(pixel) +
            pixels.getUint8(pixel + 1) +
            pixels.getUint8(pixel + 2);
      }
      brightness.add(light);
      frame.image.dispose();
    }
    expect(duration.inMilliseconds, 6000);
    expect(brightness.toSet().length, greaterThan(12));
    expect(
      brightness.reduce((a, b) => a > b ? a : b),
      greaterThan(brightness.first * 1.2),
    );
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'reduced motion $reducedMotion selects animation or bright still',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: const LoginPage(),
            ),
          ),
        );
        final image = tester.widget<Image>(
          find.byKey(const ValueKey('login-flame')),
        );
        expect(
          (image.image as AssetImage).assetName,
          reducedMotion
              ? 'assets/images/login_flame_still.png'
              : 'assets/images/login_flame_approved.webp',
        );
        expect(image.excludeFromSemantics, isTrue);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
