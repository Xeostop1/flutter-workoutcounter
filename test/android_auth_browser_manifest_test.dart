import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final queries = RegExp(
    r'<queries\b[^>]*>([\s\S]*?)</queries>',
  ).firstMatch(manifest)!.group(1)!;
  final intents = RegExp(
    r'<intent\b[^>]*>[\s\S]*?</intent>',
  ).allMatches(queries).map((match) => match.group(0)!);

  test('Android OAuth can discover an HTTPS browser on Android 11+', () {
    expect(
      intents.any(
        (intent) =>
            intent.contains('android.intent.action.VIEW') &&
            intent.contains('android:scheme="https"'),
      ),
      isTrue,
      reason: 'Firebase must be able to discover the OAuth browser.',
    );
  });

  test('Android OAuth can discover the Custom Tabs service on Android 11+', () {
    expect(
      intents.any(
        (intent) => intent.contains(
          'android.support.customtabs.action.CustomTabsService',
        ),
      ),
      isTrue,
      reason:
          'Without service visibility Firebase falls back to an external tab.',
    );
  });
}
