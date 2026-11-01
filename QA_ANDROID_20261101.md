# Android 추가 검증 — 2026-11-01

## Git 전달 상태

운동 설정창 수정/회귀 검사 소스는 `9c2cf52`로 커밋해 GitHub `codex/android-verification-20261101`에 푸시했습니다. 전달 전 관련13개 검사 재실행 통과, analyze 문제 없음(29.9초). 앞선 전체306개 검사/빌드 기록은 유지하지만 이번 Git 전달 중 전체 검사/빌드를 반복한 것은 아닙니다. 맥 작업 시작 방법은 `MAC_NEXT_STEPS.md`를 보세요. 아래 점검 일지의 '로컬/미푸시' 표현은 그 당시 상태이며 최신 전달 상태가 아닙니다. 실제 기기 검증 미완료 상태는 변하지 않았습니다.

과거 일지의 Windows 재시작/대기 요청은 다시 실행할 지시가 아닙니다. 사용자는 맥 전환과 Git 전달을 요청한 상태입니다.

## 기준과 데이터 보존

- 기준: `e5abccb`, 추가 작업 브랜치 `codex/android-verification-20261101`.
- 최신 작업 폴더: `C:/Users/hns/Desktop/gitclone/SPORKLE-Git-sync-20261031`.
- 원래 Windows 체크아웃과 기존 Mac 인계 브랜치는 덮어쓰지 않았습니다.
- 기존 AudioCheck5572의 게스트 파일 SHA-256은 시도 전후 `ed475129bf16d369a9db80441e553194a99a4b3268a4a4ac0c9d2c51824fd108`으로 동일했습니다. 앱 내부에 `files/guest_before_android_qa_20261101.json` 백업도 만들었습니다. 실제 운동 기록 생성/삭제, 계정 전환, Firestore 쓰기는 아직 하지 않았습니다.

## 최신 재개 결과: 공간 확보 후에도 부팅 환경 오류

### Chrome/Steam 종료 확인 뒤 추가 비교 (10:36 KST부터)

