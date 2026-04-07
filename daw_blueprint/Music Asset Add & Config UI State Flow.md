# Music Asset Add & Config UI State Flow

## Purpose

이 문서는 `Music Asset Add & Config Workspace` 내부의 UI 상태 흐름을 정의한다.

핵심 관심사는 아래와 같다.

- 서브씬에 진입한 직후 어떤 화면 상태로 시작하는가
- 언제 source file 검증이 끝나고 필수 필드 입력으로 넘어가는가
- 언제 app-local initial draft save가 일어나는가
- 언제 실제 `PDJE` registration이 일어나는가
- 언제 `PDJE`의 waveform 함수를 호출할 수 있고, 언제 그 호출이 아직 불가능한가
- 언제 autosave가 돌고, 언제 return save가 수행되는가

이 문서는 `Music Asset Add & Config`를 단일 화면이 아니라, **local draft 상태, PDJE registration 상태, waveform 준비 여부, 복귀 가능성에 따라 움직이는 상태 기계**로 다룬다.

## Relationship To Other Documents

- [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)
- [Godot Scene Workflow](Godot%20Scene%20Workflow.md)
- [Authoring Local Bezel](Authoring%20Local%20Bezel.md)
- [Project DJ Godot Binded Out](Project%20DJ%20Godot%20Binded%20Out.md)
- [Settings](Settings.md)

절차와 정책은 [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md)에서 정의하고, 이 문서는 그 절차가 서브씬 내부에서 어떤 UI 상태로 보이는지를 정의한다.
import 허용 방식, 초기 저장 gate, autosave 간격, waveform render profile 같은 가변 값은 [Settings](Settings.md)의 `__SETTING_VAL__...` 항목을 따른다.

## Scope

이 문서가 다루는 범위는 아래와 같다.

- source file가 없는 상태에서 시작하는 entry flow
- DnD / native file picker 기반 import 진입
- audio file validation state
- 초기 필수 필드 입력 state
- app-local initial draft save state
- PDJE registration state
- 조건부 PDJE waveform generation state
- waveform 표시 전/후의 config / BPM mapping 편집 state
- interval autosave state
- return 시 즉시 save state
- invalid source, invalid return, save failure, waveform failure 상태 처리

## Out Of Scope

이 문서는 아래를 직접 정의하지 않는다.

- BPM transition row의 상세 schema
- 태그 taxonomy의 상세 구조
- waveform widget의 그래픽 테마
- low-level STFT 알고리즘 내부 구현
- mixset timeline 쪽 authoring state

## Core State Principles

- 이 서브씬은 진입 직후 반드시 `source import gate`부터 시작한다
- source file이 유효하기 전에는 metadata form과 waveform UI를 열지 않는다
- app-local initial draft save와 실제 `PDJE` registration은 다른 상태다
- `PDJE` registration 전에 `First Beat`가 필요하다
- 현재 binding 기준으로 `PDJE` waveform 생성은 asset이 `SearchMusic(title, composer, bpm)` 가능한 상태가 된 뒤에만 시도할 수 있다
- 초기 local draft save 이후에만 interval autosave를 활성화한다
- return은 단순 화면 닫기가 아니라 `return save`를 수반하는 상태 전이다
- `SaveIcon`은 [Authoring Local Bezel](Authoring%20Local%20Bezel.md)에 있지만, 저장 차단과 필드 오류 전달은 이 서브씬 본문이 담당한다
- draft 저장과 mix-ready 저장은 같은 것이 아니다

## Why Local Draft And PDJE Registration Are Split

이 서브씬에서는 `저장`이 하나가 아니다.

- app-local initial draft save는 `Track Title`, `Composer`, `Start BPM`까지만으로 가능하다
- 하지만 실제 `PDJE` registration은 `EditorWrapper.ConfigNewMusic(..., firstBar)`를 호출해야 하므로 `First Beat`까지 필요하다

이 분리를 두는 이유는 아래와 같다.

- 사용자가 곡 제목, 작곡가, 시작 BPM을 직접 확정해야 한다
- 현재 product rule은 wrapper default `firstBar=\"0\"` 사용을 금지한다
- 따라서 `First Beat`가 아직 없을 때는 `PDJE` registration을 미루고, app-local draft만 유지하는 것이 맞다

