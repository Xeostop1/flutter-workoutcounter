import 'package:flutter/material.dart';
import '../view_models/tts_viewmodel.dart';

class TtsAutoPlayer extends StatefulWidget {
  final TtsViewModel ttsViewModel;

  const TtsAutoPlayer({super.key, required this.ttsViewModel});   // 컨스트럭처

  @override
  State<TtsAutoPlayer> createState() => _TtsAutoPlayerState();
}

class _TtsAutoPlayerState extends State<TtsAutoPlayer> {
  final List<String> phrases = ['One', 'Two', 'Three', 'Four', 'Five']; // ✅ TTS로 말할 문장
  bool isPlaying = false;

  Future<void> _playTtsSequence() async {
    setState(() {
      isPlaying = true;
    });

    for (final phrase in phrases) {
      if (!isPlaying) break; // 중간에 중단되었을 경우

      print('[TTS] speak: $phrase'); // ✅ 디버깅용 로그
      await widget.ttsViewModel.speak(phrase);
      await Future.delayed(const Duration(seconds: 1)); // ✅ 1초 간격
    }

    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isPlaying ? null : _playTtsSequence,
          child: const Text('start'),
        ),
        if (isPlaying)
          ElevatedButton(
            onPressed: () {
              widget.ttsViewModel.stop(); // ✅ TTS 멈춤
              setState(() {
                isPlaying = false;
              });
            },
            child: const Text('stop'),
          ),
      ],
    );
  }
}
