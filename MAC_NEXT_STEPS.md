# 맥북에서 Android 검증 이어가기 — 2026-11-01

최신 저장소: https://github.com/Xeostop1/flutter-workoutcounter
최신 전달 브랜치: **`codex/android-verification-20261101`**.

이 브랜치는 이전 Mac 인계의 코드·이미지와 운동 설정창 수명 오류 수정/회귀 검사를 포함합니다. Windows에서 전체306개 로컬 검사/정적 검사/debug 빌드는 앞서 통과했지만, Android 시스템과 앱 ANR 때문에 실제 TTS·운동 기록 재시작 보존·로그인 병합은 미완료입니다. 맥 전환이 오류 해결을 보장하지는 않습니다.

소스 수정 커밋은 `9c2cf52`입니다. Git 전달 전 관련13개 검사와 정적 검사를 다시 통과했습니다. 이 커밋을 포함한 전달 브랜치인지 확인한 뒤 진행하세요.

## 가장 쉬운 방법

먼저 맥북 Codex에서 기존 작업 폴더를 덮지 않는 새 폴더를 열고 아래 내용을 보내세요. 직접 받으려면 다음 절의 clone 명령을 먼저 실행한 후 받은 폴더를 여세요.

```text
SPORKLE 앱의 Android 실제 검증을 맥에서 이어서 진행해줘. 나는 Flutter 초보자이므로 가능한 작업은 직접 처리하고 내가 해야 하는 설치 승인·로그인·청취 확인만 쉽게 알려줘.

GitHub https://github.com/Xeostop1/flutter-workoutcounter 의 codex/android-verification-20261101 브랜치가 최신이야. 현재 브랜치/미커밋 변경을 먼저 확인하고, 필요하면 별도 새 폴더로 받아줘. 기존 맥 프로젝트를 덮거나 reset/clean/force push 하지 마.

먼저 CURRENT_HANDOFF.md, MAC_NEXT_STEPS.md, QA_ANDROID_20261101.md를 읽어줘. Windows의 전체306개 로컬 검사와 빌드는 통과했지만 실제 Android 시스템 및 앱 ANR 때문에 기기 검증은 미완료야. RAM 하나나 앱 코드 하나를 원인으로 단정하지 마.

맥 칩(uname -m), 메모리/디스크, Flutter·Java·Android Studio/SDK를 확인하고 Android 개발 환경을 준비해줘. 기준은 Flutter3.32.4/Dart3.8.1, Gradle8.12/AGP8.7.3/Kotlin2.1.0/NDK27.0.12077973이야. 기존 lockfile을 사용하고 패키지/Flutter/Gradle을 무작정 업그레이드하거나 flutter create로 네이티브 프로젝트를 덮지 마. 호환되는 JDK17/21을 확인하되 기존 전역 설정과 iPhone 서명을 무작정 교체하지 마.

Android Studio/SDK가 없으면 공식 배포판으로 준비하고 내가 승인할 단계만 알려줘. Apple Silicon에는 arm64-v8a, Intel에는 x86_64의 Android15(API35) Google APIs 새 AVD를 만들어줘. 기존 기기는 초기화/삭제하지 마. Windows의 x86_64 APK/AVD를 복사하지 말고 이 소스로 맥에 맞게 debug 빌드해줘. Android 출시 서명키 없이 debug로 검사하고 iOS 파일은 유지해줘.

에뮬레이터 실행 전 analyze/테스트부터 하고, 운영체제가 안정적으로 부팅된 뒤 lib/main.dart의 일반 앱을 실행해줘. test/workout_sheet_lifecycle_test.dart의 실제 설정창 취소/시작/수정/적용 회귀를 다시 확인하고, 불씨13단계 가로 탐색도 실제 UI에서 확인해줘.

검증용 게스트에 구분 가능한 QA 운동을 만들고 1초/2초 운동 카운트, 시작→하나/둘/셋→세트 종료→휴식→1/2/3→다음 세트 순서, 일시정지/재개, 운동 중 화면 켜짐 및 종료 후 해제를 확인해줘. 보이스 카운팅은 기본 off일 수 있으니 설정을 확인해줘. 실제 청취는 나에게 확인하고 로그만으로 잘 들렸다고 보고하지 마.

저장 성공 후 기록 ID/내용/개수를 확인하고, 운동 중이 아닌 상태에서 앱을 종료했다 재실행해 같은 기록이 중복 없이 남는지 확인해줘. 그다음 기존 기록이 있는 Google 계정과 병합을 검사하되 QA 기록이 그 계정에 추가된다는 것을 먼저 알려줘. 인증은 내가 직접 입력하고 비밀번호/인증번호를 채팅으로 요구하지 마. 기존 기록 삭제·임의 로그아웃·탈퇴로 검사하지 마.

맥의 Android debug 서명 SHA 지문이 Firebase에 등록됐는지도 확인해줘. 등록이 필요하면 정확한 지문과 누를 메뉴를 안내하고 기존 지문을 삭제하지 마. 모의 검사/실제 화면/청취/Firestore 결과를 구분해 기록하고 미검증은 그대로 남겨줘. 문제는 작은 재현 테스트와 최소 수정으로 처리하고, 기기 데이터·서명키·원시 인증 로그·AVD·빌드 출력은 Git에 넣지 마.
```