로컬 플러그인 기준으로 이 설계는 아래 파일과 맞닿아 있다.

- [PDJE_MIR_Bindings.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR_Bindings.cpp)
- [PDJE_MIR_Waveform.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR_Waveform.cpp)
- [EditorFunctions.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/EditorFunctions.cpp)

## PDJE Waveform Integration Contract

이 blueprint에서 `Sound To Waveform` 계열 통합은 아래 규칙으로 정의한다.

- low-level 호출은 `__SETTING_VAL__ASSET_WAVEFORM_PDJE_METHOD`를 사용한다
- 현재 요구사항 기준으로 RGB waveform + STFT 시각화는 `SoundToRGBWaveform` 경로를 기준으로 본다
- 호출 인자는 `music title`, `composer`, `start_bpm`과 waveform render profile 설정값을 사용한다
- 다만 현재 binding은 raw file path가 아니라 `SearchMusic(title, composer, bpm)`로 먼저 대상을 찾으므로, `__SETTING_VAL__ASSET_WAVEFORM_REQUIRE_PDJE_SEARCHABLE_ASSET = true`를 따른다
- low-level 결과가 encoded image buffer array라면, scene adapter가 이를 `Image.load_webp_from_buffer(...)` 계열로 decode하여 UI에서 쓰는 `waveform_images : Array[Image]`로 정규화해야 한다
- waveform decode가 끝나기 전까지는 `WaveformCanvasView`를 활성화하지 않는다
- asset이 아직 `PDJE` search-visible 상태가 아니면 `PDJE` waveform 호출을 시도하지 않고 `WaveformDeferredNotice`를 표시한다

로컬 예제 기준으로 encoded buffer를 `Image`로 풀어 쓰는 방향은 아래 파일과도 일치한다.

- [util_test.tscn](PDJE-Godot-Plugin/util_test.tscn)

즉, UI 계층이 직접 소비하는 최종 계약은 `Array[Image]`지만, low-level adapter 단계의 중간 표현은 encoded buffer일 수 있다.

## UI Zones By State

상태에 따라 보이거나 강해지는 주요 UI 영역은 아래와 같다.

- `SourceImportGateView`
- `SourceValidationPanel`
- `InitialRequiredFieldForm`
- `InitialSaveProgressView`
- `PDJERegistrationPanel`
- `WaveformDeferredNotice`
- `WaveformBuildProgressView`
- `WaveformCanvasView`
- `AdditionalConfigPanel`
- `BpmMappingEditorView`
- `TagPointEditorView`
- `InvalidReturnStatePanel`
- `SaveWarningDialog`

## Primary States

### `AwaitingSource`

이 상태는 서브씬에 처음 진입했을 때의 기본 상태다.

- 보여줄 것: `SourceImportGateView`, DnD zone, native file picker CTA
- 허용 액션: drag and drop, file picker open, return
- 금지 액션: waveform build, autosave start, mix-ready return
- local bezel: `SaveIcon`은 눌릴 수 있지만 저장은 성립하지 않는다

### `SourceValidating`

사용자가 파일을 넣은 직후, 시스템이 source file을 검사하는 상태다.

- 검사 항목: 존재 여부, 읽기 가능 여부, 지원 포맷, audio file로서의 유효성
- 보여줄 것: `SourceValidationPanel`
- 성공 시 이동: `InitialRequiredFieldEntry`
- 실패 시 이동: `AwaitingSource`

### `InitialRequiredFieldEntry`

source file이 유효하다고 판정된 뒤, 최초 필수 필드를 받는 상태다.

- 필수 세트는 `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`를 따른다
- 현재 기본 세트는 `Track Title`, `Composer`, `Start BPM`이다
- 보여줄 것: `InitialRequiredFieldForm`
- waveform canvas: 아직 숨김
- 허용 액션: 필드 입력, 수동 save 시도, source 교체, return
- 금지 액션: BPM mapping 완료 처리, mix-ready return

### `InitialLocalDraftSaving`

초기 필수 필드가 유효해지는 즉시 들어가는 자동 저장 상태다.