- 사용자가 두 프로그램 종료를 알린 뒤 Chrome/Steam/QEMU 프로세스가 없는 상태, Windows 시작11월1일10:02:33, 여유 RAM6.57GB/디스크50.62GB를 확인했습니다. 추가 사용자 프로그램 종료나 재부팅을 요구할 근거로 RAM 부족 하나를 반복 지목하지 않습니다.
- QA5574만37.2.13/Android15/host GPU/Vulkan 비활성/CPU2/RAM2GB/스냅샷 미사용으로 실행하고 `-show-kernel` 로그를 수집했습니다. 부팅 완료1이 됐으나 앱 실행 전 전화/System UI의 ANR가 재발했습니다. 커널 로그에는 이 시도의 TSC 전환이 확인됐으며 수집 구간에서 커널 panic은 찾지 못했습니다. 이는 커널 전체가 정상이라는 증명은 아닙니다. `apps-closed-kernel-out.log`/`apps-closed-kernel-error.log`/`apps-closed-boot-events.log`.
- 시계 상태의 sysfs 두 항목은 shell 읽기 Permission denied였습니다. root/SELinux 변경/권한 우회 없이 중단했습니다. 에뮬레이터 자체 부팅 출력만 사용했습니다.
- QA5574 런타임 CPU4/RAM3GB 비교에서는 TSC CPU 간 동기화 실패와 HPET 전환이 새로 관찰됐습니다. 이 구성은 앱 조작 전 단계에서 종료했고 `apps-closed-cpu4-ram3-out.log`/`apps-closed-cpu4-ram3-error.log`에 보관했습니다. 시계 경고가 모든 구성의 지연 원인이라고 확정하지 않습니다.
- CPU1/RAM3GB 비교에서는 TSC 전환/부팅 완료1/수정 APK의 선명한 로고와 로그인 화면을 확인했습니다. 설치 APK 해시는 BBE371DC…D6CCAA7로 일치했습니다. 그러나 뒤늦게 전화/System UI/런처/키보드/Google 서비스 ANR가 발생했습니다. `apps-closed-cpu1-ram3-out.log`/`apps-closed-cpu1-ram3-error.log`.
- 실제 UI에서 '로그인 없이 시작하기'를 눌러 안내01/04에 진입하고, 다음을 눌러02/04까지 전환했습니다. 새 QA 기기의 `files/guest_v1.json`은 `{"active":true}`로 저장됐습니다. 이어 SPORKLE 자체 입력 시간 초과 경고가 발생했고 Wait 이후에도 반복됐습니다. 운동 기록은 생성하지 않았으며 계정 인증/Firestore 쓰기도 없습니다. 이는 게스트 선택 저장 확인이지 운동 기록의 재시작 보존 검증이 아닙니다.
- 운동 미시작/기록 미생성 상태에서 앱만 force-stop 후 Impeller opt-out intent(`--ez enable-impeller false`)으로 재실행했습니다. 현재 SDK의 로컬 Flutter embedding JAR를 javap로 확인해 key `enable-impeller`와 false 플래그 매핑이 존재함을 확인했습니다. 앱 데이터 파일은 재실행 후에도 `{"active":true}`였습니다. 재실행에서도 System UI 경고/심한 프레임 지연이 남았습니다. 새 프로세스의 Dart VM 시작은 확인됐지만 Skia 백엔드 확정 로그는 수집하지 못했으므로 백엔드 정상 비교/해결 완료로 보고하지 않습니다. 소스/manifest에는 opt-out을 추가하지 않았습니다.
- 마지막 로그: `apps-closed-cpu1-last-anr.log`, `apps-closed-cpu1-final-events.log`, `apps-closed-skia-attempt-app.log`. 원본 AudioCheck5572와 기존 Windows 체크아웃은 건드리지 않았습니다. 이번 재개에서 앱 소스 수정/전체 검사 재실행/커밋/푸시는 하지 않았습니다.
- 최종 새 QA 게스트 파일 해시 `bbd02bf9a14d02d41f6b78dd36c79838d910f5a22937722109bf0035254b62f8`(active=true만 포함). QA5574는 정상 종료(emu kill OK)했고 연결 기기 목록이 비어 있음을 확인했습니다. 데이터 초기화/삭제는 하지 않았습니다.
- 실제 네이티브 검증의 남은 범위는 그대로입니다. 동일한 Windows 부팅/종료 요청을 더 반복하기보다 다른 호스트(예: 사용자 Mac)의 Android 에뮬레이터에서 동일 소스로 검증하는 것이 다음 대안입니다. Mac 칩 종류에 따라 에뮬레이터 ABI가 다르므로 Windows용 x86_64 APK를 Apple Silicon ARM64 기기에 그대로 설치할 수 있다고 안내하지 않습니다. 전환/추가 설치와 코드 전달은 사용자 방향 확인 뒤 진행합니다.

### 명령어 재시작 확인 후 비교 (10:11 KST부터)

