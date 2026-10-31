# 로그인 불꽃 GIF 제작

## 현재 앱 사용: 승인된 v6 후광·미소·그림자

사용자가 preview-v6 시안을 최종 승인했습니다. 앱은 `assets/images/login_flame_approved.webp`와 움직임 줄이기용 `assets/images/login_flame_still.png`를 사용합니다. 생성 이미지를 새로 그리지 않고 승인된 GIF의 비어 있는 맨 아래80px만 검사 후 제거해480×400으로 포장했습니다. 300프레임·20ms·6초·50fps 무한 반복은 유지합니다.

재현은 `node tool/export_approved_login_flame.cjs`. 앱에는 Flutter 기본 Animated WebP 디코더를 사용하며 신규 패키지가 없습니다. 앱용 무손실 파일3,554,414 bytes로 승인 GIF6,029,317 bytes보다 작습니다. 모든300프레임의 RGB가 승인 GIF의 해당 영역과 완전히 일치하며 빈 배경 제거 영역의 RGB 차이는0입니다. 초기 손실 압축본은 후광에 사각 잔상이 생겨 폐기했습니다. 얼굴/미소/후광/그림자는 자르지 않았습니다.

표시 폭은 화면 높이와 폭을 함께 고려해 약194~360 논리px로 확장했습니다. 기존156px/72px 표시보다 크게 보이도록 하되 제목/개인정보처리방침/두 로그인 버튼은 유지합니다. 작은 세로 화면5종에서 스크롤 없이 버튼이 보이고, 큰 글자에서는 접근성용 스크롤을 허용합니다.

이전 앱 GIF/정지 PNG는 `app-before-v6/`에 백업했습니다. 사용하지 않는 이전 GIF는 앱 번들에서 제거했으나 백업으로 복구할 수 있습니다. 과거 `tool/build_login_flame.cjs`는 v2 기록 재현용으로 출력 위치를 app-before-v6로 바꿔 현재 앱 이미지를 덮어쓰지 않게 했습니다. 아래 문단은 과거 버전 기록입니다.

## 이전 v2: 귀여운 불씨

사용자 피드백에 따라 사실적인 불길/강한 빛을 없앴습니다. 기존 `charactor_login.png`와 앱에 이미 있는 밝은 불씨 `charactor_first.png`를 함께 참조해 내장 image_gen으로 2D 둥근 불씨 키프레임을 새로 만들었습니다. 몸의 물방울 형태와 작은 두 눈을 유지하고 부드러운 밝아짐·통통한 움직임으로 표현합니다.

- 제작 원본: `source-spritesheet-cute-v2.png`.
- 앱에서 사용하는 파일: 기존 이름 그대로 `assets/images/login_flame_ignite.gif`, `assets/images/login_flame_still.png`. 256×256, 66프레임, 4.68초 반복. GIF 852,921 bytes / 정지 PNG 32,248 bytes.
- `tool/build_login_flame.cjs`의 입력 경로만 v2로 바꿨습니다. 로그인 Dart 코드나 접근성/레이아웃/기능은 바꾸지 않았습니다.
- v1 GIF·PNG는 `realistic-v1/`에 보관합니다. v1 생성 PNG `source-spritesheet.png`와 참조 원본 PNG 두 개도 보존했습니다. 아래 v1 설명·프롬프트는 과거 제작 기록입니다.

### v2 실제 생성 프롬프트

내장 image_gen / transparent_background=true / Image 1: charactor_login.png, Image 2: charactor_first.png.

Use case: identity-preserve. These two provided PNGs are the app's ORIGINAL finished mascot drawings, not loose inspiration. Image 1 is the dim ember state, Image 2 is the exact desired cute bright character style. Preserve this mascot identity closely. Make a transparent 4-column by 3-row sprite sheet of 12 evenly spaced square animation keyframes in reading order. Each cell contains ONLY this same small chubby teardrop ember character, front view, rounded pear-like body, ONE smooth rounded pointed tip, exactly two tiny dark dot eyes with the same size and spacing as the originals, NO mouth, NO limbs, NO added face details. Friendly simple 2D Korean app sticker illustration, soft peach-orange gradient, matte clean surface, warm and cute, NOT rendered physical fire. Frame 1 is a muted but visible orange ember resembling image 1; frames 2-4 gradually become the brighter peach/orange character from image 2; frames 5-12 have tiny playful squash/stretch and a little soft tip wobble, like breathing/bouncing with joy. Keep eye centers and rounded body base registered consistently in all cells. The bright state must still be the same plain orange teardrop, not a yellow flame inside the body. Generous fully transparent empty margin at least 18% on each side of every cell, all tips safely inside cells, no overlap between cells. Avoid entirely: realistic flames, tongues of fire, burning texture, yellow inner fire, fiery outlines, hot glow, neon, sparks, glass, glossy 3D, clay, smoke, photorealism, sharp spikes, large eyes, new facial features, different character design. No text, no numbers, no gridlines, no backgrounds or checkerboards. The design should look directly compatible with the two original tiny PNG mascot drawings, with cuteness from the existing rounded shape and subtle gentle movement rather than extra decoration.

## 이전 v1 제작 기록 — 현재 앱에서 사용하지 않음

