# Preview Playback Design

## Purpose

이 문서는 `Project DJ DAW`의 preview playback을 `audio handle`, `PCM extraction`, `master output lane visualization`, `playback cursor`, `camera follow` 관점에서 고정한다.

특히 아래를 닫는다.

- preview init path와 `demoPlayInit` 사용 규칙
- preview audio handle과 linked data line의 관계
- PCM frame 추출과 waveform 시각화 규칙
- master output lane의 preview 표시 규칙
- playback cursor 위치와 scope
- playback 중 camera follow 규칙
- preview 중 허용 편집 범위
- fallback behavior

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Automation Lane Model](Automation%20Lane%20Model.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)

이 문서는 preview 관련 상세 규칙의 authoritative local document다.  
timeline semantics는 [Mixset Timeline Model](Mixset%20Timeline%20Model.md)가 유지하되, preview 실행 상태와 master lane 표시 규칙은 이 문서를 우선한다.

## Scope

- preview transport state
- `demoPlayInit` 기반 preview handle 생성
- data line에서 PCM frame 추출
- PCM to waveform 기반 master lane 표시
- playback cursor와 global timeline sync
- playback camera follow
- preview edit restriction
- preview fallback rule

## Out Of Scope

- root DB push / persistence write-back
- render export의 최종 파일 포맷
- preview PCM에 대한 RGB 분석 구현
- waveform renderer의 low-level shader / texture optimization
- audio DSP 내부 알고리즘

## Core Principles

- preview는 persistence가 아니라 authoring 결과의 audition 단계다
- preview의 실행 source of truth는 `demoPlayInit`가 반환하는 audio handle이다
- preview의 live 시각 source of truth는 handle과 연결된 data line에서 읽은 PCM frame이다
- master output lane은 authoring command lane이 아니라 preview/render output을 보여주는 display-only lane이다
- 현재 닫힌 범위에서 master output lane의 preview 시각화는 `waveform only`다
- master output lane의 preview waveform은 transient preview data로 보고 cache read/write를 하지 않는다
- preview playback cursor는 master output lane에만 존재한다
- playback 중 camera는 playback cursor를 따라가되 순간이동하지 않고 선형 보간으로 이동한다

## Preview Init Path

preview는 현재 working authoring state를 기준으로 시작한다.

1. 시스템은 현재 workspace state를 preview-ready form으로 정리한다
2. 이 state를 바탕으로 `demoPlayInit(...)`를 호출한다
3. 시스템은 실제 재생 가능한 audio handle을 반환받는다
4. handle과 연결된 data line으로부터 PCM frame을 추출한다
5. 추출한 PCM frame을 `PCM -> Waveform` 함수로 변환한다
6. 변환 결과를 master output lane의 preview waveform으로 표시한다

이 경로는 `pushToRootDB(...)`와 분리된다.  
즉, preview는 저장이 아니라 현재 편집 결과의 즉시 검증 경로다.

## Preview Transport Lifecycle

현재 닫힌 범위에서 preview transport는 아래 상태를 가진다.

- `Idle`
- `Preparing`
- `Playing`
- `Stopped`
- `Error`

규칙은 아래와 같다.

- `Idle -> Preparing`: 사용자가 preview 재생을 요청하면 진입한다
- `Preparing -> Playing`: `demoPlayInit` 성공, audio handle 확보, PCM tap 연결 성공 시 진입한다
- `Preparing -> Error`: handle 생성 실패 또는 preview init 실패 시 진입한다
- `Playing -> Stopped`: 사용자가 stop하거나 preview가 끝까지 재생되면 진입한다
- `Error -> Idle`: 사용자가 상태를 정리하고 다시 preview를 시도할 수 있다

현재 고정 범위에서는 preview transport UI를 `play / stop / restart` 중심으로 본다.  
transport 자체의 true pause/resume는 후속 확장으로 둔다.  
`CONTROL(PAUSE)`는 preview transport UI가 아니라 mix semantic command다.

## Master Output Lane Rule

master output lane은 preview에서 아래 역할을 가진다.

- 현재 preview output의 waveform을 표시한다
- workspace 전체에서 유일한 playback cursor를 가진다
- 재생 중 현재 global output position의 시각 기준선이 된다
- authoring command 자체는 저장하지 않는다

track lane은 authored structure를 보여주고, master output lane은 preview output을 보여준다.  
즉, preview 중에도 track lane은 command/tag 중심의 정적 authoring surface이고, master output lane만 live output surface다.

## Preview Waveform Source Rule

preview 중 master output lane에 그리는 waveform은 precomputed asset waveform이 아니라 실제 preview output PCM에서 온다.

