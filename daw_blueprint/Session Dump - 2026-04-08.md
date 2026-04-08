# Session Dump - 2026-04-08

## Purpose

이 문서는 `2026-04-08` 기준으로 다음 세션에서 바로 이어서 작업할 수 있도록, 현재 blueprint의 핵심 결정 사항과 주의사항을 압축 정리한 handoff dump다.

## Project Identity

- 이 프로젝트는 실시간 DJ 퍼포먼스 앱이 아니다
- 목표는 `PDJE` 개념을 Godot GUI로 구현한 `DJ mixset authoring software`다
- 중심은 `timeline event authoring + automation + preview + persistence`다
- 일반 작곡 DAW가 아니라 DJ workflow의 DAW화가 목적이다

## Primary Reference

- 공식 상위 기준 문서: `Project DJ Godot / PDJE`
- 로컬 바인딩 기준선: [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)

다음 세션에서 `PDJE` 관련 사실 판단은 가능하면 먼저 [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)을 보고 시작하는 것이 맞다.

## Authoritative Local Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Automation Lane Model](Automation%20Lane%20Model.md)
- [Preview Playback Design](Preview%20Playback%20Design.md)
- [Functional Requirements](Functional%20Requirements.md)
- [Non-Functional Requirements](Non-Functional%20Requirements.md)
- [Settings](Settings.md)
- [todo-list](todo-list.md)

## Binding Truths That Matter

### Verified Against Local Wrapper

- `EditorWrapper.ConfigNewMusic(NewMusicName, composer, musicPath, firstBar)`가 실제 music registration entry point다
- `EditorWrapper.EditMusicFirstBar(title, firstBar)`가 first beat 수정 경로다
- music BPM row는 `PDJE_EDITOR_ARG.InitMusicArg(...) + EditorWrapper.AddLine(...)`로 추가한다
- `PDJE_MIR.SoundToWaveform` / `SoundToRGBWaveform`는 raw file path를 직접 받지 않는다
- 위 waveform API는 내부적으로 `SearchMusic(title, composer, bpm)` 후 `GetPCMFromMusData(...)`를 사용한다
- raw local file의 PCM validity 확인에는 `PDJE_Wrapper.GetPCMFromMusicData({ musicPath = ... })`를 쓸 수 있다
- `GetDiff()`는 바인딩은 되어 있으나 현재 stub이다
- 현재 wrapper surface에는 `ConfigNewMusic(...)` 이후 기존 music asset의 `title`, `composer`, `musicPath`를 인플레이스로 갱신하는 전용 API가 보이지 않는다
- waveform low-level 반환은 Godot `Image`가 아니라 encoded byte array 기반이며, UI 쪽 decode가 필요하다

### Official Doc Mismatch Notes

- 공식 `Core_Engine` 예시의 `ResetPlayer()`는 현재 wrapper에 노출되지 않는다
- 공식 Godot judge 예시는 현재 wrapper 시그니처와 다르다
- 공식/native 문서의 `firstBeat`와 달리 현재 `SearchMusic()` wrapper dictionary key는 `firstBar`다

## Product And UX Decisions Already Closed

### Scene Structure

- 거시 씬은 `Workspace Selection Scene -> Authoring Scene`
- `Authoring Scene` 내부는 `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`
- `Music Asset Add & Config`는 실제 화면 전환이 있는 별도 작업공간이다

### Global UI

- shell 구조는 `Global Top Bezel -> Local Bezel -> Scene Content -> Global Bottom Bezel`
- `Authoring Local Bezel`은 최소 공통 strip만 담당한다
- `ReturnAction`과 `SaveIcon`은 authoring local bezel 좌측 상단
- 저장 차단 사유는 bezel이 아니라 subscene 내부에서 강하게 표시한다
- 새 editor project 생성 입력은 `projectRoot` 필수, `authorName` 선택, `authorContactEmail` 선택으로 고정한다
- editor project metadata는 text file이 아니라 `PDJE_RelationalDB` 기반 registry에 `user://` 아래 고정 경로로 저장한다
- BPM mapping은 region change를 허용하지 않고 point row만 허용한다
- BPM transition metadata row schema는 `bpm:Text`, `beat:Int64`, `subBeat:Int64`, `separate:Int64`로 고정한다

