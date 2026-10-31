import 'dart:async';

import 'package:counter_01/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RecordingTts extends FlutterTts {
  final calls = <String>[];
  bool failLanguage = false;
  List<Map<String, String>> voices = [];
  @override
  Future<dynamic> get getVoices async => voices;
  @override
  Future<dynamic> setVoice(Map<String, String> voice) async =>
      calls.add("voice:${voice['identifier']}");
  @override
  Future<dynamic> stop() async => calls.add("stop");
  @override
  Future<dynamic> setSharedInstance(bool shared) async =>
      calls.add('shared:$shared');
  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    expect(category, IosTextToSpeechAudioCategory.playback);
    expect(
      options,
      contains(IosTextToSpeechAudioCategoryOptions.mixWithOthers),
    );
    calls.add('iosAudio');
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    calls.add(language);
    if (failLanguage) throw StateError('unavailable');
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setVolume(double volume) async => 1;
  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;
  @override
  Future<dynamic> setQueueMode(int mode) async => calls.add('queue');
  @override
  Future<dynamic> setPitch(double pitch) async => 1;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    calls.add('speak:$text');
    return 1;
  }
}

class BlockingTts extends RecordingTts {
  final completions = <Completer<dynamic>>[];
  bool reject = false;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) {
    calls.add('speak:$text');
    if (reject || completions.any((entry) => !entry.isCompleted)) {
      return Future<dynamic>.value(0);
    }
    final completion = Completer<dynamic>();
    completions.add(completion);
    return completion.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'overlapping requests finish in order instead of being rejected',
    () async {
      final engine = BlockingTts();
      final service = TtsService.forTesting(engine, isAndroid: true);
      final speeches = [
        service.count(1, start: true, force: true),
        service.count(2, force: true),
        service.restCount(1, force: true),
      ];
      for (var index = 0; index < speeches.length; index++) {
        await Future<void>.delayed(Duration.zero);
        expect(engine.completions.length, index + 1);
        engine.completions[index].complete(1);
        await speeches[index];
      }
      expect(engine.calls.where((call) => call.startsWith('speak:')), [
        'speak:시작! 하나!',
        'speak:둘!',
        'speak:휴식! 1!',
      ]);
    },
  );
  test(
    'stop clears queued speech even when native cancellation never returns',
    () async {
      final engine = BlockingTts();
      final service = TtsService.forTesting(engine, isAndroid: true);
      final first = service.count(1, start: true, force: true);
      final queued = service.restCount(1, force: true);
      await Future<void>.delayed(Duration.zero);
      await service.stop();
      await Future.wait([first, queued]);
      expect(engine.calls.where((call) => call.startsWith('speak:')), [
        'speak:시작! 하나!',
      ]);
      engine.completions.single.complete(0);
      final next = service.count(1, start: true, force: true);
      await Future<void>.delayed(Duration.zero);
      engine.completions.last.complete(1);
      await next;
      expect(engine.completions.length, 2);
    },
  );
  test('native rejection is an error, not successful playback', () async {
    final engine = BlockingTts()..reject = true;
    final service = TtsService.forTesting(engine, isAndroid: true);
    await expectLater(service.count(1, force: true), throwsStateError);
    engine.reject = false;
    final retry = service.count(1, force: true);
    await Future<void>.delayed(Duration.zero);
    engine.completions.single.complete(1);
    await retry;
  });
  testWidgets(
    'missing completion times out instead of blocking counting forever',
    (tester) async {
      final engine = BlockingTts();
      final service = TtsService.forTesting(engine, isIOS: true);
      await service.warmUp();
      final speech = service.count(1, force: true);
      final error = expectLater(speech, throwsA(isA<TimeoutException>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      await error;
      expect(engine.calls.last, 'stop');
    },
  );
  test(
    'iOS configures playback once and never calls Android queue API',
    () async {
      final engine = RecordingTts();
      final service = TtsService.forTesting(engine, isIOS: true);
      await Future.wait([service.warmUp(), service.warmUp()]);
      await service.count(1, totalReps: 10, force: true);
      expect(engine.calls, ['shared:true', 'iosAudio', 'ko-KR', 'speak:하나!']);
    },
  );
  test('failed initialization can retry', () async {
    final engine = RecordingTts()..failLanguage = true;
    final service = TtsService.forTesting(engine, isIOS: true);
    await expectLater(service.warmUp(), throwsStateError);
    engine.failLanguage = false;
    await service.warmUp();
    expect(engine.calls.where((call) => call == 'ko-KR').length, 2);
  });
  test('Android retains flush queue mode', () async {
    final engine = RecordingTts();
    await TtsService.forTesting(engine, isAndroid: true).warmUp();
    expect(engine.calls, ['ko-KR', 'queue']);
  });
  for (final isIOS in [false, true]) {
    test('start and rest cues use one native utterance: iOS=$isIOS', () async {
      final engine = RecordingTts();
      final service = TtsService.forTesting(
        engine,
        isIOS: isIOS,
        isAndroid: !isIOS,
      );
      await service.count(1, start: true, force: true);
      await service.count(2, start: true, totalReps: 3, force: true);
      await service.restCount(1, force: true);
      await service.restCount(2, force: true);
      expect(engine.calls.where((call) => call.startsWith('speak:')), [
        'speak:시작! 하나!',
        'speak:둘!',
        'speak:휴식! 1!',
        'speak:2!',
      ]);
    });
  }
  test(
    'Android voices use their names and native quality, not iOS ids',
    () async {
      final engine = RecordingTts()
        ..voices = [
          {'name': 'en-us-local', 'locale': 'en-US', 'quality': 'very high'},
          {
            'name': 'ko-kr-local',
            'locale': 'ko-KR',
            'quality': 'normal',
            'network_required': '0',
          },
          {
            'name': 'ko-kr-network',
            'locale': 'ko-KR',
            'quality': 'very high',
            'network_required': '1',
          },
          {'name': 'ko-kr-high', 'locale': 'ko-KR', 'quality': 'high'},
        ];
      final service = TtsService.forTesting(engine, isAndroid: true);
      final voices = await service.systemVoices();
      expect(voices.map((v) => v.id), [
        'ko-kr-network',
        'ko-kr-high',
        'ko-kr-local',
      ]);
      expect(voices.first.detail, '최고 품질 · 인터넷 필요');
      expect(voices[1].qualityLabel, '고품질');
      expect(voices.last.networkRequired, isFalse);
      await service.preview(voices.last);
      expect(engine.calls, contains('voice:ko-kr-local'));
      await service.speak('하나!', voiceId: 'com.apple.old.voice', force: true);
      expect(engine.calls, contains('voice:ko-kr-network'));
      expect(engine.calls, isNot(contains('iosAudio')));
    },
  );
  test(
    'only installed Korean voices appear, with higher quality first',
    () async {
      final engine = RecordingTts()
        ..voices = [
          {'identifier': 'english', 'name': 'English', 'locale': 'en-US'},
          {
            'identifier': 'ko-basic',
            'name': '기본',
            'locale': 'ko-KR',
            'quality': 'default',
            'gender': 'female',
          },
          {
            'identifier': 'ko-enhanced',
            'name': '고품질',
            'locale': 'ko-KR',
            'quality': 'enhanced',
            'gender': 'male',
          },
        ];
      final service = TtsService.forTesting(engine, isIOS: true);
      final voices = await service.systemVoices();
      expect(voices.map((v) => v.id), ['ko-enhanced', 'ko-basic']);
      expect(voices.first.detail, '남성 · 고품질');
      await service.preview(voices.last);
      expect(engine.calls, contains('voice:ko-basic'));
      await service.speak('테스트', voiceId: 'removed', force: true);
      expect(engine.calls, contains('voice:ko-enhanced'));
    },
  );
}
