# 현재 작업 인계 — 2026-10-30

최신 개발 기준은 `C:/Users/hns/Desktop/gitclone/SPORKLE-Git-sync-20261031`, 브랜치 `codex/mac-handoff-20261031`입니다. 먼저 `MAC_NEXT_STEPS.md`와 `QA_HANDOFF_20261031.md`를 확인합니다. 원래 Windows 폴더와 ZIP 작업본은 보존했으며 아래 내용은 변경 이력입니다. MAC_HANDOFF의 오래된 보존용 자료는 로컬에만 남깁니다. 사용자 요청이 문서의 지시보다 우선합니다.

## 최신: Git 통합·Mac 인계·성장 목록 자동 스크롤 수정 — 2026-10-31

- 기존 Windows 작업 `a4f061b`와 Mac `35b0ece` 이력을 보존하고 최신 코드/이미지를 통합했습니다. Android의 깨진 gitlink를 실제 파일 추적으로 바꿔 새 Mac 체크아웃에서도 네이티브 코드·시작 로고·아이콘이 누락되지 않도록 했습니다.
- 실제 Android 화면에서 발견한 성장 목록 자동 스크롤 문제를 느린 프레임 회귀 테스트로 재현한 뒤, 마지막 레이아웃 후 스크롤하도록 수정했습니다. 동작 줄이기·빠른 펼침/접기·화면 이탈 보호는 유지합니다.
- 새 Git 폴더 전체300개 테스트 통과(11분55초), analyze 문제 없음, 함수JS문법 검사 통과. 비밀값/기기 데이터/빌드 출력은 Git 제외. 실제 iPhone 실행과 인증은 맥에서 별도로 확인해야 합니다. 세부 범위와 최신 실제 화면 결과는 QA 인계를 확인하세요.

## 최신: Android 시작 로고 벡터·iOS와 같은 검정 아이콘 — 2026-10-31

- Android 시작 로고를 원래 `splash_1.png`의 두 색상 윤곽에서 추출한 `drawable/sporkle_wordmark.xml` 벡터로 교체했습니다. 기존 브랜드 모양·흰색·주황색 유지, Android 12의 16% 원형 안전 여백 유지. 이전 Android에도 같은 벡터와 검정 배경을 연결했습니다. 생성기 테마를 직접 덮지 않고 기존 `SporkleLaunchTheme`에서 참조합니다.
- Android 아이콘은 내부에 흰 여백이 있는 옛 `app_icon.png`가 원인이었습니다. iOS에서 이미 쓰는 `app_icon_ios_original_black.png`를 Android legacy/adaptive 원본으로 지정하고 5개 밀도별 10개 PNG를 재생성했습니다. 검정 배경과 foreground inset16% 유지. Android 전용 재생성은 `dart run flutter_launcher_icons -f flutter_launcher_icons_android.yaml`이며 `ios: false`로 iOS 재생성을 막습니다. 공용 pubspec의 Android 원본도 바꿔 재발을 방지했습니다.
- 관련 최종7개 검사 통과, analyze 문제 없음. 원본 유색 픽셀 99% 이상 보존·원형 안전 영역 밖 0픽셀·10개 이미지의 크기와 검정 모서리·테마 연결·무동작AVD참조 검사. iOS 파일64개 경로/해시 차이0. 앱 Dart 기능 코드와 승인 불씨13단계/홈/기록/성장/로그인/TTS/게스트 저장은 변경하지 않았습니다. 빌드·설치·실제 관찰은 `verification/android-branding-20261031/README.md`에 기록합니다.
- 이미지 변경 전 Android 리소스/pubspec은 같은 폴더 `android-branding-before.zip`에 보존했습니다. 시작 로고 원본과 iOS 원본 이미지는 수정하지 않았습니다. 맥 자동 동기화·iPhone 빌드·기존 응답 없음 문제 해결을 뜻하지 않습니다.
- 초기 정적 벡터 C2648F… 빌드는 실제 캡처에서 여전히 흐려 최종본으로 쓰지 않습니다. Android15의 저해상도 정적 아이콘 캐시 경로를 확인하고, 내부 scale0.68 중앙 그룹·1ms 회전0→0 AnimatedVectorDrawable로 바꿔 움직임/추가 대기 없이 직접 벡터 표시를 사용합니다. InsetDrawable 래퍼는 내부 여백으로 대체했습니다.
- 최종 일반 `lib/main.dart` Android x86_64 debug APK 빌드 성공(266초). `verification/android-branding-20261031/SPORKLE-android-branding-sharp-debug.apk`, SHA-256 `5422CEB55C05332D890F145B0DDA213F9B37229CEACBA40E32D560FB7CA3E5FA`. APK의 animated-vector/대상 그룹/1ms·0회전 animator를 AAPT2로 확인했고, 10개 검정 아이콘 PNG도 초기 검증본과 바이트 해시 일치. iOS64개/직전 승인 UI소스·테스트11개도 보존. 전체294개를 이번에 재실행한 것은 아니며 관련7개 검사 통과입니다.
- 최종 APK를 기존 AudioCheck5572에 데이터 초기화 없이 업데이트 설치 Success, 설치된 base.apk 해시 일치 및 전후/최종 게스트 파일 해시 `ed475129…24fd108` 동일. 실제 런처 검정 아이콘과 선명한 시작 로고 전체(첫S~마지막E)를 확인했습니다. `emulator-final-launcher-black.png`/`emulator-sharp-vector-splash.png`가 최종 실제 캡처입니다. 같은540×960의 초기 흐릿한 캡처와 비교해 흰 글자 회색 전이 픽셀2972→966(일반 화질 점수 아님). 앱 실행 전부터 System UI ANR가 발생해 Wait로 닫았으며 초기 빌드에서는 Bluetooth 중지/앱 ANR도 관찰했습니다. 이 기존 안정성 문제를 해결했다고 보고하지 않습니다. 실물 Android·이전Android·iPhone실행/스토어배포는 이번에 확인하지 않았습니다.

## 최신: 승인 불씨 13단계·가로 성장 목록·목표 이동 — 2026-10-31

