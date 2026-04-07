# Godot Scene Workflow

## Purpose

이 문서는 `Project DJ DAW`의 Godot 화면 구조와 scene 전환 규칙을 정의한다.  
목표는 `PDJE`의 authoring semantics를 훼손하지 않으면서, 사용자가 작업 대상을 선택하고, 믹스셋을 편집하고, 음악 자산을 분석/태깅하는 과정을 **명확한 화면 단위와 전환 흐름**으로 고정하는 것이다.

이 문서는 개별 widget 배치나 시각 스타일을 정의하지 않는다.  
중심 관심사는 아래 세 가지다.

- 어떤 화면이 하나의 거시 scene인지
- 어떤 작업이 같은 scene 내부의 subscene/view인지
- scene 사이에서 어떤 상태가 유지되고 어떤 상태가 새로 열리는지

## Relationship To PDJE

이 문서는 `Core Authoring Workflow`의 GUI 계층 버전이다.  
PDJE 기준의 실제 authoring semantics는 여전히 아래에 있다.

- `InitEditor`, `Open`, `GetEditorObject`
- `ConfigNewMusic`
- `AddLine`, `deleteLine`, `getAll`
- `demoPlayInit`
- `render`, `pushToRootDB`

Godot scene은 위 semantics를 직접 대체하지 않는다.  
scene의 역할은 **사용자 작업 맥락을 분리하고, editor model을 시각화하고, mutation 요청을 수집하는 것**이다.

`Music Asset Add & Config Workspace`의 상세 절차는 [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)에서, 서브씬 내부 상태 전이는 [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)에서 별도로 정의한다.

모든 scene 위에 지속적으로 보이는 shell UI는 [Global Frame UI](Global%20Frame%20UI.md)에서 별도로 정의한다.
높이, local bezel 액션 수, 저장 단축키 같은 가변 값은 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목을 따른다.
`Authoring` 전용 local bezel의 상세 규칙은 [Authoring Local Bezel](Authoring%20Local%20Bezel.md)에서 별도로 정의한다.

특히 scene 위의 persistent shell은 `Global Top Bezel -> Local Bezel -> Scene Content -> Global Bottom Bezel` 구조를 따른다.
여기서 bezel 높이는 `__SETTING_VAL__UI_GLOBAL_TOP_BEZEL_HEIGHT_PX`, `__SETTING_VAL__UI_LOCAL_BEZEL_HEIGHT_PX`, `__SETTING_VAL__UI_GLOBAL_BOTTOM_BEZEL_HEIGHT_PX`를 따른다.

## Design Principles

- 상위 scene은 적게 유지한다
- 작업 맥락이 바뀔 때만 큰 화면 전환을 사용한다
- 동일한 작업 맥락 안의 세부 단계는 subscene/view로 처리한다
- music asset 분석/태깅처럼 집중과 성능이 중요한 작업은 독립 작업공간으로 분리한다
- scene tree는 source of truth가 아니다
- 실제 편집 데이터는 editor state/model이 소유한다
- preview, render, push 같은 엔진 연산은 scene가 아니라 controller/service 계층이 수행한다

## Macro Scene Model

본 프로젝트의 거시 scene 구조는 두 단계로 고정한다.

1. `Workspace Selection Scene`
2. `Authoring Scene`

이 구조는 사용자가 현재 무엇을 하는지 크게 두 상태로 구분한다.

- 무엇을 편집할지 결정하는 상태
- 선택한 대상을 실제로 편집하는 상태

이 문서에서 말하는 `scene`은 Godot의 최상위 화면 전환 단위이고, `subscene/view`는 그 내부 작업공간 단위다.

## Scene 1: Workspace Selection Scene

### 역할

이 scene은 사용자가 어떤 PDJE root와 어떤 authoring target을 다룰지 결정하는 화면이다.

핵심 책임은 아래와 같다.

- PDJE root 경로 선택
- editor project root 확인
- 기존 authored track 목록 표시
- 새 track authoring 시작
- 최근 작업 또는 최근 root 접근

### 내부 subscene/view

- `RootSelectionView`
- `TrackListView`
- `NewTrackSetupView`
- `RecentWorkspaceView`