- 트리거: `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_INITIAL_REQUIRED_FIELDS_COMPLETE = true`
- 목적: UI working draft 생성, source file과 초기 메타데이터 보존
- 성격: app-local save
- 성공 시 이동: `PDJERegistrationPending`
- 실패 시 이동: `InitialRequiredFieldEntry`

### `PDJERegistrationPending`

초기 local draft는 있지만, 아직 실제 `PDJE` registration이 일어나지 않은 상태다.

- 추가 요구 입력: `First Beat`
- 필요 시 첫 BPM row를 만들 최소 정보 확인
- 보여줄 것: `PDJERegistrationPanel`, `AdditionalConfigPanel`, `BpmMappingEditorView`
- waveform: 아직 `PDJE` 기준으로 보장되지 않음
- 성공 시 이동: `PDJERegistering`

### `PDJERegistering`

이 상태에서 실제 `PDJE` editor mutation이 일어난다.

- 호출: `EditorWrapper.ConfigNewMusic(title, composer, musicPath, firstBeat)`
- 호출: 첫 BPM row용 `PDJE_EDITOR_ARG.InitMusicArg(...)`
- 호출: `EditorWrapper.AddLine(...)`
- 성공 시 이동: `DraftEditing`
- 실패 시 이동: `PDJERegistrationPending`

등록이 끝난 뒤에는 현재 verified wrapper 기준으로 `title`, `composer`, `musicPath`를 인플레이스로 다시 쓰는 전용 API가 없다.  
따라서 이후 편집 상태는 주로 `First Beat`, BPM row, app-layer tag/metadata 보정 중심으로 본다.

### `WaveformGenerating`

asset이 `PDJE` search-visible 상태가 된 뒤, 조건부로 PDJE waveform render 호출이 실행되는 상태다.

- 선행 조건: `__SETTING_VAL__ASSET_WAVEFORM_REQUIRE_PDJE_SEARCHABLE_ASSET = true`
- 호출 메서드: `__SETTING_VAL__ASSET_WAVEFORM_PDJE_METHOD`
- render profile: `__SETTING_VAL__ASSET_WAVEFORM_RENDER_PCM_PER_PIXEL`, `__SETTING_VAL__ASSET_WAVEFORM_RENDER_WIDTH_PX`, `__SETTING_VAL__ASSET_WAVEFORM_RENDER_HEIGHT_PX`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_TARGET_WINDOW`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_WINDOW_SIZE_EXP`, `__SETTING_VAL__ASSET_WAVEFORM_STFT_OVERLAP_RATIO`
- 보여줄 것: `WaveformBuildProgressView`
- 성공 조건: UI가 사용할 `waveform_images : Array[Image]`가 준비됨
- 성공 시 이동: `DraftEditing`
- 실패 시 이동: `DraftEditing`

waveform 생성 실패가 곧 draft 폐기나 `PDJE` registration 실패를 의미하지는 않는다.

### `DraftEditing`

`PDJE` registration이 끝난 뒤, 사용자가 본격적인 asset config를 진행하는 기본 편집 상태다.

- 보여줄 것: `AdditionalConfigPanel`, `BpmMappingEditorView`, `TagPointEditorView`
- 조건부 표시: `WaveformCanvasView` 또는 `WaveformDeferredNotice`
- 허용 액션: 추가 필드 수정, BPM mapping 작성, 태그 입력, manual save, return
- 금지 액션: `PDJE Registration Apply` 이후 source file / identity field의 직접 교체
- autosave: dirty 상태가 유지되면 활성화 가능
- local bezel: `SaveStateIndicator`는 `modified / latest / recently saved`를 반영

### `PeriodicAutosaving`

`DraftEditing` 중 dirty 상태가 일정 시간 이상 지속될 때 들어가는 자동 저장 상태다.

- 트리거 간격: `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_INTERVAL_SECONDS`
- 전제: 초기 local draft save 성공 이후
- scope: `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_SCOPE`
- 목적: 현재 working draft를 잃지 않도록 저장
- 특징: autosave 성공이 곧 return permission을 의미하지는 않는다
- 성공 시 이동: `DraftEditing`
- 실패 시 이동: `DraftEditing`

### `ReturnSaving`

