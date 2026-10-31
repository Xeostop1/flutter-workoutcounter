import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../widgets/support_center_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final Future<String> _versionLabel = PackageInfo.fromPlatform().then(
    (info) => '버전 ${info.version} (${info.buildNumber})',
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(
              height: 88,
              child: Center(
                child: Text(
                  '설정',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            _SettingTile(
              title: '닉네임 변경',
              onTap: () => _changeNickname(context, auth),
            ),
            _SettingTile(
              title: '휴식 시간 설정',
              trailing: Text(
                '세트 종료시 ${auth.restSeconds}초',
                style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
              ),
              onTap: () => _pickRestSeconds(context, auth),
            ),
            _SettingTile(
              title: '보이스 카운팅',
              onTap: () => _saveSetting(
                context,
                () => auth.setVoiceCountingEnabled(!auth.voiceCountingEnabled),
              ),
              trailing: Switch(
                value: auth.voiceCountingEnabled,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFFF6335),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFBDBDBD),
                onChanged: (value) async {
                  HapticFeedback.selectionClick();
                  await _saveSetting(
                    context,
                    () => auth.setVoiceCountingEnabled(value),
                  );
                },
              ),
            ),
            _SettingTile(
              title: '목소리',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _voiceLabel(auth.voicePitch),
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFBDBDBD),
                  ),
                ],
              ),
              onTap: () => _pickVoice(context, auth),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFF555555)),
            ),
            _SettingTile(
              title: '고객센터',
              onTap: () => _openSupportSheet(context),
            ),
            _SettingTile(title: '로그아웃', onTap: () => _logout(context, auth)),
            _SettingTile(
              title: '만든이들',
              onTap: () => context.push('/settings/credits'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FooterText(
                  '개인정보처리방침',
                  onTap: () => context.push('/legal/privacy'),
                ),
                const SizedBox(width: 22),
                _FooterText('이용약관', onTap: () => context.push('/legal/terms')),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: _versionLabel,
              builder: (_, snapshot) => Text(
                snapshot.data ?? (snapshot.hasError ? '버전 정보 없음' : '버전 확인 중'),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => _withdraw(context, auth),
              child: const Text(
                '회원탈퇴',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFAAAAAA),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  String _voiceLabel(double pitch) {
    if ((pitch - 1.10).abs() < 0.01) return '여성';
    if ((pitch - 0.90).abs() < 0.01) return '남성';
    return '기본';
  }

  Future<void> _pickRestSeconds(
    BuildContext context,
    AuthViewModel auth,
  ) async {
    final selected = await showMenu<int>(
      context: context,
      color: const Color(0xFF555555),
      position: const RelativeRect.fromLTRB(210, 150, 18, 0),
      items: [
        for (final seconds in [3, 5, 10, 30])
          PopupMenuItem(value: seconds, child: Text('$seconds초')),
      ],
    );
    if (selected == null || !context.mounted) return;
    await _saveSetting(context, () async {
      await auth.setRestSeconds(selected);
      if (context.mounted) {
        context.read<CounterViewModel>().setRestSeconds(selected);
      }
    });
  }

  Future<void> _pickVoice(BuildContext context, AuthViewModel auth) async {
    final selected = await showMenu<String>(
      context: context,
      color: const Color(0xFF555555),
      position: const RelativeRect.fromLTRB(290, 250, 18, 0),
      items: const [
        PopupMenuItem(value: '여성', child: Text('여성')),
        PopupMenuItem(value: '남성', child: Text('남성')),
      ],
    );
    if (selected == null || !context.mounted) return;
    HapticFeedback.selectionClick();
    await _saveSetting(
      context,
      selected == '여성' ? auth.setVoicePresetFemale : auth.setVoicePresetMale,
    );
  }

  Future<void> _saveSetting(
    BuildContext context,
    Future<void> Function() save,
  ) async {
    try {
      await save();
    } catch (_) {
      if (context.mounted) {
        _showError(context, '설정을 저장하지 못했습니다. 다시 시도해주세요.');
      }
    }
  }

  Future<void> _changeNickname(BuildContext context, AuthViewModel auth) async {
    final controller = TextEditingController(text: auth.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF4F4F4F),
        title: const Text('닉네임 변경', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '닉네임을 입력해주세요.',
            hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
          ),
          style: const TextStyle(color: Color(0xFF222222)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;

    try {
      await auth.setDisplayName(name);
    } catch (_) {
      if (context.mounted) _showError(context, '닉네임을 변경하지 못했습니다.');
    }
  }

  Future<void> _logout(BuildContext context, AuthViewModel auth) async {
    final confirmed = await _confirm(
      context,
      title: '로그아웃 하시겠어요?',
      message: '언제든 다시 로그인할 수 있어요.',
      action: '로그아웃',
    );
    if (!confirmed) return;
    try {
      await auth.signOut();
    } catch (_) {
      if (context.mounted) _showError(context, '로그아웃하지 못했습니다.');
    }
  }

  Future<void> _withdraw(BuildContext context, AuthViewModel auth) async {
    final confirmed = await _confirm(
      context,
      title: '정말 탈퇴하시겠어요?',
      message: '계정과 모든 기록은 복구할 수 없어요.',
      action: '탈퇴',
    );
    if (!confirmed) return;
    try {
      await auth.deleteAccount();
    } catch (_) {
      if (context.mounted) {
        _showError(context, '탈퇴하지 못했습니다. 다시 로그인하거나 인터넷 연결을 확인해주세요.');
      }
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: const Color(0xFF858585),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 52, 28, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 62),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF666666),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6335),
                            ),
                            child: Text(action),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _openSupportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupportCenterSheet(email: 'stop1@daum.net'),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.onTap, this.trailing});

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 20)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}