- 사용자 명령어 재시작 응답 뒤 Windows LastBootUpTime2026-11-01 10:02:33/가동9.2분을 확인했습니다. 이번에는 실제 커널 재시작이 반영됐습니다. 초기 여유 RAM3.18GB/디스크53.7GB, APK 해시는 기존 BBE371DC…D6CCAA7과 일치했습니다. 앱 코드나 기존 AudioCheck5572 데이터는 변경하지 않았습니다.
- Android15 QA5574를37.2.13/host GPU/Vulkan 비활성/RAM2GB/CPU2/스냅샷 미사용으로 콜드 부팅했습니다. 부팅 완료 속성1이 됐지만 SPORKLE 실행 전에 전화/Google 서비스/System UI의 ANR가 재현됐습니다. `reboot-confirmed-before-app-anr.log`, `reboot-confirmed-out.log`/`reboot-confirmed-error.log`에 근거를 저장했습니다. 커널 재시작만으로 해결되지 않았습니다.
- 같은 Android15 기기/엔진/RAM/CPU에서 GPU만 공식 문서의 `swiftshader`로 바꿔 비교했습니다. 실제 Google SwiftShader 렌더러 확인 후에도 앱 실행 전 System UI 시작 ANR가 재현됐습니다. `reboot-swiftshader-out.log`/`reboot-swiftshader-error.log`/`reboot-swiftshader-boot-events.log`. GPU 변경만으로 해결되지 않았으며 QA5574는 정상 종료했습니다.
- 이미 설치돼 있던 Android36/google_apis/x86_64 revision6 이미지로 별도 `SPORKLE_Android16_QA_20261101`/5576을 생성했습니다. 기존 기기 복사/초기화나 새 다운로드는 하지 않았습니다. 새 기기만 RAM2GB/CPU4/540×960/density240/vsync30/host GPU/Vulkan 비활성/마이크 입력off/스냅샷 미사용으로 실행했습니다. 음성 출력은 유지했습니다. 시스템 이미지뿐 아니라 CPU 등도 다른 대안 탐색이므로 OS 버전 하나의 인과 비교라고 해석하지 않습니다. 이 기기는 여러 분 동안 adb offline/검은 화면으로 부팅 중이었고 앱을 설치하거나 인증/기록 생성을 하지 않았습니다. 종료 직전 대기 중이던 adb 로그 명령은 반환됐지만 정상 홈/조작/부팅 완료는 확인하지 못했습니다. 로그는 `android16-compare-out.log`/`android16-compare-error.log`입니다. Android16의 부팅 시도는 Android15 앱 검증을 대체하지 않습니다. 이후5576도 정상 종료(emu kill OK)했습니다.
- 재시작 뒤 Chrome 및 Steam 프로세스가 다시 실행돼 작업 집합 합계 약2GB(공유 메모리 중복 가능)를 사용했습니다. 사용자가 저장 후 직접 종료하도록 요청했습니다. 임의 강제 종료/Windows 보안·개인정보 설정 변경은 하지 않았습니다. Windows 메모리 측정 한 번에서 Available2626MB/commit55%/PagesPersec43699였으나, 이것만으로 RAM 부족이 유일한 원인이라 단정하지 않습니다.
- 참고한 공식 안내: https://developer.android.com/studio/run/emulator-troubleshooting (SwiftShader 비교, 마이크 입력과 Bluetooth 음질, RAM/commit 점검) 및 https://developer.android.com/studio/run/emulator-commandline (기기별 데이터 보존과 실행 옵션). 공식 문서의 보안 예외/드라이버/Windows 설정 변경 제안은 실행하지 않았습니다.
- 실제 앱 수정창/성장 가로 탐색/TTS/화면 켜짐/게스트 기록 재시작/실서버 병합 검증은 여전히 미완료입니다. 앞선306개 로컬 검사 결과를 재실행하거나 네이티브 통과로 바꾸지 않았습니다. 추가 앱 소스 수정/커밋/푸시는 없습니다.

### 사용자 재부팅 응답 후 재검증 (09:51 KST부터)

