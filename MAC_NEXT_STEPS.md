# MacBook · iPhone에서 이어서 확인하기

## 가장 쉬운 방법

맥북 Codex에 아래 문장을 그대로 보내세요.

> GitHub `Xeostop1/flutter-workoutcounter`의 `codex/mac-handoff-20261031` 브랜치를 새 폴더에 받아서 이어서 작업해줘. 기존 맥 프로젝트와 미커밋 변경은 덮어쓰지 말아줘. 먼저 `CURRENT_HANDOFF.md`와 이 문서를 읽고, Flutter·Xcode·CocoaPods·연결된 iPhone을 확인한 뒤 테스트와 iPhone release 빌드를 진행해줘. 새 패키지나 SDK를 무작정 업그레이드하지 말고 현재 lockfile을 사용해줘. 로그인·인증·서명 승인 화면이 필요하면 내가 직접 처리하게 알려줘. 실제 계정/운동 기록을 삭제해서 검사하지 말아줘.

최신 앱은 이 브랜치입니다. `master`와 `mac`은 기존 이력을 보존한 브랜치이며 오늘 Windows의 최종 변경을 포함하지 않습니다.

## 직접 시작할 경우

맥의 터미널에서 실행합니다. 같은 이름의 폴더가 이미 있으면 삭제하지 말고 다른 새 폴더 이름을 쓰세요.

```sh
git clone --branch codex/mac-handoff-20261031 --single-branch https://github.com/Xeostop1/flutter-workoutcounter.git SPORKLE-Mac-20261031
cd SPORKLE-Mac-20261031
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test --concurrency=1
```

Windows 검증 환경은 Flutter 3.32.4 / Dart 3.8.1입니다. 맥에서 버전이 다르거나 의존성 오류가 나면 먼저 메시지를 확인하세요. `flutter pub upgrade`나 프로젝트 재생성으로 해결하려 하지 마세요.

## 실제 iPhone 실행

1. iPhone을 USB로 연결하고 잠금을 풀어 둡니다. 기기 신뢰/개발자 모드/인증은 직접 승인하세요.
2. 프로젝트 폴더에서 아래 명령을 실행합니다.

```sh
cd ios
pod install
open Runner.xcworkspace
```

3. Xcode에서 Runner 대상의 `Signing & Capabilities`를 확인합니다. 기존 유료 개발자 Team과 번들 ID `com.sparkleteamhns.counter01`, `Sign in with Apple` 권한을 유지합니다. 서명 문제가 있을 때 임의 Team 변경이나 새 키 발급을 하지 마세요.
4. 다시 프로젝트 최상위 폴더에서 iPhone 기기 ID를 확인하고 실행합니다.

```sh
cd ..
flutter devices
flutter run --release -d '여기에_연결된_iPhone_기기_ID'
```

기기 ID는 위 `flutter devices`에 나온 실제 값을 사용합니다. Mac 데스크톱이나 Chrome을 선택하지 마세요. 새 iOS에서 debug/JIT 실행이 실패했던 이력이 있어 실물 iPhone은 release로 확인합니다. Windows APK를 iPhone에 설치하는 것이 아닙니다.

## 확인할 화면과 동작

1. 홈: 첫날 불씨·실제 Day·닉네임·루틴·`바로 운동 시작`.
2. 불씨 클릭: 큰 현재 불씨·실제 이번 주 목표·성장 목록 펼침/접기. 펼친 뒤 목록 전체가 화면에 들어오고 13단계를 가로로 볼 수 있어야 합니다. 둘러보기로 실제 성장 단계가 바뀌면 안 됩니다.
3. 기록: 작은 달력·운동일 불꽃 도장·오늘 회색 네모. 주간 목표는 기록이 아닌 나의 불씨에 있습니다.
4. 운동: 시작/카운트/휴식 음성 순서, 일시정지·재개, 운동 중 화면 켜짐 유지, 정상 저장과 실패 시 재시도.
5. 로그인/게스트: 인증은 사용자 직접 진행. 기존 데이터를 지우거나 임의 로그아웃/탈퇴하지 않습니다. 실제 Firestore 저장·계정 전환·게스트 병합은 사용자와 별도 검증합니다.

## Git에 포함하지 않은 것

- 서명 비밀키·`.p8`·keystore·`key.properties`·서비스 계정 키·환경 비밀값.
- PC별 `local.properties`, Pods, `.dart_tool`, build, node_modules, 생성된 플러그인 등록 파일.
- APK·녹화·원시 진단 로그·로컬 보존용 백업. 최신 검사 요약은 `QA_HANDOFF_20261031.md`에 남깁니다.
- 앱의 게스트/미저장 운동 파일과 로그인 세션은 기기 데이터이므로 Git으로 옮겨지지 않습니다. 계정 기록을 공유하려면 같은 제공자와 같은 계정을 사용해야 합니다. Apple과 Google이 자동으로 같은 사용자 UID가 되는 것은 아닙니다.

iOS용 기존 서명 환경은 맥의 키체인/Xcode에 남아 있어야 합니다. Android 출시용 서명키가 필요하면 별도 안전한 방식으로 이동하고 Git이나 채팅에 올리지 마세요. Firebase 클라이언트 설정은 앱에 포함돼 있지만 관리자 비밀키는 포함하지 않습니다.