### 포함하지 않아야 하는 것

- timeline authoring
- 음악 자산의 상세 분석
- mix automation 편집
- preview playback의 핵심 제어

즉, 이 scene은 **작업 대상 선택**까지만 담당한다.

이 scene은 `Selector Local Bezel`을 가진다.
기본 액션 버튼 수 상한은 `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_SELECTOR`를 따른다.

## Scene 2: Authoring Scene

### 역할

이 scene은 사용자가 선택한 authored track 또는 새 authored track을 실제로 편집하는 메인 작업공간이다.

핵심 책임은 아래와 같다.

- mix timeline 편집
- DJ event authoring
- automation authoring
- preview playback
- history 탐색
- render / push 실행
- 음악 자산 선택 및 연결

이 scene은 `Authoring Local Bezel`을 가지며, 저장 액션은 여기에서 수행된다.
기본 액션 버튼 수 상한은 `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_AUTHORING`을 따른다.
이 bezel은 공통 최소 strip만 담당하며, 상세 규칙은 [Authoring Local Bezel](Authoring%20Local%20Bezel.md)를 따른다.

### 내부 작업공간 구조

`Authoring Scene`은 두 개의 핵심 subscene/workspace를 가진다.

1. `Mixset Editing Workspace`
2. `Music Asset Add & Config Workspace`

이 둘은 같은 상위 authoring 세션 안에 있지만, 작업 집중도와 연산 특성이 다르므로 **실제 화면 전환이 가능한 별도 subscene**으로 취급한다.

## Authoring Subscene A: Mixset Editing Workspace

### 역할

믹스셋 전체를 시간축에서 편집하는 기본 작업공간이다.

핵심 책임은 아래와 같다.

- timeline 표시
- load/unload/control event 배치
- EQ / Filter / Volume / BPM / FX automation 편집
- library에서 기존 music asset 선택
- preview playback
- history / diff 확인
- render / push 실행

### 주요 UI 영역

- `TimelineView`
- `TrackLaneView`
- `AutomationLaneView`
- `InspectorPanel`
- `TransportBar`
- `AssetBrowserPanel`
- `HistoryPanel`

여기서 `MusicBlock`은 `LOAD-UNLOAD` span 전체를 갖고, source 공급이 끊긴 pause 이후 구간이나 audio tail 구간은 empty block으로 표시할 수 있다. 또한 `CUE`, `SCRATCH`, `SPIN`, `REV`, `ECHO` 같은 supply-affecting command는 RGB waveform projection에도 반영된다. `PITCH`는 waveform 재계산 대신 tag UI로 표시한다. 이 규칙의 semantic source는 [Mixset Timeline Model](Mixset%20Timeline%20Model.md)를 따른다.

### 진입 조건

- PDJE root와 editor project가 준비되어 있다
- 편집 대상 track이 선택되었거나 새 track이 생성되었다

### 이 workspace에서 하지 않는 것

- 신규 음악 자산의 고비용 waveform/STFT 생성
- 곡 내부 태그 포인트의 상세 authoring
- 음악 파일 등록을 위한 집중형 메타데이터 작업

이런 작업은 `Music Asset Add & Config Workspace`로 넘긴다.

## Authoring Subscene B: Music Asset Add & Config Workspace

### 역할

이 작업공간은 "곡 추가" 모달이 아니다.  
하나의 음악 자산을 대상으로, 믹스셋에서 사용 가능한 상태로 만들기 위한 **집중형 asset preparation workspace**다.

### 분리 이유

이 subscene은 실제 화면 전환이 필요하다. 이유는 아래와 같다.

- 대상이 믹스셋 전체가 아니라 음악 자산 1개로 좁혀진다
- 사용자는 해당 음악의 정보와 분석 결과에 집중해야 한다
- waveform/STFT 생성, decode, 캐시 확인 같은 비교적 무거운 단계가 있다
- 파형, BPM, firstBeat, 태그 포인트 같은 단일 자산용 UI가 필요하다
- 성능상 timeline editor 전체를 유지한 채 같은 화면에서 처리하면 부담이 커질 수 있다

