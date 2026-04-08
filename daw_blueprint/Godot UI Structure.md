# Godot UI Structure

## Purpose

이 문서는 `Project DJ DAW`의 Godot UI를 실제 node tree / workspace root / controller / overlay 계층으로 고정한다.

핵심은 아래를 닫는 것이다.

- top-level scene tree
- persistent shell host 구조
- `Workspace Selection Scene`의 실제 view tree
- `Authoring Scene` 내부 child workspace 구조
- `Mixset Editing Workspace`의 timeline/lane/view 계층
- `Music Asset Add & Config Workspace`의 panel/view 계층
- shared controller / service anchor
- view와 `PDJE` editor integration 사이의 binding boundary

이 문서는 새로운 semantics를 정의하지 않는다.  
이미 닫힌 workflow/model 문서를 Godot UI 책임 경계로 번역하는 문서다.

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Automation Lane Model](Automation%20Lane%20Model.md)
- [Preview Playback Design](Preview%20Playback%20Design.md)
- [Editor Integration Boundary](Editor%20Integration%20Boundary.md)
- [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md)

scene 전환과 작업공간 경계는 [Godot Scene Workflow](Godot%20Scene%20Workflow.md)가, editor 호출 시점은 [Editor Integration Boundary](Editor%20Integration%20Boundary.md)가, timeline/automation/preview semantics는 각 모델 문서가 authoritative source다.  
이 문서는 그 결정들을 실제 Godot UI 구조로 배치하는 역할만 맡는다.

## Scope

- top-level app root와 scene host
- persistent bezel / alert / dialog host 구조
- `Workspace Selection`의 list/panel 분해
- `AuthoringScene` 내부 workspace router
- `Mixset Editing Workspace`의 timeline/lane/component 계층
- `Music Asset Add & Config Workspace`의 form/panel/component 계층
- shared controller/service node inventory
- overlay / cursor / hover layer 순서
- view-model binding과 mutation gateway 경계

## Out Of Scope

- `MixArgs` / `MusicArgs` semantics 재정의
- theme/color/font/token 재정의
- DSP / preview audio engine 내부 구현
- low-level waveform shader / texture optimization
- `PDJE` render / push 저수준 알고리즘
- BPM transition metadata schema의 세부 의미

## Core Principles

- scene tree는 source of truth가 아니다
- user-facing UI는 `RootDB` data와 editor project entry만 노출하고, `editorDB` raw content는 노출하지 않는다
- persistent shell은 scene content 바깥에서 유지한다
- `AuthoringScene`은 두 child workspace를 router로 교체하는 구조를 쓴다
- view는 wrapper를 직접 호출하지 않고 controller/service를 통해서만 `PDJE`와 상호작용한다
- waveform / STFT job은 background controller에서 처리하고, main thread는 scene graph bind만 담당한다
- preview master waveform은 transient non-cached display data다
- render / push / preview failure는 user-facing feedback으로 노출되며, 실패 상태 자체를 persistence하지 않는다

## Top-Level App Tree

canonical top-level 구조는 아래와 같다.

```text
AppRoot
├─ ServiceHub
│  ├─ WorkspaceSelectionController
│  ├─ EditorSessionController
│  ├─ EditorMutationGateway
│  ├─ PreviewTransportController
│  ├─ WaveformJobController
│  ├─ DialogCoordinator
│  └─ AlertCoordinator
├─ GlobalShellRoot
│  ├─ GlobalTopBezel
│  ├─ LocalBezelHost
│  ├─ GlobalBottomBezel
│  ├─ DialogHost
│  ├─ AlertHost
│  └─ BackgroundTaskQueueHost
└─ SceneHost
   ├─ WorkspaceSelectionScene
   └─ AuthoringScene
```

규칙은 아래와 같다.

- `GlobalShellRoot`는 scene 전환과 무관하게 유지한다
- `SceneHost`는 한 시점에 하나의 거시 scene만 active하게 둔다
- `ServiceHub`는 user-visible widget이 아니라 session/service anchor다

## Shared Service And Controller Nodes

### `WorkspaceSelectionController`

- current root 선택
- editor project list query / open / modify / discard
- `RootDB` track/music list query
- `RootDB` delete action

### `EditorSessionController`

- current editor session lifecycle
- current editor project identity
- current `trackTitle`
- current authoring workspace route

### `EditorMutationGateway`

- `AddLine`
- `deleteLine`
- `getAll`
- save-triggered `render`
- root pin / exit-triggered `pushToRootDB`

