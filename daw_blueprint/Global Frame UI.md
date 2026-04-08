# Global Frame UI

## Purpose

이 문서는 `Project DJ DAW`의 모든 거시 scene과 subscene 위에 공통으로 유지되는 상단/하단 bezel UI를 정의한다.

이 UI는 단순 장식이 아니라, 아래 역할을 수행하는 **persistent shell interface**다.

- 현재 작업 맥락 표시
- 글로벌 상태 표시
- 공통 버튼과 작은 아이콘 제공
- hover 시 데이터 읽기 전용 표시
- click 시 dialog 호출 또는 subscene 전환
- alert / warning / validation 상태의 공통 인터페이스 제공

이 문서에서는 `Global Bezel`과 `Local Bezel`을 명확히 구분한다.

- `Global Bezel`: 모든 scene에서 공통으로 유지되는 shell
- `Local Bezel`: 각 거시 scene 바로 아래에서 해당 scene의 로컬 액션을 제공하는 strip

이 문서의 목적은 씬마다 제각각인 상단바와 하단바를 만드는 것이 아니라, **앱 전체에서 일관되게 유지되는 글로벌 프레임 규약**을 고정하는 것이다.

## Relationship To Other Documents

이 문서는 아래 문서들과 직접 연결된다.

- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Settings](Settings.md)

`Godot Scene Workflow`가 scene 전환 구조를 정의한다면, 이 문서는 그 scene들 위에 항상 존재하는 shell UI를 정의한다.
높이, alert 위치, 색상, queue 제한, hover 표현 방식 같은 가변 값은 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목을 따른다.
`Authoring`용 local bezel의 상세 규칙은 [Authoring Local Bezel](Authoring%20Local%20Bezel.md)에서 별도로 정의한다.

## Scope

이 문서가 다루는 범위는 아래와 같다.

- 상단 bezel
- 하단 bezel
- local bezel
- 공통 버튼과 상태 아이콘
- hover readout
- click 시 dialog open 규칙
- click 시 subscene transition 규칙
- alert / warning / validation 상태 표시
- 공통 dialog host
- background task 상태 표시

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- timeline 편집 UI 내부 구조
- asset config form의 개별 입력 필드
- inspector 내부 레이아웃
- waveform renderer 세부 사양
- MixArgs / MusicArgs semantics
- dialog 내부 개별 폼의 상세 입력 규칙

## Core Principles

- 글로벌 프레임은 모든 주요 scene에서 지속적으로 보여야 한다
- scene 전환이 일어나도 프레임의 구조와 위치는 유지되어야 한다
- global bezel과 local bezel은 분리되어야 한다
- local bezel은 global top bezel 바로 아래에 위치해야 한다
- 프레임은 상태를 소유하지 않고 상태를 표시한다
- 프레임은 scene-specific workflow를 대체하지 않는다
- warning과 alert는 scene마다 다른 방식으로 보이지 않고 공통 인터페이스로 보인다
- hover는 읽기 전용 정보 제공에 집중한다
- click은 명시적 액션만 수행한다
- 긴 입력 작업은 dialog보다 subscene 전환이 우선될 수 있다

## Global Layout Model

글로벌 프레임은 세 개의 레이어로 구성된다.

1. `Global Top Bezel`
2. `Local Bezel`
3. `Global Bottom Bezel`

`Global Top Bezel`과 `Global Bottom Bezel`은 모든 scene에서 같은 위치에 유지된다.  
`Local Bezel`은 `Global Top Bezel` 바로 아래에 붙어 있으며, 현재 거시 scene에 따라 구성 내용이 달라진다.

### Global Top Bezel 역할

- 현재 app identity 표시
- 현재 root / workspace 표시
- 현재 scene / subscene context 표시
- alert / warning / validation icon 표시
- dialog trigger 제공
- background task queue 표시

### Local Bezel 역할

- 현재 거시 scene 전용 액션 제공
- scene별로 다른 버튼 조합 제공
- `Save` 같은 workflow-specific action 제공
- 현재 scene 내부의 보조 전환 진입점 제공