- 승인된 `SPORKLE-flame-previews-20261031/art`의 고해상도 투명 PNG 13개를 원본 그대로 포함하고 기존 실제 성장값 -2~10에 연결했습니다. 홈과 나의 불씨에서 같은 자산과 2.4초 네이티브 움직임(상하·미세 확대·회전·후광)을 사용합니다. 작은 GIF 확대를 피했으며, 백그라운드·비활성 화면·동작 줄이기에서는 정지합니다. 로그인 화면의 기존 애니메이션은 바꾸지 않았습니다.
- 홈 V1·큰 첫날 불씨·`바로 운동 시작`·실제 Day/닉네임/루틴을 유지합니다. 불씨를 누르면 큰 현재 불씨, 말풍선, 실제 이번 주 목표, 화살표로 펼쳐 보는 13단계 가로 목록이 나옵니다. `불씨 방` 타이틀과 세로 단계 격자는 사용하지 않습니다. 실제 현재 단계만 테두리/`현재` 표시하며 목록 탐색으로 성장값을 변경하지 않습니다.
- 운동 기록에서 주간 목표를 빼고 나의 불씨로 이동했습니다. 사용자 불꽃 도장·오늘 회색 네모·작은 달력·실제 수동 기록 편집은 유지합니다. 완료한 기록에는 실제 총 횟수/운동 수/세트 내역을, 중도 종료는 실제 완료 횟수만 표시합니다.
- 전체 테스트 294개 통과(10분36초), analyze 문제 없음. 360×640/375×812 기본 글자 접힌 화면은 스크롤 범위 0; Android/iOS 320×568·글자2배에서는 스크롤 접근 및 펼침/접기, 동작 줄이기/백그라운드 정지, 13개 원본 이미지/성장 매핑을 검사했습니다. 테스트의 가짜 Day/기록은 실제 사용자 데이터가 아닙니다.
- 일반 `lib/main.dart` Android x86_64 debug APK 빌드 성공(501초). `verification/approved-flames-ui-20261031/SPORKLE-approved-flames-debug.apk`, SHA-256 `E5BD060A60889FDA57E6EBF2A449ABA03455FB1FA38827670D2FB6987D14C492`. 상세 근거와 최종 네이티브 관찰은 같은 폴더 README에 기록합니다.
- 최종 APK를 기존 AudioCheck5572에 `install -r`로 업데이트 설치 Success 및 설치 해시 일치 확인. 전후·최종 게스트 파일 해시 `ed475129…24fd108` 동일. 네이티브 홈의 새 불씨/실제 Day0/성장·목표 보기/바로 운동 시작을 관찰했으나 System UI와 SPORKLE 초기 실행 ANR 경고가 발생했습니다. 각각 Wait 후에도 앱 경고가 남아 실제 나의 불씨 펼침·가로 스크롤·기록 탭 및 움직임의 부드러움 확인은 미완료입니다. 원인을 앱/PC/에뮬레이터 중 하나로 확정하지 않으며 실제 화면 안정성 통과로 보고하지 않습니다. 같은 AVD·데이터를 보존하고 열어 둡니다. 증거 `emulator-home-observation.png` 및 README 참조.
- Firebase/Auth/게스트/성장 계산/TTS/루틴/iOS 네이티브 설정/원래 Windows checkout은 수정하지 않았습니다. 맥에는 자동 동기화되지 않으며 iPhone 빌드·스토어 배포는 별도입니다. 아래 이전 APK/목표 유지/에뮬레이터 상태는 과거 기록입니다.

## 최신: 사용자 불꽃 도장·오늘 회색 네모 — 2026-10-31

- 달력 최대너비308px/요일 여백 축소로 더 작게 정리하되 날짜 터치44px은 유지했습니다. 사용자 `fire_cal.png`/`.svg` 원본을 assets/images에 보관했습니다. PNG를 실제 운동일(totalReps>0,kind=workout)의 도장으로 사용하고 메모/0회 날짜는 찍지 않습니다. 이전/다음 달 도장은 회색입니다. 오늘은 회색 네모, 오늘도 운동했으면 네모 위에 불꽃을 함께 표시합니다. 그 외 선택일은 네모 대신 밑줄입니다.
- 주간 목표는 사용자가 의견을 물은 것이므로 그대로 유지했습니다. 기록 탐색에 집중하려면 제외하는 편을 추천했으나 임의 삭제/이동하지 않았습니다.
- 관련16개 최종 검사 통과(`verification/calendar-flame-stamp-20261031/tests-final.log`). 원본 해시·테스트 렌더링·범위는 같은 폴더 README에 있습니다. 이번 턴 APK 재빌드/재설치/에뮬레이터 조작은 하지 않았고, 현재 기기는 아래 이전 records-compact APK 상태입니다. 코드와 위젯 미리보기에만 이번 변경이 반영돼 있습니다. Firebase/저장 기능/iOS 설정/맥 작업본은 변경하지 않았습니다.

## 최신: 운동 기록 달력 우선·빈 화면 간소화 — 2026-10-31

- ZIP 파생 작업본에서 달력 → 이번 주 목표 → 선택일 기록으로 변경했습니다. 달력은 실제4/5/6주만 표시하고 기록 점·선택일 테두리·오늘 복귀를 제공합니다. 목표는 실제 설정과 기존 주간 운동 횟수를 연결합니다. 빈 카드의 큰 고정 여백을 없앴으며 수동 기록 추가/수정/실패 안내/읽기 재시도/실제 운동 총 횟수는 유지합니다.
- 일반 글자360×640/375×812에서6주 월까지 빈 화면 스크롤 범위0, 큰 글자·작은 화면에서는 접근 가능한 스크롤을 검사합니다. 초기 관련14개 검사 통과. 전체 검사/분석/최종 APK 및 실제 기기 관찰은 `verification/records-compact-20261031/README.md`와 로그를 확인하세요. 위젯 테스트 자료와 실제 회원 데이터 검증은 별개입니다.
- 기존 홈 V1·게스트·닉네임 수정은 유지합니다. 원래 checkout/기존 AVD/Firebase/iOS 네이티브 설정은 변경하지 않습니다. 맥 작업본에는 자동 반영되지 않습니다.
- 최종 전체273개 검사 통과(신규13개 포함,10분48초), analyze 문제 없음. 일반 앱 x86_64 debug APK 빌드 성공(370초), `verification/records-compact-20261031/SPORKLE-records-compact-debug.apk`, SHA256 `2A47AA3AB6FEB91056D18F91145ECCBC2223215D163A21B7E8FBECE307D8B176`. AudioCheck5572를 데이터 초기화 없이 다시 부팅해 실제 화면 확인을 진행합니다.
- 최종 APK를 AudioCheck5572에 업데이트 설치 Success 및 설치 해시 일치 확인. 업데이트 전후 guest_v1.json은 ed475129…24fd108로 동일합니다. 실제 홈은 렌더링됐으나 기존 System UI ANR 경고가 Wait 후에도 계속 남아 실제 기록 탭 확인은 미완료입니다. 위젯 렌더링과 기기 관찰을 혼동하지 마세요. 에뮬레이터/데이터를 초기화하지 않았고 동일 AVD를 열어 두었습니다. 미리보기·검사·설치 로그는 위 검증 폴더에 있습니다.

## 최신: 승인 V1 홈 / 선명한 첫날 불씨 / 바로 운동 시작 — 2026-10-31

