# Todo List

## Purpose

이 문서는 현재 blueprint에서 아직 닫히지 않은 문서와, 이미 작성된 문서 안에 남아 있는 핵심 open question을 작업 순서 중심으로 정리한다.

이 문서는 설계 backlog이 아니라, **다음에 실제로 닫아야 할 문서 작업 목록**이다.

## Highest Priority

### 1. Automation Lane Model

닫아야 하는 이유:

- `Mixset Timeline Model`에서 `BarBlock`이 EQ / FX / VOL / BPM 접근 anchor라고 정의됐지만, 실제 automation row schema는 아직 없다
- `global_bpm_map`도 결국 lane schema로 구체화되어야 한다

닫아야 할 항목:

- automation lane 종류
- lane별 target parameter
- point / span / curve rule
- `BPM_CONTROL` lane schema
- EQ / FX lane의 bar 단위 접근 규칙
- interpolation rule
- `MixArgs` lowering rule

### 2. Preview Playback Design

닫아야 하는 이유:

- 현재 문서들은 preview의 존재는 정의하지만, timeline state와 playback state를 어떻게 동기화할지는 아직 없다
- `CUE`, `PAUSE`, `SCRATCH`, `SPIN`, `REV`, `ECHO`, `PITCH`가 preview에서 어떤 방식으로 재현되는지 별도 문서가 필요하다

닫아야 할 항목:

- preview transport lifecycle
- timeline cursor와 playback cursor 관계
- block highlight / playhead 동기화
- effective waveform projection과 playback state 연결
- preview 중 허용 편집 범위
- error / fallback behavior

### 3. Persistence And Translation Layer

닫아야 하는 이유:

- 현재 문서는 모델 의미를 많이 고정했지만, 그것을 어떤 intermediate structure와 어떤 순서로 `PDJE` row로 내릴지는 아직 비어 있다

닫아야 할 항목:

- app model -> intermediate compiled model
- intermediate model -> `EDIT_ARG_MUSIC`
- intermediate model -> `EDIT_ARG_MIX`
- deterministic ordering rule
- `CONTROL(CUE/PAUSE)` lower rule
- battle modifier lower rule
- asset local BPM map과 track global BPM lane compile 순서

## Medium Priority

### 4. Library And Metadata Model

닫아야 하는 이유:

- `music asset`의 준비 상태, 프로젝트 내부 참조, root DB visibility, waveform preview ref, tag data의 경계가 아직 분산되어 있다

닫아야 할 항목:

- asset identity
- asset reference rule
- `ready_for_mixset`
- project-local draft vs PDJE-visible state
- waveform preview cache ref
- tag metadata ownership

### 5. Godot UI Structure

닫아야 하는 이유:

- scene/workflow 문서는 있지만, 실제 panel/widget/component 경계 문서는 아직 없다

닫아야 할 항목:

- `TrackLaneView`
- `MusicBlockView`
- `BarBlockView`
- waveform projection renderer
- pitch tag UI
- command tag / segment overlay renderer
- reusable component tree

### 6. Functional Requirements

닫아야 하는 이유:

- 현재는 narrative 문서가 중심이고, 구현 가능한 requirement checklist 문서가 없다

닫아야 할 항목:

- must-have authoring actions
- save / validation requirements
- block manipulation requirements
- waveform interaction requirements
- preview requirements
- import/config requirements

### 7. Non-Functional Requirements

닫아야 하는 이유:

- performance, memory, latency, cache, persistence robustness 기준이 아직 문서화되지 않았다

닫아야 할 항목:

- waveform cache strategy
- preview responsiveness
- autosave durability
- large project scaling
- memory budget for image array reuse

## Lower Priority

### 8. User Personas

닫아야 하는 이유:

- 타깃 사용자는 이미 정의됐지만, 실제 UX 판단용 persona 문서는 없다

닫아야 할 항목:

- primary persona
- advanced persona
- expected workflow differences

### 9. Product Goals

닫아야 하는 이유:

- 루트 문서의 overview는 있지만, milestone 기준의 제품 목표 문서는 아직 없다

### 10. Milestone Plan

닫아야 하는 이유:

- 문서 기준으로 다음 구현 단계는 보이지만, 개발 순서와 deliverable 기준표는 없다

닫아야 할 항목:

- milestone 1: asset prep
- milestone 2: mix timeline
- milestone 3: automation
- milestone 4: preview
- milestone 5: persistence / PDJE translation

## Existing Document Open Questions

### Core Authoring Workflow

- preview 중 허용되는 편집 범위
- `LOAD/UNLOAD`의 GUI 표현 방식

### Godot Scene Workflow

- `Music Asset Add & Config`를 완전한 scene 파일로 둘지 child scene 교체 방식으로 둘지
- waveform/STFT job과 UI thread 경계

### Global Frame UI

- alert stack 세부 규칙
- global save와 local save 경계의 추가 정리 필요 여부

### Authoring Local Bezel

- 현재는 거의 닫혔지만, icon/text 조합 같은 표현 디테일은 남아 있다

### Music Asset Add & Config Workflow

- `ready_for_mixset`와 root DB visibility 후속 동기화 시점
- waveform deferred state와 return-ready 경계

### Music Asset Add & Config UI State Flow

- autosave failure를 global alert에도 올릴지
- waveform failure retry UI 세부 규칙

### Mixset Timeline Model

- battle modifier의 exact PDJE lower rule
- `BarBlock` 내부 FX/EQ offset 허용 범위
- global BPM lane interpolation rule
- 같은 asset의 복수 비연속 사용 segmentation rule

## Recommended Execution Order

1. `Automation Lane Model`
2. `Preview Playback Design`
3. `Persistence And Translation Layer`
4. `Library And Metadata Model`
5. `Godot UI Structure`
6. `Functional Requirements`
7. `Non-Functional Requirements`
8. `Milestone Plan`

## Summary

현재 blueprint는 제품 방향, 씬 구조, asset config 흐름, mixset timeline 의미 규칙까지는 많이 닫혀 있다.  
다음 핵심은 **automation schema**, **preview state model**, **PDJE translation layer**를 닫는 것이다.