`master`, `mac`, 이전 `codex/mac-handoff-20261031`은 보존합니다. 최신 수정이 필요하면 위 전달 브랜치를 사용하세요. 이 Windows 세션에서 맥의 SDK 설치·빌드·실행을 직접 완료한 것은 아닙니다.

## 직접 시작할 경우

맥의 터미널에서 실행합니다. 같은 이름의 폴더가 이미 있으면 삭제하지 말고 다른 새 폴더 이름을 쓰세요.

```sh
cd ~/Desktop
git clone --branch codex/android-verification-20261101 --single-branch https://github.com/Xeostop1/flutter-workoutcounter.git SPORKLE-Mac-Android-20261101
cd SPORKLE-Mac-Android-20261101
git log -1 --oneline
uname -m
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Windows 검증 환경은 Flutter 3.32.4 / Dart 3.8.1입니다. 맥에서 버전이 다르거나 의존성 오류가 나면 먼저 메시지를 확인하세요. `flutter pub upgrade`나 프로젝트 재생성으로 해결하려 하지 마세요.

`--enforce-lockfile`은 현재 잠금 파일로 의존성을 준비할 수 없으면 중단합니다. 이 단계가 실패하면 다음 명령을 계속 실행하지 말고 오류를 Codex에 보여주세요.

## Android Studio와 에뮬레이터 준비

1. Apple 메뉴 → **이 Mac에 관하여**에서 Apple 칩인지 Intel인지 확인합니다. Codex는 `uname -m` 결과와 함께 확인해야 합니다.
2. [공식 Android Studio](https://developer.android.com/studio)에서 Apple 칩은 **Mac with Apple chip**, Intel은 **Mac with Intel chip** 배포판을 설치합니다. DMG에서 Applications로 옮겨 실행하고 설치/라이선스 승인은 직접 처리합니다. 기존 설치가 있다면 먼저 Codex가 상태를 점검하게 하세요.
3. Welcome → **More Actions → SDK Manager**에서 필요한 SDK를 준비합니다. 이 프로젝트는 Android SDK Platform35, Build-Tools, Platform-Tools, Command-line Tools, Android Emulator와 NDK(Side by side)27.0.12077973이 기준입니다. 현재 프로젝트 버전을 무작정 최신으로 바꾸지 않습니다.
4. **More Actions → Virtual Device Manager**(프로젝트 창에서는 **Tools → Device Manager**) → **+ / Create Virtual Device** → Phone → Android15/API35 **Google APIs** 이미지를 선택합니다.
5. Apple Silicon은 **arm64-v8a**, Intel은 **x86_64**를 선택합니다. Windows의 x86_64 APK는 Apple Silicon ARM64 기기에 그대로 옮기는 대신 맥에서 소스로 다시 빌드합니다.
6. 새 기기 하나만 실행하고, 홈 화면과 키보드가 안정적으로 반응하는지 먼저 확인합니다. Windows에서 썼던 CPU1/Vulkan 비활성/Impeller 비교 옵션을 맥의 기본 설정처럼 복사하지 않습니다.

Android Studio의 Flutter 플러그인만으로 Flutter SDK가 설치되지는 않습니다. SDK가 없거나 기준 버전과 다르면 맥 Codex가 별도 설치/호환성을 확인하게 하세요. `flutter doctor -v`에 나온 Java도 확인하고 Gradle8.12/AGP8.7.3과 호환되는 JDK17/21을 사용합니다.

라이선스는 내용을 읽고 직접 동의하세요. 에뮬레이터 검사만 할 때 iPhone 연결은 필요 없습니다.

```sh
flutter doctor --android-licenses
flutter doctor -v
git diff -- pubspec.lock
flutter emulators
flutter devices
```

기기가 켜지면 `flutter devices`의 실제 Android 기기 ID로 실행합니다. 아래의 기기 ID 자리는 실제 값으로 바꿔야 합니다.

```sh
flutter run --debug -d '실제_Android_에뮬레이터_ID' -t lib/main.dart
```

Android debug 실행에는 출시용 keystore가 필요하지 않습니다. 현재 Android release 빌드는 원본 서명키가 없으면 의도적으로 차단됩니다. release 빌드가 막힌다는 이유로 새 출시 키를 만들지 않습니다.

## 맥의 Google 로그인용 서명 지문

맥의 Android debug keystore는 Windows와 다를 수 있습니다. 첫 debug 빌드 후 맥 Codex가 SHA-1/SHA-256을 확인하고, 필요하면 Firebase 프로젝트 설정 → 일반 → 내 앱 → Android `com.sparkleteamhns.counter01` → **SHA 인증서 지문 추가**를 안내해야 합니다. 기존 지문은 유지합니다.

새 google-services.json이 제공되면 프로젝트 ID/패키지와 기존 두 Android 설정 파일의 참조/일치 여부를 확인한 뒤 갱신합니다. Firebase 제공자/클라이언트 ID/Apple 키를 임의로 다시 만들거나 기존 서명키를 Git으로 옮기지 않습니다.

실제 인증은 사용자가 직접 진행합니다. 기존 계정에 QA 기록을 합치는 것은 데이터 추가 작업이므로 영향부터 안내합니다. 인증 성공만 확인하고 기록 병합까지 성공했다고 보고하지 않습니다.

## 실제 iPhone 실행

이번 우선순위는 맥에서 **Android** 검증입니다. 아래 iPhone 절차는 후속 확인용이며, 기존 Xcode·Team·키체인은 그대로 유지합니다. `pod install`은 기존 Podfile.lock을 존중하며 `pod update`로 무작정 갱신하지 않습니다.

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
- APK·녹화·원시 진단 로그·로컬 보존용 백업. 최신 검사 요약은 `QA_ANDROID_20261101.md`, 이전 인계는 `QA_HANDOFF_20261031.md`에 있습니다.
- 앱의 게스트/미저장 운동 파일과 로그인 세션은 기기 데이터이므로 Git으로 옮겨지지 않습니다. 계정 기록을 공유하려면 같은 제공자와 같은 계정을 사용해야 합니다. Apple과 Google이 자동으로 같은 사용자 UID가 되는 것은 아닙니다.

iOS용 기존 서명 환경은 맥의 키체인/Xcode에 남아 있어야 합니다. Android 출시용 서명키가 필요하면 별도 안전한 방식으로 이동하고 Git이나 채팅에 올리지 마세요. Firebase 클라이언트 설정은 앱에 포함돼 있지만 관리자 비밀키는 포함하지 않습니다.

## 공식 설정 자료

- [Flutter Android 개발 환경 설정](https://docs.flutter.dev/platform-integration/android/setup)
- [Android Studio 설치](https://developer.android.com/studio/install)
- [에뮬레이터 CPU/시스템 이미지 요구사항](https://developer.android.com/studio/run/emulator-acceleration)
- [Firebase Google 로그인과 SHA 등록](https://firebase.google.com/docs/auth/android/google-signin)

프로젝트 고정 버전은 현재 소스를 재현하기 위한 기준입니다. 최신 공식 문서의 업그레이드 권고를 이유로 lockfile이나 네이티브 구성을 즉시 교체하지 않습니다.
