import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum LegalDocument { privacy, terms }

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final title = privacy ? '개인정보처리방침' : '이용약관';
    final sections = privacy ? _privacySections : _termsSections;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, size: 32),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (_, index) {
            final section = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                SelectableText(
                  section.body,
                  style: const TextStyle(
                    color: Color(0xFFD0D0D0),
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _privacySections = [
  _LegalSection(
    '개인정보처리방침',
    'SPARKLE 운영자 [운영자명 또는 상호 확정 필요](이하 “운영자”)는 개인정보 보호법 등 관계 법령을 준수하며, 이용자의 개인정보를 안전하게 처리하기 위해 다음과 같이 개인정보처리방침을 공개합니다.\n\n시행일: 2026년 8월 15일',
  ),
  _LegalSection(
    '1. 처리하는 개인정보와 이용 목적',
    '• 회원가입·로그인: Firebase UID, 이메일 주소, 닉네임, 프로필 이미지, 로그인 제공자 정보 — 본인 확인과 계정 관리\n• 서비스 설정: 주간 운동 목표, 음성 카운팅 여부·목소리 설정, 휴식 시간, 튜토리얼 완료 여부 — 맞춤 기능 제공\n• 운동 데이터: 루틴명, 운동명, 세트·횟수·시간, 운동 날짜, 수동 기록과 메모 — 운동 카운팅과 기록 조회\n• 자동 생성 정보: 접속 일시, 기기·운영체제 정보, IP 주소, 오류·보안 로그가 Firebase 이용 과정에서 생성될 수 있음 — 서비스 안정성과 보안 유지',
  ),
  _LegalSection(
    '2. 보유 및 이용 기간',
    '개인정보는 회원 탈퇴 시까지 보유합니다. 회원이 탈퇴하면 Firebase Authentication 계정과 users/{UID} 아래의 프로필, 루틴, 운동 기록을 삭제합니다. 다만 관계 법령에 별도 보존 의무가 있는 경우 해당 기간 동안 분리 보관한 뒤 파기합니다.',
  ),
  _LegalSection(
    '3. 제3자 제공',
    '운영자는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. 법령에 근거가 있거나 이용자가 별도로 동의한 경우에만 필요한 범위에서 제공합니다.',
  ),
  _LegalSection(
    '4. 처리 위탁 및 국외 이전',
    '서비스는 인증·데이터 저장·서버 기능 제공을 위해 Google LLC의 Firebase Authentication, Cloud Firestore, Cloud Functions를 이용합니다. 처리 항목은 제1조의 계정·설정·운동 데이터이며 네트워크를 통해 전송됩니다.\n\n수탁자: Google LLC\n이전 국가·저장 리전: [Firebase 프로젝트 리전 확인 후 확정 필요]\n이전 시점·방법: 서비스 이용 시 암호화된 네트워크 전송\n보유 기간: 회원 탈퇴 또는 위탁계약 종료 시까지\n연락처: Google 개인정보 보호 문의 창구(https://policies.google.com/privacy)\n\n국외 이전을 원하지 않으면 회원 탈퇴를 요청할 수 있으나, Firebase 기반 서비스 이용이 제한될 수 있습니다.',
  ),
  _LegalSection(
    '5. 개인정보의 파기',
    '보유 기간이 끝나거나 처리 목적이 달성되면 지체 없이 파기합니다. 전자 파일은 복구하기 어려운 방식으로 삭제합니다. 회원 탈퇴 시 인증 계정 삭제 이벤트를 기준으로 서버 삭제 함수가 users/{UID} 문서와 모든 하위 컬렉션을 재귀 삭제합니다.',
  ),
  _LegalSection(
    '6. 이용자의 권리',
    '이용자는 자신의 개인정보 열람, 정정, 삭제, 처리 정지를 요청할 수 있습니다. 앱의 설정에서 닉네임을 수정하거나 회원 탈퇴를 할 수 있으며, 그 밖의 요청은 고객센터 이메일로 접수할 수 있습니다.',
  ),
  _LegalSection(
    '7. 안전성 확보 조치',
    '운영자는 Firebase Authentication을 통한 접근 통제, 전송 구간 암호화, 사용자 UID별 데이터 분리, 최소 권한 부여 등 개인정보의 안전성 확보에 필요한 조치를 적용합니다.',
  ),
  _LegalSection(
    '8. 기기 내 저장 정보',
    '연속 운동일 등 일부 값은 앱 기능 제공을 위해 기기의 로컬 저장소에 저장될 수 있습니다. 앱을 삭제하면 해당 정보도 삭제될 수 있습니다.',
  ),
  _LegalSection(
    '9. 개인정보 보호 책임자',
    '책임자: [성명 확정 필요]\n연락처: stop1@daum.net\n\n개인정보 침해 상담은 개인정보침해 신고센터(국번 없이 118), 개인정보분쟁조정위원회, 경찰청 등 관계 기관에 문의할 수 있습니다.',
  ),
  _LegalSection(
    '10. 방침의 변경',
    '이 방침의 내용이 변경되면 시행 전에 앱 또는 서비스 화면을 통해 알립니다. 이용자 권리에 중대한 변경이 있는 경우 충분한 기간을 두고 알립니다.',
  ),
];

const _termsSections = [
  _LegalSection(
    'SPARKLE 이용약관',
    '이 약관은 SPARKLE 운영자 [운영자명 또는 상호 확정 필요](이하 “운영자”)가 제공하는 운동 카운터 및 기록 서비스의 이용 조건을 정합니다.\n\n시행일: 2026년 8월 15일',
  ),
  _LegalSection(
    '1. 서비스의 내용',
    '서비스는 운동 루틴 작성, 음성 카운팅, 휴식 타이머, 운동 기록, 캐릭터 성장 기능을 제공합니다. 구체적인 기능은 운영상 필요에 따라 변경될 수 있습니다.',
  ),
  _LegalSection(
    '2. 계정과 이용 신청',
    '이용자는 Google 또는 Apple 로그인을 통해 계정을 만들 수 있습니다. 이용자는 정확한 정보를 사용하고 자신의 계정을 안전하게 관리해야 하며, 계정의 무단 사용을 알게 된 경우 즉시 운영자에게 알려야 합니다.',
  ),
  _LegalSection(
    '3. 이용자의 의무',
    '이용자는 법령 위반, 타인의 권리 침해, 서비스 방해, 계정 도용, 비정상적인 접근이나 자동화된 공격을 해서는 안 됩니다. 수동 기록에 불법적이거나 타인의 권리를 침해하는 내용을 입력해서는 안 됩니다.',
  ),
  _LegalSection(
    '4. 이용자 콘텐츠',
    '이용자가 작성한 루틴과 메모의 권리는 이용자에게 있습니다. 운영자는 서비스 제공, 저장, 동기화 및 장애 복구에 필요한 범위에서만 해당 정보를 처리합니다.',
  ),
  _LegalSection(
    '5. 서비스 이용 제한',
    '운영자는 법령 또는 약관을 위반하거나 서비스의 안전을 위협하는 이용에 대해 사전 통지 후 이용을 제한할 수 있습니다. 긴급한 보안 위험이 있는 경우 먼저 제한하고 이후 알릴 수 있습니다.',
  ),
  _LegalSection(
    '6. 서비스 변경과 중단',
    '점검, 장애, 통신망 문제, 천재지변 또는 서비스 개편으로 일부 기능이 일시 중단될 수 있습니다. 중요한 변경이나 장기 중단은 가능한 범위에서 미리 안내합니다.',
  ),
  _LegalSection(
    '7. 건강 관련 주의',
    '서비스는 운동 보조 도구이며 의료 진단이나 치료를 제공하지 않습니다. 이용자는 자신의 건강 상태와 운동 능력을 고려해야 하며, 통증이나 이상 증상이 있으면 운동을 중단하고 의료 전문가와 상담해야 합니다.',
  ),
  _LegalSection(
    '8. 책임의 범위',
    '운영자는 고의 또는 중대한 과실이 없는 한 이용자의 기기 환경, 네트워크 장애, 이용자의 잘못된 정보 입력 등 운영자가 통제하기 어려운 사유로 발생한 손해에 책임을 지지 않습니다. 관계 법령상 배제할 수 없는 책임은 제외합니다.',
  ),
  _LegalSection(
    '9. 탈퇴',
    '이용자는 설정에서 언제든 회원 탈퇴를 할 수 있습니다. 탈퇴가 완료되면 계정과 연결된 서비스 데이터는 개인정보처리방침에 따라 삭제되며 복구할 수 없습니다.',
  ),
  _LegalSection(
    '10. 준거법과 문의',
    '이 약관은 대한민국 법령을 따릅니다. 서비스 관련 문의는 stop1@daum.net으로 접수할 수 있으며, 분쟁은 관계 법령이 정한 절차와 관할에 따릅니다.',
  ),
];