- ZIP 파생 작업본에서 승인 V1의 원형 불씨·말풍선·Day 배지·로고·평면 루틴 목록·목록 아래 운동 버튼 배치로 구현했습니다. 기본110px 아바타 안 첫 단계 불씨는 실제 약64px이며 큰 후광 없이 얼굴이 선명합니다. 작은 화면에서는 비례 축소합니다. 기존 성장 PNG와 단계 계산, 실제 Day/닉네임/루틴 데이터, 게스트/Firestore 저장, 로그인 불씨 애니메이션은 보존했습니다. 시안의 Day1이나 예시 루틴을 실사용 데이터로 하드코딩하지 않습니다.
- 새 투명 이미지 `assets/images/home_ember_day1.png`를 프로젝트 안에 포함했습니다. 승인 이미지에서 내장 image_gen으로 분리했고 프롬프트/해시는 verification/home-v1-firstday-20261031/README.md에 있습니다. 앱 코드4개와 홈 검사 파일을 변경했습니다. 이전 닉네임 창 수명 오류 수정도 유지합니다.
- `바로 운동 시작`은 기존 자유 운동 설정과 연결되고 튜토리얼의 동일 문구도 바꿨습니다. 재생/편집/성장 화면/기록 탭/빈 루틴/불러오기 실패/복구 배너를 유지합니다. 작은 화면과 큰 글자에서는 자르지 않고 필요한 스크롤을 허용합니다. 하단 공통 메뉴는 시안의 불씨·달력·클립보드·설정 모양으로 맞췄고 이동 동작은 그대로입니다.
- 최종 소스 전체260개 검사 통과(home-v1-full-verified-tests.log), 전체 analyze 문제 없음(home-v1-verified-analyze.log). Flutter 위젯 미리보기는 verification/home-v1-firstday-20261031/first-day-375.png 및 first-day-360.png이며 테스트 데이터 렌더링입니다. 실제 회원 데이터 캡처와 구분합니다. APK 빌드/기기 업데이트 결과는 해당 README에 추가합니다.
- 일반 앱 Android x86_64 debug 최종 빌드 성공(Gradle465.3초). APK는 verification/home-v1-firstday-20261031/SPORKLE-home-v1-debug.apk, SHA256 11390C8F733BC02222E8E918865E4E232C071B289ABC88B5AED3CDFA4B08F869. lib/main.dart로 빌드했으며 샘플/테스트 진입점이 아닙니다. 같은 AudioCheck를 다시 켰고 설치·실제 홈 확인은 진행 중입니다.
- 최종11390C… APK를 AudioCheck(5572)에 데이터 초기화 없이 업데이트 설치 Success 및 설치된 base.apk 해시 일치 확인. 실제 홈에서 새 첫날 불씨/말풍선/바로 운동 시작/실제 Day0와 빈 루틴을 관찰했고 앱을 홈에 남겼습니다. guest_v1.json 해시는 재부팅·업데이트·앱 시작 뒤에도 ed475129…24fd108로 같았습니다. 이번 부팅242초/System UI ANR 및 am start의 초기 timeout 뒤 Wait로 홈을 확인했으므로 에뮬레이터 안정성이 완전히 해결됐다고 주장하지 않습니다. 실제 로그인·기록 병합 및 iPhone 검증은 별개로 남습니다.
- 실제 에뮬레이터의 기존 System UI ANR를 발견해 같은 AudioCheck(5572)만 데이터 초기화 없이 정상 종료했습니다. 빌드 후 같은 기기로 검증합니다. 원래 Windows checkout/기존 AVD/맥/실제 회원 데이터/서버 설정은 변경하지 않았습니다. 이 변경이 에뮬레이터 안정성·실제 계정 병합·iPhone 검증 완료를 뜻하지는 않습니다.

## 최신: 기간 제한 없는 게스트 모드와 재시작·계정 병합 구현 — 2026-10-31

- 작업본은 이 ZIP 파생 폴더입니다. 로그인 첫 화면에 로그인 없이 시작하기(주황색)를 추가하고 Google→Apple 순서를 유지했습니다. 게스트는 실제 회원 로그인과 구분하며, 기존 온보딩 뒤 기한/횟수 제한 없이 운동·기록·루틴·설정을 사용할 수 있습니다. 설정의 로그인하고 기록 보관하기에서 로그인 화면을 열고, 게스트에게 회원탈퇴는 숨깁니다.
- 신규 GuestStore는 앱 전용 Application Support/guest_v1.json에 직렬화·flush·rename으로 저장합니다. 앱 재시작 시 게스트 상태와 데이터 복원, 손상 파일 무단 초기화 금지. 로그인 시 같은 로컬 파일의 imports[uid]에 먼저 귀속해 A→B 전환에서 데이터가 섞이지 않습니다.
- 신규 GuestRecordRepository/GuestMigration/FirestoreGuestImporter로 기록/루틴을 원래 ID 그대로 이관합니다. 트랜잭션으로 문서가 없을 때만 생성하고 기존 문서는 보존합니다. 성공 확인 전 원본 유지, 실패/응답 유실/재시작 재시도, 복구 배너 연결. 새 로그인 후 서버 기록 재조회 시 서버 수정 내용을 보존하면서 로딩 중 새 쓰기도 유지합니다. 탈퇴는 전송을 중지하고 진행 중 전송 완료를 기다린 뒤 기존 삭제 절차로 진행합니다.
- 전체236개 통과(full-tests.log). 마지막 탈퇴 전송/화면 해제 보호 보강 후 관련20개 통과(lifecycle-tests.log). analyze-complete.log 문제 없음. 마지막 반복 전체 검사(full-complete-tests.log)는 자원 경합으로 중단해 전체238개 단일 통과로 보고하지 않습니다. Android x86_64 일반 앱 최종 debug 빌드 성공(build-complete.log,11분8초). 상세 테스트와 변경 파일은 verification/guest-mode-20261031/README.md입니다.
- 최종 APK: verification/guest-mode-20261031/SPORKLE-guest-mode-debug.apk, SHA-256 AA813B5C04A08158A7240C31BDDB85A182640DEF2F6DF4FEF1198682E3D82218. 이전 기능 확인 빌드647439…을 새 AudioCheck(5572)에 설치해 실제 게스트 진입/디스크 active=true/앱 프로세스 종료 후 게스트 온보딩 복원을 확인했습니다. 운동 목표/실제 운동 기록/실제 회원 인증은 대신 선택하지 않았습니다. System UI/앱 FocusEvent ANR가 있었고 앱 프로세스만 재시작해 진입했으므로 에뮬레이터 안정성 해결로 판단하지 않습니다. 최종 APK로도 데이터 초기화 없이 업데이트 중이며 실제 관찰은 README에 추가합니다.
- 실제 회원 데이터·Apple/Firebase 설정·보안 규칙·서버·iOS 네이티브 네 파일·승인 불씨 자산은 변경하지 않았습니다. 익명 Firebase 인증/Blaze/새 패키지가 필요 없습니다. 실제 운영 계정 로그인 후 Firestore 병합 왕복 및 iPhone 실기기는 미검증입니다. 맥에 자동 반영되지 않습니다. 아래 과거 글자 축소의 APK 미빌드 기록은 이번 빌드로 대체됩니다.
- 최종 AA813B… APK도 AudioCheck(5572)에 업데이트 설치 Success 및 설치 해시 일치, 로컬 게스트 active=true 유지 확인. 마지막 부팅5분 제한 초과/초기 PackageManager Broken pipe가 있었으나 저장소 RUNNING_UNLOCKED 후 앱 제거·데이터 초기화 없이 설치에 성공했습니다. 에뮬레이터 안정성은 별도 문제로 남습니다.
- 최종 AA813B…에서도 System UI 대기/앱 프로세스만 재시작 후 실제 게스트 온보딩01/04 복원을 확인했습니다. 최종 화면을 여기에 남겼으며 주간 운동 목표는 대신 선택하지 않았습니다. 캡처: verification/guest-mode-20261031/emulator-final-guest-restored.png.

