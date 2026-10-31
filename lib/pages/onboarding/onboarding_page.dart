import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1 -> 2 -> 3(입력) -> 4(확인)

  final _numCtrl = TextEditingController();
  int? _weeklyTarget;
  bool _isSaving = false;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _numCtrl.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _goto(int step) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _fade.forward(from: 0);
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onTyped(String raw) {
    final parsed = int.tryParse(raw.trim());
    setState(() {
      _weeklyTarget = (parsed != null && parsed >= 1 && parsed <= 7)
          ? parsed
          : null;
    });
  }

  Future<void> _finish() async {
    if (_isSaving) return;

    final target = _weeklyTarget;
    if (target == null) {
      if (!mounted) return;
      _goto(3);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주간 운동 횟수를 입력해주세요.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AuthViewModel>().completeOnboarding(
        weeklyTarget: target,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _goto(3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      '작은 시작,\n꾸준한 변화.',
      '운동에만\n집중하세요.',
      '이번 주,\n몇 번 움직일까요?',
      '좋아요.\n이제 시작해볼까요?',
    ];
    final descriptions = [
      '나의 속도로 쌓아가는 운동 습관.\nSPORKLE이 함께할게요.',
      '횟수와 휴식은 맡겨두세요.\n한 번의 운동에 온전히 집중할 수 있도록.',
      '부담 없이 지킬 수 있는 목표를 정해보세요.\n일주일에 1~7번 중 선택할 수 있어요.',
      '완벽한 하루보다 꾸준한 한 번.\n작은 불씨를 함께 키워가요.',
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSaving && _step > 1) _goto(_step - 1);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101114),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Row(
                  children: [
                    const Text(
                      'SPORKLE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '0$_step / 04',
                      style: const TextStyle(
                        color: Color(0xFF9B9EA8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_step - 1],
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          descriptions[_step - 1],
                          style: const TextStyle(
                            color: Color(0xFF9B9EA8),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_step == 3)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 12,
                            children: [
                              const Text('주에', style: TextStyle(fontSize: 21)),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 76,
                                child: TextField(
                                  controller: _numCtrl,
                                  enabled: !_isSaving,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFF784F),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    hintText: '3',
                                  ),
                                  onChanged: _onTyped,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                '번 운동하기',
                                style: TextStyle(fontSize: 21),
                              ),
                            ],
                          )
                        else if (_step == 4)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1E23),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '나의 주간 목표',
                                  style: TextStyle(
                                    color: Color(0xFF9B9EA8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '주 $_weeklyTarget회',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF784F),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFF3A2420),
                                    Color(0xFF101114),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/charactor_first.png',
                                  height: 76,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  children: [
                    if (_step > 1) ...[
                      TextButton(
                        onPressed: _isSaving ? null : () => _goto(_step - 1),
                        child: const Text('이전'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _isSaving || (_step == 3 && _weeklyTarget == null)
                            ? null
                            : () {
                                if (_step < 4) {
                                  _goto(_step + 1);
                                } else {
                                  _finish();
                                }
                              },
                        child: Text(
                          _isSaving ? '저장 중…' : (_step == 4 ? '시작하기' : '다음'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
