import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('보이스 카운팅'),
            value: vm.ttsOn,
            onChanged: vm.toggleTts,
          ),
          SwitchListTile(
            title: const Text('목소리 설정'),
            value: vm.voiceId != null,
            onChanged: (v) {
              /* 음성 선택 다이얼로그 연결 */
            },
          ),
          const ListTile(title: Text('고객센터')),
          const ListTile(title: Text('로그아웃')),
          const ListTile(title: Text('회원탈퇴')),
          const ListTile(title: Text('개인정보처리방침')),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '버전 25.25.0 (00000)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
