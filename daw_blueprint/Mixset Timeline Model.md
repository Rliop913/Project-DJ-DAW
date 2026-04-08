# Mixset Timeline Model

## Purpose

이 문서는 `Project DJ DAW`의 믹스셋 타임라인이 어떤 데이터 구조로 구성되는지 정의한다.

이 문서의 목적은 아래를 고정하는 것이다.

- 믹스셋의 시간축 source of truth
- `Workspace -> TrackBlock -> MusicBlock -> BarBlock` 계층의 의미
- 사용자가 직접 편집하는 값과 내부 참조값의 구분
- `PDJE`의 `Editor Format`로 번역되는 semantic boundary

이 문서는 UI 스킨 문서가 아니라, **편집기와 저장/preview/render가 공통으로 참조하는 모델 문서**다.

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Settings](Settings.md)

이 문서는 `Music Asset Add & Config`에서 확정된 `firstBeat + local BPM map`을 받아, 실제 믹스 authoring용 타임라인 모델로 올리는 단계에 해당한다.

## Scope

이 문서가 다루는 범위는 아래와 같다.

- 믹스셋 타임라인의 상위 구조
- `TrackBlock`, `MusicBlock`, `BarBlock`의 의미
- global time axis와 local beat axis의 관계
- global BPM authoring rule
- local BPM metadata의 내부 참조 규칙
- block별 편집 책임 분리
- `PDJE` event row로의 번역 방향

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- Godot widget 배치
- waveform 시각 스타일
- 최종 파일 포맷 직렬화 상세
- asset import / config UI 절차
- EQ / FX parameter curve 세부 schema

## Core Model Principles

- 믹스 authoring surface는 `single global BPM authoring model`을 채택한다
- 사용자는 음악 자체의 BPM curve를 직접 다시 편집하지 않는다
- `music config`에서 확보한 local BPM metadata는 hidden timing reference다
- `TrackBlock`은 음악 asset당 정확히 하나의 lane을 가진다
- `MusicBlock`은 그 lane 위에서 실제 사용 구간과 재생 관련 영역을 표현한다
- `MusicBlock`의 표시 길이는 `LOAD`부터 `UNLOAD`까지의 global span을 기준으로 한다
- `PAUSE` 이후 source 공급이 끊긴 구간과 audio content 소진 이후의 구간은 empty block으로 표시할 수 있다
- 실제 오디오 공급을 바꾸는 mix command는 `MusicBlock`의 RGB waveform 표시에도 반영된다
- `BarBlock`은 사용자가 직접 배치하는 영속 primitive가 아니라, `firstBeat + local BPM map + global BPM map`으로부터 계산되는 derived access unit이다
- waveform은 주로 시각화와 접근 보조를 위한 것이며, semantic source of truth가 아니다

## Model Layer Split

이 문서는 두 층을 분리해서 본다.

### UI Authoring Layer

- `Workspace`
- `TrackBlock`
- `MusicBlock`
- `BarBlock`

이 층은 사용자가 실제로 보고 조작하는 block hierarchy다.

### PDJE Semantic Layer

- `musdata`
- `trackdata`
- `EDIT_ARG_MUSIC`
- `EDIT_ARG_MIX`

이 층은 최종적으로 `PDJE Editor Format`으로 내려가는 semantic layer다.

UI block은 이 semantic layer를 직접 저장하는 것이 아니라, **보다 편집하기 쉬운 authoring model**로 제공된다.

## Canonical Hierarchy

믹스셋 타임라인의 편집 단위 계층은 아래와 같다.

1. `Workspace`
2. `TrackBlock`
3. `MusicBlock`
4. `BarBlock`

이 순서대로 상위에서 하위로 하나씩 id를 가진다.

## ID Rule

이 문서는 아래 id 계층을 기본으로 둔다.

- `workspace_id`
- `track_block_id`
- `music_block_id`
- `bar_block_id`

규칙은 아래와 같다.

- 각 `TrackBlock`은 `workspace` 내부에서 stable id를 가진다
- 각 `MusicBlock`은 반드시 하나의 `TrackBlock`에 종속된다
- 각 `BarBlock`은 반드시 하나의 `MusicBlock`에 종속된다
- 하위 id는 상위 id를 문맥상 소유자 참조로 가져야 한다

## Workspace

`Workspace`는 하나의 믹스 authoring 세션 전체를 뜻한다.

최소한 아래를 소유한다.

- global timeline axis
- global parameter lane
- `TrackBlock` 집합
- master output lane
- global transport reference
- global selection / edit context

`Workspace`는 asset BPM 자체를 직접 저장하는 곳이 아니라, **asset-owned lane들이 놓이는 전체 시간축 컨테이너**다.

## Lane Family Model

현재 blueprint에서 workspace의 lane family는 아래 3가지로 고정한다.

### 1. Global Parameter Lane

- workspace 전체에 대해 사실상 1개만 둔다
- 전역 파라미터 중에서도 BPM 관련 command만 다룬다
- 현재 닫힌 범위에서 이 lane의 실질적 대상은 `BPM_CONTROL`뿐이다

### 2. Track Lane

- 음악 asset당 하나씩 존재하는 주 lane family다
- 현재 문서의 `TrackBlock`이 바로 이 track lane instance다
- 가장 많은 sub-lane 또는 내부 편집층을 가지는 family다
- `MusicBlock`, waveform, segment, beat access, asset별 authoring 정보가 이 family 아래에 모인다

### 3. Master Output Lane