사용자가 `ReturnAction`으로 `Mixset Editing Workspace` 복귀를 시도할 때 들어가는 상태다.

- 트리거: `ReturnAction`
- 동작: 현재 변경사항 전체를 app-local draft에 반영하고, `PDJE` editor-local state에는 수정 가능한 항목만 즉시 반영 시도
- 저장 정책: `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_RETURN`
- validation gate: `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`

이 상태는 local draft save가 아니라 **return save**다.  
여기서 통과해야만 `ready_for_mixset = true`가 된다.

### `ExitToMixset`

return save가 성공하고 final required set이 유효할 때만 진입 가능한 상태다.

- 수행 결과: `Mixset Editing Workspace`로 전환
- 후속 효과: 방금 저장된 asset을 browser에서 즉시 선택 가능하게 해야 한다
- 주의: 이 전환은 project-local authoring readiness를 뜻하며, root DB searchable 상태와 자동으로 같아지지는 않는다

## Failure And Guard States

### `InvalidSourceState`

아래 상황에서 발생한다.

- 파일이 존재하지 않음
- 파일을 읽을 수 없음
- 지원 포맷이 아님
- audio decode 전제 검증 실패

이 상태에서는 `SourceValidationPanel`에 원인을 보여주고, `AwaitingSource`로 돌아가 재선택하게 한다.

### `InvalidReturnState`

아래 상황에서 발생한다.

- `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS` 중 누락이 있음
- `BPM Transition Metadata` row가 유효하지 않음
- `First Beat`가 확정되지 않음

이 상태에서는 아래가 필요하다.

- `InvalidReturnStatePanel`을 본문에 지속 표시
- `SaveWarningDialog`로 누락/오류 필드 목록 설명
- 관련 입력 영역으로 포커스 이동 또는 스크롤 이동 가능

### `SaveFailedState`

아래 상황에서 발생한다.

- app-local draft 저장 실패
- `PDJERegistering` 실패
- autosave 실패
- return save 실패

이 상태에서는 입력값을 최대한 유지하고, 사용자가 같은 상태에서 다시 저장을 시도할 수 있어야 한다.

### `WaveformGenerationFailedState`

아래 상황에서 발생한다.

- PDJE MIR 호출 실패
- waveform decode 실패
- cache read/write 실패
- asset이 아직 `PDJE` search-visible 상태가 아님

이 상태는 사용자의 메타데이터 작업을 막는 것이 아니라, waveform 관련 영역만 재시도 가능 상태로 남기는 방향이 맞다.

## State Transition Rules

핵심 상태 전이는 아래와 같다.

1. `Enter Workspace -> AwaitingSource`
2. `AwaitingSource -> SourceValidating`
3. `SourceValidating -> InitialRequiredFieldEntry`
4. `InitialRequiredFieldEntry -> InitialLocalDraftSaving`
5. `InitialLocalDraftSaving -> PDJERegistrationPending`
6. `PDJERegistrationPending -> PDJERegistering -> DraftEditing`
7. `DraftEditing -> WaveformGenerating -> DraftEditing`
8. `DraftEditing -> PeriodicAutosaving -> DraftEditing`
9. `DraftEditing -> ReturnSaving`
10. `ReturnSaving -> ExitToMixset`

실패 경로는 아래와 같다.

1. `SourceValidating -> InvalidSourceState -> AwaitingSource`
2. `InitialLocalDraftSaving -> SaveFailedState -> InitialRequiredFieldEntry`
3. `PDJERegistering -> SaveFailedState -> PDJERegistrationPending`
4. `WaveformGenerating -> WaveformGenerationFailedState -> DraftEditing`
5. `ReturnSaving -> InvalidReturnState -> DraftEditing`
6. `ReturnSaving -> SaveFailedState -> DraftEditing`

## Validation Gates

### Initial Local Draft Save Gate

초기 local draft save는 아래 조건만 통과하면 된다.

- source file valid
- `Track Title`
- `Composer`
- `Start BPM`

이 gate는 `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`를 따른다.

### PDJE Registration Gate

실제 `PDJE` registration은 아래 조건을 추가로 통과해야 한다.

