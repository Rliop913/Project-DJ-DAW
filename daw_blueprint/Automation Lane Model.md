# Automation Lane Model

## Purpose

이 문서는 `Project DJ DAW`의 automation authoring을 lane / tag / payload / lowering 관점에서 고정한다.

특히 아래를 닫는다.

- workspace lane family 구조
- point command와 span automation의 구분
- `beat / subBeat / separate` 기반 시간 접근 규칙
- `BPM_CONTROL`의 workspace-global step-hold rule
- `8PointValues` 계열 target 집합
- target별 `first / second / third` payload schema
- parameter dialog / waveform picker 규칙
- `MixArgs` full arg lowering contract

## Relationship To Other Documents

- [BluePrintRoot](BluePrintRoot.md)
- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Mixset Timeline Model](Mixset%20Timeline%20Model.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Settings](Settings.md)

이 문서는 automation 관련 상세 규칙의 authoritative local document다.  
상위 구조는 [Mixset Timeline Model](Mixset%20Timeline%20Model.md)가 유지하되, automation payload와 lane 규칙은 이 문서를 우선한다.

## Scope

- `global parameter lane`, `track lane`, `master output lane`의 역할
- automation target의 lane 배치
- point command / span automation rule
- selection / separator / quantized access rule
- `ITPL_*` / `8PointValues` 규칙
- `first / second / third` slot 의미
- 공통 parameter dialog 규칙
- waveform-linked PCM frame picker 규칙
- generic `MixArgs` lowering contract

## Out Of Scope

- preview playback state sync
- waveform renderer의 low-level 그래픽 구현
- effect DSP 내부 알고리즘
- render 이후 master output의 시각 스타일 세부
- persistence ordering / history diff UI
- asset prep 단계의 metadata 입력 workflow

## Core Principles

- automation의 semantic source of truth는 최종 `PDJE MixArgs` row다
- UI는 lane, tag, overlay, popup으로 보일 수 있어도 저장 의미는 row 집합이다
- 시간 접근은 `beat / subBeat / separate` grid로만 한다
- 더 세밀한 접근이 필요하면 free offset이 아니라 `separator`를 높여 해결한다
- `global parameter lane`은 BPM 전용이다
- `track lane`은 실제 mix authoring의 주 공간이다
- `master output lane`은 authoring lane이 아니라 preview/render output 표시용 display-only lane이다
- `LOAD`의 identity payload는 자유 입력이 아니라 등록된 asset으로부터 파생된다
- lowering은 항상 full arg shape를 유지하고, row가 읽지 않는 컬럼은 default 상태로 둔다

## Lane Family Model

workspace의 lane family는 아래 3가지로 고정한다.

### 1. Global Parameter Lane

- workspace 전체에 대해 사실상 1개만 둔다
- BPM 관련 command만 다룬다
- 현재 닫힌 범위에서 실질적 target은 `BPM_CONTROL`뿐이다
- user-facing global tempo control은 이 lane에서만 이뤄진다

### 2. Track Lane

- 음악 asset당 하나씩 존재하는 주 lane family다
- 각 track lane은 하나의 `TrackBlock`과 대응한다
- 가장 많은 내부 편집층을 가진다
- `MusicBlock`, waveform, segment, beat access, asset별 automation tag가 이 lane 아래에 모인다
- 대부분의 `MixArgs` detail은 이 lane family에서 authoring된다

### 3. Master Output Lane

- workspace 전체에 대해 사실상 1개만 둔다
- authoring command를 직접 편집하는 lane이 아니다
- preview playback 또는 render 이후의 최종 결과를 표시하는 display-only lane family다

즉, workspace는 `global parameter lane 1개 + track lane N개 + master output lane 1개` 구조를 기본으로 본다.

## Time Access Model

automation authoring의 시간 접근은 공식 `Editor_Format`의 tuple model을 따른다.

- start tuple: `beat`, `subBeat`, `separate`
- end tuple: `Ebeat`, `EsubBeat`, `Eseparate`

규칙은 아래와 같다.

- point command는 start tuple만 사용한다
- span automation은 start tuple과 end tuple을 함께 사용한다
- 선택은 `첫 클릭 = start`, `후 클릭 = end`로 잡는다
- 역방향 선택이면 내부적으로 자동 swap한다
- 중간 공백이 있는 disjoint range는 허용하지 않는다
- 자유 offset은 허용하지 않는다
- finer access는 `separator`를 높여 해결한다

### Separator Rule