- 최종 출력 체인에 대해 사실상 1개만 둔다
- authoring command를 직접 편집하는 lane이 아니다
- preview playback 또는 render 이후의 최종 결과를 표시하는 display-only lane family로 본다

즉, workspace는 `global parameter lane 1개 + track lane N개 + master output lane 1개` 구조를 기본으로 본다.

## TrackBlock

## Definition

`TrackBlock`은 음악 asset 하나당 정확히 하나 존재하는 asset-owned lane이다.

즉, 이 문서에서 `TrackBlock`은 일반적인 재사용 lane이 아니라 아래 의미를 가진다.

- lane 1개 = music asset 1개
- y축 = asset identity
- x축 = global timeline
- workspace의 `Track Lane` family에 속하는 lane instance

## Ownership Rule

- 하나의 `music asset`은 하나의 `TrackBlock`만 가진다
- 같은 asset을 여러 lane으로 복제하지 않는다
- asset의 시간축 사용 방식은 해당 `TrackBlock` 내부의 `MusicBlock`과 재생/정지 영역으로 표현한다

여기서 `same asset`은 source file path가 아니라 `asset identity` 기준이다.

- 하나의 `asset_id`는 정확히 하나의 asset identity만 뜻한다
- 같은 source audio를 다른 `asset_id`로 다시 등록하면, 그것은 이 문서에서 다른 asset이다
- 따라서 다른 `asset_id`는 별도의 `TrackBlock`과 별도의 edit state를 가진다
- waveform/RGB waveform cache가 hit되더라도, cache reuse는 시각/미리보기 데이터 재사용일 뿐 authoring state 공유를 뜻하지 않는다

## Responsibilities

`TrackBlock`은 아래 책임을 가진다.

- global time axis 위의 lane 제공
- 해당 asset의 `MusicBlock` 집합 소유
- workspace-global BPM lane이 반영된 beat access 결과 위에서 asset 구간을 표현
- lane-level visibility / mute / selection 같은 보조 상태 제공 가능

## Global BPM Lane Relation Rule

`TrackBlock`은 workspace-global BPM lane의 영향을 받지만, 자체 BPM lane을 소유하지 않는다.

핵심 규칙은 아래와 같다.

- user-facing tempo control은 workspace의 `global parameter lane`에서만 이뤄진다
- 사용자는 음악 자체의 local BPM map을 믹스 authoring 중 다시 수정하지 않는다
- 모든 `TrackBlock`은 같은 workspace-global BPM step lane을 공유한다

이 global BPM lane은 번역 시 `PDJE`의 `BPM_CONTROL` 계열 `MixArgs`로 내려간다.

## MusicBlock

## Definition

`MusicBlock`은 `TrackBlock` 내부에서 실제 음악 사용 구간과 재생 상태 영역을 표현하는 주 편집 객체다.

현재 draft는 아래 가정을 둔다.

- 하나의 `TrackBlock`은 하나 이상의 `MusicBlock`을 가질 수 있다
- 각 `MusicBlock`은 하나의 `LOAD -> UNLOAD` 사용 container다
- 같은 `asset_id`의 비연속 사용은 pause/resume이 아니라, 같은 `TrackBlock` 안의 복수 `MusicBlock`으로 표현한다

## Responsibilities

`MusicBlock`은 아래를 맡는다.

- decoded waveform 또는 waveform preview reference 보유
- effective RGB waveform projection 관리
- global timeline 위에서 시작 위치와 사용 길이 표현
- `LOAD` / `UNLOAD` 영역 authoring
- `PAUSE` 계열 재생 중단 영역 authoring
- audio-supply modifier command의 시각 반영
- silent filler segment 관리
- `BarBlock` 파생 계산의 부모 객체 역할

## MusicBlock Time Rule

`MusicBlock`은 `TrackBlock`의 global time axis를 그대로 사용한다.

즉, 사용자가 `MusicBlock`을 x축에서 이동시키는 것만으로 아래가 결정된다.

- 이 asset이 global timeline 기준 어느 시점에 사용되는가
- 그 시점부터 local beat grid가 어디에 투영되는가
- derived `BarBlock`이 global timeline 위에 어떻게 정렬되는가

## MusicBlock Span Rule

`MusicBlock`의 visible span은 `LOAD`부터 `UNLOAD`까지의 구간 전체를 뜻한다.

핵심 규칙은 아래와 같다.

- `MusicBlock.length = unload_position - load_position`
- 이 길이는 source audio의 실제 길이보다 길어도 된다
- source audio 길이가 먼저 끝나더라도 block 자체는 `UNLOAD`까지 유지된다
- 남는 구간은 empty block으로 채운다

즉, `MusicBlock`은 "실제 오디오 길이"가 아니라 **authoring된 load/unload container length**를 가진다.

## MusicBlock Playback Cursor Rule

`MusicBlock` 내부에는 global x축과 별개로 두 종류의 cursor를 둔다.

- `CanonicalSourceCursor`
- `EffectiveReadCursor`

규칙은 아래와 같다.

- `LOAD` 시 `CanonicalSourceCursor`는 asset 시작 지점에서 시작한다
- 일반 audible playback 중에는 `CanonicalSourceCursor`와 `EffectiveReadCursor`가 함께 전진한다
- `PAUSE`가 들어오면 새로운 source audio 공급은 그 지점에서 끊긴다
- 현재 draft에서는 `resume after pause`를 기본 시나리오로 두지 않는다
- 이후 같은 asset을 다시 audible playback에 쓰려면 새로운 `LOAD -> UNLOAD` container, 즉 새로운 `MusicBlock`이 필요하다
- battle-style modifier는 활성 구간 동안 `EffectiveReadCursor`만 임시로 바꿀 수 있다
- battle-style modifier가 끝나면 `EffectiveReadCursor`는 "그 modifier가 없었다면 도달했을" `CanonicalSourceCursor` 위치로 돌아간다

