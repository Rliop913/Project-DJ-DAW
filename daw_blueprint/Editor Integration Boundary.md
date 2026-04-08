# Editor Integration Boundary

## Purpose

이 문서는 `Project DJ DAW`의 Godot UI가 `PDJE editorObject`와 어떤 시점에 어떻게 상호작용하는지를 고정한다.

핵심은 새 translation layer를 설계하는 것이 아니라, 이미 `PDJE` editor core가 소유하는 `project-local state`, `typed mutation`, `preview`, `render`, `push`, `history`를 Godot UI에서 어떤 경계로 감싸는지 닫는 것이다.

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Preview Playback Design](Preview%20Playback%20Design.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)

이 문서는 editor integration 관련 상세 규칙의 authoritative local document다.  
`PDJE` 내부 translation, render, push의 저수준 구현은 바꾸지 않고, Godot 쪽 호출 타이밍과 UI 행동만 고정한다.

## Scope

- app-side ephemeral UI state와 editor project-local state의 경계
- `AddLine`, `deleteLine`, `getAll` 호출 시점
- `demoPlayInit` 호출 시점
- `render` 호출 시점
- `pushToRootDB` 호출 시점
- lint/render 실패 피드백 규칙
- save / root pin / escape exit의 integration rule

## Out Of Scope

- `PDJE` 내부 translation layer 구현
- `render` 내부 binary payload 생성 알고리즘
- root DB schema 자체 변경
- history diff의 세부 시각화

## Core Principles

- `PDJE` editor core가 typed mutation, render, push, history를 이미 소유한다
- Godot UI는 editor의 source of truth를 대체하지 않고, 적절한 시점에 typed API를 호출한다
- line 단위 mutation은 필요한 인자가 모두 확정되는 즉시 editor에 반영한다
- preview는 계산 비용이 큰 explicit action으로 취급한다
- save는 항상 `render`를 선행한다
- root DB push는 일반 save와 분리된 explicit action으로 둘 수 있으며, editor exit 시 자동 시도할 수 있다

## State Boundary Rule

이 프로젝트는 상태를 아래 두 층으로 나눈다.

### 1. App-Side Ephemeral UI State

- 현재 dialog 입력 중인 값
- 아직 line으로 확정되지 않은 draft selection
- hover 상태
- temporary widget-local state

이 상태는 아직 editor mutation 대상이 아니다.

### 2. Editor Project-Local State

- `AddLine`으로 이미 기록된 typed row
- `deleteLine`으로 제거 가능한 typed row
- `getAll`로 다시 읽어올 수 있는 authoritative working set
- `render`, `pushToRootDB`, `demoPlayInit`가 참조하는 상태

즉, line이 확정되기 전까지는 app-side state에 머물고, line이 확정되면 즉시 editor state로 들어간다.

## Source Of Truth Priority Rule

source of truth의 우선순위는 아래처럼 고정한다.

1. `RootDB`에 저장된 데이터
2. `editor DB` 또는 editor core가 보유한 project-local 저장 데이터
3. app-side ephemeral UI state

즉, Godot UI의 임시 입력값이나 실패 상태는 authoritative source가 아니다.  
UI와 저장 데이터가 충돌하면 항상 `RootDB` / `editor DB` 쪽 기록을 우선한다.

## Mutation Timing Rule

### AddLine

`AddLine`은 해당 줄의 fixable argument가 전부 모인 시점에서 즉시 발동한다.

- mix row든 music row든, 해당 row가 요구하는 payload와 position 정보가 모두 확정되면 바로 `AddLine`을 호출한다
- 사용자가 별도의 global save를 누를 때까지 mutation을 지연하지 않는다
- 따라서 line authoring 완료는 곧 editor project-local state 반영이다

### deleteLine

`deleteLine`은 해당 줄에 대한 제거 명령이 들어온 즉시 발동한다.

- 사용자가 tag 삭제, row 삭제, event 제거를 확정하면 즉시 `deleteLine`을 호출한다
- 별도 batch delete confirm이 없는 일반 제거 동작은 지연 queue에 두지 않는다

### getAll

`getAll`은 Godot UI를 실제 기록과 다시 동기화해야 하는 시점마다 호출한다.

대표 시점:

