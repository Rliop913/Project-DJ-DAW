# Project DJ DAW Blueprint Root

## Primary Reference

이 프로젝트의 상위 기준 문서는 아래 `Project DJ Godot / PDJE` 문서다.

- [Project-DJ-Engine Documentation](https://rliop913.github.io/Project-DJ-Engine/)
- [Getting Started](https://rliop913.github.io/Project-DJ-Engine/Getting%20Started.html)
- [Editor Format](https://rliop913.github.io/Project-DJ-Engine/Editor_Format.html)
- [PDJE For AI Agents](https://rliop913.github.io/Project-DJ-Engine/PDJE_For_AI_Agents.html)

이 블루프린트는 위 문서의 개념을 가능한 한 존중하며 작성한다.  
특히 `mixset authoring`, `DAW-style editing APIs`, `timeline mix events`, `preview playback`, `editor workflow` 개념은 본 프로젝트 정의의 직접적인 기준점이다.

## Blueprint Documents

- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Settings](Settings.md)
- [Todo List](todo-list.md)

## Session Dumps

- [Session Dump - 2026-04-08](Session%20Dump%20-%202026-04-08.md)

가변 값과 공통 설정 변수는 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목으로 중앙 관리한다.

## Overview

### 프로젝트 정의
이 프로젝트의 목적은 **실시간으로 디제잉을 수행하는 라이브 퍼포먼스 앱**을 만드는 것이 아니다.  
목표는 **디제잉에 사용되는 도구와 조작 개념을 소프트웨어화하여, DAW에서 작곡하듯 DJ 믹스셋을 편집하고 설계하는 그래픽 기반 저작 툴**을 만드는 것이다.

즉, 사용자는 곡을 타임라인에 배치하고, 특정 시점에 어떤 곡이 로드되고, 어떤 EQ/FX 변화가 적용되며, 어떤 전환이 일어나야 하는지를 **시간축 기반으로 설계**할 수 있어야 한다.  
이 프로젝트는 DJ의 퍼포먼스 행위를 **사후 녹음**하는 방식보다, DJ 셋을 **구성하고 자동화하고 재현 가능한 편집 데이터로 만드는 방식**에 가깝다.

### Project DJ Godot과의 관계
이 프로젝트는 `Project DJ Godot / PDJE`와 경쟁하는 별도 엔진을 새로 만드는 것이 아니다.  
오히려 목표는 `PDJE`가 이미 가진 다음 성격을 **Godot 기반의 명확한 그래픽 인터페이스로 노출하는 것**에 가깝다.

- DJ mixing + DAW-style editing 개념
- mixset authoring
- 음악 메타데이터 및 mixset 데이터 관리
- 시간축 기반 mix event 편집
- preview playback 및 재현 가능한 편집 결과

정리하면, 이 프로젝트는 **Project DJ Godot의 편집 개념을 시각적 UI/UX로 구체화한 authoring tool**이다.

### 제품 정체성
Project DJ DAW는 아래 성격을 가진다.

- DJ 셋을 시간축 위에서 설계하는 DAW형 믹스셋 에디터
- 기존 음원을 사용해 전환, EQ, FX, BPM 제어를 편집하는 저작 툴
- 라이브 DJ 퍼포먼스보다 오프라인 authoring과 재현 가능한 playback에 초점을 둔 도구
- PDJE의 mixset/editing 모델을 Godot GUI로 구체화하는 소프트웨어

### 타깃 사용자
주 타깃은 아래 사용자들이다.

- 기존 상용 DJ 소프트웨어 사용자
- 덱 기반 DJ 워크플로우에 익숙한 사용자
- DJ 개념에는 익숙하지만 더 정교한 시퀀스형 편집을 원하는 사용자
- 라이브 퍼포먼스를 반복 재현 가능한 믹스셋 데이터로 만들고 싶은 사용자
- PDJE 개념을 코드가 아니라 GUI로 다루고 싶은 사용자

이들은 일반 작곡가보다 **전환 설계, 큐 포인트, 루프, EQ 컷, FX 타이밍, 셋 구성**에 익숙한 사용자다.

### 해결하려는 문제
기존 DJ 소프트웨어는 실시간 플레이에 강하지만, 아래 요구를 충분히 만족하지 못할 수 있다.

- DJ 셋 전체를 DAW처럼 시간축에서 설계하고 싶다
- 로드, 언로드, 전환, EQ, FX 변화를 이벤트로 명시하고 싶다
- 퍼포먼스 감각의 작업을 재현 가능한 프로젝트 데이터로 저장하고 싶다
- 엔진 내부 모델과 편집 UI를 프로젝트 목적에 맞게 직접 통제하고 싶다

이 프로젝트는 위 문제를 해결하기 위해, **DJ workflow의 DAW화**를 목표로 한다.

### 핵심 개념
이 프로젝트에서 편집 대상은 단순 오디오 파형 자체가 아니라, **믹스셋을 구성하는 이벤트와 자동화 데이터**다.

핵심 개념은 아래와 같다.

- 음악 자산을 라이브러리로 등록한다
- 믹스셋 안에서 곡이 어느 시점에 로드되고 재생되는지 정의한다
- 특정 시점 또는 구간에 EQ, Filter, Volume, BPM, FX 등의 변화를 배치한다
- Cue, Pause, Load, Unload 같은 DJ 동작을 timeline event로 표현한다
- 작성된 결과를 preview playback으로 검증한다
- 최종적으로 반복 재생 가능한 믹스셋 데이터로 저장한다

### 제품 목표

- 사용자가 곡 라이브러리를 등록하고 메타데이터를 관리할 수 있어야 한다
- 믹스셋 단위의 프로젝트를 만들고 편집할 수 있어야 한다
- 곡의 배치와 로드/언로드 시점을 시간축에서 정의할 수 있어야 한다
- EQ, Filter, Volume, BPM, FX를 시간축 자동화로 편집할 수 있어야 한다
- Cue, Pause, Loop 성격의 DJ 조작을 이벤트 형태로 다룰 수 있어야 한다
- 작성된 믹스셋을 preview playback으로 확인할 수 있어야 한다
- 프로젝트 상태와 편집 결과를 저장/복원할 수 있어야 한다
- PDJE 개념을 비개발자도 다룰 수 있을 정도의 GUI로 정리해야 한다

### 비목표
초기 단계에서 아래 항목은 주 목표에서 제외한다.

- 라이브 공연용 실시간 DJ 앱을 우선 구현하는 것
- 즉흥 조작 중심의 상용 DJ 퍼포먼스 툴 완전 대체품을 만드는 것
- 전통적인 작곡용 DAW처럼 MIDI 작곡과 악기 제작 기능을 제공하는 것
- 고급 오디오 엔진 자체를 처음부터 새로 만드는 것
- PDJE의 핵심 엔진 역할을 대체하는 것

핵심 원칙은 **DJ performance software**가 아니라 **DJ authoring software**를 만든다는 점이다.

### 핵심 사용자 시나리오

1. 사용자는 음악 라이브러리에 곡을 등록한다.
2. 새 믹스셋 프로젝트를 생성한다.
3. 타임라인에 곡을 배치하고, 어느 시점에 어떤 곡이 로드될지 정의한다.
4. 전환 구간에 EQ, Filter, Volume, BPM, FX automation을 배치한다.
5. 필요 시 Cue/Pause/Load/Unload 계열 이벤트를 설정한다.
6. 전체 믹스셋을 preview playback으로 재생해 결과를 검증한다.
7. 프로젝트를 수정하고 저장하며, 반복적으로 믹스셋을 다듬는다.

이 흐름이 제품 설계의 기준선이다.

### PDJE 기준 기능 해석
PDJE 문서상 mix timeline 데이터는 단순 오디오 클립 편집이 아니라, **시간축에서 playback/process behavior를 바꾸는 event row** 개념에 가깝다.  
이 프로젝트는 그 개념을 사용자 친화적으로 시각화해야 한다.

초기 설계에서 중요하게 반영할 이벤트 범주는 아래와 같다.

- LOAD / UNLOAD
- CONTROL 계열 이벤트
- VOL 계열 자동화
- EQ / FILTER
- BPM_CONTROL
- ECHO 및 기타 FX 계열

즉, 제품의 중심은 `오디오 클립 자르기`보다 **DJ 이벤트와 믹싱 자동화를 timeline authoring 하는 것**이다.

### MVP 범위
초기 MVP는 아래 기능을 중심으로 정의한다.

- 음악 라이브러리 등록 및 메타데이터 표시
- 믹스셋 프로젝트 생성
- 시간축 기반 곡 배치
- Load/Unload 이벤트 배치
- 기본 EQ/Filter/Volume automation lane
- BPM 관련 기본 제어
- 최소 1~2종의 대표 FX automation
- preview playback
- 프로젝트 저장/불러오기
- Godot 기반 그래픽 타임라인 UI

MVP에서 중요한 것은 기능 수가 아니라, **PDJE의 mixset authoring 개념을 GUI에서 일관되게 다룰 수 있는가**다.

### 기술 방향
이 프로젝트는 다음 전제를 가진다.

- **Godot**은 그래픽 인터페이스, 타임라인 상호작용, 브라우저, 파라미터 편집 UI를 담당한다
- **Project DJ Godot / PDJE**는 믹스셋 재생과 편집 모델의 핵심 참고축이 된다
- 제품의 핵심은 실시간 공연 입력 처리보다 **프로젝트 데이터 모델과 시간축 이벤트 편집 모델**에 있다
- UI는 엔진의 내부 구조를 숨기되, 개념은 왜곡하지 않아야 한다

따라서 설계 우선순위는 아래 순서를 따른다.

1. PDJE 개념과 매핑되는 프로젝트 데이터 모델 정의
2. Mixset timeline model 정의
3. Automation lane model 정의
4. Preview playback flow 정의
5. Godot GUI 구조 정의
6. 저장 포맷과 PDJE 친화적 변환 경계 정의

### 상위 구조 개념
프로젝트는 개략적으로 다음 영역으로 분해된다.

- **Library Layer**: 음악 자산, 메타데이터, 브라우징
- **Mixset Model**: 곡 배치, 이벤트, 구간, 전환 구조
- **Automation Layer**: EQ, Filter, Volume, BPM, FX 파라미터 자동화
- **Playback Preview Layer**: 작성 결과의 검증 재생
- **Godot Editor UI**: 타임라인, 인스펙터, 브라우저, 이벤트 편집 패널
- **Persistence Layer**: 프로젝트 저장/복원 및 PDJE 개념과의 데이터 정렬

### 성공 기준
프로젝트 1차 성공 기준은 다음과 같다.

- 사용자가 실제 곡들로 하나의 믹스셋을 시간축에서 설계할 수 있어야 한다
- EQ/FX/BPM 변화를 특정 시점과 파라미터 값으로 명확히 편집할 수 있어야 한다
- preview playback 결과가 사용자가 의도한 전환 구조를 재현해야 한다
- PDJE 문서와 개념적으로 충돌하지 않는 데이터 모델을 유지해야 한다
- PDJE에 부족했던 GUI authoring 경험을 명확히 제공해야 한다

### 주요 리스크

- 제품 방향이 다시 실시간 DJ 앱 쪽으로 흔들릴 수 있다
- 일반 DAW의 오디오 편집기처럼 잘못 설계되면 PDJE 개념과 멀어질 수 있다
- 이벤트 모델과 GUI 표현 사이 매핑이 불명확하면 편집기가 오히려 더 어려워질 수 있다
- PDJE 데이터 개념을 충분히 이해하지 못하면 저장 구조가 쉽게 틀어질 수 있다

따라서 문서 단계에서 가장 먼저 고정해야 할 것은 **mixset timeline semantics, automation semantics, preview workflow, GUI mapping**이다.

## Documentation Roadmap

이 루트 문서는 전체 설계 문서의 출발점이다. 이후 최소한 아래 문서들이 순차적으로 작성되어야 한다.

- Product Goals
- User Personas
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- Functional Requirements
- Non-Functional Requirements
- Library and Metadata Model
- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- Automation Lane Model
- Preview Playback Design
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Global Frame UI](Global%20Frame%20UI.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Settings](Settings.md)
- [Todo List](todo-list.md)
- Godot UI Structure
- Persistence and Translation Layer
- Milestone Plan

## Blueprint Writing Principles

- Project DJ Godot 문서와 개념적으로 충돌하지 않게 작성해야 한다
- 실시간 DJ tool과 mixset authoring tool을 혼동하지 않아야 한다
- 모든 기능은 timeline editing 관점에서 설명해야 한다
- 이벤트와 자동화의 의미를 먼저 정의하고 UI를 나중에 덧씌워야 한다
- GUI는 엔진 개념을 단순화할 수는 있어도 왜곡해서는 안 된다

## Current Direction

현재 기준의 한 줄 정의는 다음과 같다.

> **Project DJ DAW는 Project DJ Godot의 mixset authoring 개념을 Godot GUI로 구현하여, DJ workflow를 DAW처럼 시간축에서 배치·자동화·미리듣기 할 수 있게 만드는 그래픽 기반 편집 도구다.**