즉, `PAUSE`는 현재 모델에서 **source supply cut command**다.

## MusicBlock Segment Types

`MusicBlock`은 내부적으로 아래 segment 집합으로 해석된다.

- `AudibleSegment`
- `SupplyCutEmptySegment`
- `TailEmptySegment`
- `BufferedEffectSegment`
- `TransportModifiedSegment`
- `PitchModifiedSegment`

의미는 아래와 같다.

- `AudibleSegment`: 실제 오디오가 재생되며 waveform 내용이 진행되는 구간
- `SupplyCutEmptySegment`: `PAUSE`, `UNLOAD`, source exhaustion 등으로 새 source audio 공급이 없는 silent 구간
- `TailEmptySegment`: source audio content가 먼저 끝났지만 `UNLOAD` 전까지 block이 남아 있는 silent 구간
- `BufferedEffectSegment`: source 공급은 끊겼지만 echo 같은 이전 buffer 기반 효과 출력이 남아 있는 구간
- `TransportModifiedSegment`: `CUE`, `SCRATCH`, `SPIN`, `REV` 같은 명령으로 source cursor path나 공급 방식이 변형된 구간
- `PitchModifiedSegment`: source cursor 진행은 유지하지만 출력 음정만 변형되는 구간

`BufferedEffectSegment`는 `PAUSE` 이후에는 남을 수 있지만, `UNLOAD` 이후에는 더 이상 생존하지 않는다.

`SupplyCutEmptySegment`와 `TailEmptySegment`는 **빈 블록**으로 표시한다.  
`BufferedEffectSegment`, `TransportModifiedSegment`, `PitchModifiedSegment`는 빈 블록이 아니라, effect tail 또는 변형된 waveform projection으로 표시할 수 있다.

## Empty Segment Rule

시각화 규칙은 아래와 같다.

- `PAUSE` 시점부터 다음 explicit playback-start semantic 또는 `UNLOAD` 전까지는 기본적으로 empty block으로 표시한다
- source audio content가 끝난 이후 `UNLOAD`까지 남는 구간도 empty block으로 유지한다
- `BufferedEffectSegment`가 존재하면 empty block 위에 effect-tail 성격의 waveform/projection을 별도로 표시할 수 있다
- `UNLOAD` 이후에는 남아 있던 feedback/effect tail도 종료된 것으로 본다

즉, 사용자는 하나의 `MusicBlock` 안에서 `재생되는 부분`과 `비어 있는 부분`을 동시에 보게 된다.

## Waveform Affection Rule

`MusicBlock` 내부의 RGB waveform은 raw asset waveform만을 그리는 것이 아니다.

이 문서에서 timeline waveform은 아래 두 층으로 본다.

- `SourceWaveform`: asset 자체에서 얻은 base RGB waveform
- `EffectiveWaveformProjection`: mix command 적용 이후 사용자에게 보여주는 waveform

`EffectiveWaveformProjection`에 영향을 주는 command 예시는 아래와 같다.

- `LOAD`
- `UNLOAD`
- `CONTROL(CUE)`
- `CONTROL(PAUSE)`
- `SPIN`
- `REV`
- `SCRATCH`
- `BSCRATCH`
- `ECHO`
- `PITCH`

규칙은 아래와 같다.

- source audio 공급을 끊는 명령은 waveform을 empty 또는 tail-only 상태로 바꾼다
- source cursor 경로를 바꾸는 명령은 waveform 진행 방향/위치를 바꾼다
- buffered output을 남기는 명령은 source 공급이 끊긴 뒤에도 waveform projection에 tail을 남길 수 있다
- pitch modifier는 cursor 경로를 바꾸지 않으며, waveform 이미지를 다시 계산하지 않는다
- `PITCH`의 시각 상태는 waveform 변경보다 tag UI로 드러낸다

즉, timeline의 RGB waveform은 **base waveform image**가 아니라, command 결과를 반영한 **effective audio-supply visualization**이다.

## Waveform Reuse Strategy

이 blueprint는 mix command 시각화를 위해 `SoundToRGBWaveform(...)`가 반환한 이미지 배열을 최대한 재활용한다.

핵심 규칙은 아래와 같다.

- mix command가 발생했다고 해서 `PDJE_MIR`를 다시 호출해 새 waveform을 계산하지 않는다
- 기본 source는 이미 확보된 `Array[Image]` 또는 동등 image cache다
- 시각 변형은 가능한 한 기존 image의 배치, crop, reverse, scale만으로 해결한다
- 이 문서 기준으로는 **이미지의 크기를 늘리고 줄이는 방식이면 충분하다**

즉, mix timeline의 waveform projection은 `재계산`보다 **기존 RGB waveform image array의 재배치와 스케일 조절**을 우선한다.

## Command Visual Reuse Rule

command별 기본 표시 규칙은 아래와 같다.

### `LOAD` / `UNLOAD`

- 별도 waveform 재계산 없이 block 시작/끝 경계만 바꾼다

### `PAUSE`

- `PAUSE` 이후는 empty block으로 바꾼다
- 새 waveform 이미지를 만들지 않는다

### `CUE`

- 새 cursor 위치부터 기존 source image array의 다른 구간을 즉시 참조한다
- jump cut만 일어나며 재계산은 없다