즉, 이 작업은 `Mixset Editing`의 부가 다이얼로그가 아니라 **독립 작업공간**으로 보는 것이 맞다.

### 핵심 책임

- 새 음악 파일 선택
- source file validation
- 초기 필수 필드 입력과 app-local initial draft save
- `PDJE` registration과 BPM row 적용
- 조건부 waveform generation과 파형 표시
- 메타데이터 확인 및 수정
- BPM, firstBeat, 기타 timing 관련 값 확인
- 확인된 binding 범위 안의 waveform/STFT 기반 결과 표시
- 사용자가 태그/포인트/마커를 직접 추가
- 최종적으로 mix editor에서 사용할 수 있는 music asset 생성 또는 갱신

### 주요 UI 영역

- `SourceImportGateView`
- `SourceValidationPanel`
- `InitialRequiredFieldForm`
- `WaveformBuildProgressView`
- `WaveformCanvasView`
- `MetadataEditorPanel`
- `BpmMappingEditorView`
- `WaveformStftPanel`
- `TagPointEditorView`
- `WaveformStftResultView`
- `CommitAssetActionBar`
- `InvalidReturnStatePanel`
- `SaveWarningDialog`

### 산출물 계약

이 subscene이 성공적으로 끝나면 최소한 아래 데이터를 반환해야 한다.

- music asset identifier
- audio path
- title / composer 등 메타데이터
- BPM 또는 BPM 관련 값
- `firstBeat`
- user tag markers
- mix editor가 참조 가능한 waveform/STFT preview ref와 app-layer tag data

이 산출물이 준비되어야 `Mixset Editing Workspace`에서 곡을 즉시 참조할 수 있다.

### 저장 불가 상태 피드백

`Music Asset Add & Config Workspace`는 저장 불가 상태를 숨기면 안 된다.

- 필수 필드가 비어 있거나 유효하지 않으면 subscene 내부의 `InvalidReturnStatePanel` 또는 동등한 강한 상태 UI를 표시한다
- 사용자가 `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT` 또는 `Authoring Local Bezel SaveIcon`을 시도하면 `SaveWarningDialog`를 띄운다
- dialog는 누락 필드와 수정 필요 항목을 명시해야 한다
- dialog는 저장을 대체하지 않으며, validation이 통과할 때까지 실제 commit은 일어나지 않는다

이 피드백은 `Authoring Local Bezel`이 아니라 `Music Asset Add & Config` 서브씬 내부에서 강하게 표현되어야 한다.
초기 source import, app-local initial save, `PDJE` registration, 조건부 waveform build, autosave, return save의 state sequence는 [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)를 따른다.

## Canonical Scene Flow

이 프로젝트의 대표 화면 흐름은 아래와 같다.

1. 사용자가 `Workspace Selection Scene`에 진입한다
2. PDJE root를 선택한다
3. 기존 track을 열거나 새 track authoring을 시작한다
4. `Authoring Scene`의 `Mixset Editing Workspace`로 진입한다
5. 사용자는 기존 music asset을 불러오거나 새 음악 자산 추가를 선택한다
6. 새 자산이 필요하면 `Music Asset Add & Config Workspace`로 화면 전환한다
7. 초기 필수 필드 저장, `PDJE` registration, 조건부 waveform 생성을 거쳐 메타데이터 수정과 BPM mapping, 태그 입력을 완료한다
8. return save 후 다시 `Mixset Editing Workspace`로 복귀한다
9. 방금 만든 music asset을 timeline authoring에 사용한다
10. preview 후 render / push를 실행한다

이 흐름은 `곡 추가`와 `믹스 authoring`을 같은 세션 안에서 연결하되, 작업 집중 단위는 명확히 분리한다.

## Transition Rules

### 허용 전환

- `Workspace Selection Scene -> Authoring Scene`
- `Authoring / Mixset Editing -> Authoring / Music Asset Add & Config`
- `Authoring / Music Asset Add & Config -> Authoring / Mixset Editing`
- `Authoring Scene -> Workspace Selection Scene`

### 지양 전환

