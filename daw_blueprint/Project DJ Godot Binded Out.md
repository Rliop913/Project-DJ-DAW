# Project DJ Godot Binded Out

## Purpose

이 문서는 `PDJE-Godot-Plugin/Wrapper_Includes` 기준으로, 어떤 `PDJE` 래퍼 클래스와 함수가 Godot에 실제로 노출되는지를 정리한 바인딩 참조 문서다.

이 문서의 목적은 아래 세 가지다.

- `PDJE-Godot-Plugin` 디렉토리를 나중에 제거하더라도 Godot 노출 API를 보존한다
- 향후 blueprint 문서 작성 시 어떤 wrapper가 이미 있는지 빠르게 참조한다
- `Godot method name -> wrapper method -> native/original call` 관계를 한 번에 확인할 수 있게 한다

## Source Of Truth

이 문서는 아래 소스를 기준으로 작성했다.

- [register_types.cpp](PDJE-Godot-Plugin/Wrapper_Includes/register_types.cpp)
- `PDJE-Godot-Plugin/Wrapper_Includes/core/...`
- `PDJE-Godot-Plugin/Wrapper_Includes/util/...`
- `PDJE-Godot-Plugin/Wrapper_Includes/global/...`
- `PDJE-Godot-Plugin/Wrapper_Includes/input/...`
- `PDJE-Godot-Plugin/Wrapper_Includes/judge/...`
- [CMakeLists.txt](PDJE-Godot-Plugin/CMakeLists.txt)

모든 클래스 등록은 `MODULE_INITIALIZATION_LEVEL_SCENE`에서 수행된다.

## Official PDJE Documentation Cross-Check

이 문서는 `2026-04-07` 기준으로 아래 공식 문서와 대조 검증했다.