- `separator`는 편집기에서 명시적으로 바꿀 수 있는 quantized access resolution이다
- `Shift + Mouse Wheel`로 2배 증가 / 0.5배 감소시킨다
- clamp 범위는 `1 ~ 1024`다
- `separator`가 바뀌어도 이미 고정된 tag 위치는 재배치하지 않는다
- 새로 만드는 command의 접근 해상도에만 영향을 준다

일반 `Mouse Wheel`은 separator 변경이 아니라 timeline x축 zoom이다.

## Global BPM Lane Rule

global BPM control은 `global parameter lane`에만 존재한다.

- BPM target은 workspace 전역에서 하나만 본다
- 개별 `TrackBlock`이 separate BPM lane을 가지지 않는다
- 모든 track lane은 같은 workspace-global BPM lane을 참조한다

### BPM_CONTROL Rule

`Editor_Format` 기준에서 `BPM_CONTROL`은 `ITPL + 8PointValues` 계열이 아니라 point command다.

- `first`에는 target BPM 하나만 문자열로 직렬화해 넣는다
- start tuple만 사용한다
- `second`, `third`, end tuple은 읽지 않는다
- command가 나온 시점부터 effective target BPM은 해당 값으로 고정된다
- 다음 `BPM_CONTROL` command가 나올 때까지 값이 유지된다

즉, global BPM lane은 curve interpolation lane이 아니라 `step-hold BPM change lane`이다.

## Track Automation Rule

track lane은 실제 mix command를 배치하는 주 authoring surface다.

- `LOAD`, `UNLOAD`, `CONTROL`, `BATTLE_DJ`, `COMPRESSOR` 같은 point command를 가진다
- `FILTER`, `EQ`, `DISTORTION`, `VOL`, `ECHO`, `OSC_FILTER`, `FLANGER`, `PHASER`, `TRANCE`, `PANNER`, `ROLL`, `ROBOT` 같은 span automation을 가진다
- `BarBlock`은 hand-authored primitive가 아니라 derived beat access anchor다

## 8Point Automation Rule

공식 `Editor_Format`의 `Mix Data Table` 기준으로, `ITPL + 8PointValues` 기반 span automation target은 아래와 같다.

- `FILTER`
- `EQ`
- `DISTORTION`
- `VOL`
- `ECHO`
- `OSC_FILTER`
- `FLANGER`
- `PHASER`
- `TRANCE`
- `PANNER`
- `ROLL`
- `ROBOT`

반대로 아래 계열은 `8PointValues` 기반으로 보지 않는다.

- `CONTROL`
- `LOAD`
- `UNLOAD`
- `BPM_CONTROL`
- `BATTLE_DJ`
- `COMPRESSOR`

### Interpolation Rule

- 기본 interpolation은 `ITPL_COSINE`으로 둔다
- user는 필요 시 다른 `ITPL_*`를 선택할 수 있다
- `ITPL_FLAT`에서는 하나의 값을 움직이면 다른 point도 함께 따라가도록 본다

## Parameter Input Windows

timeline에서 tag를 생성하거나 수정할 때는 최대 3개의 공통 parameter window를 재사용한다.

- `first`: 화면 하단 좌하
- `second`: 화면 하단 중하
- `third`: 화면 하단 우하

규칙은 아래와 같다.

- slot이 비어 있으면 그 창은 띄우지 않는다
- 비어 있는 slot이 있으면 남은 창이 그 영역까지 확장된다
- scalar 값은 공통 numeric dialog를 재사용한다
- 사용자가 입력한 값은 apply 직전에 `__SETTING_VAL__AUTOMATION_PARAM_SCALAR_COERCE_MODE` 규칙에 따라 그대로 유지하거나 `floor` 처리한다
- apply 시점에는 값을 자동으로 string 직렬화해 payload slot에 넣는다
- 자유 문자열 입력을 허용하는 일반 text dialog는 두지 않는다

### PCM Frame Picker

PCM frame 위치를 요구하는 slot은 일반 scalar dialog 대신 waveform-linked picker를 사용한다.

- 사용자는 RGB waveform 위의 bar 위치를 고른다
- 시스템은 그 위치를 음악 블록 내부 기준 PCM frame index로 환산한다
- 환산된 값은 해당 slot에 자동 기입된다

이 규칙은 아래 slot payload에 적용한다.

- `approx_loc`
- `StartPosition`

### Tuple Dialog

comma-separated numeric tuple을 요구하는 slot은 tuple arity에 맞는 dialog를 쓴다.

- 2-field tuple: `string(float),string(float)`
- 3-field tuple: `string(float),string(float),string(float)`

예:

- `Thresh, Knee`
- `ATT, REL`
- `BPM, feedback`
- `BPM, MiddleFreq, RangeHalfFreq`