### Global Bottom Bezel 역할

- hover data readout 제공
- 상태 메시지 표시
- validation summary 표시
- shortcut hint 표시
- context-sensitive help 표시

즉, 상단 글로벌 bezel은 **전역 상태와 큐**, local bezel은 **현재 scene 전용 액션**, 하단 글로벌 bezel은 **읽기와 피드백 중심**으로 설계한다.

## Sizing And Settings

글로벌 bezel의 높이는 기본값을 가지고 시작하되, 전체 설정에서 변경 가능해야 한다.

기본 높이 값은 아래 설정 변수를 따른다.

- `__SETTING_VAL__UI_GLOBAL_TOP_BEZEL_HEIGHT_PX`
- `__SETTING_VAL__UI_LOCAL_BEZEL_HEIGHT_PX`
- `__SETTING_VAL__UI_GLOBAL_BOTTOM_BEZEL_HEIGHT_PX`

scene별 내부 구성은 달라도, bezel 높이 규약은 위 설정값을 기준으로 유지한다.

## Persistent Component Inventory

글로벌 프레임은 최소한 아래 공통 요소를 가진다.

- `AppIdentitySlot`
- `CurrentRootIndicator`
- `CurrentWorkspaceIndicator`
- `CurrentContextTitle`
- `DirtyStateIndicator`
- `ValidationStatusIcon`
- `AlertIcon`
- `WarningIcon`
- `ErrorIcon`
- `BackgroundTaskQueueContainer`
- `HoverDataReadout`
- `StatusMessageStrip`
- `DialogHostAnchor`

프로젝트 상황에 따라 요소가 더 추가될 수 있으나, 위 요소들이 공통 shell의 핵심이다.

## Global Top Bezel Specification

### Left Zone

- app identity
- 현재 root 이름 또는 root 경로 요약
- 현재 workspace 요약

### Center Zone

- 현재 scene 이름
- 현재 subscene 이름
- 현재 작업 대상 요약

예:

- `Workspace Selection / Track List`
- `Authoring / Mixset Editing`
- `Authoring / Music Asset Add & Config`

### Right Zone

- alert/warning/validation icons
- dialog open buttons
- `BackgroundTaskQueueContainer`

### Background Task Queue Container

background task indicator는 `Global Top Bezel`에 위치해야 한다.

- bezel 내부의 전용 컨테이너로 둔다
- task queue를 리스트 형태로 보여준다
- 현재 진행 중인 작업과 대기 중인 작업을 함께 표시할 수 있어야 한다
- 컨테이너가 `__SETTING_VAL__UI_BACKGROUND_TASK_QUEUE_MAX_HEIGHT_PX`를 넘어서면 스크롤바가 나타나야 한다
- 스크롤 전 기본 표시 task 수는 `__SETTING_VAL__UI_BACKGROUND_TASK_QUEUE_MAX_VISIBLE_TASKS`를 따른다
- 사용자는 작업 큐가 쌓이는 상태를 한눈에 볼 수 있어야 한다

## Local Bezel Specification

`Local Bezel`은 `Global Top Bezel` 바로 아래에 붙는 scene-specific strip이다.

### Selector Local Bezel

`Workspace Selection Scene`에서 사용하는 local bezel이다.

대표 구성 예시는 아래와 같다.

- root 변경 액션
- root 새로고침
- 새 editor project 생성
- 선택한 editor project 열기
- 선택한 editor project 폐기
- 선택한 `RootDB` entry 삭제
- 최근 작업 보기

이 local bezel에는 `Save` 아이콘을 두지 않는다.
기본 액션 버튼 수 상한은 `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_SELECTOR`를 따른다.

### Authoring Local Bezel

`Authoring Scene`에서 사용하는 local bezel이다.

대표 구성 예시는 아래와 같다.

- `ReturnAction`
- `SaveIcon`
- `RootPinAction`
- current authoring target label
- current subscene label
- `SaveStateIndicator`