- `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS` 전체 유효
- `First Beat` 유효
- 첫 BPM row를 만들 수 있는 최소 정보가 준비됨
- `__SETTING_VAL__ASSET_CONFIG_ALLOW_PDJE_FIRSTBAR_DEFAULT = false` 정책 위반 없음

### Return Save Gate

`Mixset Editing`으로 복귀하려면 아래 조건을 통과해야 한다.

- `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS` 전체 유효
- BPM mapping row 유효
- `First Beat` 유효
- 필요한 `PDJE` registration이 이미 끝나 있음

이 gate를 통과한 저장만 `ready_for_mixset = true`를 만든다.

## Save Timing Rules

이 서브씬의 저장 타이밍은 네 종류로 고정한다.

### Initial Local Draft Save

- 최초 필수 필드가 유효해지는 즉시 실행
- 목적: UI working draft 생성

### PDJE Registration Apply

- `First Beat`와 첫 BPM row를 만들 수 있는 정보가 준비되면 실행
- 목적: `ConfigNewMusic(...)`와 `MusicArg` row 추가를 통해 실제 `PDJE` editor-local state를 만든다

### Interval Autosave

- 초기 local draft save 이후에만 활성화
- dirty 상태가 `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_INTERVAL_SECONDS` 이상 유지되면 실행
- scope는 `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_SCOPE`
- 현재 편집 draft를 보호하지만, return permission은 주지 않는다

### Return Save

- 사용자가 `ReturnAction`을 누르면 즉시 실행
- 현재 폼 상태 전체를 app-local draft에 반영한다
- `PDJE` editor-local state에는 현재 wrapper가 수정 가능한 항목만 반영한다
- 성공 시에만 서브씬을 벗어날 수 있다

## Local Bezel Mapping

[Authoring Local Bezel](Authoring%20Local%20Bezel.md)와의 연결은 아래와 같다.

- `SaveIcon`: 현재 상태에서 가능한 저장을 시도한다
- `SaveStateIndicator`: `latest`, `modified`, `recently saved`, `saving` 정도의 상태만 요약한다
- 저장 차단 사유: local bezel이 아니라 이 서브씬 본문이 보여준다

즉, `SaveIcon`은 entry point이고, 저장 차단/가드 UI는 본문 state가 담당한다.

## Return Rule

사용자는 추가 config 수정과 BPM mapping을 마친 뒤 복귀해야 한다.  
waveform은 있으면 쓰되, 현재 binding 기준으로 항상 선행 조건은 아니다.

따라서 `ReturnAction`은 아래와 같이 동작해야 한다.

- `DraftEditing`에서만 의미 있는 복귀 시도다
- 누락 필드가 있으면 실제 전환 없이 `InvalidReturnStatePanel`을 강화한다
- 필수 조건과 return save가 모두 성공해야만 `Mixset Editing Workspace`로 돌아간다
- `ready_for_mixset = true`는 project-local authoring readiness를 뜻하며, root DB searchable 상태와 자동으로 같아지지는 않는다

## Open Questions

- `PDJE_MIR`를 조기 사용하려면 별도 staging render/push 경로를 둘지 결정이 필요하다
- waveform 생성 실패 시 `DraftEditing`으로 바로 들어갈지, 별도 retry-only 상태를 둘지 정해야 한다
- BPM mapping을 point row만 허용할지, region change도 허용할지 정해야 한다
- autosave 실패를 alert queue에도 올릴지, 서브씬 내부에만 표시할지 정해야 한다
- 태그를 장기적으로 `PDJE` 쪽 데이터 모델과 연결할지, 계속 app-layer metadata로 둘지 정해야 한다

## Summary

`Music Asset Add & Config UI State Flow`는 아래 순서를 기준으로 한다.

1. source import
2. source validation
3. 초기 필수 필드 입력
4. app-local initial draft save
5. `First Beat` 확보 후 `PDJE` registration apply
6. 추가 config / BPM mapping 편집
7. 조건 충족 시에만 `PDJE` RGB waveform 생성
8. interval autosave
9. return 시 즉시 save
10. 성공 시 mixset editing으로 복귀

핵심은 `local draft`, `PDJE registration`, `PDJE waveform availability`를 같은 것으로 취급하지 않는다는 점이다.