### `SCRATCH` / `SPIN` / `REV` / `BSCRATCH`

- 기존 source image array를 재사용한다
- speed 절대값에 따라 이미지 폭을 늘리거나 줄여 진행 속도 차이를 표현한다
- 음수 speed는 반대방향 재생이므로 image 진행 방향을 뒤집거나 역방향 참조로 표현한다
- 새 MIR waveform 계산은 하지 않는다

### `ECHO`

- 기존에 보이던 image array를 재사용한다
- tail은 마지막 visible image 구간을 복제하거나 축소/감쇠해서 표현할 수 있다
- 새 waveform 계산은 하지 않는다

### `PITCH`

- waveform 이미지는 그대로 둔다
- pitch 때문에 이미지를 다시 계산하거나 다른 image로 교체하지 않는다
- 대신 `PitchModifiedSegment`에 pitch tag UI를 추가해 modifier 상태를 표시한다

## Pitch Tag UI Rule

`PITCH`의 시각 표현은 waveform shape 변형보다 tag UI를 우선한다.

규칙은 아래와 같다.

- `PITCH` 구간 위에 pitch tag 또는 badge를 표시한다
- tag에는 최소한 `first arg` 기반 pitch 변화 정보가 드러나야 한다
- waveform image 자체는 source/base projection을 그대로 유지한다

즉, `PITCH`는 **waveform 재그리기 대상이 아니라 tag UI 대상**이다.

## Cue Rule

이 문서에서 `CUE`는 `CONTROL(CUE)` 계열의 transport jump command로 본다.

규칙은 아래와 같다.

- `CUE`는 어떤 시점이든 배치될 수 있다
- `CUE`가 발생하면 source playback cursor는 즉시 `first arg`가 가리키는 위치로 이동한다
- 이 이동은 즉각적이다
- `CUE`는 재생을 정지시키지 않는다
- source 공급이 이미 끊긴 상태여도 cursor 이동 자체는 수행된다
- 즉, `CUE` 이후에는 같은 global 시점에서 곧바로 새 cursor 위치 기준의 audible segment가 이어진다

따라서 `CUE`는 pause처럼 empty block을 만드는 명령이 아니라, **재생 지속 상태에서 source 위치를 순간 점프시키는 명령**이다.

## Battle Modifier Rule

이 문서에서 `SCRATCH`, `SPIN`, `REV`, `PITCH`는 battle-style playback modifier로 본다.

공통 규칙은 아래와 같다.

- battle-style modifier는 활성 구간 동안만 적용된다
- 적용 중에는 audible output이 modifier 규칙을 따른다
- 하지만 `CanonicalSourceCursor`는 "이 modifier가 없었다면" 진행됐을 경로를 유지한다
- modifier가 끝나면 audible output은 `CanonicalSourceCursor` 위치로 복귀한다

즉, battle-style modifier는 곡의 canonical 진행 자체를 rewrite하지 않고, **일시적으로만 출력 경로를 변형하는 기능**이다.

## Scratch Rule

`SCRATCH`는 특수한 sampler-like transport modifier다.

규칙은 아래와 같다.

- `first arg`는 scratch 시작 source 위치다
- `second arg`는 scratch 재생 속도다
- 활성 구간 동안 `EffectiveReadCursor`는 `first arg` 위치에서 시작해 `second arg` 속도로 움직인다
- 속도 부호 규칙은 공통 speed rule을 따른다
- scratch가 끝나면 `EffectiveReadCursor`는 scratch가 없었다면 도달했을 `CanonicalSourceCursor` 위치로 돌아간다

## Spin And Rev Rule

`SPIN`과 `REV`는 현재 cursor 위치에서 시작하는 battle-style transport modifier다.

규칙은 아래와 같다.

- 시작 시점의 `EffectiveReadCursor` 위치를 시작점으로 삼는다
- `first arg`는 speed 값이다
- 활성 구간 동안 `EffectiveReadCursor`는 그 speed로 진행한다
- modifier가 끝나면 `EffectiveReadCursor`는 이 modifier가 없었다면 도달했을 `CanonicalSourceCursor` 위치로 돌아간다

이 blueprint에서 방향은 command 이름보다 speed 부호 규칙을 우선한다.

## Pitch Rule

`PITCH`는 transport jump가 아니라 pitch modifier다.

규칙은 아래와 같다.

- `first arg`는 pitch 변화량이다
- 활성 구간 동안 audible output의 음정이 변경된다
- `PITCH`는 `CanonicalSourceCursor` 경로를 다시 쓰지 않는다
- `PITCH`가 끝나면 output은 별도 jump 없이 당시의 `CanonicalSourceCursor` 기준 재생으로 이어진다

즉, `PITCH`는 cursor modifier가 아니라 **output pitch modifier**다.

## Speed Rule

speed 값을 쓰는 battle-style modifier의 공통 규칙은 아래와 같다.

- 양수 speed는 정방향이다
- 음수 speed는 반대방향이다
- `2.0`은 정방향 2배속이다
- `-2.0`은 반대방향 2배속이다

## MusicBlock Semantic Rule

`MusicBlock`은 재생/정지 영역을 다루지만, 최종 저장 primitive는 region object 자체가 아닐 수 있다.

번역 계층에서는 아래처럼 lower될 수 있다.

- `LOAD`
- `UNLOAD`
- `CONTROL(PAUSE)`
- 필요 시 `CONTROL(CUE)`
- `SPIN`
- `REV`
- `SCRATCH`
- `BSCRATCH`
- `ECHO`
- `PITCH`