- scene 또는 subscene 진입 직후
- 저장/푸시/히스토리 이동 직후
- preview 종료 후 authoritative state를 다시 그려야 할 때
- 명시적 refresh가 필요할 때

즉, `getAll`은 per-click mutation API가 아니라 authoritative readback / resync API다.

## Preview Trigger Rule

`demoPlayInit`은 계산 비용이 큰 action으로 본다.

- 자동 호출하지 않는다
- UI에서 사용자가 직접 클릭 가능한 preview 버튼으로만 발동한다
- button click 시점의 current editor project-local state를 snapshot처럼 사용한다

즉, preview는 background auto-refresh가 아니라 explicit expensive action이다.

## Save Rule

일반 save는 항상 `render`를 수행한다.

- 사용자가 `SaveIcon`을 누르면 먼저 `render(trackTitle, ROOTDB, lint_msg)`를 호출한다
- `render` 성공 시 local save는 완료된 것으로 본다
- `render`는 conversion + validation 단계다

따라서 이 프로젝트에서 save의 핵심은 file write 버튼이 아니라 `render success 확보`다.

## Render Failure Feedback Rule

`render` 호출 후 lint/render 실패가 발생하면 시스템은 `lint_msg`를 사용자에게 피드백 알림으로 보여줘야 한다.

- 실패 시 save 완료로 처리하지 않는다
- `lint_msg`는 alert 또는 validation feedback으로 사용자에게 노출한다
- 상세 수정은 해당 subscene이나 관련 편집 지점에서 계속한다

즉, lint message는 내부 로그가 아니라 user-facing failure feedback이다.

## Ready For Mixset Rule

`ready_for_mixset`는 별도 휴리스틱이 아니라 `render(..., lint_msg)` 성공 여부로 판정한다.

- render가 성공하면 현재 편집 상태를 `ready_for_mixset = true`로 본다
- render가 실패하면 `ready_for_mixset = false`로 유지한다
- 실패 시 획득한 `lint_msg`를 사용자에게 보여주고, 같은 편집 컨텍스트에서 계속 수정할 수 있어야 한다

즉, `ready_for_mixset`는 field checklist만으로 확정되는 값이 아니라 editor-core render validation을 통과했는지의 결과다.

## Root Push Rule

root DB push는 일반 save와 구분한다.

### Explicit Root Pin Button

- `pushToRootDB`는 `SaveIcon` 옆의 `RootPinAction`으로 explicit하게 발동할 수 있다
- 이 버튼은 현재 rendered state를 root DB에 고정하려는 action이다
- 일반 save와 별개의 intent를 가진다
- 성공 직후에는 `Workspace Selection`의 `RootDB` track/music list가 다시 동기화되어야 한다

### Exit-Time Auto Push Attempt

- 사용자가 `ESC` 등으로 track editor를 벗어날 때 시스템은 자동 `pushToRootDB`를 시도한다
- 단, push는 항상 render-ready state를 전제로 한다

이 문서에서 exit-time behavior는 `auto push attempt`로 고정한다.

## Interaction Summary

현재 닫힌 범위에서 대표 액션의 editor integration은 아래와 같다.

- row 완성: 즉시 `AddLine`
- row 제거: 즉시 `deleteLine`
- UI authoritative resync 필요: `getAll`
- preview 버튼 click: `demoPlayInit`
- save click: `render`
- root pin click: `pushToRootDB`
- track editor exit (`ESC`): 자동 `pushToRootDB` 시도
- `pushToRootDB` 성공 후 root-visible browser 갱신: `Workspace Selection` resync

## UI Contract

Godot UI는 최소한 아래 버튼/상태와 연결되어야 한다.

- `SaveIcon`
- `RootPinAction`
- preview button
- render failure alert / validation feedback
- dirty / rendered / pushed 상태 표시

## Summary

editor integration boundary는 현재 기준으로 아래처럼 닫힌다.

- row-level authoring 완료 시점에 `AddLine` / `deleteLine`을 즉시 호출한다
- `getAll`은 authoritative resync 시점에 호출한다
- `demoPlayInit`은 계산 비용이 크므로 explicit preview 버튼에서만 호출한다
- save는 매번 `render`를 수행한다
- render 실패 시 `lint_msg`를 사용자 피드백 알림으로 노출한다
- `pushToRootDB`는 `RootPinAction` 또는 track editor exit 시 자동 시도로 연결한다
