import 'dart:async';
import 'dart:convert';
import 'package:counter_01/models/trainer_voice.dart';
import 'package:counter_01/services/trainer_audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Bundle extends CachingAssetBundle {
  bool missingLast = false;
  Completer<void>? gate;
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final paths = <String>[
        for (final voice in TrainerVoice.values) ...[
          'assets/audio/trainers/${voice.id}/preview.mp3',
          for (var rep = 1; rep <= (missingLast ? 14 : 15); rep++)
            'assets/audio/trainers/${voice.id}/${rep.toString().padLeft(3, '0')}.mp3',
        ],
      ];
      return const StandardMessageCodec().encodeMessage({
        for (final path in paths)
          path: [
            {'asset': path},
          ],
      })!;
    }
    if (gate != null) await gate!.future;
    return ByteData.sublistView(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'voices': {
              for (final voice in TrainerVoice.values) voice.id: {'count': 15},
            },
          }),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sporkle/trainer_audio_test');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  test('selected male and female packs play their exact rep assets', () async {
    final service = TrainerAudioService(bundle: _Bundle(), channel: channel);
    await service.count(TrainerVoice.male, 1);
    await service.count(TrainerVoice.female, 15);
    expect(calls.map((c) => c.arguments['asset']), [
      'assets/audio/trainers/male_trainer/001.mp3',
      'assets/audio/trainers/female_trainer/015.mp3',
    ]);
    expect(await service.count(TrainerVoice.female, 16), isFalse);
    expect(calls.length, 2);
  });
  test(
    'missing audio cannot be selected or silently played as another voice',
    () async {
      final service = TrainerAudioService(
        bundle: _Bundle()..missingLast = true,
        channel: channel,
      );
      await expectLater(service.preview(TrainerVoice.male), throwsStateError);
      expect(calls, isEmpty);
    },
  );
  test('stop cancels playback that was still loading', () async {
    final gate = Completer<void>();
    final service = TrainerAudioService(
      bundle: _Bundle()..gate = gate,
      channel: channel,
    );
    final pending = service.count(TrainerVoice.female, 1);
    await service.stop();
    gate.complete();
    await pending;
    expect(calls.map((c) => c.method), ['stop']);
  });
}
