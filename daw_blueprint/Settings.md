# Settings

## Purpose

이 문서는 `Project DJ DAW`에서 여러 문서가 공통으로 참조해야 하는 설정 변수를 중앙 정의한다.

설정으로 위임된 값은 각 문서에서 하드코딩하지 않고, 반드시 이 문서의 변수명을 통해 참조해야 한다.  
문서 본문에서 설정값을 언급할 때는 `__SETTING_VAL__...` 네이밍 맹글링을 사용한다.

## Naming Convention

모든 설정 변수는 아래 규칙을 따른다.

- 접두사는 반드시 `__SETTING_VAL__`를 사용한다
- 뒤에는 대문자 스네이크 케이스를 사용한다
- 단위가 있는 값은 이름 끝에 단위를 드러낸다

예:

- `__SETTING_VAL__UI_GLOBAL_TOP_BEZEL_HEIGHT_PX`
- `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT`
- `__SETTING_VAL__ASSET_IMPORT_SUPPORTED_AUDIO_FORMATS`

## Usage Rule

- 설정 가능한 값은 개별 문서에서 직접 고정하지 않는다
- 문서 본문에서는 설정 변수명을 직접 적고, 기본값은 이 문서에서만 정의한다
- 새 설정 변수가 필요하면 먼저 이 문서에 추가한 뒤, 사용하는 문서에서 참조해야 한다

## UI Frame Settings

- `__SETTING_VAL__UI_GLOBAL_TOP_BEZEL_HEIGHT_PX`: `56`. Global top bezel 기본 높이. Used by [Global Frame UI](Global%20Frame%20UI.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md).
- `__SETTING_VAL__UI_LOCAL_BEZEL_HEIGHT_PX`: `44`. Local bezel 기본 높이. Used by [Global Frame UI](Global%20Frame%20UI.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md), [Authoring Local Bezel](Authoring%20Local%20Bezel.md).
- `__SETTING_VAL__UI_GLOBAL_BOTTOM_BEZEL_HEIGHT_PX`: `36`. Global bottom bezel 기본 높이. Used by [Global Frame UI](Global%20Frame%20UI.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md).
- `__SETTING_VAL__UI_GLOBAL_TOP_STATUS_ICON_LIMIT`: `6`. Global top bezel 우측 상태 아이콘 영역의 최대 표시 수. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_SELECTOR`: `5`. Selector local bezel의 기본 액션 버튼 상한. Used by [Global Frame UI](Global%20Frame%20UI.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md).
- `__SETTING_VAL__UI_LOCAL_BEZEL_ACTION_LIMIT_AUTHORING`: `6`. Authoring local bezel의 기본 액션 버튼 상한. Used by [Global Frame UI](Global%20Frame%20UI.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md), [Authoring Local Bezel](Authoring%20Local%20Bezel.md).

## Alert And Severity Settings

- `__SETTING_VAL__UI_ALERT_ANCHOR_POSITION`: `BottomRight`. Alert popup 기본 위치. Allowed: `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`, `Center`. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_ALERT_ALLOWED_ANCHORS`: `TopLeft, TopRight, BottomLeft, BottomRight, Center`. Alert anchor 허용 목록. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_ALERT_ICON_MODE`: `SeparatedIcons`. `Alert / Warning / Error`를 분리 아이콘으로 표시할지 결정하는 모드. Allowed: `SeparatedIcons`, `UnifiedIconWithSeverityBadge`. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_ALERT_STACK_MAX_VISIBLE`: `3`. Alert popup이 동시에 보이는 최대 수. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_ALERT_STACK_ORDER`: `NewestOnTop`. Alert popup stack 정렬 규칙. Allowed: `NewestOnTop`, `OldestOnTop`. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_VALIDATION_COLOR`: `Blue`. Validation 상태 기본 색상. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_WARNING_COLOR`: `Yellow`. Warning 상태 기본 색상. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_ERROR_COLOR`: `Red`. Error 상태 기본 색상. Used by [Global Frame UI](Global%20Frame%20UI.md).

## Hover And Background Task Settings

