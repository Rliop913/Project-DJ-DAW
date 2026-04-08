# UI Asset Source Policy

## Purpose

이 문서는 `Project DJ DAW`가 외부 UI asset을 어떤 출처와 규칙으로 가져다 쓰는지 고정한다.

현재 닫는 범위는 아래와 같다.

- 아이콘 asset의 승인된 출처
- 폰트 asset의 승인된 출처
- 라이선스 기준
- 어떤 icon family / style을 canonical로 쓸지
- 어떤 font family를 canonical로 쓸지
- asset을 가져오는 방식
- theme 문서와의 연결 규칙

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Settings](Settings.md)

이 문서는 visual theme 문서가 고정한 icon style과 font choice를 실제 asset source와 연결하는 정책 문서다.

## Approved Icon Source

현재 프로젝트에서 승인된 기본 icon source는 아래로 고정한다.

- `Google Fonts Material Symbols Library`
- URL: `https://fonts.google.com/icons`

공식 가이드 기준으로 Material Symbols는 2,500개 이상 icon을 제공하며, Google Fonts 또는 self-hosting 방식으로 사용할 수 있다.  
출처:

- https://fonts.google.com/icons
- https://developers.google.com/fonts/docs/material_symbols

## License Rule

Material Symbols는 공식 가이드 기준 `Apache License Version 2.0`으로 제공된다.

따라서 이 프로젝트는 해당 라이선스 조건을 지키는 범위에서 icon asset을 사용할 수 있다.  
출처: https://developers.google.com/fonts/docs/material_symbols

## Approved Font Source

현재 프로젝트에서 승인된 기본 UI font source는 아래로 고정한다.

- `JetBrains Mono`
- URL: `https://www.jetbrains.com/lp/mono/`

공식 사이트 기준으로 JetBrains Mono는 free & open source typeface다.  
출처: https://www.jetbrains.com/lp/mono/

## Font License Rule

JetBrains Mono 저장소의 `OFL.txt` 기준으로, 이 폰트는 `SIL Open Font License, Version 1.1`로 배포된다.  
출처:

- https://www.jetbrains.com/lp/mono/
- https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt

따라서 이 프로젝트는 해당 라이선스 조건을 지키는 범위에서 JetBrains Mono를 기본 폰트 asset으로 사용할 수 있다.

## Approved Fallback Font Source

현재 프로젝트에서 승인된 fallback font source는 아래로 고정한다.

- `Google Fonts Noto Collection`
- URL: `https://fonts.google.com/noto`
- Korean fallback target: `https://fonts.google.com/noto/specimen/Noto+Sans+KR`

Google Fonts FAQ 기준으로 Google Fonts의 폰트는 open source이며 무료이고 상업적 사용도 가능하다.  
또한 Noto는 여러 언어와 writing system을 폭넓게 지원하는 collection으로 안내된다.  
출처:

- https://fonts.google.com/noto
- https://developers.google.com/fonts/faq#can_i_use_any_font_in_a_commercial_product

## Fallback Font License Rule

Noto 계열의 개별 라이선스는 font별로 다를 수 있으므로, 실제 import 시 해당 specimen/download 기준 license를 함께 기록한다.  
다만 Google Fonts FAQ 기준으로 Google Fonts의 폰트는 open source이며, 사용 및 재배포는 각 라이선스 조건을 따른다.  
출처: https://developers.google.com/fonts/faq#can_i_use_any_font_in_a_commercial_product

## Chosen Font Family

이 프로젝트의 canonical base UI font는 아래처럼 고정한다.

- `JetBrains Mono`

다만 glyph coverage를 고려해 실제 UI stack은 아래처럼 둔다.

- `JetBrains Mono`
- `Noto Sans KR`
- system sans fallback

공식 페이지의 glyph/script 소개 기준으로 JetBrains Mono는 code-oriented Latin/Greek/Cyrillic 중심 성격이 강하다.  
Hangul fallback chain은 이 문서의 구현 해석이다.

## Chosen Icon Family

이 프로젝트의 canonical icon family는 아래처럼 고정한다.

- `Material Symbols Outlined`

이 선택의 이유는 아래와 같다.

- 이미 theme 문서가 geometric outline iconography를 채택했다
- waveform-first 화면에서 filled icon보다 outlined icon이 덜 공격적이다
- broadcast technical / low-glare dark UI와 더 잘 맞는다

즉, `Rounded`나 `Sharp`를 기본값으로 쓰지 않고, `Outlined`를 기본 family로 본다.

## Preferred Acquisition Method