## LOAD Payload Rule

`LOAD`에서의 `title`, `composer`, `bpm`은 자유 입력이 아니다.

- user는 등록된 music asset을 선택한다
- 시스템은 현재 editor 등록 상태를 질의해 `title`, `composer`, `bpm`을 자동 기입한다
- 따라서 `LOAD` payload는 freeform text가 아니라 selected asset에서 파생되는 derived payload다

## Mix Target Parameter Schema

아래 표는 공식 `Editor_Format`의 `Mix Data Table`과 현재 blueprint 해석을 결합해 고정한 것이다.

| Target | Command Shape | Start/End Usage | `first` | `second` | `third` | UI Input Rule |
| --- | --- | --- | --- | --- | --- | --- |
| `FILTER` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `EQ` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `DISTORTION` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `VOL` | span automation | start + end | `ITPL_*` | `8PointValues` | none | 8point popup |
| `ECHO` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, feedback` | 8point popup + tuple dialog |
| `OSC_FILTER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, MiddleFreq, RangeHalfFreq` | 8point popup + tuple dialog |
| `FLANGER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `PHASER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `TRANCE` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, GAIN` | 8point popup + tuple dialog |
| `PANNER` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM, GAIN` | 8point popup + tuple dialog |
| `ROLL` | span automation | start + end | `ITPL_*` | `8PointValues` | `BPM` | 8point popup + scalar dialog |
| `ROBOT` | span automation | start + end | `ITPL_*` | `8PointValues` | `ocsFreq` | 8point popup + scalar dialog |
| `CONTROL.PAUSE` | point command | start only | `approx_loc` | none | none | waveform picker |
| `CONTROL.CUE` | point command | start only | `approx_loc` | none | none | waveform picker |
| `LOAD` | point command | start only | `title` | `composer` | `bpm` | registered asset lookup only |
| `UNLOAD` | point command | start only | none | none | none | tag only |
| `BPM_CONTROL` | point command | start only | target BPM | none | none | scalar dialog |
| `BATTLE_DJ.SPIN` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.PITCH` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.REV` | point command | start only | `SPEED` | none | none | scalar dialog |
| `BATTLE_DJ.SCRATCH` | point command | start only | `StartPosition` | `SPEED` | none | waveform picker + scalar dialog |
| `COMPRESSOR` | point command | start only | `Strength` | `Thresh, Knee` | `ATT, REL` | scalar dialog + tuple dialog |

## MixArgs Lowering Contract

mix row lowering은 `PDJE_EDITOR_ARG.InitMixArg(...)`가 받는 full arg shape를 기준으로 한다.

- 모든 mix row는 기본적으로 `type`, `id`, `details`, `first`, `second`, `third`, `beat`, `subBeat`, `separate`, `Ebeat`, `EsubBeat`, `Eseparate` 전체 컬럼을 가진 full arg로 본다
- point command는 start tuple만 채운다
- span automation은 start tuple과 end tuple을 함께 채운다
- row가 실제로 읽는 payload slot만 채우고, 나머지는 default 상태로 둔다
- row가 읽지 않는 tuple column도 default 상태로 둔다

즉, lowering의 핵심은 row마다 별도 구조체를 만드는 것이 아니라, **공통 full arg shape 위에서 detail별 읽기 컬럼을 정확히 고정하는 것**이다.

## Validation Rules

- `global parameter lane`에는 `BPM_CONTROL`만 들어간다
- `track lane`은 음악 asset당 정확히 하나만 둔다
- `master output lane`은 display-only이므로 authoring command를 저장하지 않는다
- `LOAD`는 registered asset lookup 없이 freeform text로 만들지 않는다
- `8PointValues` target은 반드시 start/end tuple을 함께 가진다
- point command는 end tuple을 사용하지 않는다
- tuple payload는 schema에서 정한 arity와 정확히 일치해야 한다
- PCM frame payload는 waveform picker가 source of truth다

## Summary

Automation lane model은 현재 기준으로 아래처럼 닫힌다.

- lane family는 `global parameter lane 1개 + track lane N개 + master output lane 1개`
- global BPM은 workspace-global `BPM_CONTROL` point command 집합이다
- 대부분의 mix automation은 track lane에서 이뤄진다
- `8PointValues` 계열은 span automation, `CONTROL/LOAD/UNLOAD/BPM_CONTROL/BATTLE_DJ/COMPRESSOR`는 point command 계열이다
- parameter UI는 `first/second/third` 하단 3-slot dialog system과 waveform picker를 공유한다
- lowering은 항상 full arg shape를 유지하고, unused column은 default 상태로 둔다
