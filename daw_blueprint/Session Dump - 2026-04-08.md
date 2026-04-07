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

### Music Asset Add & Config

- import는 `DnD` 또는 native file picker
- 메타데이터 자동 확정 금지
- 필수 필드 디폴트 금지
- 초기 app-local draft save와 실제 `PDJE registration`을 분리한다
- `ready_for_mixset`는 project-local readiness일 뿐 root DB searchable 상태와 같지 않다
- waveform은 조건부 capability이며, search-visible 여부와 분리해서 생각해야 한다

## Mixset Timeline Model State

### Hierarchy

- `Workspace -> TrackBlock -> MusicBlock -> BarBlock`

### TrackBlock

- `TrackBlock = music asset당 정확히 하나의 asset-owned lane`
- user는 `TrackBlock.global_bpm_map`만 직접 편집한다
- local BPM map은 mix editor의 직접 편집 대상이 아니다

### MusicBlock

- `MusicBlock`은 `LOAD -> UNLOAD` 전체 길이를 가진다
- 실제 곡 길이보다 길어도 된다
- 곡이 먼저 끝나면 남는 구간은 empty block
- `PAUSE` 이후는 기본적으로 source supply cut
- `resume after pause`는 기본 시나리오에서 제거했다

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

## Document Status Snapshot

### Strongly Closed

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)

### Not Yet Written Or Not Yet Closed

- `Automation Lane Model`
- `Preview Playback Design`
- `Persistence And Translation Layer`
- `Library And Metadata Model`
- `Godot UI Structure`
- `Functional Requirements`
- `Non-Functional Requirements`
- `Milestone Plan`

## Immediate Next Recommended Order

1. `Automation Lane Model`
2. `Preview Playback Design`
3. `Persistence And Translation Layer`
4. `Library And Metadata Model`
5. `Godot UI Structure`

자세한 backlog는 [todo-list](todo-list.md)를 보면 된다.

## Open Questions Still Alive

- `SCRATCH/SPIN/REV/ECHO/PITCH`를 최종 `PDJE MixArgs` row로 어떻게 lower할지
- `global_bpm_map`의 row schema와 interpolation rule
- 같은 asset의 복수 비연속 사용을 현재 `MusicBlock` segmentation만으로 충분히 볼지
- `BarBlock` 내부 EQ/FX 수정이 bar 전체 단위인지, bar 내부 offset까지 허용할지
- preview state와 effective waveform projection sync 방식

## Cautions For Next Session

- 상용 제품 실명 표기는 문서에서 피하고 일반화된 표현을 쓰는 방향으로 유지 중이다
- `PITCH`는 파형 재생성 대상이 아니라 tag UI 대상이다
- `PDJE_MIR` 호출 가능 여부와 `ready_for_mixset`는 같은 것이 아니다
- `Music Asset Add & Config`에서 identity field를 registration 이후 인플레이스로 수정하는 흐름은 현재 binding 기준으로 가정하면 안 된다

## One-Line Restart Summary

`2026-04-08` 기준 blueprint는 `PDJE`를 기반으로 한 Godot DJ mixset authoring tool의 상위 구조와 timeline semantics가 많이 닫혀 있으며, 다음 핵심 작업은 `automation schema`, `preview model`, `PDJE translation layer`를 문서화하는 것이다.
