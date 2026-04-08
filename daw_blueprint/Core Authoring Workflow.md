# Core Authoring Workflow

## Purpose

이 문서는 `Project DJ DAW`의 대표 저작 흐름을 정의한다.  
목표는 사용자가 기존 음악 자산을 바탕으로 믹스셋을 시간축에서 설계하고, DJ 이벤트와 믹싱 자동화를 배치하고, preview playback으로 검증한 뒤, 재현 가능한 프로젝트 데이터로 저장하는 과정을 고정하는 것이다.

이 문서는 일반적인 오디오 클립 편집기의 작업 흐름을 정의하지 않는다.  
본 문서의 기준은 `PDJE Editor`의 `mix event authoring`, `preview playback`, `render/push persistence` 개념이다.

UI shell, shortcut, import 경로 같은 가변 값은 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목을 참조한다.

## Workflow Scope

이 문서가 다루는 핵심 범위는 아래와 같다.

- editor project 열기 또는 생성
- 음악 자산 등록과 timing metadata 준비
- 믹스셋용 timeline event authoring
- EQ, Filter, Volume, BPM, FX automation authoring
- preview playback 기반 검증
- render와 push를 통한 저장
- history 기반 수정 반복

이 문서는 아래 항목을 핵심 workflow 본체로 취급하지 않는다.

- 라이브 DJ 공연용 실시간 입력 퍼포먼스
- 일반 DAW식 오디오 파형 절단/워프 편집
- clip launcher 중심 인터페이스
- waveform UI의 세부 그래픽 표현
- loop authoring의 상세 semantics

## PDJE Grounding

이 workflow는 아래 PDJE Editor 기능에 직접적으로 기대고 있다.

- `InitEditor`, `GetEditorObject`, `Open`, `CloseEditor`
- `ConfigNewMusic`
- `AddLine`, `deleteLine`, `getAll`
- `Undo`, `Redo`, `Go`, `GetDiff`, `GetLogWithJSONGraph`, `UpdateLog`
- `demoPlayInit`
- `render`
- `pushToRootDB`

또한 timeline authoring의 핵심 데이터 의미는 아래 범주를 따른다.

- `MusicArgs`: 음악 메타데이터와 BPM timeline 관련 정보
- `MixArgs`: playback/process behavior를 바꾸는 timeline event
- `NoteArgs`: 리듬게임 chart 영역
- `KEY_VALUE`: 프로젝트 보조 값

본 프로젝트의 Core Authoring Workflow는 실질적으로 `MusicArgs + MixArgs + preview/persistence`를 중심으로 정의한다.

## Entry Conditions

이 workflow가 시작되기 위한 최소 조건은 아래와 같다.

- 사용 가능한 editor project root가 있다
- root DB 접근 경로가 준비되어 있다
- 사용자가 author identity를 지정할 수 있다
- 저작 대상 음악 파일이 준비되어 있다

선행 데이터가 전혀 없더라도, 새 project를 만들고 `ConfigNewMusic`으로 첫 음악 자산을 등록하는 형태로 시작할 수 있어야 한다.

## Exit Conditions

이 workflow가 성공적으로 끝났다고 보기 위한 조건은 아래와 같다.

- 믹스셋 timeline이 editor working state에 존재한다
- preview playback으로 의도한 전환과 automation이 검증되었다
- render가 성공했고 lint 결과가 허용 가능한 상태다
- 필요한 track/music 데이터가 root DB에 push되었다
- 이후 같은 project를 다시 열어 계속 수정할 수 있다

## Canonical Workflow

### 1. Authoring Project 시작

사용자는 새 authoring project를 만들거나 기존 project를 다시 연다.

시스템은 아래 단계를 수행한다.

- `InitEditor`로 editor path를 초기화한다
- `GetEditorObject`로 editor handle을 획득한다
- 기존 작업을 이어갈 경우 `Open`으로 특정 project path를 다시 연다

이 단계의 목적은 playback과 분리된 **authoring workspace**를 확보하는 것이다.

### 2. 음악 자산 등록

사용자는 믹스셋에 사용할 곡을 등록한다.

시스템은 아래 정보를 기반으로 음악 자산을 준비한다.

- music title
- composer
- audio file path
- `firstBeat`

PDJE 기준으로 이 단계는 `ConfigNewMusic`에 해당한다.  
이 단계의 결과는 이후 mix timeline에서 참조 가능한 `musdata` 성격의 기초 데이터가 생기는 것이다.

