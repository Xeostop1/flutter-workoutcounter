# 윈도우에서 이어서 작업하기

2026-10-30 맥 수정본 기준. 기존 Windows 프로젝트는 덮어쓰거나 삭제하지 마세요.
Git 원격 주소와 업로드 브랜치는 연결 완료 후 확인해야 합니다. 현재 이 문서만으로 업로드 완료를 뜻하지 않습니다.

## 처음 시작할 때

1. 기존 Windows 작업 폴더는 그대로 보관합니다. 미커밋 변경사항과 Android 서명 키도 보존합니다.
2. 연결된 저장소의 최신 작업 브랜치를 **새 폴더**로 clone합니다. 기존 폴더 위에 압축을 풀지 않습니다.
3. 새 폴더를 Codex에서 열고 `CURRENT_HANDOFF.md`와 이 문서를 읽어 달라고 합니다.
4. Flutter 3.32.6 / Dart 3.8.1을 기준으로 환경을 확인합니다. 기존 Windows SDK는 3.32.4였으므로 버전을 먼저 확인합니다.
5. 프로젝트에서 다음을 실행합니다.

```powershell
flutter --version
flutter doctor -v
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

잠금 파일은 유지하고 패키지를 일괄 업그레이드하지 않습니다. 캐시와 Pods는 Git에서 제외되어 각 컴퓨터가 다시 만듭니다.
Android 실행은 Android SDK와 에뮬레이터/휴대폰을 확인한 뒤 `flutter devices`, `flutter run -d <기기ID>` 순서로 진행합니다.
Windows 데스크톱과 웹에서 로그인·음성 등이 iPhone과 동일하게 작동한다고 가정하지 않습니다. 이번 변경본의 Windows/Android 실행 검증은 아직 하지 않았습니다.
iPhone 빌드·서명·설치는 macOS와 Xcode가 필요합니다. iOS 내장 음성 목록과 실제 소리는 iPhone에서 확인합니다.
Android 출시 키는 기존 Windows에 보존된 것을 사용하며 새로 만들지 않습니다. 키와 비밀번호 파일은 Git에 올리지 않습니다.

## 맥과 윈도우를 번갈아 쓸 때

최신 작업 폴더는 CURRENT_HANDOFF.md에 표시되어 있습니다. 이 압축 해제본에는 `.git`이 없으므로 아래 Git 명령을 그대로 실행해도 맥에 자동 동기화되지 않습니다. 기존 Windows 작업을 덮어쓰지 않고 최신 변경본을 맥으로 옮겨야 합니다.

- 작업 시작: `git status`로 미저장 변경을 확인한 뒤, 같은 작업 브랜치에서 `git pull --ff-only`.
- 작업 종료: 변경 파일을 검토하고 필요한 파일만 커밋한 뒤 `git push`.
- 다른 컴퓨터로 옮기기 전에 push 성공 여부를 확인합니다.
- 두 컴퓨터에서 동시에 같은 파일을 수정하지 않는 것이 가장 쉽습니다.
- pull이 막히거나 충돌하면 현재 변경을 보존한 채 Codex에 해결을 요청합니다. 강제 push나 hard reset으로 덮어쓰지 않습니다.

## Codex에게 보낼 요청

> CURRENT_HANDOFF.md와 WINDOWS_START_HERE.md를 읽고 맥에서 수정한 최신 브랜치인지 확인해줘. 기존 Windows 작업과 Android 서명 키를 보존하고 Flutter 환경과 테스트부터 준비해줘. Firebase 프로젝트를 바꾸거나 운영 데이터를 삭제하지 마. 내가 직접 해야 하는 일만 한 단계씩 알려줘.

## Apple 로그인 설정 — 이 프로젝트 기준

현재 코드는 Android와 iOS 모두 Apple·Google 버튼을 제공합니다. 2026-10-30 Firebase 설정 조회에서 Apple 제공자는 켜져 있으나 웹 인증용 Service ID, Team ID, Key ID는 비어 있었습니다. Apple Developer Program 가입은 사용자가 확인했습니다. 아래 콘솔 설정을 마치기 전에는 실제 Apple 로그인 완성으로 보지 않습니다.

1. [Apple Developer](https://developer.apple.com/account/)에 직접 로그인합니다. Certificates, Identifiers & Profiles에서 App ID `com.sparkleteamhns.counter01`의 Sign in with Apple을 활성화합니다. 기존 App ID를 재사용하고 다른 앱의 식별자를 수정하지 않습니다.
2. Identifiers에서 이 앱용 **Services ID**가 있으면 재사용합니다. 없으면 새로 만들되, 이름 예시는 `com.sparkleteamhns.counter01.signin`이며 실제 사용 가능 여부는 콘솔에서 확인합니다. Sign in with Apple을 켜고 기본 App ID를 위 iOS App ID에 연결합니다.
3. Services ID의 웹 인증 설정에 도메인 `sparkle-fe639.firebaseapp.com`, Return URL `https://sparkle-fe639.firebaseapp.com/__/auth/handler`를 등록합니다. 경로 끝의 `/__/auth/handler`까지 일치해야 합니다.
4. 같은 개발자 팀에서 이 App ID에 연결된 Sign in with Apple 키를 준비합니다. 기존 키를 재사용할 수 있으면 먼저 확인합니다. 새 키를 만들 경우 .p8 다운로드는 한 번만 가능하므로 안전한 곳에 보관합니다. **기존 키를 삭제·폐기하지 말고, .p8 내용이나 계정 비밀번호를 채팅·앱 소스·Git에 넣지 않습니다.**
5. [Firebase Authentication](https://console.firebase.google.com/project/sparkle-fe639/authentication/providers)의 Apple 제공자 설정에 실제 Services ID, Apple Team ID, Key ID, .p8 비밀키를 직접 입력하고 저장합니다. 비밀키는 Firebase 콘솔의 서버 설정에만 둡니다. Apple Developer/Xcode의 팀이 동일한지 확인합니다.
6. 이 PC의 테스트용 debug SHA-1은 Firebase 등록값과 일치하는 것을 확인했습니다. 다시 등록할 필요가 없습니다. 출시 서명은 별도 확인 대상입니다. Google Play 앱 서명을 쓰면 업로드 키가 아닌 실제 앱 서명 인증서도 등록해야 합니다. 새 서명 키를 임의로 만들거나 기존 출시 키를 바꾸지 않습니다.
7. 맥에 최신 소스를 옮긴 뒤 `flutter pub get`을 실행하고 `ios/Runner.xcworkspace`를 Xcode로 엽니다. Runner의 Signing & Capabilities에 Sign in with Apple이 표시되고 서명이 정상인지 확인합니다. entitlement는 코드에 연결했지만 개발자 콘솔 권한과 프로비저닝까지 자동 검증한 것은 아닙니다.
8. iPhone과 Android 에뮬레이터에서 Apple 로그인, 취소, 재로그인을 직접 확인합니다. 실제 계정 탈퇴 검증은 삭제할 데이터가 없는 별도 테스트 계정으로만 합니다. 앱이 두 버튼을 표시하는 것과 실제 인증 성공은 별개입니다.

공식 참고: [Firebase Flutter Apple 인증](https://firebase.google.com/docs/auth/flutter/federated-auth#apple), [Android Apple 설정](https://firebase.google.com/docs/auth/android/apple), [iOS Apple 설정 및 권한 회수](https://firebase.google.com/docs/auth/ios/apple).
