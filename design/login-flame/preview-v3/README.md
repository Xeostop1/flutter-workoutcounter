# 확인용 불씨 애니메이션 v3 — 앱 미적용

사용자 요청에 따라 이 버전은 영상/GIF 확인용입니다. 앱 assets, Dart/네이티브 코드, APK 또는 에뮬레이터 설치에는 적용하지 않습니다. 이전 v2 빌드는 사용자 요청 전 시작되어 이미 완료됐으며 새 v3 시안과는 별개입니다. 이후 앱 빌드/설치는 시작하지 않았습니다.

## 결과물

- `flame-preview-v3.gif`: 320×320, 300프레임, 각 20ms, 총6초, 무한 반복, 3,939,927 bytes. 확인용 품질로 제작했으며 앱용 용량 최적화는 승인 이후 별도입니다.
- `preview-dim.png`, `preview-smile.png`: 시작과 밝은 미소의 정지 확인 이미지.
- `source-two-states.png`: 내장 image_gen으로 생성한 원본. 기존 귀여운 불씨/원본 캐릭터를 참조해 눈 흰 반사광과 작은 웃는 입을 추가했습니다.
- `render-preview.cjs`: 같은 두 상태만 사용해 부드러운 밝기/미소 변화와 작은 숨쉬는 움직임을 생성합니다. 연속적인 배율/이동을 서브픽셀 보간하고, 표정 전환에는 완만한 가속/감속을 사용합니다. 캐릭터 표정 자체는 직접 그리지 않고 생성 원본을 사용합니다.

재현: Node와 sharp가 있는 환경에서 `node design/login-flame/preview-v3/render-preview.cjs`. 신규 앱 패키지는 필요 없습니다. image_gen CLI/API 키 경로가 아닌 내장 도구를 사용했습니다.

## 검사

- 출력 GIF의 실제 메타데이터: 300프레임 모두20ms, 총6,000ms, loop=0(무한). 최초 내보내기의 단일 delay 값은 첫 프레임에만 적용되는 것을 검출해, 모든 프레임의 delay를 명시한 뒤 재생 시간 검사를 통과했습니다.
- 밝은 상태의 흰 반사광: 좌24픽셀 / 우23픽셀 확인.
- 전체 화면 RGB 합 기준 최대 밝기/시작 밝기=1.257. 루프 처음/끝 원시 RGB 평균 차이0.0243(0–255 범위)로 급격한 점프를 피했습니다.
- 앱 GIF 해시는 작업 전후 `DB857400E95E6B9D3DFF6AEF120B51577A73D62DE28CA7184E3EEB112F1E6772`, 앱 정지 PNG는 `FB7233FC9F83D6CE00E14A50DC7332FE24100815F79A694B8A6C5C1781FC859B`로 그대로입니다.
- 파일의 프레임/타이밍과 정지 표정은 검사했으며 실제 휴대폰에서의 재생 속도는 확인하지 않았습니다. GIF 뷰어/기기의 성능에 따라 실제 표시 속도는 달라질 수 있습니다.

## 실제 생성 프롬프트

내장 image_gen / transparent_background=true. Image 1은 기존 assets/images/login_flame_still.png, Image 2는 원래 assets/images/charactor_first.png입니다.

Use case: identity-preserve, precise facial-expression edit. Image 1 is the exact current cute ember mascot EDIT TARGET; image 2 is its original app family style reference. Create ONE transparent PNG with TWO equal square panels SIDE BY SIDE, two matched expression/light states for smoothly animating the SAME character. Preserve Image 1's round chubby orange teardrop body, single rounded point, front view, simple soft 2D gradient, original tiny eye size/spacing. CRITICAL: body silhouette, size, position, eye positions, camera and base MUST be pixel-aligned and identical between both panels; only face expression and warmth/brightness differ. The mascot occupies about 65 percent of each square with generous truly transparent margins. LEFT PANEL: a clearly visible muted warm orange ember, two dark round eyes each containing a small crisp WHITE catchlight dot in the upper-left, no mouth yet or a tiny neutral closed mouth. RIGHT PANEL: the EXACT same body now warmly brighter glowing peach-orange/golden (not white), dark round eyes with the SAME visible white catchlights, and a small clearly recognizable happy U-shaped smiling mouth below/between the eyes. Make the eye catchlights easy to notice at app-icon size, about one-fifth of each dark eye, but do not enlarge the eyes. Cute gentle happy expression, no teeth, no tongue, no huge open mouth. No eyebrows/eyelashes/extra cheeks/arms/legs or other new features. Keep round eyes OPEN so both white catchlights remain visible in the happy state. Minimal matte 2D app mascot style directly matching the originals. No realistic fire, no inner flame texture, no fiery outline, no neon, no sparks, no smoke, no 3D/glass/clay render. No labels, text, panel borders, gridlines, checkerboard or background. Genuine alpha transparency. Both character silhouettes must match exactly for smooth expression blending; do not make alternate character designs or alternate poses.
