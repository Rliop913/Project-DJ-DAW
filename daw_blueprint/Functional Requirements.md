# Functional Requirements

## Purpose

이 문서는 `Project DJ DAW`가 사용자에게 반드시 제공해야 하는 기능 요구사항을 checklist 형태로 고정한다.

이 문서의 목적은 아래를 분리하는 것이다.

- 이미 닫힌 workflow/model 문서를 구현 가능한 기능 요구사항으로 재정리
- `Godot UI Structure`가 어떤 기능을 실제로 제공해야 하는지 명시
- `PDJE` 공식 editor workflow와 현재 blueprint 사이의 기능 경계를 일치시킴

즉, 이 문서는 narrative 설명이 아니라 **구현 대상 기능의 기준표**다.

## Primary References

이 문서는 아래 기준을 함께 따른다.

- 공식 `PDJE` 문서:
  - [Editor_Workflows](https://rliop913.github.io/Project-DJ-Engine/Editor_Workflows.html)
  - [Editor_Format](https://rliop913.github.io/Project-DJ-Engine/Editor_Format.html)
  - [PDJE_For_AI_Agents](https://rliop913.github.io/Project-DJ-Engine/PDJE_For_AI_Agents.html)
  - [Getting Started](https://rliop913.github.io/Project-DJ-Engine/Getting%20Started.html)
- 로컬 blueprint 문서:
  - [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
  - [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
  - [Godot UI Structure](Godot%20UI%20Structure.md)
  - [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
  - [Automation Lane Model](Automation%20Lane%20Model.md)
  - [Preview Playback Design](Preview%20Playback%20Design.md)
  - [Editor Integration Boundary](Editor%20Integration%20Boundary.md)
  - [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
  - [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)

공식 문서 기준에서 editor는 project-local state, typed mutation, render/push, preview, history를 소유한다.  
이 요구사항 문서는 그 editor workflow를 Godot UI에서 어떤 기능으로 노출해야 하는지 적는다.

## Scope

이 문서는 아래 기능 요구를 다룬다.

- workspace selection
- editor project open / modify / discard
- `RootDB` track/music browser
- music asset import / config
- mixset timeline authoring
- automation authoring
- preview playback
- save / render / root push
- history / resync
- validation / failure feedback

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- low-level DSP 품질 기준
- 메모리 / latency / scalability budget
- shader / texture optimization
- BPM transition metadata schema의 내부 의미
- loop semantics의 최종 의미론

이 항목은 [Non-Functional Requirements](Non-Functional%20Requirements.md) 또는 후속 semantics 문서에서 닫는다.

## Requirement Format

각 요구사항은 아래 의미를 가진다.

- `FR-*`는 제품이 반드시 제공해야 하는 기능이다
- `Must`는 MVP 범위에서 빠지면 안 되는 항목이다
- 문서에 없는 기능은 기본적으로 현재 MVP 범위 밖으로 본다

## FR-WS: Workspace Selection Requirements

- `FR-WS-01` 시스템은 `Workspace Selection Scene`을 시작 진입 화면으로 제공해야 한다.
- `FR-WS-02` 사용자는 현재 `PDJE` root를 선택하거나 변경할 수 있어야 한다.
- `FR-WS-03` 시스템은 현재 root 기준 editor project 목록을 사용자에게 보여줘야 한다.
- `FR-WS-04` 사용자는 editor project를 열 수 있어야 한다.
- `FR-WS-05` 사용자는 editor project를 수정 대상로 다시 진입할 수 있어야 한다.
- `FR-WS-06` 사용자는 editor project를 폐기할 수 있어야 한다.
- `FR-WS-07` 시스템은 `RootDB` 안의 track 데이터를 리스트업해야 한다.
- `FR-WS-08` 시스템은 `RootDB` 안의 music 데이터를 리스트업해야 한다.
- `FR-WS-09` 사용자는 선택한 `RootDB` track entry를 삭제할 수 있어야 한다.
- `FR-WS-10` 사용자는 선택한 `RootDB` music entry를 삭제할 수 있어야 한다.
- `FR-WS-11` 시스템은 최근 root 또는 최근 project 진입점을 제공할 수 있어야 한다.
- `FR-WS-12` `editorDB` raw content는 user-facing browser로 직접 노출하면 안 된다.
- `FR-WS-13` 사용자는 새 editor project 생성 시 `projectRoot`를 반드시 입력할 수 있어야 한다.
- `FR-WS-14` 사용자는 새 editor project 생성 시 `authorName`, `authorContactEmail`을 선택적으로 입력할 수 있어야 한다.
- `FR-WS-15` editor project metadata는 text file이 아니라 `PDJE_RelationalDB` 기반 registry에 저장되어야 한다.
- `FR-WS-16` canonical editor project metadata 저장 위치는 Godot persistent path `user://` 아래의 고정 registry DB여야 한다.
- `FR-WS-17` `Workspace Selection`은 이 registry를 통해 editor project metadata를 저장, 조회, 삭제할 수 있어야 한다.

## FR-SESSION: Authoring Session Requirements

- `FR-SESSION-01` 시스템은 `InitEditor()`를 통해 authoring session을 초기화할 수 있어야 한다.
- `FR-SESSION-02` 시스템은 기존 editor project를 다시 열 수 있어야 한다.
- `FR-SESSION-03` `Workspace Selection`에서 선택한 editor project는 같은 authoring session으로 `AuthoringScene`에 전달되어야 한다.
- `FR-SESSION-04` `AuthoringScene`은 `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`를 같은 session 안에서 교체할 수 있어야 한다.
- `FR-SESSION-05` `Music Asset Add & Config`에서 복귀해도 authoring session 자체는 reset되면 안 된다.
- `FR-SESSION-06` 복귀 시 `Mixset Editing`의 scroll/zoom/selection 같은 단기 UI 상태는 가능한 한 복원되어야 한다.

## FR-ASSET: Music Asset Preparation Requirements

- `FR-ASSET-01` 사용자는 로컬 음악 파일을 drag-and-drop 또는 native file picker로 가져올 수 있어야 한다.
- `FR-ASSET-02` 시스템은 source file validation을 수행해야 한다.
- `FR-ASSET-03` 유효하지 않은 source file은 asset rejection으로 처리되어야 한다.
- `FR-ASSET-04` rejection 시 사용자는 같은 workspace에서 파일을 다시 고르거나 수정할 수 있어야 한다.
- `FR-ASSET-05` 미등록 로컬 파일은 `Music Asset Add & Config`를 거치기 전까지 mix editor에서 직접 참조할 수 없어야 한다.
- `FR-ASSET-06` 사용자는 `Track Title`, `Composer`, `Start BPM`, `First Beat` 등 필수 입력값을 수동으로 입력할 수 있어야 한다.
- `FR-ASSET-07` 시스템은 필수 메타데이터를 자동 확정하면 안 된다.
- `FR-ASSET-08` 시스템은 초기 local draft save와 실제 `PDJE` registration을 분리해야 한다.
- `FR-ASSET-09` 시스템은 `ConfigNewMusic(...)`를 통해 music entry registration을 수행할 수 있어야 한다.
- `FR-ASSET-10` 시스템은 첫 BPM row를 music mutation으로 추가할 수 있어야 한다.
- `FR-ASSET-11` 사용자는 BPM transition metadata를 입력할 수 있어야 한다.
- `FR-ASSET-11A` BPM mapping은 항상 point row만 허용해야 하며, region change 방식은 지원하지 않아야 한다.
- `FR-ASSET-11B` BPM transition metadata row는 `bpm:Text`, `beat:Int64`, `subBeat:Int64`, `separate:Int64` schema를 따라야 한다.
- `FR-ASSET-12` 사용자는 asset-owned graphical tag를 입력/수정/삭제할 수 있어야 한다.
- `FR-ASSET-13` tag ownership key는 `asset_id`여야 한다.
- `FR-ASSET-14` 같은 source audio라도 `asset_id`가 다르면 별도 asset으로 다뤄야 한다.
- `FR-ASSET-15` 시스템은 condition이 충족된 뒤에만 asset waveform / RGB waveform 표시를 시도해야 한다.
- `FR-ASSET-16` waveform이 없더라도 metadata editing과 registration flow는 계속 가능해야 한다.
- `FR-ASSET-17` waveform generation 실패는 inline failure / retry UI로 노출되어야 하며, config 편집 자체를 막으면 안 된다.
- `FR-ASSET-18` `ready_for_mixset`는 `render(..., lint_msg)` 성공 이후에만 `true`가 될 수 있어야 한다.
- `FR-ASSET-19` render 실패 시 사용자는 `lint_msg`를 보고 같은 컨텍스트에서 계속 수정할 수 있어야 한다.

## FR-TIMELINE: Mixset Authoring Requirements

- `FR-TIMELINE-01` 시스템은 `Workspace -> TrackBlock -> MusicBlock -> BarBlock` 계층을 시각화해야 한다.
- `FR-TIMELINE-02` workspace는 `global parameter lane 1개 + track lane N개 + master output lane 1개` 구조를 보여줘야 한다.
- `FR-TIMELINE-03` global parameter lane에서는 `BPM_CONTROL` point command를 편집할 수 있어야 한다.
- `FR-TIMELINE-04` track lane에서는 `LOAD`, `UNLOAD`, `CONTROL`, `BATTLE_DJ`, `COMPRESSOR`, automation range를 편집할 수 있어야 한다.
- `FR-TIMELINE-05` 사용자는 등록된 music asset을 timeline에 배치할 수 있어야 한다.
- `FR-TIMELINE-06` `LOAD` payload는 선택한 registered asset에서 파생되어야 한다.
- `FR-TIMELINE-07` 사용자는 point command를 생성, 수정, 삭제할 수 있어야 한다.
- `FR-TIMELINE-08` 사용자는 span automation을 생성, 수정, 삭제할 수 있어야 한다.
- `FR-TIMELINE-09` 시간 접근은 `beat / subBeat / separate` grid를 통해서만 제공되어야 한다.
- `FR-TIMELINE-10` finer control이 필요할 때는 free offset이 아니라 `separator` 조정 UI를 제공해야 한다.
- `FR-TIMELINE-11` 같은 `asset_id`는 하나의 `TrackBlock`만 가져야 한다.
- `FR-TIMELINE-11A` 같은 `TrackBlock` 안에서는 같은 `asset_id`의 비연속 audible use를 복수 `MusicBlock`으로 표현할 수 있어야 한다.
- `FR-TIMELINE-11B` `PAUSE`는 source supply cut command로만 동작해야 하며, resume after pause를 의미하면 안 된다.
- `FR-TIMELINE-12` `ready_for_mixset = true`가 아닌 asset은 load 대상으로 쓸 수 없어야 한다.
- `FR-TIMELINE-13` loop-like 편집 기능은 새로운 `PDJE` extension command가 아니라, 기존 `CUE` 기반 반복 동작을 감싸는 GUI abstraction으로 제공되어야 한다.

## FR-AUTO: Automation Requirements

- `FR-AUTO-01` 시스템은 `FILTER`, `EQ`, `DISTORTION`, `VOL`, `ECHO`, `OSC_FILTER`, `FLANGER`, `PHASER`, `TRANCE`, `PANNER`, `ROLL`, `ROBOT`를 span automation target으로 지원해야 한다.
- `FR-AUTO-02` 시스템은 `BPM_CONTROL`을 global BPM point command로 지원해야 한다.
- `FR-AUTO-03` 시스템은 `CONTROL`, `LOAD`, `UNLOAD`, `BATTLE_DJ`, `COMPRESSOR`를 point-command 중심으로 지원해야 한다.
- `FR-AUTO-04` 사용자는 start/end span을 first click / second click으로 지정할 수 있어야 한다.
- `FR-AUTO-05` 역방향 선택은 자동 swap되어야 한다.
- `FR-AUTO-06` 중간 공백이 있는 disjoint selection은 허용하면 안 된다.
- `FR-AUTO-07` 8point automation target에 대해서는 popup editor를 제공해야 한다.
- `FR-AUTO-08` 기본 interpolation은 `ITPL_COSINE`이어야 한다.
- `FR-AUTO-09` `ITPL_FLAT`에서는 한 point 변경이 다른 point에 함께 반영되는 UI를 제공해야 한다.
- `FR-AUTO-10` `first/second/third` payload 입력은 공통 parameter dialog 체계로 제공해야 한다.
- `FR-AUTO-11` PCM frame payload가 필요한 경우 waveform-linked picker를 제공해야 한다.
- `FR-AUTO-12` tuple payload가 필요한 경우 tuple arity에 맞는 dialog를 제공해야 한다.
- `FR-AUTO-13` 생성된 automation은 waveform 위의 얇은 반투명 bar + 간소 tag로 표현되어야 한다.
- `FR-AUTO-14` hover 시 확장 그래프와 edit/delete affordance를 제공해야 한다.

## FR-PREVIEW: Preview Requirements

- `FR-PREVIEW-01` 사용자는 explicit preview 버튼으로만 preview를 시작할 수 있어야 한다.
- `FR-PREVIEW-02` 시스템은 `demoPlayInit(...)`를 사용해 preview handle을 생성해야 한다.
- `FR-PREVIEW-03` 시스템은 handle과 연결된 data line에서 PCM frame을 추출할 수 있어야 한다.
- `FR-PREVIEW-04` 추출한 PCM은 `PCM -> Waveform` 경로로 master output lane에 표시되어야 한다.
- `FR-PREVIEW-05` preview master lane은 현재 `waveform only`를 canonical visualization으로 사용해야 한다.
- `FR-PREVIEW-06` master preview waveform은 cache하지 않아야 한다.
- `FR-PREVIEW-07` moving playback cursor는 master output lane에만 존재해야 한다.
- `FR-PREVIEW-08` preview 중 camera는 master cursor를 선형 보간 애니메이션으로 따라가야 한다.
- `FR-PREVIEW-09` preview 중 구조 편집, automation 편집, command 변경은 비활성화되어야 한다.
- `FR-PREVIEW-10` preview 중 사용자는 hover, selection, read-only inspection을 계속 할 수 있어야 한다.
- `FR-PREVIEW-11` preview init 실패 시 user-facing error feedback을 제공해야 한다.

## FR-SAVE: Save / Render / Push Requirements

- `FR-SAVE-01` row-level authoring이 완성되면 시스템은 즉시 `AddLine()`을 호출해야 한다.
- `FR-SAVE-02` row 삭제가 확정되면 시스템은 즉시 `deleteLine()`을 호출해야 한다.
- `FR-SAVE-03` authoritative resync가 필요할 때 시스템은 `getAll()`을 호출해야 한다.
- `FR-SAVE-04` `SaveIcon`은 `render(trackTitle, ROOTDB, lint_msg)`를 수행해야 한다.
- `FR-SAVE-05` render 실패 시 save 완료로 간주하면 안 된다.
- `FR-SAVE-06` render 실패 시 `lint_msg`를 user-facing validation feedback으로 노출해야 한다.
- `FR-SAVE-07` `RootPinAction`은 explicit `pushToRootDB(...)` trigger여야 한다.
- `FR-SAVE-08` track editor exit 시 시스템은 auto push attempt를 할 수 있어야 한다.
- `FR-SAVE-09` `pushToRootDB` 성공 후 `Workspace Selection`의 `RootDB` browser는 resync되어야 한다.

## FR-HISTORY: History Requirements

- `FR-HISTORY-01` 시스템은 `Undo`, `Redo`, `Go`를 통한 history navigation을 제공해야 한다.
- `FR-HISTORY-02` 시스템은 history readout UI를 제공해야 한다.
- `FR-HISTORY-03` 필요 시 `GetDiff()` 결과를 사용자에게 읽기 가능한 형태로 보여줄 수 있어야 한다.
- `FR-HISTORY-04` history 이동 후에는 UI가 authoritative state로 다시 동기화되어야 한다.

## FR-FEEDBACK: Validation And Failure Feedback Requirements

- `FR-FEEDBACK-01` invalid save 상태는 subscene 내부에서 강하게 표시되어야 한다.
- `FR-FEEDBACK-02` `SaveWarningDialog`는 누락 필드와 수정 필요 항목을 설명해야 한다.
- `FR-FEEDBACK-03` render/lint 실패는 global alert 또는 validation feedback으로 보여줘야 한다.
- `FR-FEEDBACK-04` alert click은 target이 하나면 즉시 이동해야 한다.
- `FR-FEEDBACK-05` alert click target이 여러 개면 selector dialog를 먼저 띄워야 한다.
- `FR-FEEDBACK-06` failure state 자체는 persistence하면 안 된다.
- `FR-FEEDBACK-07` 사용자는 실패 후 현재 입력을 잃지 않고 바로 수정/재시도할 수 있어야 한다.
- `FR-FEEDBACK-08` autosave failure는 현재 서브씬 내부에서만 노출되어야 하며, global alert queue에 올리지 않아야 한다.

## FR-VISUALIZATION: Structural Visualization Requirements

- `FR-VISUALIZATION-01` `Workspace Selection`은 `RootDB` track/music과 editor project entry를 사용자에게 보여줘야 한다.
- `FR-VISUALIZATION-02` `editorDB` raw content는 user-facing list로 보이면 안 된다.
- `FR-VISUALIZATION-03` `Mixset Editing`은 timeline, lane, block, tag, overlay 구조를 분리해 표시해야 한다.
- `FR-VISUALIZATION-04` `Music Asset Add & Config`는 source import, metadata form, waveform panel, BPM mapping, tag editor, invalid state panel을 분리해 보여줘야 한다.
- `FR-VISUALIZATION-05` persistent shell은 `Global Top Bezel -> Local Bezel -> Scene Content -> Global Bottom Bezel` 구조를 유지해야 한다.

## Open Questions

현재 기능 요구 수준에서 남겨 두는 항목은 없다.

## Summary

`Functional Requirements`의 핵심은 아래처럼 요약된다.

- 사용자는 `Workspace Selection`에서 root/project/`RootDB` 대상을 선택하고 관리할 수 있어야 한다
- 사용자는 음악 자산을 등록하고, mix timeline과 automation을 편집할 수 있어야 한다
- 사용자는 preview, render, push, history를 GUI에서 명시적으로 사용할 수 있어야 한다
- 실패와 validation은 user-facing feedback으로 노출되어야 한다
- 모든 기능은 공식 `PDJE` editor workflow와 현재 blueprint semantics를 벗어나지 않아야 한다