### `PreviewTransportController`

- preview button trigger
- `demoPlayInit`
- preview handle lifecycle
- playback cursor feed
- master output lane waveform feed

### `WaveformJobController`

- asset waveform / RGB waveform job scheduling
- background decode / normalization
- progress reporting
- main-thread bind handoff

### `DialogCoordinator`

- confirm dialogs
- warning dialogs
- parameter dialogs
- waveform picker dialogs

### `AlertCoordinator`

- render/lint failure feedback
- global alert routing
- alert click target resolution

## Persistent Shell Structure

shell 구조는 아래를 따른다.

```text
GlobalShellRoot
├─ GlobalTopBezel
├─ LocalBezelHost
├─ GlobalBottomBezel
├─ DialogHost
├─ AlertHost
└─ BackgroundTaskQueueHost
```

규칙은 아래와 같다.

- `GlobalTopBezel`과 `GlobalBottomBezel`은 모든 거시 scene에서 동일 위치 유지
- `LocalBezelHost`는 현재 active scene에 따라 `Selector Local Bezel` 또는 `Authoring Local Bezel`을 표시
- `DialogHost`는 confirm / warning / parameter dialog의 단일 mount point
- `AlertHost`는 global alert / warning / validation entry host
- `BackgroundTaskQueueHost`는 worker job 상태를 읽기 전용으로 표시

## Workspace Selection Structure

`Workspace Selection Scene`의 canonical tree는 아래를 따른다.

```text
WorkspaceSelectionScene
└─ WorkspaceSelectionRoot
   ├─ RootSelectionView
   ├─ EditorProjectListView
   ├─ RootDbTrackListView
   ├─ RootDbMusicListView
   ├─ NewProjectSetupView
   └─ RecentWorkspaceView
```

### `RootSelectionView`

- current root summary 표시
- root 변경 / 새로고침 진입점 제공

### `EditorProjectListView`

- 현재 editor project entry 리스트 표시
- open / modify / discard 액션 제공
- user-facing project browser의 canonical source

### `RootDbTrackListView`

- `RootDB` track entry 리스트 표시
- delete action 제공

### `RootDbMusicListView`

- `RootDB` music entry 리스트 표시
- delete action 제공

### `NewProjectSetupView`

- 새 editor project 생성용 최소 입력 UI
- 입력 필드는 `projectRoot`, `authorName?`, `authorContactEmail?`로 고정한다
- 제출 시 metadata는 text file이 아니라 `PDJE_RelationalDB` 기반 registry에 저장한다
- canonical registry path는 `__SETTING_VAL__EDITOR_PROJECT_REGISTRY_DB_PATH`
- canonical table name은 `__SETTING_VAL__EDITOR_PROJECT_REGISTRY_TABLE_NAME`
- `projectRoot`는 editor project entry의 primary identity로 사용한다

### `RecentWorkspaceView`

- 최근 root / 최근 project 진입점 표시

### Visibility Rule

- user는 `RootDB` track/music과 editor project entry를 본다
- user는 `editorDB` raw table/content를 직접 보지 않는다
- `RootDB` delete와 editor project discard는 별도 confirm dialog를 거친다

## Authoring Scene Structure

`AuthoringScene`의 canonical tree는 아래를 따른다.

```text
AuthoringScene
└─ AuthoringSceneRoot
   ├─ AuthoringWorkspaceRouter
   │  ├─ MixsetEditingWorkspaceRoot
   │  └─ MusicAssetAddConfigWorkspaceRoot
   ├─ InspectorDockHost
   ├─ AssetBrowserDockHost
   ├─ HistoryDockHost
   └─ TransportHost
```

규칙은 아래와 같다.

- `AuthoringWorkspaceRouter`는 한 시점에 하나의 child workspace만 active하게 둔다
- `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`는 같은 `AuthoringScene` 세션을 공유한다
- `InspectorDockHost`, `AssetBrowserDockHost`, `HistoryDockHost`, `TransportHost`는 workspace에 따라 show/hide 또는 read-only mode를 바꿀 수 있다
- `Authoring Local Bezel`은 scene 바깥 shell host가 관리하며, 내부 workspace가 직접 mount하지 않는다

## Mixset Editing Workspace Structure

`Mixset Editing Workspace`의 canonical tree는 아래를 따른다.