- 사용자가 재부팅했다고 답한 뒤 조회한 LastBootUpTime은 여전히2026-10-15 11:10:08, TickCount 가동 시간16.95일이었습니다. 초기 여유 RAM4.98GB/디스크45.87GB. Kernel-General ID12의 최근 커널 시작도10월15일이며, 조회한 Kernel-Boot ID27의 가장 최근 항목은11월1일06:15:47/유형0x2였습니다. 재부팅 요청이 실제 새 커널 시작으로 반영됐다고 확인할 수 없으며 사용자가 무엇을 잘못했다고 단정하지 않습니다.
- 별도 QA5574를37.2.13/host GPU/Vulkan 비활성/RAM2048MB/CPU2/스냅샷 미사용으로 실행했습니다. 부팅 완료 속성1은 확인했지만 앱 설치 전 Bluetooth/System UI/전화/키보드/Google 서비스의 ANR가 다시 발생했습니다.
- 준비된 APK를 새 QA5574에 설치 Success. 설치된 base.apk SHA-256도 `BBE371DC12FEB9CB0802787B6121074F7521C3E00F543F31DA0DC8480D6CCAA7`로 일치했습니다. 원본 AudioCheck5572에는 이번 재개 중 설치/실행/삭제를 하지 않았습니다.
- 앱 시작 로고와 로그인 화면(게스트/Google/Apple 버튼)은 실제 관찰했습니다. System UI 경고에서 Wait를 선택했으나 경고가 반복됐고, SPORKLE에도 FocusEvent 입력 응답5003ms 초과 ANR가 발생했습니다. 앱이 정상 실행되거나 앱 원인까지 배제됐다고 보고할 수 없습니다. 실제 운동/로그인/클라우드 쓰기는 수행하지 않았습니다.
- 앱 ANR 상세는 `resume-0952-app-anr-detail.log`, `resume-0952-last-anr.log`; 시스템 선행 오류는 `resume-0952-before-app-anr.log`/`resume-0952-system-anr.log`; 앱 로그는 `resume-0952-app.log`, 실행 구성은 `resume-0952-out.log`/`resume-0952-error.log`입니다. 로그는 로컬 verification 폴더에만 보관합니다.
- 추가 앱 소스 변경/전체 검사 재실행은 하지 않았습니다. 앞선306개 로컬 테스트/정적 검사/빌드 결과와 이번 네이티브 실패를 구분합니다. 다음 사용자 조치는 작업 저장 후 Windows의 명시적 다시 시작을 실행하고 LastBootUpTime 변경부터 확인하는 것입니다. 이 조치가 에뮬레이터 오류를 해결한다고 보장하지 않습니다.
- 로그 보관 후 QA5574는 `adb emu kill`로 정상 종료(OK)했고 연결 기기 목록이 비어 있음을 확인했습니다. 기존 기기/앱 데이터는 삭제하지 않았습니다.

- 사용자가 공간을 확보한 뒤 C드라이브 여유47.69GB를 확인했습니다. Steam/Chrome 종료 뒤 새 비교 기기 `SPORKLE_Android15_QA_20261101`/`emulator-5574`를 실행했습니다. 이 단계의 공간 부족은 해소됐습니다.
- 실행 도구37.2.13 + host GPU + Vulkan 비활성 + RAM3072MB/CPU2 구성에서 Android15 부팅 후 전화·Google 서비스 등의 시작 ANR와 Bluetooth 스택 SIGABRT가 앱 설치 전에 발생했습니다. 따라서 이 재현을 SPORKLE 앱 코드의 오류라고 볼 수 없습니다.
- 이미 설치된 실행 도구35.5.10 + SwiftShader + RAM2048MB/CPU2로도 비교했습니다. 부팅 완료 속성은 최종1이 됐지만 화면이 검게 남고 Google 서비스·전화 서비스의 시작 ANR가 재발했습니다. 같은 준비 기기의 데이터로 실행 도구/렌더러/RAM을 함께 바꾼 비교이므로, 이 결과만으로 특정 구성요소의 인과를 확정하지 않습니다.
- `pm path com.sparkleteamhns.counter01` 결과가 없어 이 새 기기에 앱이 미설치인 상태임을 확인했습니다. 원본 AudioCheck5572에는 이번 재개 중 어떤 초기화/설치/삭제도 하지 않았습니다.
- Windows 조회에서 LastBootUpTime은2026-10-15 11:10:08, 커널 가동 시간은16.93일로 기록됐습니다. 이것이 오류 원인이라는 증명은 아닙니다. 다음 확인은 사용자 작업 저장 후 Windows의 '다시 시작'으로 환경을 초기화하고 같은 APK를 재검증하는 것입니다. 임의 Windows 재부팅, 보안 설정 변경, 사용자 프로그램 강제 종료는 하지 않았습니다.
- 재부팅 전에5574는 정상 종료했습니다. 앱 소스 수정은 앞서306개 검사/정적 검사/빌드를 통과한 시트 수정 그대로이며, 추가 앱 코드 우회나 데이터 삭제는 하지 않았습니다. 로그인·음성 청취·기록 병합을 실제 확인한 것으로 보고하지 않습니다.
- 로그: `fresh-space-restored-out.log`, `fresh-before-app-anr.log`, `fresh-before-app-crash.log`, `sdk35-compare-out.log`, `sdk35-before-app-anr.log` (모두 로컬 verification 폴더). 종료 후 C드라이브 여유는45.82GB였습니다.

