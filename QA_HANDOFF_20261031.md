# 2026-10-31 Git 통합·검증 인계

## 사용할 브랜치

- 저장소: `https://github.com/Xeostop1/flutter-workoutcounter`
- 최신 작업: **`codex/mac-handoff-20261031`**
- Windows 작업 폴더: `C:/Users/hns/Desktop/gitclone/SPORKLE-Git-sync-20261031`
- 맥북 안내: [MAC_NEXT_STEPS.md](MAC_NEXT_STEPS.md)

기존 `master`/`mac` 브랜치는 강제로 덮어쓰지 않습니다. 기존 Windows 미커밋 작업은 `a4f061b` 보존 커밋에 저장했고, Mac의 `35b0ece` 이력과 함께 통합합니다. 원래 Windows 체크아웃과 인덱스·사용자 변경은 보존했습니다. 복사한 코드·자산525개의 로컬 해시 목록도 보관했습니다.

## 이번에 찾아 고친 문제

### 성장 목록이 화면 밑에 가려지는 문제

실제 Android15에서 애니메이션을 켠 상태로 성장 과정을 펼치면 목록의 위쪽 일부만 보였습니다. 기존 검사는 주로 동작 줄이기 상태를 다뤘습니다.

느린 프레임을 재현하는 새 테스트에서 화면 아래616px 안에 들어와야 할 목록의 끝이710.4px에 남는 것을 확인했습니다. 마지막 크기 애니메이션의 레이아웃이 반영되기 전에 스크롤 범위를 읽는 문제입니다. `AnimatedSize.onEnd`에서 다음 레이아웃 후 프레임 콜백으로 스크롤을 수행하도록 수정했고, 같은 재현 테스트가 통과했습니다.

### Git으로 Android 코드가 전달되지 않는 문제

`android`가 Git의 일반 폴더가 아니라 연결 정보가 없는 gitlink(서브모듈 포인터)로 기록되어 있었습니다. 실제 파일은 로컬에 있어 빌드는 되더라도 새로 받은 저장소에는 Android 소스·로고·아이콘이 빠질 수 있었습니다.

새 통합 브랜치에서 gitlink 인덱스만 제거하고 실제 Android 소스 파일을 추적하도록 바꿨습니다. 기존 로컬 Android 폴더/사용자 데이터는 지우지 않았습니다. 현재 gitlink는 없으며, 누락 검사에 남는 파일은 Flutter가 재생성하는 Gradle 실행 파일/JAR와 플러그인 등록 파일뿐입니다.

## 자동 검증 결과

- Flutter **전체300개 테스트 통과**, 11분55초. 게스트 로컬 보관/병합, 미저장 복구, 계정 전환·저장 실패, TTS순서, 작은 화면·큰 글씨, 실제 목표/기록 계산, 13단계/애니메이션/이번 자동 스크롤 회귀 검사 포함.
- `flutter analyze --no-pub`: **문제 없음**.
- `node --check functions/index.js`: 통과. 함수 배포나 Firebase 쓰기 검증을 뜻하지 않습니다.
- 공개 저장소이므로 서명키·서비스 계정 키·환경 비밀값·기기 데이터·APK/캐시는 제외. 검사한 개인 키/토큰 패턴과 민감 파일 경로의 추적 결과0개.
- 파일 이름의 대소문자/유니코드 정규화 충돌0개.
- iOS Google URL scheme, Firebase 프로젝트, 번들 ID, Apple entitlement 및 Debug/Profile/Release의 entitlement 참조3개 확인. Android 두 클라이언트 설정도 같은 프로젝트/앱을 가리킵니다.
- SDK는 업그레이드하지 않고 현재 lockfile로 `flutter pub get --offline`을 수행했습니다. Windows 검증 환경은 Flutter3.32.4/Dart3.8.1입니다.

원시 로그·실제 기기 캡처·APK는 로컬 `verification/mac-handoff-20261031/`에 보관하고 Git에는 넣지 않습니다. 자동 검사는 모의 사용자·저장소를 사용하며 실제 Firestore 저장이나 실물 iPhone 검증 완료를 뜻하지 않습니다.