현재 공식 `Editor Format`과 verified wrapper는 위 command family를 mix semantic으로 드러낸다. waveform projection에 어떤 시각적 변형 규칙으로 매핑할지는 후속 문서에서 더 구체화한다.

즉, `MusicBlock`은 UI authoring block이고, 최종 `PDJE` 쪽에서는 event row 집합으로 번역된다.

## Waveform Rule

`MusicBlock`이 쓰는 waveform은 현재 verified binding 기준으로 아래 성격을 가진다.

- low-level source는 `PDJE_MIR.SoundToRGBWaveform(...)` 또는 동등 경로다
- Godot UI가 직접 소비하는 것은 decode된 `waveform_images` 또는 동등 preview reference다
- mix timeline에서 실제로 그리는 것은 필요 시 위 source를 가공한 `effective waveform projection`이다
- waveform이 아직 생성되지 않았더라도 `MusicBlock`의 semantic validity가 자동으로 깨지지는 않는다

즉, waveform은 중요하지만 source of truth는 아니다.

## BarBlock

## Definition

`BarBlock`은 `MusicBlock`을 박 단위 접근이 가능하도록 나눈 derived access unit이다.

이 block은 아래 값을 바탕으로 계산된다.

- music asset의 `firstBeat`
- music asset의 local BPM metadata
- `TrackBlock`의 global BPM map
- `MusicBlock`의 global start position

## Responsibilities

`BarBlock`의 주 역할은 아래다.

- 음악을 bar 접근 단위로 분해
- 박자 단위 EQ / FX 편집 anchor 제공
- beat-aligned edit access point 제공

즉, `BarBlock`은 tempo authoring 자체보다, **tempo가 해석된 뒤에 생기는 beat-addressable editing unit**이다.

## Derived Rule

`BarBlock`은 현재 문서에서 영속적으로 손으로 배치하는 primitive가 아니다.

핵심 규칙은 아래와 같다.

- `BarBlock`은 계산 결과로 생성된다
- local BPM map 또는 global BPM map이 바뀌면 다시 계산된다
- `MusicBlock`이 global timeline에서 이동하면 같이 재투영된다

추가 규칙은 아래와 같다.

- `SupplyCutEmptySegment`에서는 local source playback cursor가 전진하지 않는다
- 따라서 source 공급이 끊긴 empty 구간에서는 새로운 audio-driven `BarBlock` 진행이 일어나지 않는다
- `TailEmptySegment`에서는 더 이상 audio-driven `BarBlock`이 생성되지 않고 empty filler만 남는다
- `BufferedEffectSegment`는 audio tail을 가질 수 있어도 새로운 source beat 진행을 만들지는 않는다
- `TransportModifiedSegment`는 `EffectiveReadCursor`를 바꾸지만, local BPM metadata나 `CanonicalSourceCursor` 자체를 다시 쓰는 것은 아니다
- `PitchModifiedSegment`는 output pitch를 바꾸지만 beat progression 기준 자체를 다시 쓰지는 않는다
- `CUE`는 source cursor를 즉시 옮기지만 playback stop을 만들지 않는다

## Time Systems

이 모델은 세 가지 시간 계층을 가진다.

### 1. Global Timeline Time

- `Workspace`와 `TrackBlock`이 공유하는 x축
- 믹스 전체 기준의 상위 시간선
- user-facing 배치 기준

### 2. Music Local Beat Time

- music asset config에서 확정된 `firstBeat + local BPM map`
- asset 내부 박자 구조
- user-facing mix authoring에서는 주 편집 대상으로 거의 노출하지 않는다

### 3. Derived Global Beat Access Grid

- global BPM lane과 local BPM metadata를 합성한 결과
- 정확히는 workspace의 single global BPM lane과 local BPM metadata를 합성한 결과
- `BarBlock` 경계가 실제로 놓이는 grid
- EQ / FX / beat-unit edit가 접근하는 계산된 박자 단위

## Global BPM Authoring Rule

이 프로젝트의 핵심 UX 규칙은 아래와 같다.

- 사용자는 믹스 authoring 단계에서 global BPM 하나만 신경쓴다
- local BPM 변화는 내부 동작을 위한 참조 데이터로 사용된다
- 따라서 mix editor는 workspace의 single global BPM lane을 중심으로 설계한다
- 이 lane은 `BPM_CONTROL` point command만 받으며, 각 command는 그 시점 이후의 target BPM을 고정한다

이 규칙의 목표는 아래와 같다.

- authoring surface 단순화
- asset별 복잡한 BPM curve 노출 최소화
- `Music Asset Add & Config`에서 timing 정합성을 먼저 확보하고, 믹스 단계에서는 단일 global control만 보게 만들기

## Local BPM Internal Reference Rule

music asset의 local BPM metadata는 아래 성격을 가진다.

- asset prep 단계에서 확정된 internal timing reference
- `BarBlock` 계산의 입력값
- global BPM 추종 시 time-stretch 해석의 source BPM curve
- mix editor에서 직접 다시 쓰는 기본 대상은 아님

즉, local BPM map은 **숨겨진 내부 기준선**이다.

## Effective Tempo Mapping Rule

이 모델은 source BPM과 target BPM을 둘 다 참조하는 piecewise tempo mapping을 따른다.

- source BPM: `music config`에서 확보한 local BPM map
- target BPM: workspace-global BPM lane

effective stretch는 구간별로 계산된다.

예:

- local BPM map: 시작 `180 BPM`, 8박부터 `260 BPM`
- global BPM map: 시작 `100 BPM`, 10박부터 `300 BPM`