## 최신: 로그인 보조 문구 추가 축소 / 게스트 접근 방식 검토 — 2026-10-31

- 사용자 요청으로 LoginPage의 첫 문구를18→16px, 로그인 안내를14→12px로 더 줄였습니다. 핵심 문구26~28px, Google→Apple 순서, 불씨 자산/실제 로그인 로직은 유지합니다.
- test/login_page_test.dart에16/12px를 정확히 검증하도록 반영했고 관련21개 통과. 작은 화면5종/큰 글자/로그인 취소·실패 검사를 포함합니다. 실제 위젯 PNG는 verification/login-ui-compact-20261031, 로그는 verification/login-ui-compact-tests-20261031.log입니다.
- 이번에는 소스/위젯 렌더링만 검증했으며 APK 재빌드/에뮬레이터 재설치는 하지 않았습니다. 현재 설치된 APK는 바로 아래 이전 UI 빌드로 보조 문구18/14px입니다. iPhone에도 자동 반영되지 않습니다.
- 로그인 없이 이용하는 방안은 의견 요청으로만 검토했으며 구현하거나 Firebase 설정을 바꾸지 않았습니다. 추천은 기간 제한 없는 기본 게스트 사용+백업/다른 기기 복구 시 선택적 로그인이며, 3일 후 강제 차단은 권장하지 않습니다. 실제 게스트 구현에는 현재의 라우팅 로그인 검사뿐 아니라 UID 기반 기록/루틴/설정 저장, 재시작 복구, 기존 계정 로그인 시 데이터 병합과 중복 방지 검증이 필요합니다.

## 최신: 로그인 글자 크기·Google 우선 배치·로그아웃 줄바꿈 수정 — 2026-10-31

- 사용자에게서 실제 Apple 로그인이 잘 된다는 확인을 받았습니다. 이번에는 인증/탈퇴/Firestore 로직을 바꾸지 않고 로그인·설정 화면 표시만 수정했습니다.
- 첫 문구18px, 핵심 문구26~28px, 안내14px로 구분하고 Google 로그인 버튼을 Apple 위에 배치했습니다. 각 콜백/아이콘/로딩 및 오류 처리는 유지했습니다. 승인된 불씨/후광/그림자 자산은 해시가 이전과 같습니다.
- 로그아웃은 한글 인코딩 손상이 아니라 좁은 버튼의 줄바꿈이었습니다. 창 여백/버튼 폭을 보완하고 큰 글자는 세로 배치, 짧은 창은 스크롤로 보호했습니다. 같은 창을 쓰는 탈퇴도 취소 회귀 검사했습니다. 설정 하단 약관 링크도 큰 글자에서 넘치지 않게 Wrap으로 배치합니다.
- 관련27개 통과 및 실제 위젯 PNG 확인. 기본 화면5종에서 스크롤 없이 두 버튼이 보이며 Android/iOS 큰 글자 검사도 유지합니다. 전체 검사217개 통과/새 테스트의 탭 위치1건 실패 후 테스트만 보완해 관련27개 재통과했습니다. 전체 재실행은 에뮬레이터 부팅 자원 경합으로 중단해 최종 전체218개 단일 통과라고 주장하지 않습니다. analyze 문제 없음, 일반 앱 Android x86_64 debug 빌드 성공.
- APK: verification/login-ui-20261031/SPORKLE-login-ui-debug.apk, SHA-256 79418B0C5816FD2078FB3005AB6AB58C1E2DE9CC2D48EBBECFF3F7CDA0684FFE. 새 AudioCheck(5572)에 데이터 삭제 없이 업데이트 설치 Success 및 설치 해시 일치. 재기동은 기존37.2.13/host GPU/실행 시4코어 조건을 유지했습니다. 부팅 지연과 System UI 응답 없음이 다시 관찰돼 실제 창 최종 확인은 별도로 구분합니다.
- iOS 네이티브 네 파일 해시는 이전과 같고 원래 프로젝트/기존 AVD/회원 데이터는 수정하지 않았습니다. 맥에 자동 동기화되지 않습니다. 변경 소스2개/테스트2개와 상세 증거는 verification/login-ui-20261031/README.md를 참조합니다.
- 추가 관찰: 시스템 ANR 대기 후 새 APK의 실제 로그인 화면에 진입했습니다. 문구 크기·Google→Apple 순서·두 버튼의 한 화면 표시를 확인했습니다. 최종 로그인 화면이며 임의 로그아웃/인증/삭제를 하지 않았습니다. 세션 복구나 실제 로그아웃 창 확인으로 해석하지 않습니다. 로그아웃 창은 위젯 렌더링과 회귀 검사로 검증했습니다.

## 최신: Android Apple 로그인 브라우저 조회 누락 보완 — 2026-10-31

- 사용자가 새 로그인에서도 Firebase `missing initial state` 오류를 재현해 브라우저→앱 연결 수정을 요청했습니다. 새로 가입하거나 키를 다시 만들도록 안내하지 않습니다.
- 기존 SDK GenericIdpActivity의 genericidp://firebase.auth/ 콜백은 병합 Manifest 및 기기 URI 해석에서 이미 정상 등록되어 있었습니다. MainActivity에 경쟁 콜백을 추가하거나 OAuth state/nonce 검증을 우회하지 않았습니다.
- Android 11+에서 브라우저/인증용 Custom Tabs 서비스를 찾기 위한 두 queries 선언이 누락되어 AndroidManifest.xml에 HTTPS VIEW 및 android.support.customtabs.action.CustomTabsService 조회만 추가했습니다. Firebase SDK23.2.1 코드도 서비스 조회 후 Custom Tab 또는 일반 브라우저를 선택함을 확인했습니다. 라이브러리/서버/iOS/로그인·탈퇴 Dart 로직은 변경하지 않았습니다.
- 새 Manifest 회귀 검사2개는 수정 전 실패, 수정 후 관련56개 및 전체211개 통과. analyze 문제 없음. 일반 앱 Android x86_64 debug 빌드 성공. 최신 APK: verification/apple-browser-return-20261031/SPORKLE-apple-browser-return-debug.apk, SHA-256 948A3DEA9E03CBB6CD400B2A6642A6C2487F1294ABEBD14F45764D09DD208814. 기본 APK도 이 일반 앱이며 새 테스트 진입점이 아닙니다.
- 새 AudioCheck(5572)에 데이터 삭제 없이 업데이트 설치 Success, 설치된 APK 해시 일치 및 SDK 콜백 해석 확인. 기기는37.2.13·host GPU·실행 시4코어로 구동 중입니다. config.ini나 기본 실행 CMD는 변경하지 않았습니다. 과거2코어 host 실행에서는 기본 앱들 ANR, software 비교에서는 앱 설치 전 Watchdog 시스템 서버 종료가 재현됐습니다. 이번4코어 부팅/설치에서도 System UI 지연이 있었으므로 플랫폼 안정성 해결로 보지 않습니다.
- 업데이트 후 앱이 SPORKLE 01/04 온보딩으로 진입했고 사용자도 확인했습니다. 이 경로는 Firebase 로그인 상태에서만 열리므로 기존 세션 복구는 확인했습니다. 새 Apple 로그인/콜백 완주를 이번 수정의 성과로 확정하지 않습니다. 가입 설정 보존을 위해 강제 로그아웃하거나 목표 설정을 대신 선택하지 않았습니다. 온보딩 완료 후 사용자 직접 인증으로 새 왕복을 최종 확인해야 합니다.
- iOS 주요 네 파일 해시는 작업 전후 같고 원래 Windows 프로젝트·기존 AVD·실제 회원 데이터·Apple/Firebase 비밀키는 변경하지 않았습니다. 맥에 자동 반영되지 않습니다. 상세와 검증 로그는 verification/apple-browser-return-20261031/README.md입니다.

