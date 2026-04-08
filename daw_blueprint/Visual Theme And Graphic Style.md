# Visual Theme And Graphic Style

## Purpose

이 문서는 `Project DJ DAW`의 그래픽 인터페이스와 테마 방향을 고정한다.

이 문서의 목적은 단순히 "어두운 UI"를 선언하는 것이 아니라, 아래를 명확히 닫는 것이다.

- 전체 시각 방향
- 색 체계와 강조색 소유권
- typography와 숫자 표시 방식
- bezel / panel / dialog surface 규칙
- waveform 우선 시각화 규칙
- tag / badge / icon 스타일
- motion과 density 규칙
- 장시간 authoring에 맞는 low-glare visual discipline

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [UI Asset Source Policy](UI%20Asset%20Source%20Policy.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Preview Playback Design](Preview%20Playback%20Design.md)
- [Godot UI Structure](Godot%20UI%20Structure.md)
- [Settings](Settings.md)

이 문서는 visual language의 authoritative local document다.  
구조와 semantics는 다른 문서가 유지하고, 이 문서는 그것들을 어떤 graphic style로 보여줄지 고정한다.

## Scope

- theme direction
- color system
- typography system
- panel / bezel surface language
- waveform-first composition rule
- icon / badge / tag style
- motion rule
- spacing / density rule

## Out Of Scope

- component tree 자체
- timeline semantic rule
- automation payload rule
- waveform generation algorithm
- audio DSP implementation

## Core Visual Principles

- UI의 최우선 시각 정보는 waveform과 playback state다
- shell UI는 정보를 덮지 않고 뒤로 물러나야 한다
- 장시간 authoring을 버티는 low-glare dark-first 환경을 기본으로 한다
- signal color는 적게 쓰고, 의미를 독점시켜야 한다
- 공연용 네온 과장보다 편집용 명확성이 우선이다
- generic DAW 회색 톤으로 흐르지 않도록 기술적이지만 개성 있는 시각 언어를 유지한다

## Chosen Theme Direction

이 프로젝트의 canonical visual direction은 아래처럼 고정한다.

- `dark-first broadcast technical theme`
- `restrained industrial audio-console influence`
- `waveform-first composition`
- `minimal signal-color accents`

즉, 이 제품은 club booth의 과장된 네온 공연 UI가 아니라, 방송용/기술용 모니터링 장비에 가까운 편집 환경을 기본으로 삼는다.

## What We Explicitly Avoid

- 과도한 neon club UI
- glossy glassmorphism
- 과한 3D mixer 질감
- bright editorial white theme
- 의미 없는 그라디언트 남용
- waveform보다 강하게 보이는 배경 패턴

## Theme Mode Rule

v1에서는 `dark-only`를 canonical mode로 고정한다.

- light theme를 기본 제공 대상으로 두지 않는다
- 모든 색, border, overlay, tag contrast는 dark base를 기준으로 설계한다

## Color System

### Base Palette

- `CanvasBase`: `#0F141A`
- `CanvasAlt`: `#131A21`
- `PanelBase`: `#171F28`
- `PanelElevated`: `#1D2631`
- `BezelBase`: `#0C1117`
- `BorderSubtle`: `#2C3742`
- `TextPrimary`: `#E8EEF5`
- `TextSecondary`: `#A5B1BD`
- `TextMuted`: `#74808B`

### Signal Colors

- `InteractiveAccent`: `#55C7E8`
- `PlaybackAccent`: `#C6E26A`
- `WarningAccent`: `#F0B14A`
- `ErrorAccent`: `#E15A5A`
- `ValidationOkAccent`: `#61C88D`
- `RootPinAccent`: `#D58A3A`

### Color Ownership Rule

- selection / editable focus는 `InteractiveAccent`
- playback cursor / active preview follow는 `PlaybackAccent`
- warning은 `WarningAccent`
- error / blocking failure는 `ErrorAccent`
- validation ok는 `ValidationOkAccent`
- root pin / root DB fixed intent는 `RootPinAccent`

## Typography System

### Primary UI Typeface

기본 UI 서체는 `JetBrains Mono`를 기준으로 잡는다.

다만 `JetBrains Mono`는 code-oriented monospace font이므로, glyph가 없는 문자 집합에 대해서는 fallback chain을 함께 둔다.

권장 기본 stack:

- `JetBrains Mono`
- `Noto Sans KR`
- system sans fallback

### Numeric / Timeline Typeface

숫자, BPM, time tuple, frame index, compact readout은 `JetBrains Mono`를 그대로 쓴다.

### Typography Rule

- 큰 display typography는 지양한다
- headline보다 dense tool typography를 우선한다
- waveform 위 tag label은 짧고 condensed하게 유지한다
- monospace base를 쓰더라도 긴 body paragraph는 과도하게 넓어지지 않도록 compact sizing과 spacing으로 제어한다
- Hangul 또는 미지원 glyph는 fallback font가 자연스럽게 이어받아야 한다

## Surface Language

### Panel Rule

- panel은 solid semi-opaque surface를 사용한다
- blur는 최소화한다
- 경계는 1px subtle border로 분리한다
- shadow는 약하고 짧게 둔다

### Bezel Rule