그러면 내부 해석은 아래처럼 된다.

1. 시작부터 local 8박 전까지: `180 -> 100`
2. local 8박부터 global 10박 전까지: `260 -> 100`
3. global 10박 이후: `260 -> 300`

즉, 경계는 하나의 BPM curve만 보지 않고 아래 change point들의 합집합으로 나뉜다.

- local BPM change point
- global BPM change point

이 규칙이 `BarBlock` 재계산과 stretch 해석의 핵심이다.

## BPM Control Command Rule

`Editor_Format` 기준에서 `BPM_CONTROL`은 `ITPL + 8PointValues` 계열이 아니라, `first` 인자에 target BPM 하나만 가지는 point command로 본다.

- `BPM_CONTROL` row는 start position만 필요하다
- `first`에는 target BPM 하나만 문자열로 직렬화해 넣는다
- 이 command가 나타난 시점부터 lane의 effective target BPM은 해당 값으로 고정된다
- 그 상태는 다음 `BPM_CONTROL` command가 나올 때까지 유지된다
- 따라서 global BPM lane은 curve interpolation lane이 아니라 **step-hold BPM change lane**이다

## Editing Responsibility Split

block별 편집 책임은 아래처럼 고정한다.

### Workspace Level

- 전체 시간축 컨테이너
- global BPM lane
- 전체 selection context

### TrackBlock Level

- asset-owned lane identity
- lane-level visibility

### MusicBlock Level

- waveform 기반 위치 파악
- `LOAD` / `UNLOAD`
- `PAUSE` / 재생 구간
- supply-affecting command의 waveform 반영
- empty filler 구간 표시
- global timeline 상 사용 시점 결정

### BarBlock Level

- EQ 접근
- FX 접근
- beat 단위 수정 anchor

## Translation To PDJE Editor Format

현재 model은 최종적으로 아래 semantic layer로 번역된다.

### Music Asset Side

asset prep에서 확정된 local timing 정보는 아래 쪽으로 간다.

- `ConfigNewMusic(...)`
- `EditMusicFirstBar(...)`
- `PDJE_EDITOR_ARG.InitMusicArg(...)`
- `EditorWrapper.AddLine(...)`

즉, local BPM map과 `firstBeat`는 `EDIT_ARG_MUSIC` 계열과 연결된다.

### Mixset Timeline Side

mix authoring에서 만든 구조는 아래 쪽으로 간다.

- workspace-global BPM lane -> `MixArgs(BPM_CONTROL)`
- `MusicBlock load/unload/play-state` -> `MixArgs(LOAD/UNLOAD/CONTROL)`
- `BarBlock EQ/FX edits` -> `MixArgs(EQ/FILTER/VOL/FX 계열)`

여기서 중요한 점은 아래와 같다.

- UI block hierarchy는 authoring용 abstraction이다
- 최종 `PDJE` 저장 의미는 event row 집합이다
- 따라서 compile/translation 단계에서 deterministic ordering이 필요하다

### MixArgs Lowering Contract

현재 blueprint에서 mix row lowering은 `PDJE_EDITOR_ARG.InitMixArg(...)`가 받는 full arg shape를 기준으로 한다.

- 모든 mix row는 기본적으로 `type`, `id`, `details`, `first`, `second`, `third`, `beat`, `subBeat`, `separate`, `Ebeat`, `EsubBeat`, `Eseparate` 전체 컬럼을 가진 full arg로 본다
- lowering 단계는 row별로 필요한 컬럼만 채우고, 읽지 않는 컬럼은 wrapper/native default가 유지된 상태로 넘긴다
- 즉, 어떤 row가 point command인지 span command인지에 따라 start tuple만 채우거나, start/end tuple을 함께 채우는 식으로 lowering한다
- `first` / `second` / `third` 역시 row가 실제로 읽는 slot만 채우고, 나머지는 수정하지 않은 기본값으로 둔다

따라서 blueprint에서의 핵심 문제는 "모든 row를 서로 다른 구조체로 만드는 것"이 아니라, **공통 full arg shape를 유지한 채 각 detail이 어떤 컬럼을 실제로 읽는지 고정하는 것**이다.

### MixArgs Auxiliary Argument Categories

`Editor_Format` 기준으로 `MixArgs.first/second/third`는 저장층에서는 모두 `TEXT`지만, blueprint에서는 아래 semantic category로 묶어 해석한다.

#### 1. Numeric Scalar Text

문자열로 직렬화되는 `double` / `float` 계열 값이다.

- `bpm`
- `feedback`
- `middlefreq`
- `rangehalffreq`
- `gain`
- `Strength`
- `Thresh`
- `Knee`
- `ATT`
- `REL`
- `ocsFreq`
- `speed`

이 값들은 mix type에 따라 단일 scalar로 쓰이거나, comma-separated tuple의 구성 요소로 쓰일 수 있다.

#### 2. PCM Frame Position Text

문자열로 직렬화되는 `unsigned long long` 계열 위치값이다.

- `approx_loc`
- `StartPosition`

blueprint 해석상 이 둘은 모두 음악 블록 내부 기준의 PCM frame 위치를 뜻한다.  
채널 수는 따로 곱하지 않는 frame index이며, `48000 sample rate` 기준으로 `1초 = 48000`으로 본다.

#### 3. Plain String Text

문자열 자체를 의미 payload로 쓰는 값이다.

- `title`
- `composer`

### `LOAD` Payload Ownership Rule