### Music Asset Add & Config

- import는 `DnD` 또는 native file picker
- mix editor가 직접 참조할 수 있는 것은 `editor DB` 또는 `RootDB`에 메타데이터와 함께 등록된 음악 자산뿐이다
- 아직 등록되지 않은 로컬 파일은 반드시 config를 거쳐야만 authoring 대상이 된다
- 메타데이터 자동 확정 금지
- 필수 필드 디폴트 금지
- 초기 app-local draft save와 실제 `PDJE registration`을 분리한다
- 음악 경로를 실제로 수용 가능한 asset reference로 판정하는 절차는 `PDJE` core가 맡고, 실패 시 asset rejection으로 이어진다
- `ready_for_mixset`는 `render(..., lint_msg)` 성공으로 증명되는 project-local readiness일 뿐 root DB searchable 상태와 같지 않다
- waveform은 조건부 capability이며, search-visible 여부와 분리해서 생각해야 한다
- 그래픽적 tag metadata의 소유자는 `asset_id`다
- 같은 source audio라도 `asset_id`가 다르면 tag를 공유하지 않는다
- source of truth 우선순위는 `RootDB` 저장 데이터, `editor DB` 저장 데이터, app-side 임시 상태 순서다
- 실패 상태는 persistence하지 않고 transient UI state로만 남긴다

## Mixset Timeline Model State

### Hierarchy

- `Workspace -> TrackBlock -> MusicBlock -> BarBlock`
- workspace lane family는 `global parameter lane 1개 + track lane N개 + master output lane 1개` 구조다
- `global parameter lane`은 BPM만 다룬다
- `master output lane`은 preview/render output만 표시하는 display-only lane이다

### TrackBlock

- `TrackBlock = music asset당 정확히 하나의 asset-owned lane`
- `TrackBlock`은 `track lane` family의 개별 lane instance다
- user-facing BPM control은 workspace의 `global parameter lane`에서만 이뤄진다
- global BPM lane은 point-command 기반 step-hold BPM lane이다
- 하나의 `asset_id`에는 정확히 하나의 music asset만 대응한다
- 같은 source audio라도 다른 `asset_id`로 불러오면 다른 asset data로 본다
- waveform cache hit는 허용하지만, 다른 `asset_id`끼리 edit state를 공유하면 안 된다
- local BPM map은 mix editor의 직접 편집 대상이 아니다

### MusicBlock

- `MusicBlock`은 `LOAD -> UNLOAD` 전체 길이를 가진다
- 같은 `TrackBlock`은 복수 `MusicBlock`을 가질 수 있다
- 실제 곡 길이보다 길어도 된다
- 곡이 먼저 끝나면 남는 구간은 empty block
- `PAUSE` 이후는 기본적으로 source supply cut
- `resume after pause`는 기본 시나리오에서 제거했다
- 같은 asset을 나중에 다시 쓰려면 같은 `TrackBlock` 안에 새로운 `MusicBlock`을 만든다
- `PAUSE` 이후에는 echo 같은 feedback FX tail만 남을 수 있고, `UNLOAD` 이후에는 그 영향도 끝난다

### CUE

- `CUE`는 `first arg` 위치로 source cursor를 즉시 점프시킨다
- `CUE`는 재생을 멈추지 않는다
- 어떤 시점이든 배치 가능하다

### Battle Modifiers

- `SCRATCH`, `SPIN`, `REV`, `PITCH`는 battle-style modifier
- `CanonicalSourceCursor`와 `EffectiveReadCursor`를 분리해서 본다
- modifier 활성 중에는 `EffectiveReadCursor`만 변형된다
- modifier 종료 후에는 `이 modifier가 없었다면 도달했을 CanonicalSourceCursor 위치`로 복귀한다
- speed rule: 양수 정방향, 음수 역방향, `2.0` 두배속, `-2.0` 역방향 두배속

### Waveform Visualization