`SaveIcon`은 `Global Bezel`이 아니라 반드시 `Authoring Local Bezel`에 속한다.  
즉, 저장은 전역 shell 액션이 아니라 authoring 맥락의 로컬 액션이다.
`ReturnAction`과 `SaveIcon`은 좌측 상단 bezel 영역에 배치한다.
기본 액션 버튼 수 상한은 `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_AUTHORING`을 따른다.

### Local Bezel Behavior

- `Local Bezel` 구성은 `Selector`와 `Authoring`에서 달라야 한다
- `Authoring` 내부에서도 subscene에 따라 일부 버튼은 달라질 수 있다
- 하지만 `SaveIcon`의 소속은 항상 `Authoring Local Bezel`이다

## Global Bottom Bezel Specification

### Left Zone

- hover readout
- 현재 포인터 아래 UI 요소 설명

### Center Zone

- status message
- validation summary

### Right Zone

- shortcut hint
- context action hint
- focused scene help entry

## Interaction Model

글로벌 프레임의 상호작용은 아래 네 종류로 나뉜다.

1. `Passive Display`
2. `Hover Readout`
3. `Click Action`
4. `Blocked Action Feedback`

### Passive Display

아이콘이나 인디케이터는 현재 상태를 즉시 보여줘야 한다.

예:

- dirty state 존재
- validation 실패 상태
- background task 진행 중
- warning 존재

### Hover Readout

hover는 짧은 정보 확인을 위한 동작이다.

- 값의 읽기 전용 요약 표시
- 아이콘 의미 설명
- 현재 상태의 짧은 원인 설명
- 버튼 클릭 시 일어날 결과에 대한 짧은 안내

hover는 상태를 바꾸지 않는다.

### Click Action

click은 아래 세 가지 중 하나만 수행해야 한다.

- dialog open
- panel toggle
- subscene transition

하나의 버튼이 동시에 여러 종류의 큰 동작을 수행하면 안 된다.

### Blocked Action Feedback

사용자가 현재 상태에서 실행할 수 없는 액션을 시도하면, 시스템은 이유를 공통 방식으로 설명해야 한다.

예:

- 저장 불가
- root 미선택
- 편집 대상 미선택
- asset 준비 미완료

이 경우 단순 무반응은 허용하지 않는다.

## Hover Data Rules

hover 시 보여줄 데이터는 아래 원칙을 따른다.

- 읽기 전용이어야 한다
- 짧고 즉시 이해 가능해야 한다
- 현재 scene의 핵심 맥락을 깨지 않아야 한다
- 복잡한 입력 UI를 hover에 넣지 않는다

hover 대상 예시는 아래와 같다.

- root indicator hover: 현재 root 경로 요약
- validation icon hover: 저장 불가 원인의 짧은 목록
- warning icon hover: 최근 warning 요약
- background task icon hover: 분석 또는 렌더 진행률 요약

특히 `Alert / Warning / Error` 아이콘 위에 hover하면, 해당 아이콘이 대표하는 메시지를 짧게 표시해야 한다.
hover 표현 방식은 `__SETTING_VAL__UI_HOVER_PRESENTATION_MODE`를 따른다.

## Click Routing Rules

글로벌 프레임 버튼 클릭 시 라우팅은 아래 원칙을 따른다.

### Dialog Open이 적합한 경우

- 짧은 경고 확인
- 설정 확인
- destructive action 확인
- 경미한 상태 설명
- 저장 불가 원인 목록 표시

### Subscene Transition이 적합한 경우

- 집중 입력 작업
- 긴 폼 입력
- 많은 정보 검토가 필요한 작업
- 별도 화면 집중이 필요한 작업

이 기준으로 보면 아래 예가 성립한다.

- root 변경 확인: dialog 가능
- music asset add & config: subscene transition 적합

### Alert And Warning Icon Routing

