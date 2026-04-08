# Module Impl - 2026-04-08

## Purpose

이 문서는 `2026-04-08` 시점 blueprint 중 **완전히 닫힌 상태로 구현 가능한 모듈만** 골라 실제 코드 구현 범위를 고정한다.

이 문서는 설계 확장 문서가 아니다.  
여기 적힌 항목은 바로 구현에 들어가며, 닫히지 않은 항목은 명시적으로 제외한다.

## Implementation Rule

- blueprint에서 의미가 닫힌 모듈만 구현한다
- UI는 닫힌 책임 경계만 구현하고, 열린 의미 규칙은 placeholder 또는 read-only 상태로 둔다
- `automation`, `preview playback`, `PDJE translation compile`은 구현 대상에서 제외한다
- 현재 wrapper surface에 없는 capability는 가정하지 않는다
- 현재 구현은 `authoring shell + asset prep + session state`까지를 목표로 한다

## Included Modules

### 1. App Shell

구현 범위:

- global top bezel
- local bezel
- global bottom bezel
- scene title / subscene title / current target / save state readout
- alert/status strip의 최소 UI skeleton

이 모듈은 [Global Frame UI](Global%20Frame%20UI.md), [Authoring Local Bezel](Authoring%20Local%20Bezel.md) 기준으로 구현한다.

### 2. Workspace Selection Scene

구현 범위:

- root path summary 표시
- current editor project list 표시
- `RootDB` track list 표시
- `RootDB` music list 표시
- 선택 project open / modify / discard
- 선택 `RootDB` track / music delete
- 새 authoring session 진입
- 최근 선택 workspace 표시용 최소 panel

열린 항목:

- 새 editor project 생성 시 최소 입력 세트는 현재 구현에서 `track title` 하나로 제한한다

구현 규칙:

- `editorDB`는 내부 구현용 임시 저장소로만 사용하고, 사용자에게 직접 노출하지 않는다

### 3. Authoring Scene Routing

구현 범위:

- `Workspace Selection -> Authoring`
- `Authoring / Mixset Editing`
- `Authoring / Music Asset Add & Config`
- `ReturnAction`
- `SaveIcon`
- subscene 전환 시 current target / current subscene 상태 반영

### 4. Authoring Session State

구현 범위:

- current root summary
- authored track title
- current subscene
- selected asset draft
- asset draft list
- dirty / saving / saved 상태
- project-local JSON persistence

현재 구현은 full project persistence가 아니라 **app-local authoring state persistence**만 담당한다.

### 5. PDJE Service Adapter

구현 범위:

- engine/editor init
- music search
- raw path PCM validation 경로
- `ConfigNewMusic(...)`
- first BPM row add
- `EditMusicFirstBar(...)`
- conditional waveform generation

제한:

- `GetDiff()`는 사용하지 않는다
- music identity in-place rewrite는 지원하지 않는다
- `render/push`는 현재 구현의 기본 경로에 넣지 않는다

### 6. Music Asset Add & Config Workspace

구현 범위:

- source path 입력
- `Track Title`, `Composer`, `Start BPM`, `First Beat` 입력
- BPM transition row 입력
- local draft save gate
- PDJE registration gate
- return-ready gate
- subscene 내부 invalid-save UI
- autosave timer
- waveform preview placeholder / conditional fetch

구현 규칙:

- 필수 메타데이터 default 금지
- source path validation 실패 시 save 차단
- `ready_for_mixset`와 `PDJE searchable`는 분리한다
- waveform은 가능할 때만 가져오고, 실패해도 config 편집은 유지한다

### 7. Mixset Editing Workspace Shell

구현 범위:

- 현재 authored track title 표시
- ready asset list 표시
- asset별 lane summary card 표시
- asset config workspace 진입
- 닫히지 않은 timeline authoring 영역은 read-only placeholder로 유지

주의:

- 실제 `LOAD/UNLOAD` event authoring
- automation lane editing
- preview playback

위 세 항목은 이 구현에 포함하지 않는다.

## Explicitly Excluded

- `Automation Lane Model`
- `Preview Playback Design`
- `Editor Integration Boundary`
- `Godot UI Structure`의 세부 component decomposition
- `TrackBlock.global_bpm_map` 편집기
- `BarBlock` 기반 EQ/FX authoring
- editor integration / render / push handoff workflow
- semantic diff / history graph visualization

## Deliverables

### UI Deliverables

- root app scene 1개
- workspace selection view 1개
- authoring workspace shell 1개
- mixset editing workspace 1개
- music asset add/config workspace 1개
- 공통 bezel component set

### Script Deliverables

- app/session state script
- PDJE adapter/service script
- asset draft persistence script
- workspace selection controller
- authoring shell controller
- asset config controller
- mixset workspace controller

### Data Deliverables

- project-local asset draft JSON file
- authored track state JSON file

## Runtime Contracts

### Save State Contract

save state는 아래 네 값만 사용한다.

- `latest`
- `modified`
- `saving`
- `recently_saved`

### Asset Draft Contract

최소 draft field:

- `asset_id`
- `source_audio_path`
- `music_title`
- `composer`
- `start_bpm`
- `first_beat`
- `bpm_transition_metadata`
- `user_tags`
- `pdje_registered`
- `pdje_searchable_by_search_music`
- `ready_for_mixset`
- `waveform_preview_available`

### Track Contract

현재 구현의 authored track은 아래 정도만 가진다.

- `track_title`
- `asset_ids`
- `current_subscene`
- `last_opened_asset_id`

## Orchestration Plan

1. implementation doc를 먼저 작성해 scope를 잠근다
2. 공통 상태/서비스 계층을 만든다
3. app shell과 scene routing을 만든다
4. asset config workspace를 붙인다
5. mixset workspace shell을 붙인다
6. 가능한 수준에서 headless parse 또는 project load 검증을 한다

## Success Condition

아래가 가능하면 이번 구현 범위는 완료로 본다.

- 앱을 열면 `Workspace Selection`이 보인다
- authored track을 선택하면 `Authoring`으로 진입한다
- `Music Asset Add & Config`에서 필수 필드를 입력하고 local draft를 저장할 수 있다
- PDJE registration gate를 통과하면 wrapper mutation이 시도된다
- return-ready를 만족한 asset은 `Mixset Editing`에서 ready asset으로 보인다
- `SaveIcon`, `ReturnAction`, save state indicator가 subscene 상태와 일치한다

## Non-Goals For This Implementation

- mixset이 실제로 완성된 `PDJE MixArgs` row로 내려가는 것
- BPM lane curve를 편집하는 것
- preview cursor와 waveform projection을 동기화하는 것
- battle modifier를 authoring하는 것