## 최신: 승인된 v6 불씨·후광·그림자 실제 적용 및 확대 — 2026-10-31

- 사용자가 preview-v6를 최종 승인하고 앱에 크게 적용하도록 요청했습니다. 승인된 캐릭터/반짝이는 눈/밝아지며 미소/크고 옅은 후광/입 아래까지의 빛/가벼운 그림자를 새로 그리지 않고 그대로 사용합니다.
- 앱 자산은 `assets/images/login_flame_approved.webp`, 움직임 줄이기용은 같은 승인 그림의 `login_flame_still.png`입니다. 내용이 없는 맨 아래80px만 전 프레임 RGB 검사 후 제거해480×400으로 포장했습니다. 원본480×480 GIF와 모든 시안은 design/login-flame 아래에 남겼습니다.
- 300프레임·20ms·6초·50fps 무한 반복 유지. 앱용 무손실 Animated WebP3,554,414 bytes로 승인 GIF6,029,317 bytes보다 작고 모든 프레임 RGB가 원본과 정확히 일치합니다. 초기 손실 압축본의 사각 잔상을 캡처에서 발견해 최종본은 무손실로 바꿨습니다. Flutter 기본 디코더를 사용하며 신규 패키지는 없습니다. 재현은 `tool/export_approved_login_flame.cjs`입니다. 과거 v2 `tool/build_login_flame.cjs`는 app-before-v6에만 출력합니다.
- 로그인 그림은 화면 높이/폭에 따라 약194~360px 폭으로 확대하고 비율6:5를 유지합니다. 작은 세로 화면5종에서 기본 글자·안전 영역 포함 두 버튼이 스크롤 없이 표시되며 큰 글자에서는 기존 스크롤 대체를 유지합니다. 이미지가 커져도 로그인 기능/약관 링크는 그대로입니다.
- 이전 GIF·정지 PNG는 design/login-flame/app-before-v6에 해시 일치 확인 후 보관했습니다. 사용하지 않는 이전 GIF만 앱 번들에서 제거했으며 복구 가능합니다. 참조 원본 캐릭터 PNG는 삭제하지 않았습니다.
- 관련25개/전체209개 검사 통과, analyze 문제 없음. 마지막 무손실 자산 교체 후 관련25개 재통과 및 일반 앱 Android x86_64 debug 재빌드 성공. 최신 APK는 `verification/approved-login-flame-20261031/SPORKLE-approved-login-flame-debug.apk`, SHA-256 `2A8105F97297F4A30DBE757BC097BE69A22D7801AEF75BEAE0B479EEE75DCBF7`. 기본 빌드 출력도 같은 일반 앱입니다.
- APK 내부 새 무손실 애니메이션의 길이/해시(`568CDBFE9D270D857B403209A8121972AA1BB53A601942C45246F4702429ABBD`)가 소스와 일치하고 이전 GIF는 포함되지 않음을 확인했습니다. 새 Android 15 AudioCheck(5572)에 데이터 삭제 없이 업데이트 설치·실행 성공. 확대된 캐릭터/반사광/미소/후광과 두 로그인 버튼이 스크롤 없이 보입니다(`verification/approved-login-flame-20261031/applied-login-screen.png`). 연속5캡처의 불씨 영역 변화로 실제 애니메이션도 확인했습니다. 상세는 해당 폴더 README.md입니다. 원래 AVD의 설정 해시와 사용자 데이터 크기/수정 시각은 이전 값 그대로입니다.
- iOS 네이티브/시작 로고/서명 설정 및 운동/TTS/인증/Firestore 로직은 이번에 수정하지 않았습니다. iPhone은 맥에 수정본을 옮겨 재빌드/확인해야 하며 자동 동기화되지 않습니다. 기존 첫 실행 지연/TTS 첫 실행 안정성을 해결한 작업으로 판단하지 않습니다.

## 최신: 원본 캐릭터 기반 로그인 불꽃 GIF — 2026-10-31

- 기존 charactor_login.png를 참조해 내장 image_gen으로 12개 키프레임을 제작하고, 눈 위치를 맞춘 66프레임 GIF로 조립했습니다. 불씨가 밝아져 활활 흔들린 뒤 부드럽게 반복합니다. 256×256, 4.68초, 무음, 1,376,929 bytes. 원본 그림은 보존했습니다. 생성 원본/실제 프롬프트/재현 스크립트는 `design/login-flame/README.md`, `tool/build_login_flame.cjs`입니다.
- LoginPage만 GIF/밝은 정지 PNG로 연결했습니다. 움직임 줄이기 설정이면 정지 PNG, 일반 설정이면 GIF. 새 Flutter 패키지나 네트워크 동영상은 사용하지 않습니다. 화면 높이가 충분하면 156px, 작으면 기존 72px 높이입니다. 작은 세로 화면의 두 로그인 버튼 가시성/스크롤 범위 0 검사도 통과했습니다.
- 관련 검사 23개 통과, analyze 문제 없음, 일반 앱 Android x86_64 debug 빌드 성공. 이번에 전체 테스트는 재실행하지 않았습니다. 기존 시작 로고, 운동 중 화면 유지, TTS/인증/Firestore 동작과 iOS 네이티브 파일은 수정하지 않았습니다. iPhone 실기기는 미검증이며 맥에 자동 반영되지 않습니다.
- 최신 일반 앱 APK: `verification/login-flame-20261031/SPORKLE-login-flame-debug.apk`, SHA-256 `FA4900C1E14F62DB5ABE62DC5222A0AC5DBE2F6E24571C081B16EA8B02A2F965`. 기본 빌드 출력도 같은 일반 앱입니다. APK 내부 GIF의 길이/해시가 최종 assets/images/login_flame_ignite.gif와 일치하는 것도 확인했습니다.
- 새 Android 15(5572)에 일반 앱 업데이트 설치/실행 성공. System UI 응답 없음 안내가 있었으나 Wait 한 번 후 정상 로그인 화면에 진입했습니다. 두 네이티브 캡처의 불꽃 영역만 비교해 21,384픽셀의 유의한 변화로 실제 GIF 움직임을 확인했고, 두 로그인 버튼도 스크롤 없이 보입니다. 현재 일반 앱을 이 화면에 남겼습니다. 상세/최종 상태는 `verification/login-flame-20261031/README.md`를 참조합니다. 원래 Windows 프로젝트/기존 AVD/실제 회원 데이터는 변경하지 않았습니다. 이전 첫 실행 지연/음성 첫 실행 안정성 문제는 이번 GIF 작업으로 해결됐다고 주장하지 않습니다.