`Alert`, `Warning`, `Error` 아이콘은 단순 상태 표시가 아니라 **routable issue anchor**로 동작한다.

- icon hover: 대표 메시지 표시
- icon click: 관련 subscene 또는 관련 위치로 자동 이동

즉, subscene jump는 별도 전용 jump button보다, 우선적으로 `Alert / Warning` 아이콘을 통해 수행할 수 있어야 한다.

여러 개의 미해결 이슈가 있을 경우에는 아래 순서를 따른다.

1. 가장 높은 severity
2. 현재 scene와 가장 가까운 수정 지점
3. 가장 최근에 발생한 미해결 이슈

그 결과 선택된 이슈의 소유 subscene으로 자동 이동한다.

## Alert And Warning Interface

글로벌 프레임은 앱 전체의 공통 alert / warning 인터페이스다.

### Severity Levels

- `Info`
- `Notice`
- `Warning`
- `Blocking Warning`
- `Error`

### Presentation Rules

- `Info`와 `Notice`는 status strip 또는 badge 수준으로 표시 가능
- `Warning`은 icon badge와 hover summary를 가져야 한다
- `Blocking Warning`은 icon badge + status strip + click 시 관련 subscene 자동 이동을 요구한다
- `Error`는 강한 시각 표시를 동반하고, 가능한 경우 관련 subscene으로 자동 이동해야 한다

alert icon 구성 방식은 `__SETTING_VAL__UI_ALERT_ICON_MODE`를 따른다.

### Alert Popup Anchor

alert popup은 아래 다섯 위치 중 하나에 표시할 수 있어야 한다.

- `__SETTING_VAL__UI_ALERT_ALLOWED_ANCHORS`

현재 실제 anchor는 `__SETTING_VAL__UI_ALERT_ANCHOR_POSITION`을 따른다.

alert popup stack은 아래 설정을 따른다.

- `__SETTING_VAL__UI_ALERT_STACK_MAX_VISIBLE`
- `__SETTING_VAL__UI_ALERT_STACK_ORDER`

### Common Alert Sources

- 저장 불가 validation
- root DB 접근 실패
- asset config 미완료
- background task 실패
- render/push 실패

## Validation Interface

validation 관련 상태는 글로벌 프레임에서 공통 방식으로 표시해야 한다.

최소한 아래가 필요하다.

- `ValidationStatusIcon`
- validation summary text
- hover 시 요약 메시지
- click 시 관련 subscene 또는 관련 수정 지점으로 이동

이 인터페이스는 scene마다 다르게 구현하면 안 된다.

예:

- `Music Asset Add & Config`에서는 필수 필드 누락
- `Mixset Editing`에서는 render 전 validation issue

표시 방식은 같고, 내용만 scene context에 따라 달라져야 한다.

## Common Dialog Host

글로벌 프레임은 공통 dialog host 진입점을 제공해야 한다.

dialog host가 다루는 대표 항목은 아래와 같다.

- save warning dialog
- validation detail dialog
- alert detail dialog
- destructive confirm dialog
- background task detail dialog

dialog는 scene 밖의 별도 세계가 아니라, **현재 scene 맥락을 유지한 채 호출되는 공통 overlay**로 동작해야 한다.

## Subscene Jump Integration

글로벌 프레임은 특정 subscene으로의 빠른 이동 진입점을 제공할 수 있다.

허용 예시는 아래와 같다.

- `Mixset Editing -> Music Asset Add & Config`
- `Music Asset Add & Config -> Mixset Editing`

하지만 모든 subscene 이동을 별도 버튼으로 bezel에 억지로 올리면 안 된다.  
우선 순위는 아래와 같다.

1. alert / warning / validation icon 기반 자동 이동
2. 꼭 필요한 경우에만 explicit jump control 제공

즉, subscene jump의 대표 인터페이스는 `Alert / Warning / Validation` 아이콘이다.

## Scene Integration Contract

각 scene 또는 subscene은 글로벌 프레임에 아래 정보를 제공해야 한다.