## 재현해서 수정한 앱 오류

운동 수정창에서 이름을 입력한 뒤 취소하거나 수정 결과를 반환하면, 닫힘 애니메이션 도중 `A FocusNode was used after being disposed`와 후속 렌더링 오류가 발생했습니다. 실제 `showEditExerciseSheet`를 사용하는 회귀 검사 두 개에서 수정 전 실패했습니다. 자유 운동 일반/튜토리얼 시작·취소 네 경우도 같은 검사에 포함했습니다.

원인은 `showAppSheet`의 Future가 화면 제거가 아니라 pop 시작 때 완료되어 호출자가 입력 자원을 먼저 해제하는 것입니다. 공통 helper에서 기존과 같은 테마·배리어·지역화·드래그 설정의 `ModalBottomSheetRoute`를 사용하고, `route.completed`까지 기다린 뒤 결과를 반환하도록 수정했습니다. 고정 지연 시간이나 애니메이션 제거로 우회하지 않았습니다.

새 회귀 검사 여섯 개는 모두 통과했습니다. 이것은 실제 앱 위젯을 사용하는 로컬 검사이며 에뮬레이터에서 수정본을 손으로 조작한 결과와 구분합니다.

`flutter analyze --no-pub`는 문제 없이 통과했습니다. 전체306개 테스트도 14분25초에 모두 통과했습니다. 일반 `lib/main.dart` Android x86_64 debug APK 빌드도 466.4초에 성공했습니다. 로컬 산출물은 `verification/android-validation-20261101/SPORKLE-android-validation-debug.apk`, SHA-256 `BBE371DC12FEB9CB0802787B6121074F7521C3E00F543F31DA0DC8480D6CCAA7`입니다. 이는 출시 서명/ARM 실물 휴대폰 빌드나 수정 APK의 실제 조작 검증 완료를 뜻하지 않습니다.

수정 APK를 기존 기기에 `install -r`로 설치한 결과는 Success이고 설치된 `base.apk`도 위 SHA-256과 일치했습니다. 설치 후 게스트 파일 해시도 변경되지 않았습니다. 테스트 로그는 `full-tests.log`, 정적 검사는 `analyze.log`, 빌드는 `build.log`입니다.

- 재현: `verification/android-validation-20261101/edit-sheet-before.log`
- 수정 후: `verification/android-validation-20261101/workout-sheet-after.log`
- 검사 코드: `test/workout_sheet_lifecycle_test.dart`

## 실제 에뮬레이터 관찰과 제한