```text
MixsetEditingWorkspaceRoot
├─ TransportBar
├─ TimelineViewport
│  ├─ TimelineCameraController
│  ├─ GlobalBpmLaneView
│  ├─ TrackLaneListView
│  │  └─ TrackLaneView*
│  └─ MasterOutputLaneView
├─ InspectorPanel
├─ AssetBrowserPanel
└─ HistoryPanel
```

### `TimelineViewport`

- global x-axis scroll/zoom host
- timeline clipping / viewport transform root
- user-facing block/lane surface의 mount point

### `TimelineCameraController`

- preview 중 master playback cursor follow
- 일반 편집 중 viewport pan/zoom 반영

### `GlobalBpmLaneView`

- workspace-global BPM step command 표시
- display + edit surface
- `BPM_CONTROL` point command만 다룸

### `TrackLaneListView`

- `TrackLaneView`의 세로 리스트 host
- asset 순서 / lane visibility projection 담당

### `TrackLaneView`

각 `TrackLaneView`는 아래 레이어를 가진다.

```text
TrackLaneView
├─ TrackLaneHeader
├─ MusicBlockLayer
├─ BarGridOverlay
├─ CommandTagLayer
├─ AutomationRangeLayer
├─ PitchTagLayer
├─ SelectionOverlayLayer
└─ HoverOverlayLayer
```

#### `TrackLaneHeader`

- asset label
- lane-local status
- lane-level selection/readout

#### `MusicBlockLayer`

- `MusicBlockView` mount
- visible `LOAD -> UNLOAD` container 표시
- empty segment / silent segment 표시

#### `BarGridOverlay`

- derived `BarBlock` access grid 표시
- `beat / subBeat / separate` 접근 anchor 시각화

#### `CommandTagLayer`

- `LOAD`, `UNLOAD`, `CONTROL`, `BATTLE_DJ`, `COMPRESSOR` 등 point command tag 표시

#### `AutomationRangeLayer`

- waveform 위 얇은 반투명 바 + 간소 태그 표시
- automation span stack 처리

#### `PitchTagLayer`

- waveform 재생성 대상이 아닌 `PITCH` tag 표시

#### `SelectionOverlayLayer`

- selection rectangle
- current selection tint

#### `HoverOverlayLayer`

- hover 확장 그래프
- edit/delete affordance

### `MusicBlockView`

각 `MusicBlockView`는 아래 내부 레이어를 가진다.

```text
MusicBlockView
├─ AssetWaveformLayer
├─ EffectiveProjectionLayer
├─ EmptySegmentLayer
└─ InlineCursorReadoutLayer
```

- `AssetWaveformLayer`: registered asset waveform/RGB projection 표시
- `EffectiveProjectionLayer`: supply-affecting command 반영된 projection 표시
- `EmptySegmentLayer`: source 공급 종료 이후 empty 영역 표시
- `InlineCursorReadoutLayer`: local cursor / beat readout 보조 정보

### `MasterOutputLaneView`

`MasterOutputLaneView`는 display-only lane이며 아래 구조를 가진다.

```text
MasterOutputLaneView
├─ PreviewWaveformLayer
└─ PlaybackCursorLayer
```

- `PreviewWaveformLayer`: preview PCM-derived waveform만 표시
- `PlaybackCursorLayer`: workspace 유일 playback cursor 표시
- master preview waveform은 session-local transient data이며 cache하지 않는다

### `InspectorPanel`

- selected tag / block / automation payload readout
- parameter edit entry
- direct wrapper 호출이 아니라 view-model edit 요청만 발행

### `AssetBrowserPanel`

- ready asset list
- asset attach / load 진입점
- asset config workspace 진입 action

### `HistoryPanel`

- history step 목록
- diff / go / undo / redo 진입점

## Music Asset Add & Config Workspace Structure

`MusicAssetAddConfigWorkspaceRoot`의 canonical tree는 아래를 따른다.

```text
MusicAssetAddConfigWorkspaceRoot
├─ SourceImportGateView
├─ SourceValidationPanel
├─ InitialRequiredFieldForm
├─ MetadataEditorPanel
├─ BpmMappingEditorView
├─ WaveformPanelHost
├─ TagPointEditorView
├─ InvalidReturnStatePanel
└─ SaveWarningDialog
```

### `WaveformPanelHost`

`WaveformPanelHost`는 아래 subview를 가진다.

```text
WaveformPanelHost
├─ WaveformDeferredNotice
├─ WaveformBuildProgressView
├─ WaveformCanvasView
├─ WaveformStftResultView
└─ WaveformFailureInlinePanel
```