- current scene title
- current subscene title
- current context summary
- warning list
- validation summary
- dirty state
- background task state
- hover detail source
- quick action availability

즉, 글로벌 프레임은 독립적으로 모든 것을 계산하지 않고, 현재 활성 scene의 context provider를 구독해 상태를 표시한다.

## State Ownership Rules

### 글로벌 프레임이 소유하면 안 되는 것

- mixset data source of truth
- music asset metadata source of truth
- render result source of truth
- scene 내부 입력 폼 상태 전체

### 글로벌 프레임이 구독해서 보여줘야 하는 것

- current root
- current workspace
- current scene/subscene
- dirty state
- validation state
- alert queue
- warning queue
- background task progress

## Visual Behavior Rules

- bezel은 scene 전환 중에도 시각적으로 유지되어야 한다
- transition animation이 있더라도 bezel 자체가 사라졌다 다시 나타나면 안 된다
- icon은 작은 크기여도 상태 의미가 분명해야 한다
- validation 색상은 `__SETTING_VAL__UI_VALIDATION_COLOR`
- warning 색상은 `__SETTING_VAL__UI_WARNING_COLOR`
- error 색상은 `__SETTING_VAL__UI_ERROR_COLOR`
- hover readout은 화면을 가리지 않는 방향이 좋다
- dialog는 bezel과 경쟁하지 않고 bezel 위에서 호출돼야 한다

상단 상태 아이콘 영역의 기본 개수 제한은 `__SETTING_VAL__UI_GLOBAL_TOP_STATUS_ICON_LIMIT`을 따른다.

## Suggested Common Actions

글로벌 프레임에 둘 수 있는 대표 action은 아래와 같다.

- 현재 root 정보 보기
- 현재 workspace 요약 보기
- warning 대상 이동
- validation 대상 이동
- background task detail 열기

그리고 local bezel에 둘 수 있는 대표 action은 아래와 같다.

- `ReturnAction`
- `SaveIcon`
- `RootPinAction`
- current authoring target label
- current subscene label
- `SaveStateIndicator`

단, `Save`와 `RootPinAction`은 글로벌 프레임에 올리지 않고 local bezel에 둔다.

## Integration With Invalid Save UX

`Music Asset Add & Config Workflow`에서 정의한 저장 차단 UX는 기본적으로 해당 서브씬 내부에서 처리한다.

- `SaveIcon` 자체의 소속은 `Authoring Local Bezel`이다
- `RootPinAction`도 `Authoring Local Bezel`에 속한다
- 하지만 저장 차단 사유와 상세 경고는 `Music Asset Add & Config` 서브씬 내부 UI가 설명한다
- 글로벌 프레임은 그 차단 사유를 기본적으로 중복 표시하지 않는다
- render 실패 시 `lint_msg`는 global alert / validation feedback으로 노출할 수 있다

즉, 저장/루트 고정 액션은 local bezel에 두되, 저장 차단 또는 render failure의 피드백은 global alert 또는 subscene 내부 UI로 연결한다.

## Alert Click Routing Rule

alert click routing은 아래처럼 고정한다.

- 연결 가능한 target이 하나로 명확하면 그 target으로 바로 이동한다
- 연결 가능한 target이 둘 이상이면 target selector dialog를 먼저 띄운다

`Alert / Warning / Error / Validation`의 visual grouping은 [Visual Theme And Graphic Style](Visual%20Theme%20And%20Graphic%20Style.md) 기준으로 single status cluster로 고정했다.

## Summary

`Global Frame UI`는 모든 scene 위에 항상 존재하는 global top / local / global bottom bezel shell이며, 상태 표시, hover data readout, 공통 버튼, dialog 호출, alert / warning / validation 인터페이스, scene-specific local action strip을 담당한다.

핵심 원칙은 아래 두 가지다.

- 글로벌 프레임은 상태를 소유하지 않고 표시한다
- 어떤 scene에서든 같은 종류의 경고와 상태는 같은 방식으로 보여야 한다
