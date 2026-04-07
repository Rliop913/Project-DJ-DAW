# Music Asset Add & Config Workflow

## Purpose

이 문서는 사용자의 컴퓨터에 있는 음악 파일을 `Project DJ DAW` 안으로 가져오고, 믹스 에디터에서 사용할 수 있는 `music asset`으로 확정하는 절차를 정의한다.

이 문서의 핵심 목표는 아래 두 단계를 고정하는 것이다.

1. `Add`: 운영체제 파일 탐색기 기반으로 음악 파일을 선택하거나 드래그 앤 드롭으로 가져온다
2. `Config`: 가져온 음악 파일에 대해 필요한 메타데이터와 BPM 관련 정보를 **전부 수동으로 입력**하고, 검증을 통과한 뒤에만 저장한다

이 workflow는 단순 파일 등록이 아니라, **믹스 authoring에 사용할 수 있는 신뢰 가능한 music asset을 만드는 절차**다.

## Relationship To Other Documents

이 문서는 아래 문서들과 직접 연결된다.

- [Core Authoring Workflow](Core%20Authoring%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Settings](Settings.md)

`Core Authoring Workflow` 안에서는 이 절차가 "음악 자산 등록" 단계에 해당하며, `Godot Scene Workflow` 안에서는 `Music Asset Add & Config Workspace`의 상세 행동 규칙에 해당한다.
파일 import 허용 방식, 저장 단축키, 초기 save gate, autosave 간격, waveform render profile, invalid save feedback 같은 가변 값은 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목을 따른다.

## Scope

이 문서가 다루는 범위는 아래와 같다.

- 운영체제 파일 탐색기에서 음악 파일 가져오기
- 드래그 앤 드롭 기반 추가
- 네이티브 파일 탐색기 호출 기반 추가
- 가져온 파일의 유효성 확인
- Config 단계에서의 수동 메타데이터 입력
- app-local initial draft save
- `PDJE` editor registration
- 조건부 `PDJE` waveform 생성 호출과 파형 표시 준비
- BPM 시작값과 BPM 전환 메타데이터 입력
- timing anchor 입력
- 사용자 태그 입력
- app-local 주기적 autosave
- 저장 가능 여부 검증
- return save 후 mix editor로 복귀

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- 믹스셋 timeline 편집
- EQ / FX automation authoring
- 라이브 DJ 입력 처리
- 루트 DB 최종 push 절차
- MIR 알고리즘 내부 구현
- waveform renderer의 그래픽 구현 세부

## Core Rules

이 workflow는 아래 규칙을 강하게 따른다.

- 음악 파일은 반드시 사용자의 로컬 컴퓨터에서 가져와야 한다
- 파일 유입 수단은 `__SETTING_VAL__ASSET_IMPORT_ALLOW_DRAG_AND_DROP`와 `__SETTING_VAL__ASSET_IMPORT_ALLOW_NATIVE_FILE_PICKER`가 허용한 경로만 사용한다
- 제목, BPM, 작곡가 등 모든 핵심 메타데이터는 Config 단계에서 사용자가 직접 입력해야 한다
- 필수 필드에는 `__SETTING_VAL__ASSET_CONFIG_ALLOW_FIELD_DEFAULTS = false` 규칙을 적용한다
- 자동 분석 결과가 있더라도 필수 필드를 자동으로 채우지 않는다
- source file이 valid 되기 전에는 config form을 열지 않는다
- 초기 app-local draft save는 `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`를 충족해야 한다
- 실제 `PDJE` registration은 `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS`를 충족해야 한다
- return save는 `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`를 충족해야 한다
- `EditorWrapper.ConfigNewMusic(NewMusicName, composer, musicPath, firstBar)`는 `firstBar`를 요구하므로, 현재 blueprint는 `__SETTING_VAL__ASSET_CONFIG_ALLOW_PDJE_FIRSTBAR_DEFAULT = false` 정책을 따른다
- 현재 `PDJE_MIR.SoundToWaveform` 계열은 raw file path를 받지 않고 `SearchMusic(title, composer, bpm)` 가능한 대상을 요구하므로, `PDJE` waveform은 asset이 `PDJE` search-visible 상태가 된 뒤에만 호출할 수 있다
- `autosave`는 현재 `PDJE` binding이 직접 제공하는 save API가 아니라, `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_SCOPE`가 정의하는 app-local working draft 보호 기능으로 본다