- `__SETTING_VAL__UI_HOVER_PRESENTATION_MODE`: `BottomReadoutOnly`. Hover 정보를 `Global Bottom Bezel` readout만으로 보여줄지 결정한다. Allowed: `BottomReadoutOnly`, `BottomReadoutPlusTooltip`. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_BACKGROUND_TASK_QUEUE_MAX_HEIGHT_PX`: `160`. `BackgroundTaskQueueContainer`의 기본 최대 높이. 넘치면 스크롤바를 표시한다. Used by [Global Frame UI](Global%20Frame%20UI.md).
- `__SETTING_VAL__UI_BACKGROUND_TASK_QUEUE_MAX_VISIBLE_TASKS`: `4`. 스크롤 전 한 번에 보여주는 task 행 수의 기본값. Used by [Global Frame UI](Global%20Frame%20UI.md).

## Shortcut And Save Guard Settings

- `__SETTING_VAL__SHORTCUT_SAVE_CURRENT_CONTEXT`: `Ctrl+S`. 현재 authoring context 저장 단축키. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md), [Global Frame UI](Global%20Frame%20UI.md), [Authoring Local Bezel](Authoring%20Local%20Bezel.md).
- `__SETTING_VAL__SAVE_GUARD_SHOW_DIALOG_ON_INVALID_SAVE`: `true`. 저장 불가 상태에서 저장 시도 시, 현재 서브씬 내부 문맥으로 경고 dialog를 표시할지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Authoring Local Bezel](Authoring%20Local%20Bezel.md).
- `__SETTING_VAL__SAVE_GUARD_SHOW_STATUS_ICON_ON_INVALID_SAVE`: `true`. 저장 불가 상태를 현재 서브씬 내부의 강한 상태 UI로 지속 표시할지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).

## Asset Import Settings

- `__SETTING_VAL__ASSET_IMPORT_ALLOW_DRAG_AND_DROP`: `true`. OS 파일 탐색기 드래그 앤 드롭 import 허용 여부. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).
- `__SETTING_VAL__ASSET_IMPORT_ALLOW_NATIVE_FILE_PICKER`: `true`. 네이티브 파일 탐색기 호출 import 허용 여부. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).
- `__SETTING_VAL__ASSET_IMPORT_SUPPORTED_AUDIO_FORMATS`: `wav, mp3, flac, ogg`. 지원 오디오 포맷 목록. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).

## Asset Config Policy Settings

- `__SETTING_VAL__ASSET_CONFIG_INITIAL_SAVE_REQUIRED_FIELDS`: `TrackTitle, Composer, StartBPM`. source validation 직후 app-local initial draft save를 열기 위한 최소 필드 목록. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_PDJE_REGISTRATION_REQUIRED_FIELDS`: `TrackTitle, Composer, StartBPM, FirstBeat`. 실제 `EditorWrapper.ConfigNewMusic(...)`와 첫 BPM row 적용 전에 필요한 최소 필드 목록. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_REQUIRED_FIELDS`: `TrackTitle, Composer, StartBPM, BPMTransitionMetadata, FirstBeat`. `Mixset Editing`으로 복귀하기 전 final return save에서 반드시 채워야 하는 필수 필드 목록. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_ALLOW_FIELD_DEFAULTS`: `false`. 필수 필드에 디폴트 값을 자동 주입할지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).
- `__SETTING_VAL__ASSET_CONFIG_ALLOW_PDJE_FIRSTBAR_DEFAULT`: `false`. `EditorWrapper.ConfigNewMusic(..., firstBar=\"0\")`의 wrapper default를 자동으로 소비할지 결정한다. 현재 blueprint는 사용자가 `First Beat`를 직접 넣기 전까지 이 default를 쓰지 않는다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_REQUIRE_EXPLICIT_INITIAL_BPM_ROW`: `true`. BPM 고정 곡이라도 첫 BPM row를 명시적으로 입력해야 하는지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md).
- `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_INITIAL_REQUIRED_FIELDS_COMPLETE`: `true`. 초기 필수 필드가 유효해지는 즉시 draft save를 자동 실행할지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_SAVE_ON_RETURN`: `true`. `ReturnAction` 시 즉시 return save를 강제할지 결정한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_INTERVAL_SECONDS`: `30`. 최초 필수 필드 저장 이후, `Music Asset Add & Config` 서브씬 편집 중 app-local working draft autosave 간격. Used by [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_CONFIG_AUTOSAVE_SCOPE`: `AppLocalDraftOnly`. autosave가 PDJE editor mutation이 아니라 UI working draft에만 적용되는지 결정한다. Allowed: `AppLocalDraftOnly`, `FuturePDJESync`. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_READY_FOR_MIXSET_IMPLIES_ROOT_DB_VISIBILITY`: `false`. `ready_for_mixset`가 root DB searchable 상태를 뜻하는지 여부. 현재 blueprint는 project-local authoring readiness만 뜻한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).

## Asset Waveform Settings

- `__SETTING_VAL__ASSET_WAVEFORM_PDJE_METHOD`: `SoundToRGBWaveform`. `Music Asset Add & Config`가 `PDJE`에서 호출할 waveform 렌더 메서드 이름. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_REQUIRE_PDJE_SEARCHABLE_ASSET`: `true`. 현재 `PDJE_MIR.SoundToWaveform` 계열이 raw file path가 아니라 `SearchMusic(title, composer, bpm)` 가능한 자산을 요구한다는 제약을 반영한다. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md), [Godot Scene Workflow](Godot%20Scene%20Workflow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_RENDER_PCM_PER_PIXEL`: `48`. waveform render 시 기본 `pcm_per_pixel` 값. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_RENDER_WIDTH_PX`: `4096`. waveform image 기본 폭. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_RENDER_HEIGHT_PX`: `256`. waveform image 기본 높이. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_STFT_TARGET_WINDOW`: `HANNING`. RGB waveform 생성 시 사용할 기본 STFT window. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_STFT_WINDOW_SIZE_EXP`: `10`. RGB waveform 생성 시 사용할 기본 STFT window size exponent. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).
- `__SETTING_VAL__ASSET_WAVEFORM_STFT_OVERLAP_RATIO`: `0.5`. RGB waveform 생성 시 사용할 기본 STFT overlap ratio. Used by [Music Asset Add & Config Workflow](Music%20Asset%20Add%20%26%20Config%20Workflow.md), [Music Asset Add & Config UI State Flow](Music%20Asset%20Add%20%26%20Config%20UI%20State%20Flow.md).

## Summary

이 문서는 `Project DJ DAW`의 설정 기준점이다.  
UI 높이, alert 배치, hover 방식, background task queue 제한, 저장 단축키, asset import 허용 방식, asset config validation 정책, waveform render profile은 여기서만 기본값을 정의한다.