- [Core_Engine](https://rliop913.github.io/Project-DJ-Engine/Core_Engine.html)
- [Editor_Workflows](https://rliop913.github.io/Project-DJ-Engine/Editor_Workflows.html)
- [Editor_Format](https://rliop913.github.io/Project-DJ-Engine/Editor_Format.html)
- [Input_Engine](https://rliop913.github.io/Project-DJ-Engine/Input_Engine.html)
- [Judge_Engine](https://rliop913.github.io/Project-DJ-Engine/Judge_Engine.html)
- [Util_Engine](https://rliop913.github.io/Project-DJ-Engine/Util_Engine.html)
- [FX_ARGS](https://rliop913.github.io/Project-DJ-Engine/FX_ARGS.html)
- [PDJE_For_AI_Agents](https://rliop913.github.io/Project-DJ-Engine/PDJE_For_AI_Agents.html)

### Verification Labels

- `Officially Verified`: 공식 hand-written 문서나 generated API 문서로 직접 뒷받침되는 항목
- `Local Code Verified Only`: 로컬 `PDJE-Godot-Plugin` 코드에서만 확인되며 공식 문서에는 구체 설명이 없는 항목
- `Official Doc Mismatch`: 공식 문서 예시 또는 설명이 현재 Godot 바인딩 코드와 어긋나는 항목

### Current Findings

- `PDJE_Wrapper`, `PlayerWrapper`, editor lifecycle, playback mode, manual FX/music panel 개념, editor mutation/render/push/preview/history 흐름은 공식 문서로 뒷받침된다.
- 정확한 Godot 등록 클래스 목록, 대부분의 Godot wrapper 메서드명, `Dictionary` key shape, signal payload, utility DB wrapper surface, MIR 반환 shape는 공식 문서가 아니라 로컬 바인딩 코드 기준이다.
- `Core_Engine`의 현재 GDScript 예시는 `engine.InitPlayer(..., tracks[0], 480)`와 `engine.ResetPlayer()`를 사용하지만, 현재 Godot 바인딩은 `InitPlayer(mode, track_title:String, buffer_size)`만 노출하고 `ResetPlayer()`는 바인딩하지 않는다.
- `Judge_Engine`의 현재 Godot 예시는 `DeviceAdd(device, 4, 0, InputLine.BTN_L, 0, 5)`를 사용하지만, 현재 바인딩은 `DeviceAdd(device_list, PDJE_KEY_CODE, offset_microsecond, MatchRail_id)` 4개 인자만 노출하며 mouse enum 이름도 `PDJE_BTN_*` 계열이다.
- native editor 문서는 `GetDiff()`를 semantic diff API로 설명하지만, 현재 Godot wrapper 구현은 빈 `Dictionary`를 반환하는 stub이다.

## Registration Summary

### Always Registered

- `EnumWrapper : RefCounted`
- `PDJE_EDITOR_ARG : RefCounted`
- `EditorWrapper : RefCounted`
- `MusPanelWrapper : RefCounted`
- `FXArgWrapper : RefCounted`
- `FXWrapper : RefCounted`
- `CoreLine : RefCounted`
- `PDJE_VectorItem : RefCounted`
- `PDJE_VectorHit : RefCounted`
- `PDJE_RelationalRow : RefCounted`
- `PDJE_RelationalExecResult : RefCounted`
- `PDJE_StftResult : RefCounted`
- `PDJE_KeyValueDB : Node`
- `PDJE_VectorDB : Node`
- `PDJE_RelationalDB : Node`
- `PDJE_MIR : Node`
- `PlayerWrapper : RefCounted`
- `PDJE_Wrapper : Node`

### Conditionally Registered

아래 클래스는 `PDJE_GODOT_ENABLE_INPUT_WRAPPER`가 켜질 때만 등록된다.

- `InputLine : Node`
- `PDJE_Input_Module : Node`
- `PDJE_Judge_Module : Node`

빌드 기준으로는 [CMakeLists.txt](PDJE-Godot-Plugin/CMakeLists.txt)에서 `PDJE_DEVELOP_INPUT`이 켜진 경우에 `PDJE_GODOT_ENABLE_INPUT_WRAPPER`가 정의된다. 현재 CMake는 `APPLE`이 아니면 기본적으로 `PDJE_DEVELOP_INPUT ON`으로 잡는다.

#### Verification Note

- Status: `Local Code Verified Only`
- 공식 문서는 `PDJE_Wrapper`, `PDJE_Input_Module`, `PDJE_Judge_Module` 같은 Godot wrapper 이름의 존재만 넓게 언급한다. 정확한 등록 클래스 목록과 `PDJE_GODOT_ENABLE_INPUT_WRAPPER` 조건은 로컬 코드와 CMake에서만 확인된다.

## Reading Rule

아래 표는 아래 순서로 읽으면 된다.

- `Godot API`: GDScript/C# 쪽에서 호출하는 이름
- `Wrapper Method`: 바인딩된 C++ 메서드
- `Original / Native`: wrapper가 실제로 넘기는 PDJE/native 호출
- `Role`: wrapper가 담당하는 실질 역할

## Core API

### `PDJE_Wrapper`

- Base: `Node`
- Source: [PDJE_Core_Wrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/PDJE_Core_Wrapper.hpp), [PDJE_Core_Wrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/PDJE_Core_Wrapper.cpp)
- Role: `PDJE` 엔진, player, editor의 최상위 진입점

#### Enums

- `FULL_PRE_RENDER`
- `HYBRID_RENDER`
- `FULL_MANUAL_RENDER`

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `InitEngine` | `DBPath` | `bool` | `PDJE_Wrapper::InitEngine` | `engine.emplace(GpathToCPath(DBPath).string())` | root DB 경로 기준으로 `PDJE` 엔진 인스턴스를 생성한다 |
| `InitEditor` | `authName, authEmail, projectRoot` | `bool` | `PDJE_Wrapper::InitEditor` | `engine->InitEditor(...)` | editor session을 초기화한다 |
| `SearchMusic` | `Title, composer, bpm=-1.0` | `Array` | `PDJE_Wrapper::SearchMusic` | `engine->SearchMusic(...)` | music metadata를 검색한다 |
| `GetPCMFromMusicData` | `music_data` | `Dictionary` | `PDJE_Wrapper::GetPCMFromMusicData` | `engine->GetPCMFromMusData(query)` | music metadata 단서 또는 `musicPath`로 PCM을 뽑는다 |
| `SearchTrack` | `Title` | `Array` | `PDJE_Wrapper::SearchTrack` | `engine->SearchTrack(...)` | track metadata를 검색한다 |
| `InitPlayer` | `mode, track_title, buffer_size` | `bool` | `PDJE_Wrapper::InitPlayer` | `engine->InitPlayer(pm, td.front(), FrameBufferSize)` | player를 초기화한다 |
| `GetPlayer` | 없음 | `PlayerWrapper` | `PDJE_Wrapper::GetPlayer` | `engine->player` 참조로 wrapper 생성 | 현재 player control wrapper를 얻는다 |
| `GetEditor` | 없음 | `EditorWrapper` | `PDJE_Wrapper::GetEditor` | `engine->editor` 참조로 wrapper 생성 | 현재 editor control wrapper를 얻는다 |
| `CloseEditor` | 없음 | `void` | `PDJE_Wrapper::CloseEditor` | `engine->CloseEditor()` | editor session을 닫는다 |
| `PullOutCoreLine` | 없음 | `CoreLine` | `PDJE_Wrapper::PullOutCoreLine` | `engine->PullOutDataLine()` | core data line wrapper를 만든다 |
| `GetNoteObjects` | `trackTitle` | `bool` | `PDJE_Wrapper::GetNoteObjects` | `engine->SearchTrack(...)`, `engine->GetNoteObjects(track, osc)` | note object를 순회하며 Godot signal로 뿌린다 |

#### Signals

- `note_gen_signal(note_type, note_detail, first_arg, second_arg, third_arg, y_pos_start, y_pos_end, rail_id)`

#### Returned Shapes

`SearchMusic`는 `Array<Dictionary>`를 반환한다. 각 항목 key는 아래와 같다.

- `title`
- `composer`
- `bpm`
- `firstBar`
- `musicPath`

`SearchTrack`는 `Array<Dictionary>`를 반환한다. 각 항목 key는 아래와 같다.

- `title`
- `mixSet`

`GetPCMFromMusicData`는 `Dictionary`를 반환한다. 주요 key는 아래와 같다.

- `pcm : PackedFloat32Array`
- `channel_count : int`
- `musicPath : String`
- `pcm_length : int`

#### Not Exposed But Exists

- `ResetPlayer`
- `PullOutRawCoreLine`

둘 다 C++에는 있지만 `ClassDB::bind_method`가 없어 Godot에는 직접 노출되지 않는다.

#### Verification Notes

- Status: `Officially Verified` for facade role, `PLAY_MODE`, playback/editor 진입점, and `PDJE_Wrapper` naming.
- Status: `Official Doc Mismatch` for the current `Core_Engine` GDScript snippet: 공식 예시는 `tracks[0]`를 `InitPlayer()`에 넘기고 `ResetPlayer()`를 호출하지만, 현재 바인딩은 `String track_title`을 받아 내부에서 `SearchTrack()`를 다시 수행하며 `ResetPlayer()`는 노출하지 않는다.
- Status: `Local Code Verified Only` naming quirk: official docs and native structs use `firstBeat`, but the current `SearchMusic()` wrapper dictionary key is `firstBar`.
- Status: `Local Code Verified Only` for `GetPCMFromMusicData`, `PullOutCoreLine`, returned `Dictionary` shapes, and `note_gen_signal` payload shape.

### `CoreLine`

- Base: `RefCounted`
- Source: [CoreLine.hpp](PDJE-Godot-Plugin/Wrapper_Includes/global/DataLine/CoreLine.hpp), [CoreLine.cpp](PDJE-Godot-Plugin/Wrapper_Includes/global/DataLine/CoreLine.cpp)
- Role: player/core timing과 pre-rendered audio buffer를 읽는 data-line wrapper

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `GetUsedFrame` | 없음 | `PackedInt64Array` | `CoreLine::GetEngineTime` | `core_data.syncD->load(...)` | `[consumed_frames, microsecond]`를 돌려준다 |
| `GetNowCursor` | 없음 | `int64` | `CoreLine::GetNowCursor` | `*core_data.nowCursor` | 현재 cursor frame |
| `GetMaxCursor` | 없음 | `int64` | `CoreLine::GetMaxCursor` | `*core_data.maxCursor` | 최대 cursor frame |
| `GetPreRenderedFrames` | 없음 | `PackedFloat32Array` | `CoreLine::GetPreRenderedFrames` | `core_data.preRenderedData` memcpy | stereo pre-rendered float buffer를 통째로 읽는다 |

#### Notes

- Godot 노출명은 `GetUsedFrame`인데 실제 wrapper 메서드명은 `GetEngineTime`이다
- `GetPreRenderedFrames`는 `maxCursor * 2` 샘플을 stereo로 복사한다

## Player Control API

### `PlayerWrapper`

- Base: `RefCounted`
- Source: [PlayerWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/PlayerWrapper.hpp), [PlayerWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/PlayerWrapper.cpp)
- Role: `audioPlayer` control wrapper

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `Activate` | 없음 | `bool` | `PlayerWrapper::Activate` | `playerobj->Activate()` | playback 활성화 |
| `Deactivate` | 없음 | `bool` | `PlayerWrapper::Deactivate` | `playerobj->Deactivate()` | playback 비활성화 |
| `ChangeCursorPos` | `framePos` | `bool` | `PlayerWrapper::ChangeCursorPos` | `playerobj->ChangeCursorPos(std::stoull(...))` | 재생 cursor frame 이동 |
| `GetConsumedFrames` | 없음 | `String` | `PlayerWrapper::GetConsumedFrames` | `playerobj->GetConsumedFrames()` | 소비된 frame 수를 문자열로 반환 |
| `GetStatus` | 없음 | `String` | `PlayerWrapper::GetStatus` | deprecated stub | `"This is Deprecated Function."` 반환 |
| `GetFXControlPanel` | 없음 | `FXWrapper` | `PlayerWrapper::GetFXControlPanel` | `playerobj->GetFXControlPanel()` | FX panel wrapper 획득 |
| `GetMusicControlPanel` | 없음 | `MusPanelWrapper` | `PlayerWrapper::GetMusicControlPanel` | `playerobj->GetMusicControlPanel()` | music control panel wrapper 획득 |

#### Notes

- `GetConsumedFrames`는 숫자가 아니라 `String`을 반환한다
- `GetStatus`는 deprecated 상태다
- Status: `Officially Verified` for native playback lifecycle, `audioPlayer`, and manual control panel concepts.
- Status: `Local Code Verified Only` for the wrapper-specific `String` return type of `GetConsumedFrames()` and the deprecated `GetStatus()` stub message.

### `MusPanelWrapper`

- Base: `RefCounted`
- Source: [MusPanelWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/MusPanelWrapper.hpp), [MusPanelWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/MusPanelWrapper.cpp)
- Role: load/unload/cue/BPM change 같은 music panel 제어

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `LoadMusic` | `Title, composer, bpm=-1.0` | `int` | `MusPanelWrapper::LoadMusic` | `engine->SearchMusic(...)` -> `musref->LoadMusic(*engine->DBROOT.get(), muslist.front())` | DB에서 음악을 찾아 panel에 load |
| `CueMusic` | `title, newPos` | `bool` | `MusPanelWrapper::CueMusic` | `musref->CueMusic(title, pos)` | cue 위치 변경 |
| `SetMusic` | `title, onoff` | `bool` | `MusPanelWrapper::SetMusic` | `musref->SetMusic(title, onOff)` | 특정 음악 on/off |
| `GetLoadedMusicList` | 없음 | `Array` | `MusPanelWrapper::GetLoadedMusicList` | `musref->GetLoadedMusicList()` | 현재 loaded music title 목록 |
| `UnloadMusic` | `title` | `bool` | `MusPanelWrapper::UnloadMusic` | `musref->UnloadMusic(title)` | 음악 unload |
| `getFXHandle` | `title` | `FXWrapper` | `MusPanelWrapper::getFXHandle` | `musref->getFXHandle(title)` | 특정 음악용 FX handle 획득 |
| `ChangeBpm` | `title, targetBpm, originBpm` | `bool` | `MusPanelWrapper::ChangeBpm` | `musref->ChangeBpm(...)` | 특정 음악의 BPM 조정 |

#### Notes

- `LoadMusic`는 wrapper 레벨에서 `SearchMusic`을 먼저 수행하므로, title/composer/bpm 조합이 search key 역할도 한다
- `CueMusic`의 `newPos`는 `String`으로 받아 `stoull` 변환한다
- Status: `Officially Verified` for native manual music control concepts such as `LoadMusic`, `SetMusic`, `CueMusic`, `ChangeBpm`, and `GetMusicControlPanel()`.
- Status: `Official Doc Mismatch / Ambiguity`: 공식 `Core_Engine` 문서의 native `MusicControlPanel::LoadMusic(...)` 항목은 시그니처 표기는 `bool`인데 설명 본문은 `int, miniaudio Error code`를 말한다. 현재 Godot wrapper는 실제로 `int`를 반환한다.

### `FXWrapper`

- Base: `RefCounted`
- Source: [FXWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/FXWrapper.hpp), [FXWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/FXWrapper.cpp)
- Role: FX on/off와 FX arg setter 진입점

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `CheckFXOn` | 없음 | `bool` | `FXWrapper::CheckFXOn` | `fxpanel->checkSomethingOn()` | 어떤 FX라도 켜져 있는지 확인 |
| `FX_ON_OFF` | `fx, onoff` | `bool` | `FXWrapper::FX_ON_OFF` | `fxpanel->FX_ON_OFF(static_cast<FXList>(fx), onoff)` | FX on/off |
| `GetArgSetter` | 없음 | `FXArgWrapper` | `FXWrapper::GetArgSetter` | `FXArgWrapper::Init(fxpanel)` | FX argument setter 획득 |

#### Verification Notes

- Status: `Officially Verified` for native `FXControlPanel`, `FXList`, and exact argument names via [FX_ARGS](https://rliop913.github.io/Project-DJ-Engine/FX_ARGS.html).
- Status: `Official Doc Mismatch` in adapter shape: native docs describe `FXControlPanel::GetArgSetter(FXList)`, but the current Godot wrapper returns a generic `FXArgWrapper` with no `fx` argument. The `fx` selection happens later in `FXArgWrapper.GetFXArgKeys(fx)` and `FXArgWrapper.SetFXArg(fx, key, arg)`.

### `FXArgWrapper`

- Base: `RefCounted`
- Source: [FXArgWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/FXArgWrapper.hpp), [FXArgWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/FXArgWrapper.cpp)
- Role: FX parameter key 조회 및 값 설정

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `GetFXArgKeys` | `fx` | `Array` | `FXArgWrapper::GetFXArgKeys` | `refwrap->GetFXArgKeys(static_cast<FXList>(fx))` | FX에 쓸 수 있는 parameter key 목록 |
| `SetFXArg` | `fx, key, arg` | `bool` | `FXArgWrapper::SetFXArg` | `refwrap->SetFXArg(static_cast<FXList>(fx), key, arg)` | FX parameter 설정 |

### `EnumWrapper`

- Base: `RefCounted`
- Source: [EnumWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/EnumWrapper.hpp), [EnumWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Player/EnumWrapper.cpp)
- Role: FX enum constant provider

#### Exposed Enum

- `COMPRESSOR`
- `DISTORTION`
- `ECHO`
- `EQ`
- `FILTER`
- `FLANGER`
- `OCSFILTER`
- `PANNER`
- `PHASER`
- `ROBOT`
- `ROLL`
- `TRANCE`
- `VOL`

## Editor API

### `PDJE_EDITOR_ARG`

- Base: `RefCounted`
- Source: [WrappedEditorArgs.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/WrappedEditorArgs.hpp), [WrappedEditorArgs.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/WrappedEditorArgs.cpp)
- Role: `EditorWrapper.AddLine` / `deleteLine`에 넘길 편집 인자 생성기

#### Exposed Enums

`EDITOR_TYPE_LIST`

- `FILTER`
- `EQ`
- `DISTORTION`
- `CONTROL`
- `VOL`
- `LOAD`
- `UNLOAD`
- `BPM_CONTROL`
- `ECHO`
- `OSC_FILTER`
- `FLANGER`
- `PHASER`
- `TRANCE`
- `PANNER`
- `BATTLE_DJ`
- `ROLL`
- `COMPRESSOR`
- `ROBOT`

`EDITOR_DETAIL_LIST`

- `HIGH`
- `MID`
- `LOW`
- `PAUSE`
- `CUE`
- `TRIM`
- `FADER`
- `TIME_STRETCH`
- `SPIN`
- `PITCH`
- `REV`
- `SCRATCH`
- `BSCRATCH`

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `InitNoteArg` | `Note_Type, Note_Detail, first, second, third, beat, subBeat, separate, Ebeat, EsubBeat, Eseparate, RailID` | `void` | `PDJE_EDITOR_ARG::InitNoteArg` | `EDIT_ARG_NOTE` field 채움 | note edit arg 생성 |
| `InitMusicArg` | `musicName, bpm, beat, subBeat, separate` | `void` | `PDJE_EDITOR_ARG::InitMusicArg` | `EDIT_ARG_MUSIC` field 채움 | music BPM row arg 생성 |
| `InitMixArg` | `enum_editor_type, enum_editor_details, ID, first, second, third, beat, subBeat, separate, Ebeat, EsubBeat, Eseparate` | `void` | `PDJE_EDITOR_ARG::InitMixArg` | enum을 `TypeEnum`, `DetailEnum`으로 매핑 후 `EDIT_ARG_MIX` field 채움 | mix event arg 생성 |
| `InitKeyValueArg` | `key, value` | `void` | `PDJE_EDITOR_ARG::InitKeyValueArg` | `EDIT_ARG_KEY_VALUE` field 채움 | key/value arg 생성 |

#### Notes

- 이 클래스는 엔진을 직접 호출하지 않고 내부 arg struct를 채우는 역할만 한다
- Status: `Officially Verified` for the underlying `MixArgs`, `MusicArgs`, `NoteArgs`, `KEY_VALUE` families and current mix/detail categories via [Editor_Workflows](https://rliop913.github.io/Project-DJ-Engine/Editor_Workflows.html) and [Editor_Format](https://rliop913.github.io/Project-DJ-Engine/Editor_Format.html).
- Status: `Local Code Verified Only` for the exact Godot-facing enum constant exposure on `PDJE_EDITOR_ARG`.

### `EditorWrapper`

- Base: `RefCounted`
- Source: [EditorWrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/EditorWrapper.hpp), [EditorWrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/EditorWrapper.cpp), [EditorFunctions.cpp](PDJE-Godot-Plugin/Wrapper_Includes/core/Editor/EditorFunctions.cpp)
- Role: `editorObject` 기반 편집, render, demo play, history control

#### Exposed Enum

- `NOTE`
- `KV`
- `MIX`
- `MUSIC`

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `AddLine` | `arg` | `bool` | `EditorWrapper::AddLine` | `edit->AddLine<EDIT_ARG_...>(...)` | note/music/mix/kv line 추가 |
| `EditMusicFirstBar` | `title, firstBar` | `bool` | `EditorWrapper::EditMusicFirstBeat` | `edit->AddLine(title, firstBeat)` | music first beat 수정 |
| `deleteLine` | `obj, skipType_if_mix_obj, skipDetail_if_mix_obj` | `int` | `EditorWrapper::deleteLine` | `edit->deleteLine<...>(...)` 또는 `edit->deleteLine(mix, skipType, skipDetail)` | line 삭제 |
| `render` | `trackTitle` | `String` | `EditorWrapper::render` | `edit->render(trackTitle, *engine->DBROOT.get(), render_msg)` | lint/render 수행, 성공 시 `Flag_is_rendered = true` |
| `demoPlayInit` | `frameBufferSize, trackTitle` | `PlayerWrapper` | `EditorWrapper::demoPlayInit` | `edit->demoPlayInit(player, frameBufferSize, trackTitle)` | editor-authored content로 demo player 생성 |
| `pushTrackToRootDB` | `trackTitleToPush` | `bool` | `EditorWrapper::pushTrackToRootDB` | `edit->pushToRootDB(*engine->DBROOT.get(), trackTitle)` | render된 track을 root DB에 반영 |
| `pushToRootDB` | `musicTitle, musicComposer` | `bool` | `EditorWrapper::pushToRootDB` | `edit->pushToRootDB(*engine->DBROOT.get(), musicTitle, musicComposer)` | render된 music data를 root DB에 반영 |
| `getMixDatas` | 없음 | `bool` | `EditorWrapper::getMixDatas` | `edit->getAll<EDIT_ARG_MIX>(callback)` | mix data signal emit |
| `getMusicDatas` | 없음 | `bool` | `EditorWrapper::getMusicBpmDatas` | `edit->getAll<EDIT_ARG_MUSIC>(callback)` | music BPM data signal emit |
| `getNoteDatas` | 없음 | `bool` | `EditorWrapper::getNoteDatas` | `edit->getAll<EDIT_ARG_NOTE>(callback)` | note data signal emit |
| `getKeyValueDatas` | 없음 | `bool` | `EditorWrapper::getKeyValueDatas` | `edit->getAll<EDIT_ARG_KEY_VALUE>(callback)` | kv data signal emit |
| `getAll` | 없음 | `Dictionary` | `EditorWrapper::getAll` | `edit->getAll<...>` 여러 번 호출 | 전체 편집 데이터를 dictionary로 묶어 반환 |
| `Undo` | `_FLAG_EDITOR_OBJ, musicName_if_flag_music=""` | `String` | `EditorWrapper::Undo` | `edit->Undo<...>()` | type별 undo |
| `Redo` | `_FLAG_EDITOR_OBJ, musicName_if_flag_music=""` | `String` | `EditorWrapper::Redo` | `edit->Redo<...>()` | type별 redo |
| `Go` | `_FLAG_EDITOR_OBJ, OID` | `String` | `EditorWrapper::Go` | `edit->Go<...>(node_id)` | 특정 commit/log OID로 이동 |
| `GetLogWithJSONGraph` | `_FLAG_EDITOR_OBJ, musicName_if_flag_music` | `String` | `EditorWrapper::GetLogWithJSONGraph` | `edit->GetLogWithJSONGraph<...>(...)` | JSON graph 형식의 log 조회 |
| `UpdateLog` | 없음 | `String` | `EditorWrapper::UpdateLog` | `edit->UpdateLog<...>()` | 각 repo log 갱신 |
| `DESTROY_PROJECT` | 없음 | `String` | `EditorWrapper::DESTROY_PROJECT` | `edit->DESTROY_PROJECT()` | project 제거 |
| `ConfigNewMusic` | `NewMusicName, composer, musicPath, firstBar="0"` | `bool` | `EditorWrapper::ConfigNewMusic` | `edit->ConfigNewMusic(...)` | 새 music asset 등록 |
| `GetDiff` | `_FLAG_EDITOR_OBJ, musicName_if_flag_music, from_OID, to_OID` | `Dictionary` | `EditorWrapper::GetDiff` | 현재 stub | diff API placeholder |

#### Signals

- `pdje_editor_get_mix_data(type, ID, details, first, second, third, beat, subbeat, separate, Ebeat, Esubbeat, Eseparate)`
- `pdje_editor_get_music_bpm_data(music_title, beat, subbeat, separate, bpm)`
- `pdje_editor_get_note_data(note_type, note_detail, first, second, third, beat, subbeat, separate, Ebeat, Esubbeat, Eseparate, RailID)`
- `pdje_editor_get_key_value_data(key, value)`

#### Returned Shape

`getAll()`은 `Dictionary`를 반환하며 key는 아래와 같다.

- `mixDatas : Array<Dictionary>`
- `musicDatas : Array<Dictionary>`
- `noteDatas : Array<Dictionary>`
- `keyValues : Dictionary`

`mixDatas` 항목은 아래 의미를 담는 field들을 가진다.

- type
- details
- ID
- first
- second
- third
- beat / subBeat / separate
- Ebeat / EsubBeat / Eseparate

`musicDatas` 항목은 아래 의미를 담는 field들을 가진다.

- title
- beat / subBeat / separate
- bpm

`noteDatas` 항목은 아래 의미를 담는 field들을 가진다.

- note type
- note detail
- first / second / third
- beat / subBeat / separate
- Ebeat / EsubBeat / Eseparate
- rail id

#### Important Notes

- `EditMusicFirstBar`라는 Godot API 이름이지만 실제로는 first beat 문자열을 수정한다
- 현재 노출된 music-side mutation은 사실상 `ConfigNewMusic(...)`, `EditMusicFirstBar(...)`, `PDJE_EDITOR_ARG.InitMusicArg(...) + AddLine(...)` 계열뿐이다
- 즉, 현재 wrapper surface에는 `ConfigNewMusic(...)` 이후 기존 music asset의 `title`, `composer`, `musicPath`를 인플레이스로 갱신하는 전용 API가 보이지 않는다
- `render`가 먼저 성공하지 않으면 `pushTrackToRootDB`와 `pushToRootDB`는 실패한다
- `GetDiff`는 바인딩은 되어 있지만 현재 구현이 `return Dictionary();`로 고정된 stub다
- Status: `Officially Verified` for editor mutation families, history API 존재, `render`/`pushToRootDB`/`demoPlayInit` workflow, and `firstBeat` semantics.
- Status: `Official Doc Mismatch / Coverage Gap`: native docs still describe `editorObject::Open()`, but the current Godot wrapper surface here does not bind `Open()`. The wrapper entry path remains `PDJE_Wrapper.InitEditor(...)` plus `GetEditor()`.
- Status: `Official Doc Mismatch` for `GetDiff`: native 공식 문서는 semantic diff를 설명하지만, 현재 Godot wrapper는 비어 있는 `Dictionary`만 반환한다.
- Status: `Local Code Verified Only` for Godot signal payload shapes, `getAll()` top-level key names, and the exact wrapper enum integers.

## MIR API

### `PDJE_MIR`

- Base: `Node`
- Source: [PDJE_MIR.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR.hpp), [PDJE_MIR_Bindings.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR_Bindings.cpp), [PDJE_MIR_Waveform.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR_Waveform.cpp), [PDJE_MIR_STFT.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_MIR_STFT.cpp)
- Role: waveform / STFT / cached MIR utility node

#### Exposed Enum

- `BLACKMAN`
- `BLACKMAN_HARRIS`
- `BLACKMAN_NUTTALL`
- `HANNING`
- `NUTTALL`
- `FLATTOP`
- `GAUSSIAN`
- `HAMMING`
- `NONE`

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `SoundToWaveform` | `core_api, cache_db, music_title, composer, bpm, pcm_per_pixel, width=4096, height=256, start_index=0, end_index=-1` | `Array` | `PDJE_MIR::SoundToWaveform` | `engine->SearchMusic(...)` -> `engine->GetPCMFromMusData(..., 2)` -> `EncodeWaveformWebps(...)` | 기본 waveform 이미지 buffer array 생성 |
| `SoundToRGBWaveform` | `core_api, cache_db, music_title, composer, bpm, pcm_per_pixel, width=4096, height=256, start_index=0, end_index=-1, target_window=HANNING, window_size_exp=10, overlap_ratio=0.5` | `Array` | `PDJE_MIR::SoundToRGBWaveform` | 위 흐름 + STFT config 포함 `EncodeWaveformWebps(...)` | RGB/STFT 기반 waveform 이미지 buffer array 생성 |
| `STFT_MUSIC` | `core_api, cache_db, music_title, composer, bpm, target_window=HANNING, window_size_exp=10, overlap_ratio=0.5` | `PackedColorArray` | `PDJE_MIR::STFT_MUSIC` | `engine->SearchMusic(...)` -> `engine->GetPCMFromMusData(..., 1)` -> `PDJE_PARALLEL::STFT::calculate(...)` | 곡 전체 STFT를 RGB color sequence로 계산 |
| `STFT_PCM_DATA` | `pcm, channel_count, target_window=HANNING, window_size_exp=10, overlap_ratio=0.5, toPower=true, to_bin=true, normalize_min_max=true, mel_scale=true, to_db=true, to_rgb=true` | `TypedArray<PDJE_StftResult>` | `PDJE_MIR::STFT_PCM_DATA` | `PDJE_PARALLEL::STFT::calculate(...)` | PCM 직접 입력 기반 multi-channel STFT 계산 |

#### Important Notes

- `SoundToWaveform`와 `SoundToRGBWaveform`는 Godot `Image`가 아니라 `Array` 안에 encoded `PackedByteArray`를 담아 반환한다
- 로컬 예제 [util_test.tscn](PDJE-Godot-Plugin/util_test.tscn)은 `Image.load_webp_from_buffer(...)`로 decode해서 사용한다
- 내부 구현은 cache DB가 열려 있으면 waveform/STFT 결과를 cache key로 저장/재사용한다
- Status: `Officially Verified` only for the broader fact that `PDJE_UTIL` is active in-tree and includes database abstractions plus STFT/image helper code.
- Status: `Local Code Verified Only` for the existence of `PDJE_MIR`, the exact Godot method names, cache-key behavior, and the encoded `PackedByteArray` return contract used by the Godot wrapper.

### `PDJE_StftResult`

- Base: `RefCounted`
- Source: [PDJE_StftResult.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_StftResult.hpp), [PDJE_StftResult.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/MIR/PDJE_StftResult.cpp)
- Role: `STFT_PCM_DATA` 반환용 데이터 carrier

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `set_real` | `real` | `void` | `PDJE_StftResult::set_real` | internal field set | 실수부 저장 |
| `get_real` | 없음 | `PackedFloat32Array` | `PDJE_StftResult::get_real` | internal field get | 실수부 반환 |
| `set_imag` | `imag` | `void` | `PDJE_StftResult::set_imag` | internal field set | 허수부 저장 |
| `get_imag` | 없음 | `PackedFloat32Array` | `PDJE_StftResult::get_imag` | internal field get | 허수부 반환 |

#### Exposed Properties

- `real`
- `imag`
- `power`

#### Important Notes

- `power` property는 `ADD_PROPERTY`에는 등록되어 있지만 `set_power/get_power` 바인딩이 실제 구현에 없다
- Status: `Local Code Verified Only`

## Utility Database API

이 섹션의 native backend 존재 자체는 [Util_Engine](https://rliop913.github.io/Project-DJ-Engine/Util_Engine.html)로 확인된다.

- `RocksDbBackend`
- `SqliteBackend`
- `AnnoyBackend`

다만 `PDJE_KeyValueDB`, `PDJE_VectorDB`, `PDJE_RelationalDB`라는 Godot wrapper 이름과 그 method signature는 공식 문서가 아니라 로컬 Godot binding 코드 기준이다.

### `PDJE_KeyValueDB`

- Base: `Node`
- Source: [PDJE_KeyValueDB.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/keyvalue/PDJE_KeyValueDB.hpp), [PDJE_KeyValueDB.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/keyvalue/PDJE_KeyValueDB.cpp)
- Native backend: `RocksDbBackend`
- Role: binary/text key-value store

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `Create` | `path, truncate_if_exists=false` | `bool` | `PDJE_KeyValueDB::Create` | `NativeKeyValueBackend::create(...)` | DB 파일 생성 |
| `Destroy` | `path` | `bool` | `PDJE_KeyValueDB::Destroy` | `NativeKeyValueBackend::destroy(...)` | DB 제거 |
| `Open` | `path, create_if_missing=false, truncate_if_exists=false, read_only=false` | `bool` | `PDJE_KeyValueDB::Open` | `backend.open(...)` | DB 열기 |
| `Close` | 없음 | `bool` | `PDJE_KeyValueDB::Close` | `backend.close()` | DB 닫기 |
| `IsOpen` | 없음 | `bool` | `PDJE_KeyValueDB::IsOpen` | internal state | open 상태 확인 |
| `GetPath` | 없음 | `String` | `PDJE_KeyValueDB::GetPath` | internal state | 현재 path |
| `Contains` | `key` | `bool` | `PDJE_KeyValueDB::Contains` | `backend.contains(key)` | key 존재 여부 |
| `GetText` | `key` | `String` | `PDJE_KeyValueDB::GetText` | `backend.get_text(key)` | text value 읽기 |
| `GetBytes` | `key` | `PackedByteArray` | `PDJE_KeyValueDB::GetBytes` | `backend.get_bytes(key)` | byte value 읽기 |
| `PutText` | `key, value` | `bool` | `PDJE_KeyValueDB::PutText` | `backend.put_text(key, value)` | text value 저장 |
| `PutBytes` | `key, value` | `bool` | `PDJE_KeyValueDB::PutBytes` | `backend.put_bytes(key, span)` | byte value 저장 |
| `Erase` | `key` | `bool` | `PDJE_KeyValueDB::Erase` | `backend.erase(key)` | key 삭제 |
| `ListKeys` | `prefix=""` | `PackedStringArray` | `PDJE_KeyValueDB::ListKeys` | `backend.list_keys(prefix)` | key 목록 조회 |

#### Notes

- `TryGetBytesSilently`는 내부 cache lookup용 helper이며 Godot에는 노출되지 않는다

### `PDJE_VectorDB`

- Base: `Node`
- Source: [PDJE_VectorDB.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorDB.hpp), [PDJE_VectorDB.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorDB.cpp)
- Native backend: `NearestNeighborIndex<AnnoyBackend>`
- Role: embedding vector nearest-neighbor DB

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `Create` | `root_path, dimension, trees=10, prefault=false, truncate_if_exists=false` | `bool` | `PDJE_VectorDB::Create` | `NativeNearestIndex::create(...)` | vector index 생성 |
| `Destroy` | `root_path, dimension, trees=10, prefault=false` | `bool` | `PDJE_VectorDB::Destroy` | `NativeNearestIndex::destroy(...)` | vector index 제거 |
| `Open` | `root_path, dimension, trees=10, prefault=false, create_if_missing=false, truncate_if_exists=false, read_only=false` | `bool` | `PDJE_VectorDB::Open` | `NativeNearestIndex::open(...)` | vector index 열기 |
| `Close` | 없음 | `bool` | `PDJE_VectorDB::Close` | `index.close()` | vector index 닫기 |
| `IsOpen` | 없음 | `bool` | `PDJE_VectorDB::IsOpen` | internal state | open 상태 확인 |
| `GetRootPath` | 없음 | `String` | `PDJE_VectorDB::GetRootPath` | internal state | root path |
| `GetDimension` | 없음 | `int` | `PDJE_VectorDB::GetDimension` | internal state | embedding dimension |
| `Contains` | `id` | `bool` | `PDJE_VectorDB::Contains` | `index.contains(id)` | item 존재 여부 |
| `GetItem` | `id` | `PDJE_VectorItem` | `PDJE_VectorDB::GetItem` | `index.get_item(id)` | item 조회 |
| `UpsertItem` | `item` | `bool` | `PDJE_VectorDB::UpsertItem` | `index.upsert_item(MakeNearestItem(item))` | item insert/update |
| `EraseItem` | `id` | `bool` | `PDJE_VectorDB::EraseItem` | `index.erase_item(id)` | item 삭제 |
| `Search` | `query_embedding, limit=10, search_k=-1` | `Array` | `PDJE_VectorDB::Search` | `index.search(span, opts)` | nearest-neighbor search |
| `ListKeys` | 없음 | `PackedStringArray` | `PDJE_VectorDB::ListKeys` | `index.list_keys()` | id 목록 조회 |

#### Notes

- `UpsertItem`는 `item.embedding.size() == configured dimension` 조건을 강하게 검사한다
- `Search`는 `Array<PDJE_VectorHit>`를 반환한다

### `PDJE_VectorItem`

- Base: `RefCounted`
- Source: [PDJE_VectorTypes.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorTypes.hpp), [PDJE_VectorTypes.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorTypes.cpp)
- Role: `PDJE_VectorDB.UpsertItem` 입력용 data carrier

#### Exposed Methods And Properties

- `set_id / get_id`
- `set_embedding / get_embedding`
- `set_text_payload / get_text_payload`
- `set_bytes_payload / get_bytes_payload`

Properties:

- `id`
- `embedding`
- `text_payload`
- `bytes_payload`

### `PDJE_VectorHit`

- Base: `RefCounted`
- Source: [PDJE_VectorTypes.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorTypes.hpp), [PDJE_VectorTypes.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/nearest/PDJE_VectorTypes.cpp)
- Role: `PDJE_VectorDB.Search` 결과 carrier

#### Exposed Methods And Properties

- `set_id / get_id`
- `set_distance / get_distance`
- `set_text_payload / get_text_payload`
- `set_bytes_payload / get_bytes_payload`

Properties:

- `id`
- `distance`
- `text_payload`
- `bytes_payload`

### `PDJE_RelationalDB`

- Base: `Node`
- Source: [PDJE_RelationalDB.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalDB.hpp), [PDJE_RelationalDB.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalDB.cpp)
- Native backend: `RelationalDatabase<SqliteBackend>`
- Role: SQLite 기반 relational DB wrapper

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `Create` | `path, truncate_if_exists=false` | `bool` | `PDJE_RelationalDB::Create` | `SqliteBackend::create(...)` | DB 파일 생성 |
| `Destroy` | `path` | `bool` | `PDJE_RelationalDB::Destroy` | `SqliteBackend::destroy(...)` | DB 파일 제거 |
| `Open` | `path, create_if_missing=false, truncate_if_exists=false, read_only=false` | `bool` | `PDJE_RelationalDB::Open` | `NativeRelationalDatabase::open(...)` | DB 열기 |
| `Close` | 없음 | `bool` | `PDJE_RelationalDB::Close` | `database.close()` | DB 닫기 |
| `IsOpen` | 없음 | `bool` | `PDJE_RelationalDB::IsOpen` | internal state | open 상태 확인 |
| `GetPath` | 없음 | `String` | `PDJE_RelationalDB::GetPath` | internal state | 현재 path |
| `Execute` | `sql, params=[]` | `PDJE_RelationalExecResult` | `PDJE_RelationalDB::Execute` | `database.execute(sql, native_params)` | non-query SQL 실행 |
| `Query` | `sql, params=[]` | `Array` | `PDJE_RelationalDB::Query` | `database.query(sql, native_params)` | query 실행 후 row 반환 |
| `BeginTransaction` | 없음 | `bool` | `PDJE_RelationalDB::BeginTransaction` | `database.begin_transaction()` | transaction 시작 |
| `Commit` | 없음 | `bool` | `PDJE_RelationalDB::Commit` | `database.commit()` | commit |
| `Rollback` | 없음 | `bool` | `PDJE_RelationalDB::Rollback` | `database.rollback()` | rollback |

#### Notes

- `params`에는 `nil`, `int`, `float`, `String`, `PackedByteArray`만 허용된다
- `Query`는 `Array<PDJE_RelationalRow>`를 반환한다

### `PDJE_RelationalRow`

- Base: `RefCounted`
- Source: [PDJE_RelationalTypes.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalTypes.hpp), [PDJE_RelationalTypes.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalTypes.cpp)
- Role: relational query row carrier

Methods and properties:

- `set_columns / get_columns`
- `set_values / get_values`
- properties: `columns`, `values`

### `PDJE_RelationalExecResult`

- Base: `RefCounted`
- Source: [PDJE_RelationalTypes.hpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalTypes.hpp), [PDJE_RelationalTypes.cpp](PDJE-Godot-Plugin/Wrapper_Includes/util/db/relational/PDJE_RelationalTypes.cpp)
- Role: `Execute` 결과 carrier

Methods and properties:

- `set_affected_rows / get_affected_rows`
- `set_has_last_insert_rowid / get_has_last_insert_rowid`
- `set_last_insert_rowid / get_last_insert_rowid`
- properties: `affected_rows`, `has_last_insert_rowid`, `last_insert_rowid`

## Input And Judge API

이 섹션은 `PDJE_GODOT_ENABLE_INPUT_WRAPPER`가 활성화된 빌드에서만 유효하다.

### `InputLine`

- Base: `Node`
- Source: [InputLine.hpp](PDJE-Godot-Plugin/Wrapper_Includes/global/DataLine/InputLine.hpp), [InputLine.cpp](PDJE-Godot-Plugin/Wrapper_Includes/global/DataLine/InputLine.cpp)
- Role: input data line을 drain하고 Godot signal로 변환

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `emit_input_signal` | 없음 | `void` | `InputLine::emit_input_signal` | `input_data.input_arena->Receive()` / `midi_datas->Get()` -> parse -> `emit_signal(...)` | keyboard/mouse/MIDI 이벤트를 signal로 방출 |

#### Exposed Enums

Keyboard enum `PDJE_KEY`

- function keys, number keys, alpha keys
- keypad keys
- arrows, ctrl/alt/shift
- punctuation and special keys

Mouse enum `DEVICE_MOUSE_EVENT`

- `PDJE_BTN_EX`
- `PDJE_BTN_SIDE`
- `PDJE_BTN_M`
- `PDJE_BTN_R`
- `PDJE_BTN_L`
- `PDJE_WHEEL_X`
- `PDJE_WHEEL_Y`
- `PDJE_AXIS_MOVE`

#### Signals

- `pdje_input_keyboard_signal(device_id, device_name, microsecond_string, keyboard_key, isPressed)`
- `pdje_input_mouse_signal(device_id, device_name, microsecond_string, L_btn, R_btn, wheel_btn, side_btn, ex_btn, is_wheel_YAxis, wheel_move, mouse_axis_type, x, y)`
- `pdje_midi_input_signal(port_name, input_type, channel, position, value, microsecond_string)`

#### Notes

- `Init`은 C++에는 있지만 Godot에 바인딩되지 않는다
- 이 노드는 `PDJE_Input_Module.InitializeInputLine(...)`로 data line을 주입받아야 의미가 생긴다
- Status: `Officially Verified` for the Godot wrapper flow using `PDJE_Input_Module`, `InitializeInputLine`, and `emit_input_signal`.
- Status: `Local Code Verified Only` for the full enum inventory and signal payload field ordering.

### `PDJE_Input_Module`

- Base: `Node`
- Source: [PDJE_Input_Wrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/input/PDJE_Input_Wrapper.hpp), [PDJE_Input_Wrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/input/PDJE_Input_Wrapper.cpp)
- Role: input backend 초기화, device 검색/선택, input loop 구동

#### Exposed Enum

- `DEVICE_CONFIG_STATE`
- `INPUT_LOOP_READY`
- `INPUT_LOOP_RUNNING`
- `DEAD`

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `Init` | 없음 | `bool` | `PDJE_Input_Module::Init` | `InitWithOptions(false)` | 기본 input init |
| `InitWithOptions` | `use_internal_window=false` | `bool` | `PDJE_Input_Module::InitWithOptions` | `input_module.Init(platform_ctx0, platform_ctx1, use_internal_window)` | backend + platform context init |
| `GetCurrentInputBackend` | 없음 | `String` | `PDJE_Input_Module::GetCurrentInputBackend` | `input_module.GetCurrentInputBackend()` | 현재 backend 이름 |
| `Config` | `devices, MIDIdevices` | `bool` | `PDJE_Input_Module::Config` | `input_module.Config(devs, target_midis)` | 사용할 keyboard/mouse/MIDI 장치 선택 |
| `Kill` | 없음 | `bool` | `PDJE_Input_Module::Kill` | `input_module.Kill()` | input loop 종료 |
| `Run` | 없음 | `bool` | `PDJE_Input_Module::Run` | `input_module.Run()` | input loop 시작 |
| `GetState` | 없음 | `INPUT_STATE` | `PDJE_Input_Module::GetState` | `input_module.GetState()` | 상태 조회 |
| `InitializeInputLine` | `input_line` | `void` | `PDJE_Input_Module::InitializeInputLine` | `input_line->Init(input_module.PullOutDataLine())` | `InputLine`에 raw data line 연결 |
| `GetDevs` | 없음 | `Array` | `PDJE_Input_Module::GetDevs` | `input_module.GetDevs()` | keyboard/mouse device 목록 |
| `GetMIDIDevs` | 없음 | `Array` | `PDJE_Input_Module::GetMIDIDevs` | `input_module.GetMIDIDevs()` | MIDI port 목록 |

#### Returned Shape

`GetDevs()` 항목 key:

- `device_specific_id`
- `name`
- `type` with values `KEYBOARD` or `MOUSE`

`GetMIDIDevs()`는 port name string 배열이다.

#### Not Exposed But Exists

- `PullOutRawDataLine`

#### Verification Notes

- Status: `Officially Verified` for `Init`, `GetDevs`, `GetMIDIDevs`, `Config`, `InitializeInputLine`, `Run`, `Kill`, and the state enum names shown in `Input_Engine`.
- Status: `Local Code Verified Only` for compile-time availability, exact returned `Dictionary` keys, and `PullOutRawDataLine` not being bound.

### `PDJE_Judge_Module`

- Base: `Node`
- Source: [PDJE_Judge_Wrapper.hpp](PDJE-Godot-Plugin/Wrapper_Includes/judge/PDJE_Judge_Wrapper.hpp), [PDJE_Judge_Wrapper.cpp](PDJE-Godot-Plugin/Wrapper_Includes/judge/PDJE_Judge_Wrapper.cpp)
- Role: note judging, input rail mapping, miss/use callbacks

#### Exposed Methods

| Godot API | Args | Return | Wrapper Method | Original / Native | Role |
|---|---|---:|---|---|---|
| `AddDataLines` | `input, core` | `bool` | `PDJE_Judge_Module::AddDataLines` | `judge_module.inits.coreline = core->PullOutRawCoreLine()`, `judge_module.inits.inputline = input->PullOutRawDataLine()` | judge에 input/core data line 연결 |
| `DeviceAdd` | `device_list, PDJE_KEY_CODE, offset_microsecond, MatchRail_id` | `bool` | `PDJE_Judge_Module::DeviceAdd` | `judge_module.inits.SetRail(dev, keymask, offset, rail)` | keyboard/mouse device event를 rail에 매핑 |
| `MIDI_DeviceAdd` | `midi_device_name, match_rail_id, input_type, ch, pos, offset_microsecond` | `bool` | `PDJE_Judge_Module::MIDI_DeviceAdd` | `judge_module.inits.SetRail(port, rail, midi_type, ch, pos, offset)` | MIDI input을 rail에 매핑 |
| `SetRule` | `use_range_half_us, miss_range_half_us, useloop_sleep_time_ms, missloop_sleep_time_ms, enable_custom_mouse_signal` | `void` | `PDJE_Judge_Module::SetRule` | `judge_module.inits.SetEventRule(...)`, `SetCustomEvents(...)` | judge time window와 callbacks 설정 |
| `SetNotes` | `core, track_title` | `bool` | `PDJE_Judge_Module::SetNotes` | `core->engine->SearchTrack(...)`, `core->engine->GetNoteObjects(track, osc)`, `judge_module.inits.NoteObjectCollector(...)` | 특정 track note objects를 judge에 등록 |
| `StartJudge` | 없음 | `bool` | `PDJE_Judge_Module::StartJudge` | `judge_module.Start()` | judge loop 시작 |
| `EndJudge` | 없음 | `void` | `PDJE_Judge_Module::EndJudge` | `judge_module.End()` | judge 종료 |

#### Signals

- `pdje_judge_miss_signal(missed_list)`
- `pdje_judge_use_signal(rail_id, is_pressed, is_late, time_diff)`
- `pdje_judge_custom_mouse_parse_signal(microsecond, found_events, rail_id, X, Y, AXIS_ENUM)`

#### Notes

- `MIDI_DeviceAdd`는 구현상 마지막 성공 return이 명시되어 있지 않다
- `SetRule`는 miss/use/custom mouse callback을 Godot signal emit 쪽으로 연결한다
- Status: `Officially Verified` for the Godot wrapper flow around `AddDataLines`, `MIDI_DeviceAdd`, `SetRule`, `SetNotes`, `StartJudge`, and `EndJudge`.
- Status: `Official Doc Mismatch` for `DeviceAdd`: 공식 `Judge_Engine` 예시는 현재 바인딩 시그니처와 맞지 않는 6개 인자 호출을 보여준다. 현재 코드 기준으로는 4개 인자만 유효하다.
- Status: `Official Doc Mismatch` for the mouse enum spelling used in that example: 공식 예시의 `InputLine.BTN_L` 대신 현재 바인딩 enum은 `PDJE_BTN_L` 계열이다.

## Practical Notes For Future Blueprint Work

- `PDJE_Wrapper` 하나로 engine/editor/player 진입이 모두 가능하다
- `EditorWrapper`는 현재 blueprint의 `authoring semantics`와 가장 직접적으로 연결되는 래퍼다
- `PDJE_MIR.SoundToWaveform` / `SoundToRGBWaveform`는 `Image`가 아니라 encoded byte array를 반환하므로, UI 계층에서 decode step을 별도 설계해야 한다
- `GetDiff`는 현재 stub이므로 diff viewer 같은 기능을 blueprint에 바로 가정하면 안 된다
- input/judge 계열은 빌드 플래그에 따라 빠질 수 있으므로, core blueprint 기준 필수 의존으로 잡기 전에 조건을 확인해야 한다

## Fast Index

향후 문서 작업에서 가장 자주 볼 가능성이 높은 클래스는 아래다.

- `PDJE_Wrapper`
- `EditorWrapper`
- `PDJE_EDITOR_ARG`
- `PDJE_MIR`
- `PDJE_KeyValueDB`
- `PlayerWrapper`
- `MusPanelWrapper`

이 여섯 개가 현재 `Project DJ DAW` 문서 작업에서 가장 직접적으로 쓸 바인딩 축이다.