- `Workspace Selection`에서 직접 `Music Asset Add & Config`로 진입
- `Music Asset Add & Config`에서 별도 독립 메인 scene 체인으로 계속 분기
- `render/push`를 위해 별도 메인 scene을 열기

### 원칙

- 메인 작업 맥락 변경: scene 전환 허용
- 같은 authoring 세션 안의 집중 작업 이동: subscene 전환 허용
- 단순 선택/수정/확인: panel, dialog, dock, overlay 우선

## State Ownership Rules

### Scene가 소유하면 안 되는 것

- MixArgs, MusicArgs의 source of truth
- render/push 결과 상태의 최종 판단
- preview 엔진 상태의 영속 저장값

### Editor model이 소유해야 하는 것

- 현재 track authoring state
- music asset registry와 참조 관계
- timeline event working set
- automation working set
- history / diff 대상 상태

### Scene가 가져야 하는 것

- 현재 선택된 UI 탭
- 패널 열림 여부
- viewport, zoom, selection rectangle 같은 단기 UI 상태
- 현재 subscene 진입 여부

## Session Continuity Rules

`Music Asset Add & Config`로 이동하더라도, 사용자는 같은 authoring 세션 안에 있어야 한다.

따라서 아래 규칙이 필요하다.

- `Mixset Editing`의 현재 선택 상태는 가능한 한 유지한다
- 복귀 시 timeline scroll, zoom, selection을 복원한다
- 방금 생성된 music asset은 복귀 직후 browser에서 선택 가능해야 한다
- asset 등록 실패 시도는 editor session 전체를 깨뜨리면 안 된다

핵심은 `scene transition`은 일어나지만, `authoring session reset`은 일어나지 않는다는 점이다.

## Performance And Focus Considerations

`Music Asset Add & Config Workspace`를 분리하는 이유는 UX뿐 아니라 성능상 이점도 있다.

- 무거운 waveform/STFT 연산 UI를 timeline editor와 분리할 수 있다
- 파형 분석, 태그 포인트 편집, metadata inspection에 화면을 집중시킬 수 있다
- Godot에서 불필요한 editor subview 동시 활성화를 줄일 수 있다
- 장기적으로 백그라운드 분석 작업과 진행 표시 UX를 넣기 쉬워진다

따라서 이 subscene 분리는 단순 취향 문제가 아니라 제품 구조상 합리적인 선택이다.

## Recommended Scene Tree Direction

구현 초안 수준에서의 상위 구조는 아래와 같다.

- `WorkspaceSelectionScene`
- `AuthoringScene`
- `AuthoringScene/MixsetEditingWorkspace`
- `AuthoringScene/MusicAssetAddConfigWorkspace`

그리고 `AuthoringScene` 아래에 공통 service/controller 연결 지점을 둔다.

- current editor session binding
- preview transport binding
- mutation command entry
- asset registry access

이렇게 하면 두 authoring subscene이 같은 세션 상태를 공유하면서도 화면 책임은 분리할 수 있다.

## Open Questions

- `Music Asset Add & Config`에서 태그 포인트의 정확한 의미를 어떻게 표준화할지 결정이 필요하다
- waveform/STFT 결과를 즉시 editor model에 반영할지, 임시 검토 후 commit할지 결정이 필요하다
- `Workspace Selection`에서 새 track 생성 시 필요한 최소 입력값을 어디까지 받을지 정해야 한다
- `Music Asset Add & Config`를 완전한 scene 파일로 분리할지, `AuthoringScene` 내부 child scene 교체 방식으로 운영할지 정해야 한다
- background waveform/STFT job과 UI thread의 경계를 어떻게 둘지 정해야 한다

## Summary

`Project DJ DAW`의 Godot scene workflow는 크게 `Workspace Selection Scene`과 `Authoring Scene`으로 나뉜다.  
그리고 `Authoring Scene`은 다시 `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`로 나뉜다.

이 중 `Music Asset Add & Config`는 단순 모달이 아니라, 단일 음악 자산에 대한 waveform/STFT 생성, 메타데이터 수정, 태그 포인트 입력을 수행하는 **집중형 별도 작업공간**이며, 실제 화면 전환이 정당화된다.