## 최신: 로그인 첫 화면 / 운동 중 화면 자동 꺼짐 방지 — 2026-10-31

- 로그인 화면의 고정 상단 여백·이미지 높이·버튼 주변 여백을 화면 높이에 맞췄습니다. 기본 글자 크기에서 320×568 / 360×640 / 375×812 및 상하 안전 영역 포함, 두 로그인 버튼을 스크롤 없이 표시하는 검사 통과. 큰 글자/가로 화면에는 내용 잘림 방지를 위해 스크롤을 유지합니다. 인증 기능/개인정보처리방침 링크는 유지합니다.
- CounterPage에 앱 수명주기와 VM 상태를 연결했습니다. 운동/세트 전환 대기/휴식에만 화면 유지, 일시정지/편집/초기화/저장 대기/완료/dispose/백그라운드에서 해제합니다. Android FLAG_KEEP_SCREEN_ON, iOS UIApplication.isIdleTimerDisabled를 작은 MethodChannel로 사용하며 신규 패키지나 권한은 추가하지 않았습니다. iOS는 AppDelegate.swift 한 파일만 바뀌었고 시작 로고/서명 설정은 유지했습니다. 맥에는 자동 동기화되지 않으며 iOS 빌드/실행은 미검증입니다.
- 전체 테스트 204개 통과, analyze 문제 없음, Android x86_64 debug 빌드 성공. 기존 TTS 지연/저장/계정 전환 테스트도 포함합니다.
- 새 Android 15(5572) 검사 앱에서 운동 시작 시 KEEP_SCREEN_ON 활성화, 일시정지 시 해제를 확인했습니다. 새 기기 자동 꺼짐을 검사 중 15초로 바꾸고 충전 중 유지도 껐는데 추가 터치 없이 42초 후에도 Awake였습니다. 검사 후 화면 시간 2147483647, 충전 중 유지 1로 정확하게 복원했습니다. 기존 AVD/실제 Firestore 데이터를 변경하지 않았습니다.
- 최신 일반 앱 APK: `verification/login-awake-20261031/SPORKLE-login-screen-awake-debug.apk`, SHA-256 `B7CD19D8FCDC161F7B3ADE0F2E4CEAD9D444208D78B36D5A81443BCB197D1052`. 기본 빌드 출력도 이 일반 앱입니다. 검사 앱은 별도 보존했으며 일반 배포에 사용하지 않습니다.
- 검증 후 일반 앱 업데이트 복원/시작 성공. 스크롤 없이 제목부터 Apple·Google 두 로그인 버튼까지 한 화면에 보이는 것을 확인했습니다(`verification/login-awake-20261031/login-one-screen.png`). 실제 로그인은 하지 않았고 일반 앱 로그인 화면에 남겼습니다. 첫 진입 지연은 계속 관찰됐습니다.
- 검사 중 음성 자동 음소거도 관찰했으므로 이번 실행으로 새 TTS 청취 통과를 주장하지 않습니다. 첫 실행 지연/음성 첫 실행 안정성은 별도 진단 대상입니다. 상세 로그·제한은 `verification/login-awake-20261031/README.md`입니다.

## 최신: Android 시작 로고 잘림 수정 — 2026-10-31

- Android 12 이상에만 원본 로고를 16% inset으로 감싸는 XML과 자체 `SporkleLaunchTheme`를 적용했습니다. 생성 테마를 상속하며, iOS/공용 이미지/pubspec은 변경하지 않았습니다. iOS 파일 64개의 작업 전후 경로/해시가 모두 같았습니다.
- 새 Android 15 검증 기기 `SPORKLE_Android15_AudioCheck`(5572)에 데이터 삭제 없이 일반 앱 APK를 업데이트 설치했습니다. 밝은/어두운 기기 테마에서 첫 S와 끝 E까지 표시되는 것을 확인하고 원래 밝은 기기 테마로 복원했습니다. 기존 AVD는 실행/초기화하지 않았고 설정 해시/사용자 데이터 크기·시각이 유지됐습니다.
- 새 로고 회귀 검사 2개 통과, analyze 문제 없음, Android x86_64 debug 빌드 성공. 이번에는 전체 Flutter 테스트를 재실행하지 않았습니다.
- 최신 일반 앱 APK: `verification/android-splash-20261031/SPORKLE-android-splash-fixed-debug.apk`, SHA-256 `601A913750811D9D46A797FE12AD500C36DDD286B4A5D9BA3FA63F8948A2E8EE`. 현재 기본 빌드 출력 `build/app/outputs/flutter-apk/app-debug.apk`도 `lib/main.dart`의 일반 앱입니다. 아래 이전 TTS 테스트 진입점/기본 출력 주의는 과거 시점 기록입니다. 이전 테스트 APK는 그대로 보존했습니다.
- 첫 일반 앱 실행에서 랜딩 화면 위 ‘응답 없음’ 안내, 재실행 시에도 시작 지연을 관찰했습니다. 최종 재실행은 응답 없음 창 없이 랜딩에 진입한 상태입니다. 로고 잘림 수정은 확인했지만 시작 안정성까지 통과한 것으로 보지 않습니다. 원인을 PC/에뮬레이터/앱 중 하나로 확정하지 않았으며 별도 진단이 필요합니다. 로그인/Firestore 저장, 실물 Android/iPhone, 출시 빌드는 이번 범위가 아닙니다.
- 상세 증거와 밝은/어두운 테마 캡처: `verification/android-splash-20261031/README.md`. 변경은 별도 Windows 작업본에만 있으며 맥에 자동 반영되지 않습니다.

## Windows 후속 변경: Android·iOS 모두 Apple·Google 로그인