- source: `demoPlayInit` audio handle의 linked data line
- intermediate: extracted PCM frame window
- visualization: `PCM -> Waveform`

이 규칙의 의미는 아래와 같다.

- `CUE`, `SCRATCH`, `SPIN`, `REV`, `ECHO`, `PITCH` 같은 명령을 master lane에서 별도 재시뮬레이션할 필요가 없다
- preview audio path가 실제로 출력한 결과를 그대로 waveform으로 본다
- track lane의 `EffectiveWaveformProjection`은 authored-model visualization으로 남고, master lane waveform은 live preview result visualization으로 남는다

## Current Visualization Fix

현재 닫힌 범위에서 preview master lane 시각화는 `waveform only`로 고정한다.

- RGB 분석은 지금 당장 preview path에 넣지 않는다
- 이후 `Project DJ Godot API`를 개선해 `demoPlayInit` PCM으로부터 RGB 분석이 가능해지면 확장할 수 있다
- 그 전까지 preview master lane은 waveform 표시만 정식 지원한다

즉, preview lane의 현행 canonical visualization은 `PCM-derived waveform`이다.

## Preview Master Waveform Cache Rule

master output lane의 preview waveform은 캐시하지 않는다.

- 이 데이터는 현재 편집 상태를 기준으로 `demoPlayInit`가 만든 실제 preview output에서 나온다
- 편집 중 mix content가 계속 바뀌므로 cache hit의 의미가 없다
- 따라서 master preview waveform은 session-local transient visualization으로만 다룬다
- registered asset waveform / RGB waveform cache와 master preview waveform cache는 같은 계층으로 취급하지 않는다

## Playback Cursor Rule

preview playback cursor는 master output lane에만 둔다.

- track lane에는 별도 moving playback cursor를 두지 않는다
- track lane은 필요하면 현재 재생 시점과 겹치는 `TrackBlock` / `MusicBlock` / segment를 highlight할 수 있다
- user가 실제로 따라가야 하는 기준 cursor는 항상 master output lane의 playback cursor 하나다

즉, preview 모드에서 temporal source of truth는 `master cursor 1개`다.

## Timeline Sync Rule

preview 중 sync 규칙은 아래와 같다.

- preview audio handle의 현재 재생 위치가 master playback cursor의 global x 위치를 결정한다
- master playback cursor의 global x 위치가 block highlight 기준이 된다
- master output lane waveform도 같은 preview PCM source를 기준으로 갱신된다

즉, 아래 세 가지는 같은 preview session을 공유한다.

- audible output
- master playback cursor
- master output waveform

## Camera Follow Rule

playback 모드에서는 화면 camera가 master playback cursor를 따라간다.

- camera target x는 현재 master playback cursor의 x 위치다
- camera는 그 target으로 순간이동하지 않는다
- camera 이동은 animation이 들어간 선형 보간 방식으로 처리한다
- 따라서 재생 중 화면은 cursor를 부드럽게 따라간다

이 문서에서 camera follow는 `instant snap`이 아니라 `animated linear interpolation follow`로 고정한다.

## Edit Rule During Preview

preview session은 compiled playback snapshot에 묶여 있으므로, active playback 중 authoring state를 직접 바꾸지 않는다.

- preview 중 structural edit는 비활성화한다
- preview 중 automation 생성/수정/삭제는 비활성화한다
- preview 중 `LOAD`/`UNLOAD`/battle tag 변경도 비활성화한다
- hover, selection, read-only inspection은 허용한다
- 새 편집을 적용하려면 preview를 stop한 뒤 다시 preview를 시작한다

즉, preview는 live patching이 아니라 `stop -> edit -> restart` 규칙으로 본다.

## Fallback Rule

- `demoPlayInit` 실패 시 preview는 `Error` 상태로 들어간다
- audio handle은 살아 있지만 PCM tap이 실패하면, audio preview는 계속할 수 있으나 master lane은 cursor-only fallback으로 둔다
- preview PCM에 대한 RGB 분석이 없더라도 waveform-only mode가 canonical fallback이 아니라 현재 기본 동작이다

## Summary

preview playback design은 현재 기준으로 아래처럼 닫힌다.

- preview는 `demoPlayInit`가 반환하는 audio handle을 기준으로 실행된다
- handle과 연결된 data line에서 PCM frame을 추출한다
- 추출한 PCM은 `PCM -> Waveform` 경로로 master output lane에 표시한다
- preview master lane은 현재 `waveform only`로 고정한다
- preview master lane waveform은 cache하지 않는다
- playback cursor는 master output lane에만 존재한다
- playback 중 camera는 cursor를 선형 보간 애니메이션으로 따라간다
- preview 중 authoring edit는 잠그고, stop 이후 다시 preview snapshot을 만든다