`Editor_Format`의 `LOAD` row에서 쓰이는 `title`, `composer`, `bpm`은 user가 mixset timeline에서 자유 텍스트나 숫자로 직접 작성하는 필드로 두지 않는다.

- 이 셋은 오직 `LOAD` 명령의 asset identity payload를 구성하기 위한 인자다
- 사용자는 timeline에서 `LOAD`할 대상을 현재 editor에 등록된 music asset 중에서 선택한다
- 시스템은 그 선택 결과를 기준으로 현재 등록된 music metadata를 질의해 `title`, `composer`, `bpm`을 자동 기입하거나 동기화한다
- 따라서 `LOAD` row의 `title/composer/bpm`은 user-authored freeform payload가 아니라 **selected registered asset에서 파생되는 derived payload**로 본다

여기서 `bpm`은 일반적인 scalar numeric automation 입력과 같은 성격으로 직접 편집하지 않는다.  
즉, `LOAD`의 `bpm`은 검색/동일성 보조 payload이며, workspace-global BPM lane이나 FX 파라미터 입력과 다른 규칙을 따른다.

### 8Point Automation Target Set

공식 `Editor_Format`의 `Mix Data Table` 기준으로, 현재 blueprint에서 `ITPL + 8PointValues` 기반 span automation으로 취급하는 대상은 아래와 같다.

- `FILTER`
- `EQ`
- `DISTORTION`
- `VOL`
- `ECHO`
- `OSC_FILTER`
- `FLANGER`
- `PHASER`
- `TRANCE`
- `PANNER`
- `ROLL`
- `ROBOT`

여기서 공식 표의 구 표기는 `OCS_Filter`지만, blueprint에서는 현재 소스명 기준의 `OSC_FILTER`로 통일해 적는다.

반대로 아래 계열은 `8PointValues` 기반 automation target으로 보지 않는다.

- `CONTROL`
- `LOAD`
- `UNLOAD`
- `BPM_CONTROL`
- `BATTLE_DJ`
- `COMPRESSOR`

### Interpolation Default Rule

`8PointValues` 기반 automation의 기본 interpolation은 `ITPL_COSINE`으로 둔다.

- user는 필요 시 다른 interpolation으로 바꿀 수 있다
- `ITPL_FLAT`에서는 하나의 control value를 움직이면 다른 point도 함께 따라가도록 본다

### Parameter Window Reuse Rule

timeline에서 tag를 생성하거나 수정할 때는 최대 3개의 공통 파라미터 창을 재사용한다.

- 각 창은 단순한 실수 입력 필드값을 받는 공통 dialog window다
- 창 배치는 화면 하단 기준으로 `first`는 좌하, `second`는 중하, `third`는 우하이다
- 파라미터가 없는 slot은 창을 띄우지 않는다
- 비어 있는 slot이 있으면 남은 창이 그 영역까지 확장되어 더 넓게 보이도록 한다
- `double` / `unsigned int` 성격의 값은 모두 같은 공통 numeric 입력 dialog를 재사용한다
- 사용자가 입력한 값은 apply 직전에 `__SETTING_VAL__AUTOMATION_PARAM_SCALAR_COERCE_MODE` 규칙에 따라 그대로 유지하거나 `floor` 처리한다
- apply 시점에는 정규화된 값을 자동으로 string으로 직렬화해 `first` / `second` / `third` payload에 넣는다
- `title`, `composer`처럼 자유 문자열이지만 derived payload로 다뤄야 하는 값은 별도 freeform 입력 대상으로 두지 않는다

PCM frame 위치를 의미하는 인자는 직접 타이핑보다 waveform 기반 picking을 우선한다.

- `approx_loc`
- `StartPosition`

이 값들은 RGB waveform 위에서 사용자가 bar 위치를 찍으면 자동으로 기입되도록 한다.

### Mix Target Parameter Schema

아래 표는 공식 `Editor_Format`의 `Mix Data Table`을 기준으로, 현재 blueprint가 각 target의 `first` / `second` / `third`를 어떻게 해석하는지 고정한 것이다.  
공식 표의 구 표기 `bpmControl`, `OCS_Filter`는 여기서 각각 `BPM_CONTROL`, `OSC_FILTER`로 읽는다.

