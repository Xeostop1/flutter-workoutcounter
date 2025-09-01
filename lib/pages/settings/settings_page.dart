import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final tts = context.watch<SettingsViewModel>();
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('보이스 카운팅'),
            value: tts.voiceEnabled,
            onChanged: (v) => tts.toggleVoice(v),
          ),
          ListTile(
            title: const Text('목소리/언어'),
            subtitle: Text(tts.language),
            onTap: () => tts.setLanguage(tts.language == 'ko-KR' ? 'en-US' : 'ko-KR'),
          ),
          const Divider(),
          const ListTile(title: Text('고객센터')),
          ListTile(title: const Text('개인정보처리방침'), onTap: () {}),
          ListTile(title: const Text('로그아웃'), onTap: () => auth.signOut()),
          ListTile(
            title: const Text('회원탈퇴'),
            textColor: Colors.red,
            onTap: () => auth.deleteAccount(),
          ),
        ],
      ),
    );
  }
}
