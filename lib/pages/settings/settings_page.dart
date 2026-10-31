import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart';
import '../../widgets/support_center_sheet.dart';
import '../../widgets/system_voice_picker.dart';
import '../../services/tts_service.dart';
import '../../repositories/guest_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final Future<String> _versionLabel = PackageInfo.fromPlatform().then(
    (info) => '버전 ${info.version} (${info.buildNumber})',
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final guest = auth.user?.uid == GuestStore.uid;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Text(
                '설정',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '나의 운동 환경',
                style: TextStyle(color: Color(0xFF9B9EA8), fontSize: 13),
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
              trailing: CupertinoSwitch(
                value: auth.voiceCountingEnabled,
                activeTrackColor: const Color(0xFFFF784F),
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
                    auth.systemVoiceId?.isNotEmpty == true
                        ? '선택한 목소리'
                        : '자동 선택',
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
            if (guest) ...[
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '게스트 이용 중 · 기록은 이 기기에 저장됩니다.\n로그인하면 기존 계정 기록과 중복 없이 합쳐집니다.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9B9EA8)),
                ),
              ),
              _SettingTile(
                title: '로그인하고 기록 보관하기',
                onTap: () => context.push('/login'),
              ),
            ] else
              _SettingTile(title: '로그아웃', onTap: () => _logout(context, auth)),
            _SettingTile(
              title: '만든이들',
              onTap: () => context.push('/settings/credits'),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 22,
              runSpacing: 4,
              children: [
                _FooterText(
                  '개인정보처리방침',
                  onTap: () => context.push('/legal/privacy'),
                ),
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
            if (!guest)
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
    await TtsService.instance.stop();
    if (!context.mounted) return;
    final selected = await showSystemVoicePicker(
      context,
      selected: auth.systemVoiceId,
    );
    if (selected == null || !context.mounted) return;
    await _saveSetting(context, () => auth.setSystemVoice(selected));
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
    var draft = auth.displayName ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF4F4F4F),
        title: const Text('닉네임 변경', textAlign: TextAlign.center),
        // Keep the controller alive until the closing animation unmounts the field.
        content: TextFormField(
          initialValue: draft,
          onChanged: (value) => draft = value,
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
              final value = draft.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
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
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: const Color(0xFF858585),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  OverflowBar(
                    spacing: 12,
                    overflowSpacing: 12,
                    alignment: MainAxisAlignment.center,
                    overflowAlignment: OverflowBarAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF666666),
                          minimumSize: const Size(96, 54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('취소', maxLines: 1, softWrap: false),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF784F),
                          minimumSize: const Size(96, 54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        child: Text(action, maxLines: 1, softWrap: false),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E23),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9B9EA8)),
        onTap: onTap,
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