## 아직 분리해서 확인할 부분

- 실제 iPhone의 Xcode/CocoaPods 빌드·서명·Google/Apple 인증·음성 청취는 맥에서 확인해야 합니다. Windows에서 완료했다고 주장하지 않습니다.
- Windows Android 에뮬레이터는 앱 실행 전부터 System UI/Bluetooth 오류와 초기 앱 응답 없음이 관찰됐습니다. GPU를 host로 바꾼 재부팅에서도 System UI·전화·Google 서비스·키보드의 응답 없음이 발생했습니다. 앱 또는 PC 하나가 원인이라고 확정하거나, GPU 변경으로 해결했다고 보고하지 않습니다.
- 사용자 계정 삭제나 실제 운동 기록 생성/삭제로 시험하지 않았고, 기존 게스트 파일은 해시로만 보존을 확인합니다.
- 빌드 출력·로컬 기기 파일은 Git으로 이동하지 않습니다. 맥에서 새 소스로 다시 빌드하세요.

## 최종 Android 빌드·실제 화면 확인

- 일반 `lib/main.dart` Android x86_64 debug APK 빌드 성공, 925.7초. 출시용 ARM APK나 스토어 서명 빌드가 아닙니다.
- 로컬 APK: `verification/mac-handoff-20261031/SPORKLE-mac-handoff-debug.apk`.
- SHA-256: `53318C950E1121BBAA44D42A453199ADD1F318B81987AF52470D7CB9BE4AC1B1`.
- 기존 `SPORKLE_Android15_AudioCheck`, `emulator-5572`에 `install -r`로 업데이트 설치 Success. 설치된 `base.apk` 해시와 위 APK가 일치합니다. 초기화·재가입·로그아웃·운동 기록 생성/삭제는 하지 않았습니다.
- 초기 시스템 응답 없음에서 대기한 뒤 홈 진입, 실제 게스트 Day0와 기존 루틴 없음, 큰 현재 불씨, `바로 운동 시작`을 확인했습니다.
- 나의 불씨에서 실제 이번 주 목표0/1회와 성장 목록을 펼쳤습니다. 수정 후 자동 스크롤로 현재 불씨 테두리·`현재` 글자와 목록 전체 높이가 화면 안에 들어왔습니다. 수정 전처럼 윗부분만 걸치는 현상은 이번 실행에서 재현되지 않았습니다. 실제 캡처 `native-growth-scroll-before.png` / `native-growth-scroll-after.png` 참조.
- 13단계 양 끝 가로 이동·성장값 불변은 위젯 테스트에서 통과했습니다. 실제 에뮬레이터의 마우스 휠/드래그 시도는 목록 이동을 확인하지 못했으므로, 실물 iPhone 손가락 스와이프 검증은 남깁니다. 입력 전달 실패인지 앱 동작 문제인지는 이 관찰만으로 확정하지 않습니다.
- 기록 탭에서 작은 달력, 오늘31일 회색 네모, 빈 기록 안내가 스크롤 없이 함께 보이고 주간 목표가 없는 것을 확인했습니다. `native-records-final.png` 참조. 실제 운동일 도장은 이번 빈 게스트 화면에서 확인하지 않았으며 관련 위젯 테스트와 별개입니다.
- 게스트 파일은 설치 전/후·화면 탐색 후 모두 SHA-256 `ed475129bf16d369a9db80441e553194a99a4b3268a4a4ac0c9d2c51824fd108`으로 동일했습니다. 이는 이 기기의 파일 보존 확인이지, 실제 계정과의 Firestore 병합 시험 완료를 뜻하지 않습니다.
- 전체 테스트 로그 `full-tests.log`, 정적 검사 `analyze.log`, 빌드 `build.log`, 회귀 A/B `scroll-repro-before-final.log` / `scroll-repro-after-final.log`, 시스템 ANR 관찰 `host-gpu-anr-after.log`를 로컬 검증 폴더에 보관합니다.