즉, `Add`는 파일을 데려오는 절차이고, `Config`는 그 파일을 authoring asset으로 확정하는 절차다.

## PDJE Capability Boundary

현재 binding 기준으로 `PDJE`가 직접 해줄 수 있는 일과, 앱 레이어가 맡아야 하는 일은 분리해서 봐야 한다.

### PDJE-Bound Capabilities

- `PDJE_Wrapper.GetPCMFromMusicData(...)`를 통한 PCM decode 기반 유효성 확인
- `EditorWrapper.ConfigNewMusic(...)`를 통한 music entry 등록
- `EditorWrapper.EditMusicFirstBar(...)`를 통한 `firstBeat` 수정
- `PDJE_EDITOR_ARG.InitMusicArg(...)` + `EditorWrapper.AddLine(...)`를 통한 BPM row 등록
- `PDJE_MIR.SoundToWaveform(...)` / `SoundToRGBWaveform(...)`를 통한 waveform/STFT 생성

### App-Layer Responsibilities

- OS drag-and-drop / native file picker import
- 초기 draft 저장과 form working copy 관리
- autosave 스케줄링
- tag UI와 tag persistence
- 저장 불가 상태 UI와 validation message presentation
- `PDJE` registration 이후 identity field를 다시 바꾸고 싶을 때의 재시작/재생성 UX

### Important Constraint

현재 binding 문서 기준으로 `PDJE_MIR.SoundToWaveform(...)`는 imported file의 raw path를 직접 받지 않는다.  
내부적으로 `PDJE_Wrapper.SearchMusic(title, composer, bpm)`를 먼저 수행하므로, **새 파일을 막 가져온 직후의 app-local draft만으로는 PDJE waveform 호출이 보장되지 않는다**.

## Entry Conditions

이 workflow가 시작되기 위한 최소 조건은 아래와 같다.

- 사용자가 이미 유효한 authoring session 안에 있다
- `Music Asset Add & Config Workspace`로 진입할 수 있다
- 사용자는 새 음악 자산 추가 또는 기존 음악 자산 재설정을 선택했다

## Exit Conditions

이 workflow가 성공적으로 끝났다고 보기 위한 조건은 아래와 같다.

- 음악 파일의 source path가 유효하다
- 필수 메타데이터가 전부 수동 입력되었다
- BPM 시작값과 BPM 전환 메타데이터가 유효하다
- timing anchor가 확정되었다
- `PDJE` editor registration이 완료되었다
- asset identifier가 생성 또는 갱신되었다
- 저장 직후 mix editor에서 해당 asset을 **project-local authoring 대상**으로 사용할 수 있다

`ready_for_mixset`는 현재 문서에서 `__SETTING_VAL__ASSET_READY_FOR_MIXSET_IMPLIES_ROOT_DB_VISIBILITY = false`를 따른다.  
즉, 이 상태는 root DB searchable 상태와 동의어가 아니다.

## Workflow Split

이 workflow는 두 단계로 나뉜다.

1. `Add Step`
2. `Config Step`

`Add Step`를 통과하지 못하면 `Config Step`으로 갈 수 없다.  
`Config Step`을 통과하지 못하면 `mix-ready asset`으로 확정할 수 없고, `Mixset Editing`에서 즉시 사용할 수 있는 상태도 만들어지지 않는다.

## Add Step

### Purpose

사용자의 로컬 환경에서 정확한 음악 파일 하나를 선택하고, 그 파일을 Config 대상으로 확정한다.

### Allowed Entry Methods

