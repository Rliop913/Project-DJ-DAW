# Non-Functional Requirements

## Purpose

이 문서는 `Project DJ DAW`가 이미 닫은 기능과 의미론을 어떤 품질 수준으로 제공해야 하는지 고정한다.

핵심은 아래를 분리하는 것이다.

- [Functional Requirements](Functional%20Requirements.md)의 기능 checklist를 품질 기준으로 변환
- preview, waveform job, render/push, resync가 어떤 안정성/반응성 규칙을 따라야 하는지 명시
- `RootDB` / `editor DB` / app-side UI state 사이의 일관성 원칙을 품질 요구사항으로 못 박기

즉, 이 문서는 **무엇을 할 수 있는가**가 아니라 **얼마나 안정적이고 일관되게 동작해야 하는가**를 적는 기준표다.

## Primary References

이 문서는 아래 기준을 함께 따른다.

- 공식 `PDJE` 문서:
  - [Editor_Workflows](https://rliop913.github.io/Project-DJ-Engine/Editor_Workflows.html)
  - [Editor_Format](https://rliop913.github.io/Project-DJ-Engine/Editor_Format.html)
  - [PDJE_For_AI_Agents](https://rliop913.github.io/Project-DJ-Engine/PDJE_For_AI_Agents.html)
  - [Getting Started](https://rliop913.github.io/Project-DJ-Engine/Getting%20Started.html)
- 로컬 blueprint 문서:
  - [Functional Requirements](Functional%20Requirements.md)
  - [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
  - [Preview Playback Design](Preview%20Playback%20Design.md)
  - [Godot UI Structure](Godot%20UI%20Structure.md)
  - [Editor Integration Boundary](Editor%20Integration%20Boundary.md)
  - [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
  - [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
  - [Settings](Settings.md)

## Scope

이 문서는 아래 품질 속성을 다룬다.

- UI responsiveness
- preview init / playback stability
- waveform / STFT background job behavior
- render / push / autosave durability
- large project scaling baseline
- memory / image buffer hygiene
- authoritative state consistency
- failure / progress feedback visibility

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- loop semantics의 최종 의미론
- BPM transition metadata schema의 내부 의미
- BPM mapping point vs region semantics
- 같은 `asset_id`의 복수 비연속 사용 segmentation semantics
- low-level DSP algorithm 품질
- shader / texture renderer 구현 세부

## Requirement Format

각 요구사항은 아래 의미를 가진다.

- `NFR-*`는 제품이 충족해야 하는 non-functional requirement다
- `Must`는 MVP에서도 지켜야 하는 품질 기준이다
- 수치형 기준은 target baseline에 대한 품질 보장선으로 본다

## Target Quality Baseline

이 문서의 품질 기준은 아래 baseline을 대상으로 한다.

- workspace lane family는 `global parameter lane 1개 + track lane 최대 32개 + master output lane 1개`
- 긴 DJ mixset authoring을 전제로 하며, 수 시간 길이의 timeline을 다룰 수 있어야 한다
- combined command / tag / automation item은 `2000`개 수준까지 catastrophic degradation 없이 다룰 수 있어야 한다
- background waveform / STFT job, preview, save / render / push가 같은 세션 안에서 반복될 수 있어야 한다

이 baseline은 “반드시 이 수를 넘겨야 한다”가 아니라, **적어도 이 정도 규모에서는 구조적으로 무너지면 안 된다**는 뜻이다.

## NFR-RESP: Responsiveness Requirements

- `NFR-RESP-01` hover, selection, focus change, dialog open, alert reveal 같은 경량 UI 상호작용은 `100ms` 안에 첫 시각 피드백을 보여줘야 한다.
- `NFR-RESP-02` scroll, zoom, separator wheel 입력은 target baseline에서도 체감상 연속 편집이 가능해야 하며, 명백한 hard-freeze를 일으키면 안 된다.
- `NFR-RESP-03` `250ms`를 넘길 가능성이 있는 작업은 idle처럼 보여주면 안 되고, 즉시 `Preparing`, `Saving`, `Rendering`, `Generating` 같은 명시적 상태로 전환해야 한다.
- `NFR-RESP-04` scene / workspace route 전환은 persistent shell continuity를 깨면 안 되며, 기존 session context가 사라진 것처럼 보이게 하면 안 된다.

## NFR-PREVIEW: Preview Stability Requirements

- `NFR-PREVIEW-01` preview button click 이후 UI는 `100ms` 안에 `Preparing` 상태를 보여줘야 한다.
- `NFR-PREVIEW-02` target baseline에서 preview는 합리적 시간 안에 `Playing` 또는 `Error`로 귀결되어야 하며, `Preparing` 상태에 무기한 머물면 안 된다.
- `NFR-PREVIEW-03` preview 중 audible output, master playback cursor, master output waveform은 같은 preview session을 공유해야 하며, 서로 다른 시점을 가리키면 안 된다.
- `NFR-PREVIEW-04` preview 중 camera follow는 cursor 추적성을 잃을 정도로 끊기거나 점프하면 안 된다.
- `NFR-PREVIEW-05` PCM tap이 실패해도 audio handle이 살아 있다면 session 전체를 폐기하지 말고 `cursor-only fallback`으로 강등할 수 있어야 한다.
- `NFR-PREVIEW-06` preview 종료 또는 restart 이후 obsolete preview waveform data는 즉시 재사용 불가 상태로 내려가야 하며, 이후 편집 상태와 섞이면 안 된다.

## NFR-BGJOB: Background Job Requirements

- `NFR-BGJOB-01` waveform render, RGB waveform build, STFT, decode, normalization 같은 무거운 작업은 main thread blocking job으로 실행하면 안 된다.
- `NFR-BGJOB-02` background job 결과를 scene graph에 bind하는 마지막 단계만 main thread에서 수행해야 한다.
- `NFR-BGJOB-03` zoom 변경, waveform 재요청, STFT 재요청이 연속으로 들어오면 `latest request wins` 정책을 따라야 한다.
- `NFR-BGJOB-04` superseded job은 취소하거나, 취소가 어렵다면 결과를 폐기해야 한다. 오래된 결과가 최신 UI를 덮어쓰면 안 된다.
- `NFR-BGJOB-05` background job은 최소한 `queued / running / succeeded / failed` 수준의 상태를 user-facing queue 또는 panel에 드러낼 수 있어야 한다.

## NFR-SAVE: Durability And Persistence Robustness Requirements

- `NFR-SAVE-01` row-level authoring 완료 후의 `AddLine` / `deleteLine` 반영은 silent drop되면 안 된다. 실패 시 사용자는 즉시 failure feedback을 받아야 한다.
- `NFR-SAVE-02` `render(..., lint_msg)` 실패는 save success나 `ready_for_mixset = true`로 잘못 해석되면 안 된다.
- `NFR-SAVE-03` `pushToRootDB(...)` 실패는 root-visible 승격 실패일 뿐이며, editor-local working state 손실로 이어지면 안 된다.
- `NFR-SAVE-04` autosave는 app-local draft 보호 수단으로만 동작해야 하며, autosave failure는 현재 서브씬 내부에서만 경고하고 global alert queue로 승격하지 않는다.
- `NFR-SAVE-05` failure state 자체는 persistence 대상이 아니며, 재시작 후 authoritative source처럼 복원되면 안 된다.
- `NFR-SAVE-06` save, push, history move, reopen 이후 UI는 필요 시 `getAll()` 기반 authoritative resync를 통해 최신 editor state로 복원되어야 한다.

## NFR-SCALE: Scale And Throughput Requirements

- `NFR-SCALE-01` target baseline인 `32 track lane`과 `2000`개 수준의 combined item에서도 timeline browse, selection, zoom, preview trigger가 실사용 가능한 수준을 유지해야 한다.
- `NFR-SCALE-02` off-screen lane, overlay, dialog-hosted heavy view는 eager full-materialization을 강제하지 않아야 하며, 필요 시 lazy bind 또는 virtualization을 허용해야 한다.
- `NFR-SCALE-03` repeated preview, repeated waveform regeneration, repeated resync가 누적되더라도 동일 scene tree 안에 orphaned lane/view/job 결과가 쌓이면 안 된다.

## NFR-MEM: Memory And Buffer Hygiene Requirements

- `NFR-MEM-01` master preview waveform은 캐시하지 않으며, session-local transient visualization으로만 유지해야 한다.
- `NFR-MEM-02` registered asset waveform / RGB waveform의 장기 캐시는 core wrapper와 cache DB가 맡고, Godot UI가 동일 자산의 장기 복사본을 별도 cache 계층으로 중복 보유하면 안 된다.
- `NFR-MEM-03` stale preview buffer, superseded waveform job result, obsolete decoded image array는 가능한 한 빠르게 폐기되어야 한다.
- `NFR-MEM-04` 같은 시점에 필요 없는 `Array[Image]`, encoded buffer, hover expansion graph data를 무한히 누적하면 안 된다.
- `NFR-MEM-05` timeline visualization은 가능한 경우 기존 image array 재사용을 우선하고, canonical live preview path처럼 실제 PCM이 필요한 경우에만 새 waveform을 생성해야 한다.

## NFR-CONSISTENCY: Authoritative State Consistency Requirements

- `NFR-CONSISTENCY-01` source of truth 우선순위는 항상 `RootDB > editor DB > app-side ephemeral UI state`여야 한다.
- `NFR-CONSISTENCY-02` UI의 `saved`, `rendered`, `pushed`, `ready_for_mixset` 표시는 widget-local 추정치가 아니라 authoritative state를 기준으로 갱신되어야 한다.
- `NFR-CONSISTENCY-03` history 이동, save, push, scene re-entry, root browser refresh 이후 stale widget state가 authoritative state를 덮어쓰면 안 된다.
- `NFR-CONSISTENCY-04` `editorDB` raw content는 user-facing browser에 노출되지 않아야 하며, 내부 임시 저장소라는 역할을 유지해야 한다.

## NFR-FEEDBACK: Failure And Progress Visibility Requirements

- `NFR-FEEDBACK-01` render, preview init, push, registration, waveform generation 실패는 사용자에게 action 가능한 피드백으로 보여야 한다.
- `NFR-FEEDBACK-02` 어떤 작업이 진행 중인지 사용자가 구분할 수 있도록 save/render/preview/waveform build에는 명시적 busy or progress state가 필요하다.
- `NFR-FEEDBACK-03` render/lint failure는 관련 편집 컨텍스트에서 수정 가능한 형태로 노출되어야 하며, 단순 로그 출력으로 끝나면 안 된다.
- `NFR-FEEDBACK-04` autosave failure는 현재 서브씬 내부에서 강하게 보이되, global alert stack을 오염시키지 않아야 한다.
- `NFR-FEEDBACK-05` failure 이후 사용자는 현재 입력을 잃지 않고 즉시 수정 / 재시도할 수 있어야 한다.

## Summary

`Non-Functional Requirements`의 핵심은 아래처럼 요약된다.

- target baseline은 `32 track lane + 2000 item` 수준의 대규모 authoring 세션이다
- UI는 실용형 반응성을 유지해야 하고, 무거운 작업은 반드시 async + progress state로 보이게 해야 한다
- waveform / STFT / preview 관련 오래된 작업 결과는 최신 UI를 덮어쓰면 안 된다
- autosave failure는 로컬 경고만 사용하고, failure state 자체는 persistence하지 않는다
- authoritative state는 항상 `RootDB > editor DB > UI ephemeral state` 순서를 따른다