- timeline에 보이는 것은 raw waveform이 아니라 `EffectiveWaveformProjection`
- `LOAD`, `UNLOAD`, `CUE`, `PAUSE`, `SCRATCH`, `SPIN`, `REV`, `ECHO`, `PITCH` 영향이 반영된다
- 하지만 시각 구현은 `SoundToRGBWaveform` 결과 image array를 최대한 재사용하는 방향으로 고정했다
- `SCRATCH/SPIN/REV/BSCRATCH`: image array reuse + width scale / reverse
- `PAUSE`: empty block
- `ECHO`: tail projection reuse
- `PITCH`: waveform 재계산 금지, tag UI만 추가

### BarBlock

- `BarBlock`은 hand-authored primitive가 아니라 derived access unit
- 입력값은 `firstBeat + local BPM map + global BPM map + MusicBlock global start`
- 주 역할은 beat 단위 EQ/FX 접근 anchor

### MixArgs Auxiliary Argument Categories

- `Editor_Format`의 `first/second/third`는 저장층에서는 모두 `TEXT`다
- `ITPL + 8PointValues`가 아닌 보조 인자는 blueprint에서 `Numeric Scalar Text`, `PCM Frame Position Text`, `Plain String Text`로 묶어 본다
- `Numeric Scalar Text`: `bpm`, `feedback`, `middlefreq`, `rangehalffreq`, `gain`, `Strength`, `Thresh`, `Knee`, `ATT`, `REL`, `ocsFreq`, `speed`
- `PCM Frame Position Text`: `approx_loc`, `StartPosition`
- `Plain String Text`: `title`, `composer`
- `approx_loc`와 `StartPosition`은 음악 블록 내부 기준 PCM frame 위치로 해석하며, `48000 sample rate` 기준 `1초 = 48000`으로 본다
- `LOAD`에서의 `title`, `composer`, `bpm`은 자유 입력 필드가 아니다
- 사용자는 등록된 music asset을 선택하고, 시스템이 현재 editor 등록 상태를 질의해 `LOAD` payload를 자동 기입한다
- `8PointValues` 기반 target은 `FILTER`, `EQ`, `DISTORTION`, `VOL`, `ECHO`, `OSC_FILTER`, `FLANGER`, `PHASER`, `TRANCE`, `PANNER`, `ROLL`, `ROBOT`으로 고정한다
- `BPM_CONTROL`, `CONTROL`, `LOAD`, `UNLOAD`, `BATTLE_DJ`, `COMPRESSOR`는 같은 계열로 보지 않는다
- 기본 interpolation은 `ITPL_COSINE`으로 둔다
- tag 입력 UI는 `first/second/third` 3개 공통 파라미터 창을 재사용하고, 화면 하단의 좌하/중하/우하에 배치한다
- 각 창은 실수 입력 기반 공통 dialog이며, apply 시 설정에 따라 `floor` 또는 그대로 유지 후 string 직렬화한다
- 없는 slot은 숨기며 남은 창이 확장된다
- `approx_loc`, `StartPosition`은 숫자 직접 입력보다 RGB waveform 클릭으로 자동 기입하는 쪽을 우선한다
- `BPM_CONTROL`은 `first = target BPM`만 가지는 point command이며, 이후 다음 BPM command가 나올 때까지 값이 유지된다
- target별 `first/second/third` schema는 공식 `Mix Data Table` 기준 표로 고정했다
- mix row lowering은 항상 full arg (`type/id/details/first/second/third/beat/subBeat/separate/Ebeat/EsubBeat/Eseparate`)를 기준으로 하고, row가 읽지 않는 컬럼은 default 상태로 넘긴다
- PCM frame 위치 payload는 RGB waveform bar 선택으로 자동 기입하는 picker window로 처리한다
- `Thresh,Knee` 같은 comma-separated tuple payload는 2-field 또는 3-field float dialog로 받고, 저장 시 comma-separated string으로 직렬화한다

### Preview Playback

- preview는 persistence가 아니라 `demoPlayInit` 기반 audition 단계다
- preview 시작 시 실제 재생 가능한 audio handle을 반환받는다
- handle과 연결된 data line에서 PCM frame을 추출한다
- 추출한 PCM은 `PCM -> Waveform` 경로로 master output lane에 표시한다
- preview master lane은 현재 `waveform only`로 고정한다
- preview master waveform은 cache하지 않는다
- playback cursor는 master output lane에만 존재한다
- playback 중 camera는 cursor를 선형 보간 애니메이션으로 따라간다
- active preview 중 authoring edit는 잠그고 `stop -> edit -> restart` 규칙으로 간다