- 운영체제 파일 탐색기에서 드래그 앤 드롭
- UI의 `Browse` 또는 `Import File` 액션을 통해 네이티브 파일 탐색기 호출

실제 허용 여부는 아래 설정을 따른다.

- `__SETTING_VAL__ASSET_IMPORT_ALLOW_DRAG_AND_DROP`
- `__SETTING_VAL__ASSET_IMPORT_ALLOW_NATIVE_FILE_PICKER`

### Canonical Add Flow

1. 사용자는 `Add Music` 액션을 실행한다
2. 시스템은 파일 드롭 영역을 보여주거나 네이티브 파일 탐색기를 호출할 수 있게 한다
3. 사용자는 파일을 드래그 앤 드롭하거나 파일 탐색기에서 선택한다
4. 시스템은 파일 경로, 접근 가능 여부, 지원 포맷 여부를 검증한다
5. 검증이 성공하면 임시 import session을 만든다
6. 시스템은 `Config Step`으로 이동한다

### Validation In Add Step

아래 조건을 통과해야 한다.

- 파일이 실제로 존재한다
- 읽기 가능한 경로다
- `__SETTING_VAL__ASSET_IMPORT_SUPPORTED_AUDIO_FORMATS` 안의 지원 오디오 포맷이다
- 오디오 소스로 열 수 있는 파일이다
- 현재 session에서 참조 가능한 source file이다

이 단계의 audio validity 검사는 app-level decoder 또는 `PDJE_Wrapper.GetPCMFromMusicData({ musicPath = ... })` 경로로 수행할 수 있다.  
반대로 `PDJE_MIR.SoundToWaveform(...)`는 이 단계에서 쓰는 것이 맞지 않다. 해당 binding은 raw file path가 아니라 `SearchMusic(...)` 가능한 자산을 전제로 하기 때문이다.

이 단계에서는 아직 asset을 저장하지 않는다.  
성공 결과는 **"Config 가능한 source file 확보"**다.

### Rejected Behavior

- 앱이 임의 폴더를 자동 스캔해 곡을 가져오는 것
- 파일명만으로 곡 제목 필드를 자동 채우는 것
- 파일 태그를 읽어서 필수 메타데이터를 자동 확정하는 것

이 workflow에서 파일 유입은 허용되지만, 메타데이터 확정은 사용자 수동 입력으로만 이뤄진다.

## Config Step

### Purpose

`Add Step`에서 가져온 source file에 대해, 믹스 authoring에 필요한 메타데이터와 timing 정보를 수동으로 입력하고 검증하는 단계다.

### Design Rule

Config 단계는 **수동 입력 중심**으로 설계한다.

- 제목 자동 입력 금지
- BPM 자동 입력 금지
- 작곡가 자동 입력 금지
- `__SETTING_VAL__ASSET_CONFIG_ALLOW_FIELD_DEFAULTS = false`
- 빈 placeholder가 실제 값으로 간주되는 동작 금지

읽기 전용 정보는 보여줄 수 있다.

- source file path
- 파일 길이
- 파일 크기
- 분석 진행 상태
- waveform build 진행 상태

그러나 위 정보는 필수 입력값을 대신하지 않는다.

## Initial Local Draft Save Gate Fields

가장 이른 저장 시점은 app-local working draft save다.

이 gate는 `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`를 따른다.

- `Track Title`
- `Composer`
- `Start BPM`

이 저장은 UI working state를 보존하기 위한 것이지, 아직 `PDJE` 엔진에 `ConfigNewMusic(...)`를 호출하는 단계가 아니다.

## PDJE Registration Gate Fields

실제 `PDJE` editor mutation을 시작하는 첫 시점은 별도 gate로 본다.

이 gate는 `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS`를 따른다.

- `Track Title`
- `Composer`
- `Start BPM`
- `First Beat`

이 gate를 통과해야 아래 작업을 안전하게 수행할 수 있다.

- `EditorWrapper.ConfigNewMusic(title, composer, musicPath, firstBeat)`
- 첫 BPM row용 `PDJE_EDITOR_ARG.InitMusicArg(...)`
- `EditorWrapper.AddLine(...)`