| Target | Command Shape | Start/End Usage | `first` | `second` | `third` | UI Input Rule |
| --- | --- | --- | --- | --- | --- | --- |
| `FILTER` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `EQ` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `DISTORTION` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `VOL` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `ECHO` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, feedback` | 8point popup + scalar dialog |
| `OSC_FILTER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, MiddleFreq, RangeHalfFreq` | 8point popup + scalar dialog |
| `FLANGER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `PHASER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `TRANCE` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, GAIN` | 8point popup + scalar dialog |
| `PANNER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, GAIN` | 8point popup + scalar dialog |
| `ROLL` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `ROBOT` | span automation | start + end | `ITPL_*` | `8PointValues` | `ocsFreq` | 8point popup + scalar dialog |
| `CONTROL.PAUSE` | point command | start only | `approx_loc` | none | none | waveform picking |
| `CONTROL.CUE` | point command | start only | `approx_loc` | none | none | waveform picking |
| `LOAD` | point command | start only | `title` | `composer` | `bpm` | registered asset lookup only |
| `UNLOAD` | point command | start only | none | none | none | tag only |
| `BPM_CONTROL` | point command | start only | target BPM | none | none | scalar dialog |
| `BATTLE_DJ.SPIN` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.PITCH` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.REV` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.SCRATCH` | point command | start only | `StartPosition` | `SPEED` | none | waveform picking + scalar dialog |
| `COMPRESSOR` | point command | start only | `Strength` | `Thresh, Knee` | `ATT, REL` | scalar dialog |

표의 `Command Shape`는 현재 blueprint 해석이다.  
이는 공식 표의 payload column과 공식 시간 모델의 `start tuple only` / `start+end tuple` 구분을 결합해 도출한 것이다.

### Special Payload Input Rules

특수 계열도 lowering 구조 자체는 일반 `MixArgs`와 다르지 않다.  
다만 `first` / `second` / `third` slot이 요구하는 payload shape에 따라 입력 UI가 달라진다.

#### 1. PCM Frame Position Payload

`first` / `second` / `third` 중 어떤 slot이든 PCM frame 위치를 요구하는 경우, 해당 slot은 일반 scalar dialog 대신 waveform-linked picker window로 처리한다.

- 사용자는 RGB waveform 위의 bar 위치를 선택한다
- 시스템은 그 위치를 음악 블록 내부 기준 PCM frame index로 환산한다
- 환산된 값은 해당 slot payload에 자동 기입된다
- 이 picker window는 기존 `first` / `second` / `third` 하단 파라미터 레이아웃과 호환되게 배치한다

#### 2. Comma-Separated Numeric Tuple Payload

쉼표로 구분된 numeric tuple을 요구하는 slot은 tuple arity에 맞는 전용 dialog를 사용한다.

- `Thresh, Knee`처럼 2개 scalar를 요구하는 경우: 2-field float dialog
- `ATT, REL`처럼 2개 scalar를 요구하는 경우: 2-field float dialog
- `BPM, feedback`처럼 2개 scalar를 요구하는 경우: 2-field float dialog
- `BPM, MiddleFreq, RangeHalfFreq`처럼 3개 scalar를 요구하는 경우: 3-field float dialog

저장 시에는 각 field 값을 개별적으로 string 변환한 뒤, comma-separated text로 직렬화한다.

- 예: `string(float),string(float)`
- 3-field인 경우도 같은 방식으로 `string(float),string(float),string(float)`로 직렬화한다

## Validation Rules

- `TrackBlock`은 `ready_for_mixset = true`인 asset에 대해서만 생성할 수 있다
- 하나의 asset은 하나의 `TrackBlock`만 가진다
- workspace에는 BPM 전용 `global parameter lane`이 하나만 존재한다
- local BPM metadata가 없으면 `BarBlock` 계산이 불완전해진다
- waveform preview가 없어도 semantic validity를 자동으로 잃지는 않는다
- `MusicBlock`의 재생/정지 영역은 번역 가능한 event set으로 환원 가능해야 한다
- `SupplyCutEmptySegment`와 `TailEmptySegment`는 global span은 차지하지만 source cursor를 전진시키지 않는다
- waveform projection은 raw asset waveform이 아니라 mix command 적용 이후 상태를 반영할 수 있어야 한다

## Persistence Boundary

영속 저장되는 핵심은 아래다.

- block id와 참조 관계
- global 위치 정보
- workspace-global BPM lane data
- `MusicBlock`의 사용 영역 / 재생 상태 영역
- `MusicBlock` 내부 silent / empty segment 경계
- `BarBlock` 편집 결과에서 파생된 semantic event
- asset ref

아래는 source of truth로 저장하지 않는다.

- pixel 좌표
- temporary zoom
- waveform bitmap 자체
- UI hover / selection rectangle

registered asset waveform은 cache asset으로 취급할 수 있지만, master preview waveform은 transient preview data로 보고 cache하지 않는다.

## Discontinuous Use Rule

- 같은 `asset_id`는 여전히 하나의 `TrackBlock`만 가진다
- 하지만 같은 `asset_id`의 비연속 audible use는 하나의 `MusicBlock` 내부 segmentation으로 보지 않는다
- 비연속 audible use는 같은 `TrackBlock` 안의 복수 `MusicBlock`으로 표현한다
- `PAUSE`는 block 내부 source supply cut일 뿐, 이후 resume semantics를 만들지 않는다

## Summary

`Mixset Timeline Model`의 현재 draft는 아래 구조를 따른다.

- `TrackBlock`은 음악 asset당 정확히 하나의 lane이다
- 같은 `TrackBlock`은 복수 `MusicBlock`을 가질 수 있다
- 사용자는 workspace-global BPM lane만 직접 편집한다
- local BPM map은 hidden internal timing reference다
- `MusicBlock`은 global timeline 위에서 asset의 사용과 재생 상태를 다루며, `LOAD-UNLOAD` 전체 길이를 가진다
- `PAUSE` 이후에는 기본적으로 source 공급이 끊기며, audio 종료 이후 남는 구간과 함께 empty block으로 표시한다
- 같은 asset을 나중에 다시 쓰려면 pause/resume이 아니라 새로운 `MusicBlock`을 만든다
- `LOAD`, `UNLOAD`, `CUE`, `PAUSE`, `SCRATCH`, `SPIN`, `REV`, `ECHO` 같은 supply-affecting command는 RGB waveform 표시에도 반영된다
- `BarBlock`은 local BPM map과 global BPM map으로부터 계산되는 derived beat access unit이다
- 최종적으로 이 모델은 `PDJE Editor Format`의 `MusicArgs`와 `MixArgs` 집합으로 번역된다

핵심 목표는 **사용자는 global BPM 하나만 신경쓰게 만들고, 내부적으로는 asset local BPM metadata를 참조해 정확한 beat-unit authoring을 가능하게 만드는 것**이다.