### 3. 믹스셋 타깃 정의

사용자는 현재 저작 중인 믹스셋의 결과 단위를 정한다.

제품 UI 관점에서는 현재 작업 단위를 `editor project`로 다루고, PDJE persistence 관점에서는 최종적으로 특정 `trackTitle`을 대상으로 render/push되는 authored track 결과물로 관리한다.

즉, 이 둘은 같은 이름의 동의어가 아니다.

- `editor project`: 사용자가 `Workspace Selection`에서 보고, 다시 열고, 수정하고, 폐기하는 현재 authoring 단위
- `trackTitle`: render / push 대상이 되는 `RootDB` track 식별 단위

이 단계에서 UI는 최소한 아래 상태를 관리해야 한다.

- 현재 편집 중인 editor project 이름
- 현재 project가 대상으로 삼는 `trackTitle`
- timeline의 기준 단위
- 어떤 음악 자산들이 현재 project에서 사용 중인지

### 4. Timeline에 곡 구조를 배치

사용자는 "어느 시점에 어떤 곡이 들어오고 빠지는가"를 정의한다.

이 단계의 중심은 오디오 클립을 자유롭게 자르는 것이 아니라, **곡의 로드/언로드와 전환 구조를 event row로 설계하는 것**이다.

대표 authoring 동작은 아래와 같다.

- 특정 beat 위치에 `LOAD` 배치
- 특정 beat 또는 구간 이후 `UNLOAD` 배치
- 필요한 시점에 `CONTROL` 계열 이벤트 배치

이 단계의 결과는 "셋에 어떤 곡이 어떤 시간축 위치에서 활성 상태가 되는가"가 명확해지는 것이다.

### 5. 믹싱 자동화 작성

사용자는 전환과 믹싱의 성격을 timeline automation으로 작성한다.

핵심 authoring 대상은 아래 범주다.

- `VOL`
- `EQ`
- `FILTER`
- `BPM_CONTROL`
- `ECHO`
- 기타 지원 FX 계열 이벤트

PDJE 기준으로 이들은 `MixArgs` row이며, start position과 end position을 가질 수 있다.  
따라서 본 제품의 GUI는 automation을 곡선이나 lane처럼 보여줄 수 있지만, 내부 의미는 **time-bounded event/automation row**로 유지해야 한다.

### 6. 세부 값 조정과 반복 수정

사용자는 아래 항목을 반복적으로 수정한다.

- 이벤트 위치
- 이벤트 지속 구간
- interpolation 성격
- 파라미터 값
- 트랙 간 전환 타이밍

시스템은 `getAll`을 통한 working state 조회와 `AddLine/deleteLine` 중심 mutation을 지원해야 한다.  
이 단계는 가장 자주 반복되는 편집 루프이며, GUI 상에서는 drag, inspector edit, numeric edit, lane edit 등으로 표현될 수 있다.

### 7. Preview Playback으로 검증

사용자는 현재 authored result를 실제로 들어보며 검증한다.

PDJE 기준 preview는 `demoPlayInit`로 연결되며, 이 단계는 persistence와 구분되어야 한다.

사용자는 preview에서 아래를 확인한다.

- 곡 로드/전환 순서가 의도와 맞는지
- EQ/Filter/Volume/BPM/FX 변화가 의도한 시점에 일어나는지
- automation의 강도와 지속 시간이 적절한지

preview는 저장과 동일한 단계가 아니다.  
preview는 **authoring 결과를 audition하는 검증 단계**다.

### 8. Render와 Push로 저장

사용자가 현재 결과를 저장 가능한 상태로 확정하면 시스템은 아래 흐름을 수행한다.

1. `render(trackTitle, ROOTDB, lint_msg)`
2. lint 결과 확인
3. 일반 save는 여기서 끝날 수 있다
4. 사용자가 `RootPinAction`을 누르거나 editor를 벗어날 때 `pushToRootDB(ROOTDB, trackTitle)`를 시도한다
5. 필요한 경우 music metadata도 root DB에 반영

이 단계에서 중요한 구분은 아래와 같다.

- `render`: conversion + validation
- `push`: persistence write-back

즉, authoring workspace의 working state가 바로 root DB 상태와 동일한 것은 아니다.

### 9. History 기반 반복 작업

사용자는 preview 또는 review 결과에 따라 이전 상태와 현재 상태를 비교하고 되돌릴 수 있어야 한다.