- 현재 작업 폴더는 `C:/Users/hns/Desktop/gitclone/SPORKLE-Android-20261030/SPORKLE-Windows/flutter-workoutcounter2`입니다. 기존 Windows 프로젝트는 보존했습니다. 이 폴더는 Git 저장소가 아니므로 자동으로 맥과 동기화되지 않습니다.
- 사용자 최종 결정: Android와 iOS 모두 Apple·Google 로그인을 제공합니다. Google만 남기거나 플랫폼별로 버튼을 숨기려던 중간 변경은 폐기했습니다.
- Apple 로그인·재인증을 `FirebaseAuth.signInWithProvider` / `User.reauthenticateWithProvider`로 통일했습니다. Firebase SDK가 iOS nonce 및 최초 이름 전달을 처리하고 Android는 Firebase의 웹 OAuth 흐름을 사용합니다. 별도 `sign_in_with_apple` 플러그인은 제거했습니다.
- 로그인 취소는 실패로 표시하지 않고, 설정 오류·네트워크 오류·다른 제공자로 가입된 계정 충돌은 구분해서 안내합니다. 자동 계정 연결이나 이메일 기준 데이터 병합은 하지 않습니다. 중복 요청 방지 및 큰 글자 대응은 유지합니다.
- 탈퇴 시 재인증 후 Apple 권한을 회수하고 나서 사용자 데이터를 삭제합니다. iOS는 Firebase SDK, Android/web은 Firebase 공식 `accounts:revokeToken` API를 사용합니다. 재인증 취소·토큰 누락·회수 실패·계정 변경 시 데이터 삭제를 중단합니다. 실제 사용자 데이터 삭제로 테스트하지 않습니다.
- iOS Runner에 Apple 로그인 entitlement와 Debug/Profile/Release 설정, Xcode capability 표시를 추가했습니다. Apple Developer/Firebase의 제공자 활성화 및 프로비저닝은 변경하지 않았습니다. 맥에서 서명·실제 Apple 로그인을 확인해야 합니다.
- 기존 세션이나 계정 데이터를 강제 삭제·로그아웃·이전하지 않았고 Firebase 콘솔의 제공자도 변경하지 않았습니다.
- Apple와 Google로 로그인한다고 자동으로 같은 UID가 되는 것은 아닙니다. 두 OS에서 같은 제공자와 같은 계정을 사용하세요. Android Apple용 Services ID는 iOS의 같은 기본 App ID에 연결해야 합니다. 계정 연결·이전 기능은 이번 범위가 아닙니다.
- App Store 규정 4.8은 예외에 해당하지 않는 제3자 로그인 앱에 동등한 개인정보 보호 대체 로그인을 요구하므로 iOS Apple 로그인을 유지합니다. 최종 심사 승인을 보장하는 것은 아닙니다. https://developer.apple.com/app-store/review/guidelines/#login-services
- Android 15 작업용 에뮬레이터는 `SPORKLE_Android15`입니다. 검은 화면은 이 AVD의 그래픽을 `swiftshader_indirect`로 바꾸고 콜드 부팅한 뒤 해소됐습니다. 앱의 기본 렌더러는 유지했습니다.
- 현재 검증 자료는 `verification/android15/` 아래에 있습니다. 아래의 맥 검증 수치는 이전 시점의 기록입니다. Google 실제 인증 및 Firestore 저장, 이번 변경본의 iPhone 실행은 별도 확인이 필요합니다.
- 2026-10-30 Firebase 제공자 설정을 읽기 전용으로 조회했습니다. Apple enabled=true이지만 Service ID, Team ID, Key ID가 비어 있습니다. 비밀키는 조회·출력하지 않았습니다. Android Apple 로그인 및 Apple 권한 회수를 완성하려면 Apple Developer/Firebase 설정을 채워야 합니다. 상세 절차는 WINDOWS_START_HERE.md의 Apple 로그인 설정 절을 따릅니다.
- 사용자는 Apple Developer Program에 가입되어 있다고 확인했습니다. 비밀번호·.p8 키를 채팅이나 저장소로 수집하지 않습니다. 설정은 Apple Developer와 Firebase Console에 직접 입력합니다.
- 이전 `platform-login-*` APK·화면·검증 자료는 Android Google만 표시하던 중간 버전입니다. 최신 수정의 검증 자료는 `verification/android15/apple-auth-*`이며, 실제 인증 성공과 스토어 배포 완료를 뜻하지 않습니다.
- 최신 검증: 전체 테스트 188개 통과, analyze 문제 없음. Android x86_64 debug 빌드 및 에뮬레이터 업데이트 설치 성공. `apple-google-login.png`에서 두 로그인 버튼을 확인했습니다. 최신 APK는 `verification/android15/SPORKLE-apple-google-debug.apk`입니다. 테스트는 가짜 사용자·가짜 DB·HTTP 모의 응답을 사용했고 실제 계정 탈퇴나 권한 회수를 실행하지 않았습니다.
- 이 PC의 Android debug SHA-1은 Firebase 등록값과 일치합니다. 출시용 서명 일치 여부는 별도 검증 대상입니다. Firebase 제공자의 비밀키·프로필·회원 데이터는 변경하지 않았습니다.

## Windows 후속 변경: 운동·휴식 시작 음성

- 각 세트는 "시작! 하나!" → "둘!" → "셋!" 순서로 읽습니다. 시작 안내와 첫 숫자를 하나의 발화로 전달합니다.
- 휴식은 "휴식! 1!" → "2!" → "3!" 순서로 읽습니다. 휴식 길이만큼만 읽으며 화면의 남은 시간 표시는 유지합니다.
- 일시정지 후 재개할 때 시작 안내를 반복하지 않습니다. 초기화 후 새로 시작하면 다시 안내하며, 이전 운동 완료 여부와 현재 세트의 시작 여부를 구분합니다.
- 기존 전체·루틴·세션별 음소거 및 플랫폼별 내장 음성 선택을 유지합니다. 타이머·운동 기록 저장 방식과 Firebase 설정은 변경하지 않았습니다.
- 최종 전체 테스트 191개 통과, analyze 문제 없음. 발화 순서 검증은 모의 TTS를 사용하며 실제 iPhone 음성과 짧은 간격에서의 기기별 발화 길이는 별도 청취 확인이 필요합니다. 맥에는 자동 동기화되지 않습니다.
- 최신 APK는 `verification/android15/SPORKLE-start-rest-debug.apk`입니다(Android x86_64 에뮬레이터 전용 debug). SHA-256: `F30678F1B0835BE10D3B0F0CD9B8F89200E0BD00DABAA1E80DFF254C400D6EDF`. `emulator-5560`에 데이터 삭제 없이 업데이트 설치하고 앱 시작 명령의 성공을 확인했습니다. 실제 로그인·운동 화면의 청취 검증을 뜻하지 않습니다.
- **후속 네이티브 검증 실패:** 실제 CounterPage/CounterViewModel/TtsService를 이용한 별도 테스트 실행에서 1초·2초 설정 모두 휴식 안내/숫자 발화가 누락됐습니다. Android `flutter_tts` 4.2.3은 이전 발화 중인 flush 요청을 반환값 0으로 버릴 수 있고 앱은 이를 확인하지 않습니다. 제품 수정은 아직 하지 않았습니다. 모의 테스트 191개 통과가 실제 음성 정상 재생을 의미하지 않습니다.
- 상세 증거는 `verification/android15/counter-native-results.md`, `counter-native-1s.json`, `counter-native-2s.json`, 음성 포함 WebM 녹화에 있습니다. 테스트는 메모리 기록만 사용했으며 실제 계정/Firestore 데이터는 변경하지 않았습니다. 검증 후 위 일반 앱 APK를 데이터 삭제 없이 다시 설치·시작했습니다. 기본 빌드 출력 `build/app/outputs/flutter-apk/app-debug.apk`는 테스트 진입점의 APK일 수 있으므로 일반 앱 배포에 그대로 사용하지 않습니다.

## 보존할 구현

