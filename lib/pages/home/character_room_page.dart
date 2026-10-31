import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/streak_viewmodel.dart';

class CharacterRoomPage extends StatelessWidget {
  const CharacterRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final day = context.select<StreakViewModel, int>((vm) => vm.day);
    final stage = context.select<StreakViewModel, int>((vm) => vm.flameStage);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left, size: 34),
                      ),
                    ),
                    const Text(
                      '나의 불씨',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E4E4E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Day $day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Image.asset(
                _stageAsset(stage),
                width: 290,
                height: 290,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 32),
              Text(
                _message(stage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF0F0F0),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 180,
                height: 54,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6335),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '운동하러 가기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageAsset(int stage) {
    if (stage == -2) return 'assets/images/flame_stage_m2.png';
    if (stage == -1) return 'assets/images/flame_stage_m1.png';
    return 'assets/images/flame_stage_${stage.clamp(0, 10)}.png';
  }

  String _message(int stage) {
    if (stage < 0) return '불씨가 기다리고 있어요.\n오늘 다시 움직여볼까요?';
    if (stage < 3) return '작은 불씨가 자라고 있어요.\n꾸준히 함께 운동해요!';
    if (stage < 7) return '꾸준함이 불씨를\n더 밝게 만들고 있어요!';
    return '대단해요!\n불씨가 활활 타오르고 있어요!';
  }
}