PDJE 기준으로 아래 기능이 대응된다.

- `Undo`
- `Redo`
- `Go`
- `GetDiff`
- `GetLogWithJSONGraph`
- `UpdateLog`

따라서 본 제품은 단순 파일 overwrite 방식이 아니라, **authoring history를 탐색하고 비교 가능한 편집기**로 설계되어야 한다.

## Timeline Semantics

Core workflow에서 사용하는 시간축은 PDJE의 beat-grid 스타일 모델을 따른다.

- `beat`: whole beat index
- `subBeat`: 현재 beat 안의 subdivision index
- `separate`: subdivision denominator
- `Ebeat`, `EsubBeat`, `Eseparate`: duration-based event의 end position

이 의미는 아래 규칙을 가진다.

- 점 이벤트는 start position만으로 표현 가능하다
- 지속 이벤트나 automation은 start/end position을 함께 가진다
- mix automation과 DJ event는 같은 시간축 모델을 공유한다

따라서 GUI의 snap, zoom, lane, block 표현은 자유롭게 설계할 수 있어도, 내부 semantics는 위 모델을 깨면 안 된다.

## User Intent vs System Response

### 곡을 셋에 포함시키고 싶다

- 사용자 의도: 특정 곡을 특정 시점부터 믹스셋에 참여시키고 싶다
- 시스템 반응: 해당 곡을 참조하는 `LOAD` 계열 Mix event를 생성한다

### 곡을 셋에서 제거하고 싶다

- 사용자 의도: 특정 시점 이후 그 곡이 더 이상 active하지 않게 하고 싶다
- 시스템 반응: 대응되는 `UNLOAD` 계열 Mix event를 생성한다

### 전환 감각을 조정하고 싶다

- 사용자 의도: EQ/Filter/Volume/FX를 시간에 따라 변화시키고 싶다
- 시스템 반응: start/end position과 parameter payload를 가진 automation 성격의 `MixArgs` row를 생성한다

### 결과를 먼저 들어보고 싶다

- 사용자 의도: 저장 전에 현재 결과를 확인하고 싶다
- 시스템 반응: `demoPlayInit` 기반 preview playback path를 사용한다

### 이전 편집 상태로 돌아가고 싶다

- 사용자 의도: 특정 수정 전 상태를 복원하거나 비교하고 싶다
- 시스템 반응: history API를 사용해 undo/redo/go/diff를 수행한다

## GUI Responsibilities

PDJE가 직접 규정하는 것은 event/timeline authoring semantics이며, 아래 항목은 본 프로젝트가 GUI 차원에서 구체화해야 한다.

- event row를 어떻게 lane과 block으로 시각화할지
- MixArgs 파라미터를 어떤 inspector로 편집할지
- trackTitle, music asset, mix timeline의 관계를 어떤 화면 구조로 보여줄지
- history와 diff를 어떤 UX로 노출할지
- preview 상태를 timeline과 어떻게 동기화해서 보여줄지

즉, 본 프로젝트의 차별점은 새 semantics를 만드는 것이 아니라, **PDJE semantics를 사람이 다루기 쉬운 GUI workflow로 변환하는 것**이다.

## Out Of Scope For This Workflow

아래 항목은 현재 Core Authoring Workflow의 확정 범위 밖이다.

- live input capture를 automation으로 바로 기록하는 기능
- waveform editing 자체를 중심에 둔 clip manipulation
- CUE 기반 loop-like GUI 편의 기능의 상세 규칙
- 실시간 DJ hardware integration
- note/chart authoring flow

필요하면 이들은 후속 문서에서 별도로 정의한다.

## Loop Interpretation

- loop는 새로운 `PDJE` command family나 engine extension으로 보지 않는다
- loop는 기존 `CUE` command를 반복적으로 이용해 특정 구간을 되감아 재진입하는 GUI 응용계층 convenience로 본다
- 따라서 loop authoring은 저장 의미론을 새로 확장하기보다, existing `PDJE` mix semantics 위의 editor-side abstraction으로 다룬다

## Summary

Project DJ DAW의 Core Authoring Workflow는 **음악 자산 등록 -> mix timeline event 작성 -> automation 작성 -> preview 검증 -> render/push 저장 -> history 기반 반복 수정**의 흐름이다.

이 문서는 제품의 중심을 `live DJ control`이 아니라 `PDJE-compatible mixset authoring`에 둔다.