- 2026-10-31 TTS 순서 후속 수정 및 재개 검사: 발화 직렬화/명시적 실패 처리/중지 시 대기 취소/20초 네이티브 완료 콜백 제한과 카운터의 발화 완료 대기, 세트 완료 대기 중 수동 시작 방어를 구현했습니다. 긴 안내일 때 설정 간격은 최소 간격으로 동작하며 화면도 기다립니다. 정적/관련 자동 검사와 Android 빌드는 통과했습니다. 이후 준비된 APK(9AD6154A…73F7AA)를 재빌드 없이 새 기기에 설치해 실제 CounterPage/CounterViewModel/TtsService와 Google Android TTS를 실행했습니다. 2초·1초 설정 각각 11개 발화가 순서대로 완료됐고 겹침/누락/취소 없이 3회×2세트(6회)를 마쳤습니다. 사용자도 "두 검사 모두 순서대로 잘 들렸어요"라고 실제 PC 스피커 청취를 확인해 이번 Android TTS 검증을 완료했습니다. 기존 SwiftShader 부팅은 앱 설치 전 Watchdog 종료를 재현했고, 별도 37.2.13 엔진의 `-gpu host`(Intel Iris Xe)에서는 부팅 완료와 동일 시스템 서버 PID 578을 두 검사 종료까지 확인했습니다. `START_ANDROID15_AUDIOCHECK.cmd`도 이 검증 조건으로 갱신했습니다. 기존 SDK 35.5.10/원래 AVD의 설정 해시 및 데이터 크기·정확한 UTC 시각은 유지됐습니다. 새 기기에 검사 앱을 실행 상태로 남겨뒀으며 중복 실행하지 않습니다. 테스트 전용 APK이므로 일반 앱/출시용 배포에 사용하지 않습니다. 실제 로그인/Firestore 저장과 iPhone 실기기는 미검증이며 맥 자동 동기화도 되지 않습니다. 상세 해시·로그·다시 실행 절차는 `verification/tts-sequence-20261031/README.md`입니다. 수정 전 실패 증거는 보존했습니다.

- 2026-10-31 후속: 사용자 승인으로 별도 `SPORKLE_Android15_AudioCheck`(5572)를 생성했습니다. 기존 AVD 설정 해시/사용자 데이터 메타데이터는 변경되지 않았고 기존 엔진 35.5.10도 유지했습니다. 새 엔진 37.2.13은 별도 SDK 루트에 설치했습니다. 새 기기 부팅과 녹음된 한국어 WAV 재생 화면, Android 출력 프레임 증가, Windows 믹서의 새 세션까지 확인했으나 실제 청취는 사용자 응답 대기입니다. 실시간 TTS/운동 음성 정상 판정은 하지 않습니다. 상세: `verification/android15-audio-20261031/README.md`. 재실행은 `START_ANDROID15_AUDIOCHECK.cmd` 사용(이미 실행 중이면 중복 실행하지 않음). 앱 소스·Firestore는 변경하지 않았습니다. 아래 이전 기록은 새 기기 생성 전 상태입니다.

- Windows 에뮬레이터 무음 후속 점검은 미해결입니다. 작업용 SPORKLE_Android15의 마이크 입력을 끄고 출력은 유지했습니다. RAM 2GB·CPU 2코어 실험은 원래 3GB·4코어로 복원했고 대기 중인 이 작업의 Gradle 데몬 1개를 정상 종료했습니다. 사용자 앱 정리 후에도 시스템 서버 재시작이 반복되어 음성 검증을 못 했으며, 반복 부팅 중인 에뮬레이터는 종료합니다. AVD/데이터 초기화는 하지 않았습니다. 기존 AVD를 보존한 별도 검증용 기기 생성을 제안하는 단계이며 아직 새 기기는 만들지 않았습니다. 백업과 상세 근거는 `verification/android15/emulator-audio-fix.md` 참조. 앱의 TTS 겹침 누락도 별도 미수정입니다.

- 온보딩 자동 이동 제거, 명시적 버튼으로 진행.
- 루틴 여러 개 선택 삭제 및 전체 삭제 확인.
- iOS 중심 다크 UI, 기존 불씨·덤벨 아이콘 유지, 검정 배경으로 배치 정리.
- 시작 화면 중복 로고 제거.
- 바로 운동 기본값: 스쿼트 / 3세트 / 세트당 15회 / 2초.
- 시작 즉시 1을 표시하고 각 세트 첫 발화는 "시작! 하나!". 이후 둘·셋으로 세고 완료한 횟수만 기록에 저장. 일시정지 후 재개는 시작 안내를 반복하지 않습니다.
- 휴식 첫 발화는 "휴식! 1!", 이후 1초마다 2·3으로 증가합니다. 화면은 기존 남은 휴식 시간 표시를 유지합니다. Android/iOS 내장 TTS와 기존 음소거 설정을 사용하며 DB 저장 방식은 변경하지 않습니다.
- 커진 굵은 그라데이션 링과 버튼, 휴식은 초록 그라데이션.
- 무료 iOS 내장 한국어 음성 선택·미리듣기, 하나·둘·셋으로 카운트.
- 운동 끝내기 → 네: 음성 완료를 기다리지 않고 중지 요청, 저장 성공 후 홈으로 이동. 저장 실패는 재시도 가능.

## 최근 검증

- Flutter 3.32.6 / Dart 3.8.1, Xcode 16.4, macOS 15.6.
- Flutter 전체 테스트 134개 통과, analyze 문제 없음.
- iOS release 빌드 및 연결된 iPhone 설치 성공.
- iPhone의 새 iOS에서 debug JIT 실행 문제가 있어 release로 설치합니다.
- 실기기에서 최근 종료 수정의 사용자 확인은 별도 필요합니다.
- 사용자는 내장 음성이 기계적이라고 평가했습니다. 자연스러움은 미해결입니다.

## 음성 관련 주의

ElevenLabs 유료 사용은 취소했고 무료 내장 음성으로 전환했습니다. 유료 가입이나 결제를 진행하지 않습니다. 실험용 TrainerVoice/TrainerAudioService 소스는 보존되어 있지만 현재 선택 화면은 SystemVoicePicker입니다. 유료 샘플을 앱에 추가하지 않습니다.

## 데이터와 플랫폼

Firebase 프로젝트와 계정별 루틴·기록 저장 방식 유지. 실제 데이터 삭제로 테스트하지 않습니다. 미저장 기록은 기기별 로컬 저장이므로 Git으로 옮겨지지 않습니다.
Windows에서는 소스 작업과 테스트, 준비된 Android 환경에서 실행할 수 있습니다. iPhone 설치는 맥에서 진행합니다. Windows 데스크톱/웹 호환성은 별도 검증 대상입니다.
Firebase 클라이언트 설정은 앱에 포함되어 있습니다. 공개 저장소 업로드는 피하고 기존 저장소 공개 범위를 먼저 확인합니다. 인증서·개인 키·Android 서명 비밀번호는 Git 제외입니다.

## Git 연결

원본 압축에는 .git이 없습니다. 기존 이력을 찾으면 별도 임시 checkout에서 최신 파일을 비교·반영하여 이력을 보존합니다. 기존 Windows 작업을 강제로 덮어쓰지 않습니다. 원격 주소 확인 및 push 성공 전에는 동기화가 완료됐다고 보고하지 않습니다.