- 기존 설치 APK는 전일 최종 APK와 동일한 SHA-256 `53318c950e1121bbaa44d42a453199add1f318b81987af52470d7cb9be4ac1b1`임을 확인했습니다. 이 APK에는 위의 새 시트 수정이 아직 없습니다.
- 기존 기기는 Android15 `SPORKLE_Android15_AudioCheck`, serial `emulator-5572`. 데이터 초기화/앱 삭제 없이 사용했습니다.
- WHPX 하드웨어 가속이 사용 가능하다는 엔진 자체 검사를 통과했습니다. 이것이 실행 안정성을 보장하지는 않습니다.
- 앱 실행 전부터 System UI, Google 서비스, 키보드의 시작/서비스 실행 응답 없음이 재현됐습니다. 메모리 확보 후 Vulkan 경로를 끈 재부팅에서도 System UI 시작 응답 없음이 발생했습니다. 사용자 메모리 부족 하나 또는 앱 하나가 원인이라고 확정하지 않습니다.
- Android 입력 장치 로그에서 실제 터치 DOWN/UP 전달은 확인했지만, 이는 앱이나 시스템 UI가 그 입력을 정상 처리했다는 증거는 아닙니다.
- 전면 활성화 후 실제 시작 로고 전체가 선명하게 보이는 것은 확인했습니다. 가려진 창의 캡처는 다른 창 내용이 섞일 수 있어 검증 근거로 사용하지 않았습니다.
- 비교용 새 AVD `SPORKLE_Android15_QA_20261101`을 별도로 준비했으나, 엔진이 요구하는 userdata 여유 공간 약7373MB에 비해 C드라이브 약4.7GB만 남아 실행되지 못했습니다. 이 기기에 앱 설치/로그인은 하지 않았습니다.
- 새 기기 비교와 별도로, 원본 설정 파일을 백업하고 기존 AudioCheck를 런타임 RAM3GB로 기동했습니다. 게스트 `/proc/meminfo`에서 MemTotal3048508kB, MemAvailable2021332kB였지만 System UI·키보드·전화 등의 시작 응답 없음이 다시 발생했습니다. 이후 Pixel Launcher 경고도 표시됐습니다. 따라서 RAM 증설로 해결됐다고 보고하거나 메모리 부족 하나로 원인을 확정하지 않습니다. `ram3gb-anr.log`에 관찰을 보관했습니다. 원래 config.ini의 RAM2048 값은 유지됐습니다.
- 빌드 캐시만 정리하는 명령을 시도했으나 실행 전에 정책으로 차단됐습니다. 이 명령으로 삭제된 파일은 없습니다. 소스/이미지/기기 데이터나 승인 목업은 삭제하지 않았습니다.

## 남은 검증

1. Windows의 공간 확보·실제 커널 재시작·Chrome/Steam 종료·새 기기/그래픽/CPU/RAM 비교는 수행했으나 안정적인 앱 조작을 확보하지 못했습니다. 같은 재시작 요청을 반복하지 말고 사용자 요청에 따라 맥의 새 Android AVD로 검증을 이어갑니다. 맥의 설치/실행은 이 Windows 세션에서 확인한 것이 아닙니다.
2. 수정 APK 설치 후 운동 수정창 시작/취소, 13단계 양 끝 가로 탐색.
3. 정식 앱의 실제 Android TTS 1초/2초 운동·휴식 순서, 일시정지·재개, 운동 중 화면 켜짐.
4. 별도 검증용 게스트 운동 기록 생성, 앱 프로세스 재시작 후 같은 ID/내용 보존.
5. 사용자가 직접 Google/Apple 인증한 뒤 실제 Firestore 저장·계정 기록 보존·중복 없는 게스트 병합. 모의 검사 통과만으로 실제 서버 확인 완료라고 보고하지 않습니다.

현재 2~5는 완료로 보고할 수 없습니다. 로그인/인증번호는 사용자가 직접 처리하고 음성 청취도 별도 확인이 필요합니다. 원시 로그·APK와 기기 파일은 Git에 넣지 않습니다.

이번 수정은 GitHub `codex/android-verification-20261101`의 `9c2cf52`로 전달했습니다. 기존 Mac 인계 브랜치를 받았다는 이유만으로 이번 수정이 Mac에 자동 반영되는 것은 아닙니다. 새 브랜치를 새 폴더로 받고 실제 검증을 이어가세요.