규칙은 아래와 같다.

- waveform 생성 실패 시 별도 retry-only main state로 분기하지 않는다
- `DraftEditing` 안에서 `WaveformFailureInlinePanel`을 띄우고 retry action을 제공한다
- waveform / STFT 결과는 display/analysis aid이지 authoritative metadata state가 아니다

### `SourceImportGateView`

- DnD zone
- native file picker CTA

### `SourceValidationPanel`

- source file valid/invalid 결과 표시
- rejection reason 표시

### `InitialRequiredFieldForm`

- 초기 필수 메타데이터 입력
- local draft save gate와 직접 연결

### `MetadataEditorPanel`

- title/composer/start BPM/firstBeat 등 수동 입력 UI
- derived/display-only field와 editable field 구분

### `BpmMappingEditorView`

- BPM row 입력/edit surface
- point vs region semantics는 BPM metadata schema 문서가 닫힐 때까지 current workflow rule만 반영

### `TagPointEditorView`

- asset-owned graphical tag 입력 UI
- tag ownership key는 `asset_id`
- 최소 tag taxonomy는 강제하지 않는다

### `InvalidReturnStatePanel`

- return 차단 이유와 수정 유도 UI
- 필수 필드 누락 / validation error / lint feedback을 강하게 표시

## Layering Rule

timeline 계층 순서는 아래를 기본으로 둔다.

1. lane background
2. waveform / block body
3. bar grid / beat access overlay
4. point command tag
5. automation range bar
6. pitch tag
7. selection overlay
8. hover-expanded overlay
9. playback cursor

규칙은 아래와 같다.

- track lane의 authored structure가 master lane 위로 겹쳐 보이면 안 된다
- master playback cursor는 master output lane에서만 moving cursor로 보인다
- hover-expanded graph는 base waveform보다 위에 뜨되, dialog보다 아래에 있어야 한다

## Data Flow And Binding Rule

- view는 wrapper를 직접 호출하지 않는다
- controller/service만 `PDJE` API를 호출한다
- `getAll` 결과는 먼저 controller에서 normalized view-model로 바꾼 뒤 view에 전달한다
- dialog confirm, button click, drag end는 mutation intent signal만 발행한다
- `EditorMutationGateway`가 실제 `AddLine/deleteLine/render/push`를 수행한다
- `WorkspaceSelectionController`가 `RootDB` browser와 editor project list를 동기화한다

## Background Job Rule

- waveform / STFT / decode / image normalization은 worker job에서 실행한다
- `BackgroundTaskQueueHost`는 그 진행 상태를 읽기 전용으로 표시한다
- worker thread는 Godot node tree를 직접 건드리지 않는다
- 최종 `Image` / texture bind와 widget 상태 변경은 main thread에서만 수행한다

## Dialog Inventory

이 구조에서 canonical dialog inventory는 아래와 같다.

- `SaveWarningDialog`
- `ProjectDiscardConfirmDialog`
- `RootDbDeleteConfirmDialog`
- `AlertTargetSelectorDialog`
- `NumericParameterDialog`
- `TupleParameterDialog`
- `WaveformPickerDialog`

모든 dialog는 `DialogHost` 아래에서 열고, `DialogCoordinator`가 생명주기를 관리한다.

## Reusable Component Inventory

- `IconTextActionButton`
- `StatusBadge`
- `InlineFailurePanel`
- `ReadonlyLabelRow`
- `SectionCard`
- `LaneHeaderStrip`
- `WaveformCanvasView`
- `TagChip`
- `AutomationRangeTag`
- `PlaybackCursorView`

## Summary

`Godot UI Structure`는 아래처럼 닫힌다.

- top-level은 `AppRoot / ServiceHub / GlobalShellRoot / SceneHost` 구조를 따른다
- `Workspace Selection`은 `RootDB` browser와 editor project list를 사용자에게 노출한다
- `editorDB` raw content는 user-facing list로 노출하지 않는다
- `AuthoringScene`은 `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`를 child workspace router로 교체한다
- `Mixset Editing`은 `TimelineViewport / GlobalBpmLaneView / TrackLaneView / MasterOutputLaneView / Inspector / AssetBrowser / History` 구조를 가진다
- `Music Asset Add & Config`는 import/form/waveform/tag/invalid-state panel로 구성된다
- waveform / STFT job은 background controller에서 실행하고, main thread는 최종 bind만 수행한다
- 모든 `PDJE` 호출은 controller/service boundary를 통해서만 수행한다