현재 프로젝트의 권장 방식은 아래 순서다.

1. 개별 SVG asset 다운로드 후 프로젝트 내부에서 사용
2. icon 수가 많아질 때만 self-hosted icon font 고려
3. production canonical asset source로서 직접 Google Fonts CDN 의존은 기본값으로 두지 않음

이 프로젝트는 Godot GUI authoring tool이므로, 초기 기준에서는 `개별 SVG asset import`가 가장 단순하고 안전하다.

## Allowed Formats

승인된 사용 형식은 아래와 같다.

- `SVG`
- `PNG`  
  단, 가능하면 SVG 우선

공식 가이드는 개별 icon을 SVG 또는 PNG로 받을 수 있다고 설명한다.  
출처: https://developers.google.com/fonts/docs/material_symbols

## Web Font / Self-Hosting Note

공식 가이드는 Material Symbols를 Google Fonts font 또는 self-hosted font로도 쓸 수 있다고 설명한다.

이 프로젝트에서의 해석은 아래와 같다.

- 웹 프로토타이핑이나 초기 빠른 실험에는 font 방식 허용
- 실제 Godot UI asset 기준선은 `SVG 우선`
- font 방식이 필요해질 경우에도 가능하면 self-hosting을 우선 검토

출처: https://developers.google.com/fonts/docs/material_symbols

## Theme Compatibility Rule

이 프로젝트에서 Material Symbols를 쓸 때는 아래 visual rule을 따른다.

- 기본 family는 `Outlined`
- 기본 상태는 `FILL = 0`
- active / selected / pinned / critical 상태에서만 filled 또는 더 강한 강조를 허용한다
- dark background glare를 줄이기 위해 grade를 낮게 쓰는 방향을 우선 고려한다

공식 가이드는 dark background에서 glare를 줄이기 위해 낮은 grade 값을 쓰는 사례를 제시한다.  
출처: https://developers.google.com/fonts/docs/material_symbols

## Font Compatibility Rule

이 프로젝트에서 JetBrains Mono를 쓸 때는 아래 visual rule을 따른다.

- base UI font는 `JetBrains Mono`
- numeric / tuple / readout은 항상 `JetBrains Mono` 우선
- glyph가 없는 문자 집합은 `Noto Sans KR`가 우선 이어받는다
- long-form explanatory paragraph는 크기와 spacing을 보수적으로 잡아 monospace 과밀감을 줄인다

## Icon Use Rule

- `ReturnAction`, `SaveIcon`, `RootPinAction` 같은 primary action은 icon-only가 아니라 text와 함께 쓴다
- status cluster의 alert/warning/error/validation은 icon + badge 방식으로 쓴다
- waveform 위 tag에 들어가는 icon은 작은 보조표시로만 쓰고 waveform readability를 해치면 안 된다

세부 style은 [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md)를 따른다.

## Asset Management Rule

- icon asset 이름은 Material Symbols 원본 snake_case 명칭을 최대한 유지한다
- local asset import 시 source URL 또는 원본 이름을 기록해 추적 가능하게 둔다
- 같은 의미의 icon을 여러 family로 섞지 않는다
- custom icon을 추가해도 canonical action icon은 Material Symbols 계열과 시각적으로 충돌하면 안 된다
- font asset도 source URL과 license를 함께 기록한다
- fallback font import 시에는 target language/script를 함께 기록한다

## Recommended Initial Icon Set

초기 authoring shell에서 우선 써도 되는 icon 예시는 아래와 같다.

- `arrow_back`
- `save`
- `push_pin`
- `play_arrow`
- `stop`
- `warning`
- `error`
- `check_circle`
- `settings`
- `library_music`
- `tune`

이 목록은 초기 shell/action/status용 추천 세트일 뿐이며, source of truth는 Material Symbols Library 전체다.

## Summary

이 프로젝트의 기본 icon asset source는 `Google Fonts Material Symbols Library`이고, 기본 UI font source는 `JetBrains Mono`, 기본 fallback font source는 `Google Fonts Noto Collection`이다.  
아이콘은 `Apache License 2.0`, JetBrains Mono는 `SIL Open Font License 1.1` 기준으로 사용한다. Noto fallback은 Google Fonts FAQ와 각 font license를 따른다.  
canonical icon family는 `Material Symbols Outlined`, canonical base UI font는 `JetBrains Mono`, 기본 fallback은 `Noto Sans KR`, 기본 icon 가져오기 방식은 `SVG import`다.  
실제 style 사용 규칙은 [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md)를 따른다.
