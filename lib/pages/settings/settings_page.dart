// lib/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/tts_repository.dart';
import 'makers_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _restSeconds = 10; // 기본 10초
  bool _voiceCounting = false;
  String _voice = '여성'; // 기본 여성

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<TtsRepository>();
      final dyn = repo as dynamic;
      try {
        final rs = dyn.restSeconds as int?;
        if (rs != null) _restSeconds = rs;
      } catch (_) {}
      try {
        final vc = dyn.voiceCounting as bool?;
        if (vc != null) _voiceCounting = vc;
      } catch (_) {}
      try {
        final vg = dyn.voiceGender as String?;
        if (vg == 'female') _voice = '여성';
        if (vg == 'male') _voice = '남성';
      } catch (_) {}
      if (mounted) setState(() {});
    });
  }

  void _applyToRepo() {
    final repo = context.read<TtsRepository>();
    final dyn = repo as dynamic;
    try {
      dyn.setRestSeconds?.call(_restSeconds);
    } catch (_) {}
    try {
      dyn.setVoiceCounting?.call(_voiceCounting);
    } catch (_) {}
    try {
      dyn.setVoiceGender?.call(_voice == '여성' ? 'female' : 'male');
    } catch (_) {}
  }

  Future<void> _pickRestSeconds() async {
    final options = <int>[0, 3, 5, 10, 15, 20, 30, 45, 60];

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (_, i) {
              final v = options[i];
              final selected = v == _restSeconds;
              return ListTile(
                title: Text(
                  v == 0 ? '쉬지 않음' : '$v초',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
                onTap: () => Navigator.of(context).pop(v),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: options.length,
          ),
        );
      },
    );

    if (picked != null && picked != _restSeconds) {
      setState(() => _restSeconds = picked);
      _applyToRepo();
    }
  }

  void _pickVoice() async {
    final picked = await showMenu<String>(
      context: context,
      color: const Color(0xFF2A2A2A),
      position: const RelativeRect.fromLTRB(200, 180, 16, 0),
      items: const [
        PopupMenuItem(
          value: '여성',
          child: Text('여성', style: TextStyle(color: Colors.white)),
        ),
        PopupMenuItem(
          value: '남성',
          child: Text('남성', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
    if (picked != null && picked != _voice) {
      setState(() => _voice = picked);
      _applyToRepo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 휴식 시간 설정
          _SettingTile(
            title: '휴식 시간 설정',
            // ⛳️ 여기: 위젯을 넘길 때는 trailingWidget 사용!
            trailingWidget: _Pill(
              text: _restSeconds == 0
                  ? '세트 종료시 쉬지 않음'
                  : '세트 종료시 ${_restSeconds}초',
              onTap: _pickRestSeconds,
            ),
          ),

          // 보이스 카운팅
          _SettingTile(
            title: '보이스 카운팅',
            trailingWidget: Switch.adaptive(
              value: _voiceCounting,
              onChanged: (v) {
                setState(() => _voiceCounting = v);
                _applyToRepo();
              },
            ),
          ),

          // 목소리
          _SettingTile(
            title: '목소리',
            // ⛳️ 여기도 trailingWidget로 변경
            trailingWidget: _Pill(text: _voice, onTap: _pickVoice),
          ),

          const Divider(height: 24, thickness: 0.6, color: Color(0x33FFFFFF)),

          ListTile(
            title: const Text(
              '고객센터',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('고객센터 준비 중입니다.')));
            },
          ),
          ListTile(
            title: const Text(
              '로그아웃',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그아웃 준비 중입니다.')));
            },
          ),
          ListTile(
            title: const Text(
              '만든이들',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MakersPage()));
            },
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '개인정보처리방침    이용약관',
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '버전 25.25.0 (00000)',
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '회원탈퇴',
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, this.trailing, this.trailingWidget});

  final String title;
  final String? trailing; // 간단 문자열 표시용
  final Widget? trailingWidget; // 커스텀 위젯 표시용

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: trailingWidget ?? _Pill(text: trailing ?? '', onTap: null),
      onTap: null,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
