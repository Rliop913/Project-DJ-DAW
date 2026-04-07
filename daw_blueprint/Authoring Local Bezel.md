# Authoring Local Bezel

## Purpose

이 문서는 `Authoring Scene`에서 사용하는 `Local Bezel`의 역할과 배치를 정의한다.

핵심 원칙은 간단하다.  
`Authoring Local Bezel`은 `Mixset Editing Workspace`와 `Music Asset Add & Config Workspace`가 **공통으로 가지는 최소 액션과 최소 상태만** 보여주는 strip이다.

즉, 이 bezel은 서브씬별 도구 모음을 대신하지 않는다.  
너무 많은 정보를 담지 않고, authoring 전체에서 항상 의미가 유지되는 요소만 포함해야 한다.

## Relationship To Other Documents

- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Settings](Settings.md)

이 문서는 `Global Frame UI`가 정의한 `Local Bezel` 개념 중, `Authoring` 영역만 상세화한다.

## Scope

이 문서가 다루는 범위는 아래와 같다.

- `Authoring Local Bezel`의 공통 역할
- 좌측 상단 배치 규칙
- 공통 액션과 공통 상태의 범위
- `SaveIcon`과 `Return` 계열 액션의 위치
- `Mixset Editing`과 `Music Asset Add & Config` 모두에서 유지되는 최소 공통 구조

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- `Global Top Bezel`과 `Global Bottom Bezel`
- alert center와 background task queue
- timeline 내부 toolbar
- metadata form 내부 button
- subscene 전용 toolbar
- render / push / analysis 같은 서브씬 의존 액션의 세부 규칙

## Core Principles

- `Authoring Local Bezel`은 공통 요소만 담아야 한다
- 서브씬 전용 도구는 본문이나 서브씬 내부 toolbar로 내려야 한다
- 정보 밀도는 낮게 유지해야 한다
- 핵심 액션은 빠르게 접근 가능해야 한다
- `Return`과 `Save`는 좌측 상단 bezel 영역에 배치해야 한다
- 버튼 수는 `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_AUTHORING`을 넘기지 않는 방향을 따른다
- 높이는 `__SETTING_VAL__UI_LOCAL_BEZEL_HEIGHT_PX`를 따른다

## Role Definition

`Authoring Local Bezel`은 아래 두 역할만 수행한다.

1. 현재 authoring 맥락의 최소 공통 상태 표시
2. 모든 authoring subscene에서 의미가 유지되는 핵심 액션 제공

이 문서 기준으로, `Authoring Local Bezel`은 **공통 strip**이지 **기능 집약 toolbar**가 아니다.

## Minimal Common Content

이 bezel에 남겨야 하는 공통 요소는 아래 정도로 제한한다.

- current authoring target 요약
- current subscene label
- `ReturnAction`
- `SaveIcon`
- `SaveStateIndicator`

이보다 깊은 정보는 넣지 않는다.

예를 들어 아래 정보는 넣지 않는다.

- 선택된 event 상세값
- BPM row 상세
- metadata field 상세
- background task queue
- 긴 경고 목록
- render / push / analysis 개별 제어

## Layout Rule

`Authoring Local Bezel`은 `Global Top Bezel` 바로 아래에 위치한다.

레이아웃은 아래 세 구역으로 나눈다.

### Left Zone

이 구역은 가장 중요한 공통 액션 영역이다.

- `ReturnAction`
- `SaveIcon`

즉, 씬 전환 성격의 `Return`과 씬 상태 기록 성격의 `Save`는 모두 **좌측 상단 bezel 영역**에 배치한다.

### Center Zone

- current authoring target label
- current subscene label

이 구역은 현재 작업 맥락을 짧게 보여주는 용도다.

### Right Zone

- `SaveStateIndicator`

이 구역은 읽기 중심의 짧은 상태 표시만 허용한다.

## Common Actions

### ReturnAction

`ReturnAction`은 authoring 안에서 현재 서브씬을 벗어나 **기본 작업 공간**으로 돌아가기 위한 공통 액션이다.

일반 규칙은 아래와 같다.

- `Mixset Editing Workspace`에서는 주 작업 공간이므로 `ReturnAction`은 비활성화되거나 숨길 수 있다
- `Music Asset Add & Config Workspace`에서는 `Mixset Editing Workspace`로 복귀하는 공통 액션으로 동작한다
- 이 액션은 좌측 상단 bezel 영역에 위치한다

### SaveIcon

`SaveIcon`은 현재 authoring context를 저장하려는 공통 액션이다.

