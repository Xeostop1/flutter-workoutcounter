import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android 12 wordmark fits completely inside the circular safe area',
    () async {
      final xml = File(
        '$_res/drawable/sporkle_wordmark.xml',
      ).readAsStringSync();
      final scale = double.parse(
        RegExp(r'android:scaleX="([\d.]+)"').firstMatch(xml)!.group(1)!,
      );
      expect(scale, .68);
      final image = await _wordmark();
      addTearDown(image.dispose);
      expect(image.width, 1152);
      expect(image.height, 1152);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var colored = 0;
      var clipped = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final index = (y * image.width + x) * 4;
          if (pixels.getUint8(index + 3) == 0 ||
              pixels.getUint8(index) +
                      pixels.getUint8(index + 1) +
                      pixels.getUint8(index + 2) ==
                  0) {
            continue;
          }
          colored++;
          final dx = (x + 0.5 - 576) / 4 * scale;
          final dy = (y + 0.5 - 576) / 4 * scale;
          if (dx * dx + dy * dy > 96 * 96) clipped++;
        }
      }
      expect(colored, greaterThan(0));
      expect(
        clipped,
        0,
        reason: 'No visible logo pixel may extend outside the 192dp circle.',
      );
    },
  );

  test(
    'Android launch screens use vectors on black and retain generated day/night themes',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:theme="@style/SporkleLaunchTheme"'));
      final base = File(
        '$_res/values/sporkle_launch_theme.xml',
      ).readAsStringSync();
      expect(base, contains('parent="@style/LaunchTheme"'));
      expect(base, isNot(contains('windowSplashScreenAnimatedIcon')));
      expect(base, contains('@drawable/sporkle_launch_background'));
      final background = File(
        '$_res/drawable/sporkle_launch_background.xml',
      ).readAsStringSync();
      expect(background, contains('@android:color/black'));
      expect(background, contains('android:gravity="center"'));
      expect(background, contains('@drawable/sporkle_wordmark'));
      expect(background, contains('android:width="288dp"'));
      final modern = File(
        '$_res/values-v31/sporkle_launch_theme.xml',
      ).readAsStringSync();
      expect(modern, contains('parent="@style/LaunchTheme"'));
      expect(modern, contains('@drawable/sporkle_splash_vector'));
      final wrapper = File(
        '$_res/drawable-v31/sporkle_splash_vector.xml',
      ).readAsStringSync();
      expect(
        wrapper,
        contains('android:drawable="@drawable/sporkle_wordmark"'),
      );
      final vector = File(
        '$_res/drawable/sporkle_wordmark.xml',
      ).readAsStringSync();
      expect(vector, contains('<vector'));
      expect(vector, isNot(contains('<bitmap')));
      for (final folder in ['values-v31', 'values-night-v31']) {
        expect(
          File('$_res/$folder/styles.xml').readAsStringSync(),
          contains('name="LaunchTheme"'),
        );
      }
      for (final folder in ['values', 'values-night']) {
        expect(
          File('$_res/$folder/styles.xml').readAsStringSync(),
          contains('@drawable/launch_background'),
        );
      }
    },
  );

  test(
    'Android 12 bypasses static low-resolution caching without visible motion',
    () {
      final wrapper = File(
        '$_res/drawable-v31/sporkle_splash_vector.xml',
      ).readAsStringSync();
      expect(wrapper, contains('<animated-vector'));
      expect(wrapper, contains('android:name="wordmark"'));
      expect(wrapper, contains('@animator/sporkle_logo_still'));
      final animation = File(
        '$_res/animator/sporkle_logo_still.xml',
      ).readAsStringSync();
      expect(animation, contains('android:propertyName="rotation"'));
      expect(animation, contains('android:valueFrom="0" android:valueTo="0"'));
      expect(animation, contains('android:duration="1"'));
      final vector = File(
        '$_res/drawable/sporkle_wordmark.xml',
      ).readAsStringSync();
      expect(vector, contains('android:name="wordmark"'));
      expect(vector, contains('android:pivotX="576" android:pivotY="576"'));
      expect(vector, contains('android:scaleX="0.68" android:scaleY="0.68"'));
      expect(
        File('$_res/drawable-v31/android12_splash_safe.xml').existsSync(),
        isFalse,
      );
    },
  );

  test('vector preserves the existing wordmark shape and colors', () async {
    final original = await _image('assets/icons/splash_1.png');
    final vector = await _wordmark();
    addTearDown(original.dispose);
    addTearDown(vector.dispose);
    final source = (await original.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final rendered = (await vector.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    var changed = 0, visible = 0;
    int color(ByteData data, int at) {
      if (data.getUint8(at + 3) < 128 || data.getUint8(at) < 128) return 0;
      return data.getUint8(at + 1) >= 128 ? 1 : 2;
    }

    for (var i = 0; i < source.lengthInBytes; i += 4) {
      final expected = color(source, i), actual = color(rendered, i);
      if (expected != 0 || actual != 0) visible++;
      if (expected != actual) changed++;
    }
    expect(visible, greaterThan(80000));
    expect(
      changed / visible,
      lessThan(.01),
      reason: 'Trace must preserve over 99% of the original colored pixels.',
    );
    final xml = File('$_res/drawable/sporkle_wordmark.xml').readAsStringSync();
    expect(xml, contains('android:fillColor="#ffffff"'));
    expect(xml, contains('android:fillColor="#ff5722"'));
  });

  test('Android icon regeneration uses the approved black iOS source only', () {
    final config = File(
      'flutter_launcher_icons_android.yaml',
    ).readAsStringSync();
    expect(config, contains('ios: false'));
    expect(
      config,
      contains(
        'image_path_android: "assets/icons/app_icon_ios_original_black.png"',
      ),
    );
    expect(
      config,
      contains(
        'adaptive_icon_foreground: "assets/icons/app_icon_ios_original_black.png"',
      ),
    );
    expect(config, contains('adaptive_icon_background: "#000000"'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(
        'image_path_android: "assets/icons/app_icon_ios_original_black.png"',
      ),
    );
    expect(
      pubspec,
      contains(
        'image_path_ios: "assets/icons/app_icon_ios_original_black.png"',
      ),
    );
    expect(
      pubspec,
      isNot(contains('adaptive_icon_foreground: "assets/icons/app_icon.png"')),
    );
    final colors = File('$_res/values/colors.xml').readAsStringSync();
    expect(
      colors,
      contains('<color name="ic_launcher_background">#000000</color>'),
    );
  });

  test(
    'every Android icon density has a black opaque corner, not the old white frame',
    () async {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final entry in sizes.entries) {
        for (final foreground in [false, true]) {
          final path = foreground
              ? '$_res/drawable-${entry.key}/ic_launcher_foreground.png'
              : '$_res/mipmap-${entry.key}/launcher_icon.png';
          final image = await _image(path);
          addTearDown(image.dispose);
          expect(
            image.width,
            foreground ? (entry.value * 2.25).round() : entry.value,
          );
          expect(image.height, image.width);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          expect(
            [for (var c = 0; c < 4; c++) pixels.getUint8(c)],
            [0, 0, 0, 255],
            reason: path,
          );
        }
      }
    },
  );

  test(
    'branding previews render vector at multiple densities and adaptive masks',
    () async {
      final wordmark = await _wordmark();
      final icon = await _image(
        '$_res/drawable-xxxhdpi/ic_launcher_foreground.png',
      );
      addTearDown(wordmark.dispose);
      addTearDown(icon.dispose);
      for (final density in [1.0, 1.5, 2.0, 3.0, 4.0]) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.scale(density);
        canvas.drawColor(const ui.Color(0xFF000000), ui.BlendMode.src);
        canvas.save();
        canvas.translate(144, 144);
        canvas.scale(.68 * 288 / 1152);
        canvas.translate(-576, -576);
        _drawWordmark(canvas);
        canvas.restore();
        final picture = recorder.endRecording();
        final size = (288 * density).round();
        final output = await picture.toImage(size, size);
        picture.dispose();
        expect(output.width, size);
        if (const bool.fromEnvironment('BRANDING_PREVIEWS')) {
          await File(
            'verification/android-branding-20261031/wordmark-${density}x.png',
          ).writeAsBytes(
            (await output.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List(),
          );
        }
        output.dispose();
      }
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFF151515), ui.BlendMode.src);
      for (var index = 0; index < 2; index++) {
        canvas.save();
        final rect = ui.Rect.fromLTWH(24.0 + index * 240, 24, 192, 192);
        if (index == 0) {
          canvas.clipPath(ui.Path()..addOval(rect));
        } else {
          canvas.clipRRect(
            ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(43)),
          );
        }
        canvas.drawColor(const ui.Color(0xFF000000), ui.BlendMode.srcOver);
        final inset = (192 - 192 * 108 / 72 * .68) / 2;
        canvas.drawImageRect(
          icon,
          ui.Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
          rect.deflate(inset),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final output = await picture.toImage(480, 240);
      picture.dispose();
      if (const bool.fromEnvironment('BRANDING_PREVIEWS')) {
        await File(
          'verification/android-branding-20261031/black-icons-preview.png',
        ).writeAsBytes(
          (await output.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List(),
        );
      }
      output.dispose();
    },
  );
}

Future<ui.Image> _image(String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

Future<ui.Image> _wordmark() async {
  final recorder = ui.PictureRecorder();
  _drawWordmark(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(1152, 1152);
  } finally {
    picture.dispose();
  }
}

void _drawWordmark(ui.Canvas canvas) {
  // Draw raw path geometry; splash-preview code applies the tested 0.68 padding.
  final xml = File('$_res/drawable/sporkle_wordmark.xml').readAsStringSync();
  for (final match in RegExp(
    r'<path android:fillColor="#([0-9a-f]+)" android:pathData="([^"]+)"',
  ).allMatches(xml)) {
    final path = ui.Path();
    final tokens = RegExp(
      r'[MLZ]|\d+',
    ).allMatches(match.group(2)!).map((m) => m[0]!).toList();
    for (var i = 0; i < tokens.length;) {
      final command = tokens[i++];
      if (command == 'Z') {
        path.close();
        continue;
      }
      final x = double.parse(tokens[i++]), y = double.parse(tokens[i++]);
      if (command == 'M') {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = ui.Color(0xFF000000 | int.parse(match.group(1)!, radix: 16)),
    );
  }
}