현재 blueprint는 `__SETTING_VAL__ASSET_CONFIG_ALLOW_PDJE_FIRSTBAR_DEFAULT = false`를 따르므로, wrapper default `"0"`를 자동 사용하지 않는다.

## Identity Field Mutability Rule

현재 확인된 binding surface 기준으로, `ConfigNewMusic(...)` 이후에 아래 identity field를 전용 수정 API로 다시 쓰는 경로는 보이지 않는다.

- `Track Title`
- `Composer`
- `source_audio_path`

반대로 아래 값은 현재 wrapper로 계속 조정 가능한 범위에 속한다.

- `First Beat`
- BPM row

따라서 이 workflow는 아래를 따른다.

- `PDJE Registration Apply` 이전에는 source file과 identity field를 자유롭게 수정할 수 있다
- `PDJE Registration Apply` 이후에는 identity field를 인플레이스로 바꾸는 것을 기본 flow로 가정하지 않는다
- 등록 후 source file 또는 identity field를 바꾸려면 현재 asset session을 재생성하거나, 별도 reset/recreate flow를 거쳐야 한다

## Return-Ready Required Fields

아래 항목은 `Mixset Editing`으로 복귀하기 전 final return save에서 필요한 필수 필드다.

이 필수 세트는 `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`를 따른다.

- `Track Title`
- `Composer`
- `Start BPM`
- `BPM Transition Metadata`
- `First Beat`

필요하면 이후 버전에서 필수 필드가 늘어날 수 있지만, 최소한 위 다섯 항목은 복귀 전에 반드시 필요하다.

## BPM Metadata Rule

이 workflow에서는 BPM 정보를 반드시 사용자가 직접 기입해야 한다.

최소 요구사항은 아래와 같다.

- 곡 시작 지점의 `Start BPM`
- 곡 전체에 대한 `BPM Transition Metadata`

`BPM Transition Metadata`는 적어도 하나 이상의 명시적 row를 가져야 한다.  
즉, BPM이 고정된 곡이라도 "변화 없음"을 암묵적 기본값으로 처리하지 않고, **사용자가 직접 첫 BPM row를 만들어야 한다**.

이 규칙은 `__SETTING_VAL__ASSET_CONFIG_REQUIRE_EXPLICIT_INITIAL_BPM_ROW`를 따른다.

추가 BPM row가 있다면 아래를 만족해야 한다.

- 시간축 순서가 올바르다
- BPM 값이 유효한 양수다
- 첫 row는 시작 BPM과 논리적으로 일치한다

현재 binding 기준으로 이 BPM metadata는 `PDJE_EDITOR_ARG.InitMusicArg(musicName, bpm, beat, subBeat, separate)`와 `EditorWrapper.AddLine(...)` 조합으로 `PDJE` editor state에 반영된다.

## Optional Fields

아래 항목은 선택 입력으로 둘 수 있다.

- album
- genre
- year
- comment
- custom notes

선택 입력은 저장 가능 여부의 기준이 되지 않는다.

## Tagging Workflow

Config 단계에서는 사용자가 곡 내부에 태그나 포인트를 넣을 수 있다.

이 태그는 이후 mix editor에서 아래 목적에 쓰인다.

- 구조적 참조 지점 표시
- 전환 기준점 표시
- 사용자 정의 cue-like marker 표시

태그는 저장 가능하지만, 필수 태그 세트는 별도 문서에서 확정할 수 있다.  
현재 문서에서는 태그 자체를 강제하지 않되, 저장 구조와 UI는 태그 입력을 지원해야 한다.

중요한 점은 현재 확인된 `PDJE` binding에는 dedicated music tag API가 없다는 점이다.  
따라서 태그는 현재 blueprint에서 **app-layer metadata**로 다루며, `PDJE` editor mutation과 동일한 계층으로 가정하지 않는다.

## Waveform Generation Rule