일반 규칙은 아래와 같다.

- 모든 authoring subscene에서 같은 위치를 유지해야 한다
- 위치는 항상 좌측 상단 bezel 영역이다
- 단축키는 `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT`를 따른다
- 저장 불가 상태라면 `__SETTING_VAL__SAVE_GUARD_SHOW_DIALOG_ON_INVALID_SAVE` 규칙에 따라 경고 dialog를 띄운다

저장 불가 상태의 상세 표시는 local bezel이 아니라, 해당 서브씬 내부 UI를 따른다.

### SaveStateIndicator

`SaveStateIndicator`는 현재 authoring context의 저장 상태를 짧게 보여주는 공통 표시다.

이 표시가 담당하는 범위는 아래와 같다.

- 최신 저장 상태인지
- 아직 저장되지 않은 변경이 있는지
- 방금 저장이 완료되었는지
- 현재 저장이 진행 중인지

이 표시가 담당하지 않는 범위는 아래와 같다.

- 저장 불가 원인의 상세 목록
- 필수 필드 누락 설명
- validation 오류 설명

즉, `SaveStateIndicator`는 **저장 상태 표시**이고, **저장 차단 사유 표시**가 아니다.

## Common Status

### Current Authoring Target

center zone에는 현재 편집 중인 authoring target을 짧게 표시한다.

예:

- 현재 track title
- 현재 asset config 대상 이름

이 값은 긴 설명이 아니라 식별 가능한 짧은 label이어야 한다.

### Current Subscene Label

현재 서브씬 이름을 표시한다.

예:

- `Mixset Editing`
- `Music Asset Add & Config`

### Save State

우측 영역의 `SaveStateIndicator`는 아래 정도의 최소 상태만 보여준다.

- latest
- modified
- recently saved
- saving

이 표시는 icon 또는 짧은 badge로 충분해야 한다.

## What Must Stay Out

아래 항목은 `Authoring Local Bezel`에 올리지 않는다.

- preview
- render
- push
- re-run analysis
- add music asset
- event-specific command
- field-specific fix button

이들은 서브씬별 toolbar, panel, inspector, main content action 영역으로 내려야 한다.

## Variant Rule

`Authoring Local Bezel`은 `Mixset Editing`과 `Music Asset Add & Config` 모두에서 보이지만, 차이는 최소화해야 한다.

허용되는 차이는 아래 정도다.

- `ReturnAction`의 활성/비활성 상태
- center zone의 current target label 내용

즉, bezel의 골격 자체는 바뀌지 않아야 한다.

## Interaction Rules

### Hover

- `ReturnAction` hover: 어디로 돌아가는지 설명
- `SaveIcon` hover: 현재 저장 대상이 무엇인지 설명
- `SaveStateIndicator` hover: 현재 저장 상태 설명

### Click

- `ReturnAction` click: 기본 작업 공간으로 이동
- `SaveIcon` click: 현재 context 저장 시도

### Blocked Action

- 저장 불가 상태에서 `SaveIcon` click 시, 차단 사유는 현재 서브씬 내부 UI가 설명한다
- 현재 위치가 이미 기본 작업 공간이면 `ReturnAction`은 무반응이 아니라 비활성 또는 숨김 처리

## Scene Integration Contract

각 authoring subscene은 `Authoring Local Bezel`에 아래 정보를 제공해야 한다.

- current target label
- current subscene name
- save state
- save availability
- return target availability

이 bezel은 이 정보만 구독해서 공통 strip을 유지한다.

## Relationship To Global Frame

`Authoring Local Bezel`은 `Global Frame UI`와 역할이 겹치면 안 된다.

- global frame: alert, warning, background task, hover readout, global status
- authoring local bezel: return, save, save state, 최소 공통 상태

즉, 경고 시스템과 작업 큐는 global frame에 두고, authoring local bezel은 최대한 가볍게 유지한다.

## Open Questions

- `ReturnAction`을 icon만으로 둘지, icon + text로 둘지 결정이 필요하다
- `SaveStateIndicator`를 icon만으로 둘지, 짧은 text badge를 함께 둘지 결정이 필요하다

## Summary

`Authoring Local Bezel`은 authoring subscene들이 공통으로 공유하는 최소 공통 strip이다.  
핵심 규칙은 아래 두 가지다.

- `Return`과 `Save`는 좌측 상단 bezel 영역에 둔다
- 공통 요소만 남기고, 서브씬 전용 도구는 본문 쪽으로 내린다