- global top bezel과 local bezel은 timeline canvas보다 더 어둡고 안정적인 surface여야 한다
- bezel은 decorative chrome가 아니라 instrument shell처럼 보여야 한다
- bezel은 시각적으로 튀지 않고 상태와 액션만 또렷해야 한다

### Dialog Rule

- dialog는 panel elevated tone을 쓴다
- destructive / blocking dialog만 accent border를 허용한다

## Waveform Priority Rule

waveform은 이 제품의 최우선 시각 정보다.

- timeline의 주 시각 중심은 waveform이다
- overlay, tag bar, segment tint는 waveform을 완전히 가리면 안 된다
- waveform 위의 반투명 바는 desaturated tone과 낮은 opacity를 사용한다
- hover 확장 그래프는 waveform을 읽을 수 있는 상태를 최대한 유지한 채 펼쳐져야 한다

### Track Lane Rule

- track lane에서는 `EffectiveWaveformProjection`이 중심이다
- base UI는 waveform보다 채도가 낮아야 한다
- `PITCH` 같은 tag UI는 waveform 자체를 다시 그리는 대신 얇은 badge / bar로 드러낸다

### Master Lane Rule

- master output lane은 preview waveform을 가장 명확하게 보여줘야 한다
- playback cursor contrast는 master lane에서 가장 높아야 한다
- master lane 주변 배경은 track lane보다 더 단순하게 둔다

## Tag And Badge Style

### Automation Tag Rule

- 기본 형태는 얇은 반투명 horizontal bar
- label은 compact text + small icon 조합
- hover 전까지는 최소 정보만 보인다
- hover 시만 graph 확장 panel이 열린다

### Point Command Tag Rule

- `LOAD`, `UNLOAD`, `CUE`, `PAUSE`, battle modifier는 짧은 capsule badge로 표현한다
- waveform을 덮는 큰 카드형 태그는 쓰지 않는다

### Save / Status Badge Rule

- `SaveStateIndicator`는 icon + short text badge로 고정한다
- pure icon-only state 표시는 기본형으로 쓰지 않는다

## Iconography Rule

- icon은 geometric outline 기반으로 고정한다
- fill은 active / error / selected 상태에서만 제한적으로 쓴다
- primary action icon은 text label과 함께 쓴다

### Closed Decisions

- `ReturnAction`은 `icon + short text`
- `SaveIcon`은 `icon + short text`
- `RootPinAction`은 `icon + short text`
- `SaveStateIndicator`는 `icon + short text badge`
- canonical icon family는 `Material Symbols Outlined`
- canonical base UI font는 `JetBrains Mono`다

## Status Cluster Rule

right-zone status 영역은 하나의 `status cluster`로 묶는다.

- `Alert / Warning / Error / Validation`을 완전히 분리된 두 개의 큰 영역으로 나누지 않는다
- 하나의 cluster 안에서 순서, 색, border, spacing으로 구분한다
- validation은 안정적인 상태 badge
- warning / error는 더 강한 signal accent를 가진 icon/badge다

## Motion Rule

motion은 decorative가 아니라 functional이어야 한다.

- hover expansion: `120ms ~ 160ms`
- dialog open/close: `140ms ~ 180ms`
- alert emphasis: 짧은 opacity / scale pulse 1회
- camera follow는 linear interpolation 기반이다

### Motion Avoidance

- elastic bounce
- 과한 spring
- 장시간 반복되는 pulse
- bezel 전체가 흔들리는 transition

## Density And Spacing Rule

이 제품의 density는 `compact-professional`로 고정한다.

- 넓은 여백 기반 editorial UI로 가지 않는다
- badge, icon cluster, tuple readout은 compact하게 유지한다
- 기본 spacing scale은 `4 / 8 / 12 / 16 / 24` 계층을 권장한다

## Theme Integration Decisions

- v1은 dark-only
- waveform-first composition
- broadcast technical base + restrained industrial influence
- icon + short text action labels
- icon + short text save-state badge
- single right-side status cluster
- low-glare solid surfaces

## Future Settings Tokens

세부 수치는 이후 [Settings](Settings.md)에 아래 형태로 옮기는 것이 맞다.

- `__SETTING_VAL__UI_THEME_CANVAS_BASE`
- `__SETTING_VAL__UI_THEME_PANEL_BASE`
- `__SETTING_VAL__UI_THEME_BORDER_SUBTLE`
- `__SETTING_VAL__UI_THEME_TEXT_PRIMARY`
- `__SETTING_VAL__UI_THEME_ACCENT_INTERACTIVE`
- `__SETTING_VAL__UI_THEME_ACCENT_PLAYBACK`
- `__SETTING_VAL__UI_THEME_ACCENT_WARNING`
- `__SETTING_VAL__UI_THEME_ACCENT_ERROR`
- `__SETTING_VAL__UI_THEME_ACCENT_VALIDATION_OK`
- `__SETTING_VAL__UI_THEME_ACCENT_ROOT_PIN`

## Summary

이 프로젝트의 그래픽 인터페이스는 `dark-first broadcast technical theme`를 기준으로 한다.  
waveform이 최우선 정보이고, bezel과 panel은 low-glare solid surface로 뒤로 물러나야 하며, signal color는 적게 쓰되 의미를 독점해야 한다.  
primary action은 `icon + short text`, status는 하나의 right-side cluster, overall density는 `compact-professional`로 고정한다.