원본 `assets/images/charactor_login.png`의 둥근 주황색 몸과 검은 두 눈을 참조해 내장 image_gen으로 움직임용 PNG 키프레임을 생성했습니다. 원본 그림을 덮어쓰지 않았습니다. CLI/API 키 또는 유료 동영상 서비스는 사용하지 않았습니다.

- `source-spritesheet.png`: 생성한 투명 PNG, 4열×3행, 12개 키프레임. 앱에는 이 제작 원본을 번들하지 않습니다.
- `../../assets/images/login_flame_ignite.gif`: 최종 반복 애니메이션. 약한 불씨 → 밝아짐 → 활활 흔들림 → 부드럽게 약한 불씨로 돌아와 반복. 무음/오프라인 재생.
- `../../assets/images/login_flame_still.png`: 움직임 줄이기 설정용 밝은 정지 그림.
- `../../tool/build_login_flame.cjs`: 이미 생성된 키프레임을 GIF로 포장하는 재현용 Node/sharp 스크립트. 행마다 조금 다른 눈 위치를 정렬하고 앱 배경 #101114에 합성한 뒤 키프레임을 교차 전환합니다. 캐릭터를 새로 그리지 않습니다. GIF는 부드러운 반투명을 지원하지 않으므로 배경색 변경 시 스크립트의 background도 맞춰 재생성해야 합니다.

256×256, 66프레임, 4.68초, 무한 반복. Flutter 기본 Image.asset 디코더를 사용하며 신규 앱 패키지는 추가하지 않았습니다. 로그인 화면에서만 사용하고 Android/iOS 시작 로고·다른 성장 단계 캐릭터·운동/TTS/DB는 바꾸지 않습니다.

## 사용한 생성 프롬프트

내장 image_gen, transparent_background=true. 첫 입력은 기존 charactor_login.png, 두 번째 입력은 첫 생성 결과입니다. 다음은 최종 프롬프트 세트입니다.

### 1. 키프레임 제작

Use case: identity-preserve. Asset type: production animation sprite sheet for an existing Korean fitness app mascot, not a UI mockup. Input image 1 is the EDIT TARGET and exact character identity anchor. Create ONE transparent PNG sprite sheet, exactly 4 columns by 3 rows of equal square cells, 12 animation keyframes in reading order left-to-right then top-to-bottom. Prefer total canvas 1024 by 768 (each cell 256 by 256). No borders, grid, labels, numbers, letters or watermark. Every cell has the SAME front-facing adorable rounded teardrop/flame body from the input, with precisely the same two tiny black round eyes and their spacing, no mouth, no arms, no legs, no props; preserve its soft matte painted orange gradient style. Lock registration: horizontal center, eye locations and bottom of the rounded body identical in every cell; no camera zoom, no character drifting. All content including soft amber glow stays inside its own cell with at least 12% transparent outer padding, no pixels touching adjacent frames. Animation: cell 1 is a dim but clearly visible warm ember (never invisible/black), cells 2-4 progressively ignite and brighten into a lively warm orange-gold flame. Cells 5-12 are a continuous subtle vigorous flame flicker cycle: upward flame licks alternately lean slightly left, center, right, rising softly with bright yellow-orange light in the body and warm amber glow, retaining the mascot face and rounded body. Highest bright flame remains comfortably inside cell. Distinguish the animation keyframes by the flame tip silhouette and light, NOT by changing the eyes/face or identity. Elegant friendly app illustration, energetic but not an explosion, no photorealistic fire, no scary expression, no huge sparks, no white-hot flash. True alpha transparency across the background; do not paint a checkerboard or dark rectangular backplate.

### 2. 여백/정렬 보정

Use case: precise-object-edit. Edit this 12-frame mascot animation sprite sheet. Preserve the SAME original orange teardrop mascot, same two black round eyes, same painted gradient, same ignition-to-bright-fire frame sequence and 4-column by 3-row layout. Change ONLY the spacing/registration for clean animation: make the character PLUS ALL glow significantly smaller within every cell so every cell has a truly empty transparent margin of AT LEAST 18 percent on all four sides. No flame tip or glow may touch any cell edge, no overlap between adjacent cells. Maintain exactly equal square cells in a 4 by 3 regular grid. Each frame must share identical bottom baseline and eye positions; do not drift the body vertically or horizontally. Glow should be subtle and smoothly fading, NOT noisy red spray or grain between frames. The first four frames gradually brighten; frames 5-12 gently change flame tip shape in a continuous flicker cycle, same character face. Render no numbers, labels, checkerboards, borders, backgrounds or text. Actual transparent alpha background. Clean production sprite sheet with obvious empty spacing around each frame, not a tightly packed contact sheet.

## 재생성

Node와 sharp가 있는 제작 환경에서 `node tool/build_login_flame.cjs` 실행. 이 프로젝트의 앱 런타임에는 Node/sharp가 필요 없습니다. 마지막 생성 PNG는 source-spritesheet.png로 보관했습니다. 프레임 사이 얼굴 위치 편차는 생성 결과에 남아 있어 스크립트가 눈 중심을 기준으로 기계적으로 정렬합니다.