### Editor Integration Boundary

- line에 필요한 fixable argument가 모두 모이면 즉시 `AddLine`을 호출한다
- line 제거 명령이 들어오면 즉시 `deleteLine`을 호출한다
- `getAll`은 Godot UI를 실제 editor 기록과 다시 동기화해야 하는 시점마다 호출한다
- `demoPlayInit`은 계산 비용이 큰 explicit preview 버튼 action으로만 둔다
- 일반 save는 매번 `render(trackTitle, ROOTDB, lint_msg)`를 실행한다
- render 실패 시 `lint_msg`를 사용자 피드백 alert/validation 메시지로 노출한다
- `pushToRootDB`는 `SaveIcon` 옆의 `RootPinAction` 또는 track editor exit 시 자동 시도로 연결한다

### Visual Theme

- canonical visual direction은 `dark-first broadcast technical theme`다
- waveform이 최우선 시각 정보다
- bezel과 panel은 low-glare solid surface를 사용한다
- canonical base UI font는 `JetBrains Mono`다
- primary action은 `icon + short text`를 기본으로 한다
- `SaveStateIndicator`는 `icon + short text badge`를 기본으로 한다
- right-side status 영역은 single cluster로 묶는다

### UI Asset Source

- 기본 icon source는 `Google Fonts Material Symbols Library`다
- canonical icon family는 `Material Symbols Outlined`다
- 라이선스는 공식 가이드 기준 `Apache License 2.0`로 본다
- 기본 가져오기 방식은 `SVG import`다
- font 방식이 필요해질 경우 Google Fonts 또는 self-hosting을 참고하되, canonical asset 기준선은 local SVG다
- 기본 font source는 `JetBrains Mono`다
- 기본 UI font stack은 `JetBrains Mono -> Noto Sans KR -> system sans fallback`이다
- fallback font source는 `Google Fonts Noto Collection`이다

## Document Status Snapshot

### Strongly Closed

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md)
- [UI Asset Source Policy](UI%20Asset%20Source%20Policy.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Automation Lane Model](Automation%20Lane%20Model.md)
- [Preview Playback Design](Preview%20Playback%20Design.md)
- [Editor Integration Boundary](Editor%20Integration%20Boundary.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Godot UI Structure](Godot%20UI%20Structure.md)

### Drafted But Still Reviewable

- [Functional Requirements](Functional%20Requirements.md)
- [Non-Functional Requirements](Non-Functional%20Requirements.md)

### Not Yet Written Or Not Yet Closed

- `Milestone Plan`

## Immediate Next Recommended Order

1. `Milestone Plan`
2. `User Personas`
3. `Product Goals`

자세한 backlog는 [todo-list](todo-list.md)를 보면 된다.

## Open Questions Still Alive

- 현재 semantic open question은 없다

## Cautions For Next Session

- 상용 제품 실명 표기는 문서에서 피하고 일반화된 표현을 쓰는 방향으로 유지 중이다
- `PITCH`는 파형 재생성 대상이 아니라 tag UI 대상이다
- `PDJE_MIR` 호출 가능 여부와 `ready_for_mixset`는 같은 것이 아니다
- `Music Asset Add & Config`에서 identity field를 registration 이후 인플레이스로 수정하는 흐름은 현재 binding 기준으로 가정하면 안 된다
- 같은 source audio의 waveform cache hit와 asset identity 공유는 다른 문제다

## One-Line Restart Summary

`2026-04-08` 기준 blueprint는 `PDJE`를 기반으로 한 Godot DJ mixset authoring tool의 상위 구조, timeline semantics, automation schema, preview model, editor integration boundary, asset identity 원칙, workspace visibility rules, Godot UI structure, functional requirements draft, non-functional requirements draft가 많이 닫혀 있으며, 다음 핵심 작업은 `milestone plan`을 문서화하는 것이다.