이 workflow에서 `PDJE` waveform은 **초기 app-local draft save 직후 자동으로 보장되지 않는다**.

이유는 아래와 같다.

- `PDJE_MIR.SoundToWaveform(...)`와 `SoundToRGBWaveform(...)`는 raw file path를 받지 않는다
- 현재 binding 구현은 내부적으로 `PDJE_Wrapper.SearchMusic(title, composer, bpm)`를 먼저 수행한다
- 따라서 imported file이 `PDJE` search-visible 상태가 되기 전에는 `PDJE` waveform 호출이 실패하거나 빈 결과가 될 수 있다

이 문서에서는 아래를 기준으로 삼는다.

- 호출 메서드는 `__SETTING_VAL__ASSET_WAVEFORM_PDJE_METHOD`
- `PDJE` waveform은 `__SETTING_VAL__ASSET_WAVEFORM_REQUIRE_PDJE_SEARCHABLE_ASSET = true` 조건을 만족할 때만 호출한다
- render profile은 `__SETTING_VAL__ASSET_WAVEFORM_RENDER_PCM_PER_PIXEL`, `__SETTING_VAL__ASSET_WAVEFORM_RENDER_WIDTH_PX`, `__SETTING_VAL__ASSET_WAVEFORM_RENDER_HEIGHT_PX`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_TARGET_WINDOW`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_WINDOW_SIZE_EXP`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_OVERLAP_RATIO`를 따른다
- low-level 결과가 encoded image buffer array라면, UI layer는 이를 `Array[Image]`로 decode하여 화면에 바인딩해야 한다
- `PDJE` waveform이 아직 불가능한 상태여도 metadata 입력, `First Beat` 입력, BPM row 입력, tag 입력은 계속 가능해야 한다

즉, 현재 binding-only 기준에서 `PDJE` waveform은 **deferred / conditional capability**다.  
즉시 waveform이 필요하면, 별도의 staging render/push 경로를 설계하거나, `PDJE_MIR` 외 다른 pre-registration path를 추가로 설계해야 한다.

## Canonical Config Flow

1. `Add Step`에서 선택한 source file이 Config 화면에 로드된다
2. 시스템은 source file path를 읽기 전용으로 보여준다
3. 사용자는 `Track Title`을 직접 입력한다
4. 사용자는 `Composer`를 직접 입력한다
5. 사용자는 `Start BPM`을 직접 입력한다
6. `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`가 유효해지면 app-local initial draft save를 수행한다
7. 사용자는 `First Beat`를 직접 입력한다
8. `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS`가 충족되면 시스템은 `EditorWrapper.ConfigNewMusic(title, composer, musicPath, firstBeat)`를 호출한다
9. 시스템은 `PDJE_EDITOR_ARG.InitMusicArg(...)` + `EditorWrapper.AddLine(...)`로 첫 BPM row를 만든다
10. 사용자는 추가 `BPM Transition Metadata` row를 직접 입력하고, 시스템은 이를 같은 `MusicArg` 계열 mutation으로 반영한다
11. 필요 시 태그와 추가 메타데이터를 입력한다
12. 초기 local draft save 이후 편집 중 dirty 상태가 유지되면 `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_INTERVAL_SECONDS` 간격으로 app-local autosave를 수행한다
13. asset이 `PDJE_Wrapper.SearchMusic(title, composer, bpm)`로 검색 가능한 시점이 되면, 그 이후에만 조건부로 `PDJE` waveform generation을 호출한다
14. 시스템은 return 가능 여부를 실시간 검증한다
15. return 불가 상태라면 subscene 내부에 강한 `저장 불가 상태 UI`를 표시한다
16. 사용자가 `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT` 또는 `Authoring Local Bezel`의 `SaveIcon`을 시도하면 시스템은 현재 상태에 맞는 save/apply를 수행하거나 가드 dialog를 띄운다
17. 사용자가 `ReturnAction`을 시도하면 즉시 return save를 수행한다
18. `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`를 모두 통과했고 필요한 `PDJE` editor registration이 완료된 경우에만 `ready_for_mixset = true`로 저장되고 `Mixset Editing Workspace`로 복귀한다

## Validation Rules

### Initial Local Draft Save Validation

초기 app-local draft save는 아래 조건을 통과할 때만 가능하다.

- source file path가 유효하다
- `Track Title`이 비어 있지 않다
- `Composer`가 비어 있지 않다
- `Start BPM`이 비어 있지 않고 유효한 수치다

### PDJE Registration Validation

실제 `PDJE` editor registration은 아래 조건을 추가로 통과해야 한다.

- `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS` 전체 유효
- `First Beat`가 비어 있지 않고 유효하다
- 첫 BPM row를 만들 수 있는 최소 정보가 준비되었다
- `__SETTING_VAL__ASSET_CONFIG_ALLOW_PDJE_FIRSTBAR_DEFAULT = false` 정책을 위반하지 않는다

### Return Save Validation

`Mixset Editing`으로 복귀하는 return save는 아래 조건을 모두 통과할 때만 가능하다.

- source file path가 유효하다
- `Track Title`이 비어 있지 않다
- `Composer`가 비어 있지 않다
- `Start BPM`이 비어 있지 않고 유효한 수치다
- `BPM Transition Metadata`가 비어 있지 않다
- `BPM Transition Metadata`의 각 row가 유효하다
- `First Beat`가 비어 있지 않고 유효하다

아래 조건에서는 `저장 불가 상태`로 간주해야 한다.

- 필수 필드 미입력
- 숫자 필드 형식 오류
- BPM row 순서 오류
- 중복되거나 충돌하는 BPM transition row
- source file 접근 불가

즉, 이 workflow는 `저장 불가능 상태를 먼저 명확히 보여주고, 저장 시도 시 원인을 경고창으로 설명하는 방식`을 우선한다.

현재 binding 기준으로 `PDJE_MIR` waveform 호출 가능 여부는 위 validation과 별도다.  
return-ready 상태가 곧 `PDJE` waveform 사용 가능 상태를 뜻하지는 않는다.

## Invalid Save Feedback

Config 단계에서 저장이 불가능한 상태라면, 시스템은 아래 피드백을 제공해야 한다.

- subscene 내부에 `저장 불가 상태 UI`를 지속적으로 표시한다
- 이 UI는 현재 asset이 아직 저장 가능한 상태가 아님을 한눈에 알 수 있게 해야 한다
- 이 UI는 최소한 "필수 필드 미완성" 또는 동등한 상태 메시지를 포함해야 한다
- 누락 필드와 잘못된 필드를 subscene 내부 문맥에서 더 강하게 드러낼 수 있어야 한다

사용자가 아래 행동을 하면, 시스템은 현재 state에 맞지 않는 저장을 수행하지 않고 경고창을 띄워야 한다.

- `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT`
- `Authoring Local Bezel`의 `SaveIcon` 클릭

경고창은 최소한 아래 정보를 포함해야 한다.

- 저장이 현재 불가능하다는 사실
- 누락되거나 잘못된 필드 목록
- 사용자가 다음에 무엇을 수정해야 하는지에 대한 짧은 안내

이 경고창은 저장 실패 후 뒤늦게 뜨는 시스템 오류창이 아니라, **validation guard dialog**로 동작해야 한다.
이 동작은 `__SETTING_VAL__SAVE_GUARD_SHOW_DIALOG_ON_INVALID_SAVE`를 따른다.

중요한 점은 아래와 같다.

- `SaveIcon`은 `Authoring Local Bezel`에 속한다
- 그러나 저장 차단 사유의 전달은 `Music Asset Add & Config` 서브씬 내부가 담당한다
- 즉, 저장 액션과 저장 차단 표현은 같은 레이어에 있지 않아도 된다

## Save Rule

이 workflow에는 네 종류의 저장 / apply 단계가 있다.

### Initial Local Draft Save

- `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_INITIAL_REQUIRED_FIELDS_COMPLETE`를 따른다
- source file + 초기 필수 필드가 유효해지는 즉시 실행한다
- app-local working draft를 만들지만 아직 `PDJE` registration은 아니다

### PDJE Registration Apply

- `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS`를 통과했을 때 실행한다
- `EditorWrapper.ConfigNewMusic(...)`를 호출한다
- 첫 BPM row는 `PDJE_EDITOR_ARG.InitMusicArg(...)` + `EditorWrapper.AddLine(...)`로 반영한다
- 이 단계가 끝나야 asset이 현재 project authoring context에서 `PDJE` editor-local music asset으로 간주될 수 있다

### Periodic Autosave

- 초기 local draft save 성공 이후에만 활성화한다
- 간격은 `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_INTERVAL_SECONDS`를 따른다
- scope는 `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_SCOPE`를 따른다
- 현재 기준에서는 UI working draft 보호가 목적이며, `PDJE` root DB write를 의미하지 않는다

### Return Save

- `ReturnAction` 시 즉시 실행한다
- `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_RETURN`를 따른다
- 현재 폼 상태 전체를 app-local draft에 반영한다
- `PDJE` editor-local state에는 현재 wrapper가 실제로 수정 가능한 항목인 `First Beat`와 BPM row만 반영한다
- `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`를 모두 통과해야 `ready_for_mixset = true`가 된다

구체 규칙은 아래와 같다.

- 초기 필수 필드가 하나라도 비어 있으면 initial local draft save 실행 금지
- `First Beat`가 없으면 `PDJE Registration Apply` 실행 금지
- `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS` 중 하나라도 비어 있으면 return save 실행 금지
- validation을 통과하지 못하면 `Return` 불가
- validation 실패 상태에서 `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT`를 누르면 경고창 표시
- validation 실패 상태에서 `Authoring Local Bezel`의 `SaveIcon`을 클릭하면 경고창 표시
- validation 실패 상태에서는 subscene 내부의 `저장 불가 상태 UI`를 유지 표시
- app-local draft는 있을 수 있지만, `PDJE Registration Apply` 이전 상태를 `PDJE` editor asset으로 취급하지 않는다

즉, `local draft 저장은 허용하지만`, `PDJE registration`과 `mix-ready 복귀`는 더 강한 gate를 통과할 때만 허용한다.

## Output Contract

Config 완료 후 상태에 따라 산출물이 갈린다.

### Draft Save Output

- `asset_id`
- `source_audio_path`
- `music_title`
- `composer`
- `start_bpm`
- `pdje_registered = false`
- `ready_for_mixset = false`

### Return Save Output

- `asset_id`
- `source_audio_path`
- `music_title`
- `composer`
- `start_bpm`
- `bpm_transition_metadata`
- `first_beat`
- `user_tags`
- `waveform_preview_ref?`
- `pdje_registered = true`
- `pdje_searchable_by_search_music = conditional`
- `ready_for_mixset = true`

`user_tags`는 현재 binding 기준으로 `PDJE` native music API가 아니라 app-layer metadata다.

`ready_for_mixset`가 참이 아닌 asset은 현재 project의 믹스 authoring에서 로드 대상으로 사용할 수 없다.  
단, `__SETTING_VAL__ASSET_READY_FOR_MIXSET_IMPLIES_ROOT_DB_VISIBILITY = false`이므로 이것이 곧 root DB searchable 상태를 뜻하지는 않는다.

## Return To Mixset Editing

return save에 성공하면 시스템은 아래를 수행해야 한다.

- 현재 authoring session을 유지한다
- `Mixset Editing Workspace`로 복귀한다
- 방금 생성한 asset을 browser에서 바로 찾을 수 있게 한다
- 필요 시 방금 생성한 asset을 자동 선택 상태로 만든다

이 복귀는 현재 project-local authoring 문맥에서의 사용 가능 상태를 뜻한다.  
`PDJE_MIR`나 runtime `SearchMusic(...)`이 같은 자산을 즉시 찾을 수 있는지 여부는 별도의 root DB visibility 단계에 달려 있다.

return save에 실패한 경우에는 아래를 수행해야 한다.

- `Config Step`에 머문다
- 어떤 필드가 문제인지 명시한다
- subscene 내부의 `저장 불가 상태 UI`를 계속 표시한다
- authoring session 전체를 초기화하지 않는다

## Error And Recovery

### 파일 선택 실패

- 드래그 앤 드롭 실패
- 파일 탐색기 취소
- 지원하지 않는 포맷 선택

결과:

- import session 생성 금지
- Config Step 진입 금지

### Config 검증 실패

- 필수 필드 누락
- BPM row 오류
- First Beat 미입력

결과:

- subscene 내부의 `저장 불가 상태 UI` 표시 유지
- `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT` 또는 `Authoring Local Bezel SaveIcon` 시도 시 경고창 표시
- 입력값 수정 유도

### 저장 실패

- app-local working draft 반영 실패
- `PDJE Registration Apply` 실패
- 파일 참조 상태 문제

결과:

- 사용자는 Config 화면에 남아 있어야 한다
- 입력한 값은 가능한 한 유지해야 한다
- 사용자는 수정 후 재시도할 수 있어야 한다

### PDJE Waveform 보류 또는 실패

- asset이 아직 `PDJE_Wrapper.SearchMusic(...)`로 검색되지 않음
- `PDJE_MIR` 호출 실패
- waveform decode 실패

결과:

- metadata 편집과 `PDJE` registration flow 자체는 계속 진행 가능해야 한다
- waveform UI는 `deferred` 또는 `retryable` 상태로 남겨야 한다
- `waveform unavailable`이 곧 `return-ready false`를 자동 의미해서는 안 된다

## Performance Notes

이 workflow는 waveform / MIR 처리를 포함하더라도 아래 원칙을 유지해야 한다.

- 분석은 Config 화면의 보조 기능일 수 있지만, 필수 필드는 자동 확정하지 않는다
- 무거운 분석 작업은 UI를 완전히 멈추게 하지 않는 방향이 좋다
- waveform/STFT 결과가 있더라도 사용자가 수동 입력으로 최종 확정해야 한다
- `PDJE` waveform build는 `PDJE search-visible` 상태 이후의 backgroundable state로 다루는 것이 좋다
- autosave와 waveform build가 동시에 겹칠 경우, source of truth는 app-local draft state와 `PDJE` registration state를 구분해서 다뤄야 한다

즉, 자동 분석은 보조 수단일 수 있지만, **authoritative metadata source는 항상 사용자 입력**이다.

## Open Questions

- BPM transition metadata의 정확한 row schema를 별도 문서로 분리할지 결정이 필요하다
- 태그의 최소 필수 세트를 둘지 결정이 필요하다
- `Composer` 외에 `Artist`를 별도 필수 필드로 둘지 결정이 필요하다
- `PDJE_MIR`를 조기 사용하려면 별도 staging render/push 경로를 둘지 결정이 필요하다
- waveform 실패 시 `return-ready` 편집을 얼마나 허용할지 결정이 필요하다
- `ready_for_mixset`와 root DB visibility 사이의 후속 동기화 시점을 별도 문서로 닫을지 결정이 필요하다

## Summary

`Music Asset Add & Config Workflow`는 로컬 음악 파일을 `드래그 앤 드롭` 또는 `네이티브 파일 탐색기 호출`로 가져온 뒤, app-local draft를 만들고, `First Beat`와 첫 BPM row를 포함한 조건을 만족하면 `PDJE` editor registration을 수행하고, 그 이후 필요 시 조건부로 `PDJE` waveform을 호출하며, 추가 config와 BPM mapping을 거쳐 return save로 복귀하는 절차다.

이 workflow의 가장 중요한 규칙은 아래 두 가지다.

- 필수 메타데이터에 디폴트 값을 주지 않는다
- app-local draft gate, `PDJE` registration gate, return gate를 분리한다
