class_name PDJEService
extends RefCounted

signal boot_status_changed(ready: bool, message: String)

const DEFAULT_TEMP_ROOT := "res://TempRoot"
const DEFAULT_EDITOR_ROOT := "res://EditTempRoot"
const DEFAULT_CACHE_DB := "res://img_cache_db"

var engine_root = null
var editor_root = null
var mir_api = null
var cache_db = null

var _ready := false
var _boot_message := "PDJE service not booted"


func boot(
	temp_root_path: String = DEFAULT_TEMP_ROOT,
	editor_root_path: String = DEFAULT_EDITOR_ROOT,
	cache_db_path: String = DEFAULT_CACHE_DB
) -> bool:
	if _ready:
		return true

	if not ClassDB.class_exists("PDJE_Wrapper"):
		_set_boot_status(false, "PDJE_Wrapper class is not available")
		return false

	engine_root = PDJE_Wrapper.new()
	if engine_root == null:
		_set_boot_status(false, "Failed to construct PDJE engine wrapper")
		return false

	if not engine_root.InitEngine(temp_root_path):
		_set_boot_status(false, "InitEngine failed for %s" % temp_root_path)
		return false

	if not engine_root.InitEditor("ProjectDJDAW", "local@project-dj-daw", editor_root_path):
		_set_boot_status(false, "InitEditor failed for %s" % editor_root_path)
		return false

	editor_root = engine_root.GetEditor()
	if editor_root == null:
		_set_boot_status(false, "EditorWrapper is unavailable after InitEditor")
		return false

	mir_api = PDJE_MIR.new()
	cache_db = PDJE_KeyValueDB.new()
	if cache_db != null:
		cache_db.Open(cache_db_path)

	_ready = true
	_set_boot_status(true, "PDJE service ready")
	return true


func is_ready() -> bool:
	return _ready


func get_boot_message() -> String:
	return _boot_message


func validate_source_audio_path(source_audio_path: String) -> Dictionary:
	var path := source_audio_path.strip_edges()
	if path.is_empty():
		return {
			"ok": false,
			"reason": "Source path is empty",
			"mode": "none",
		}

	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"reason": "Source file does not exist",
			"mode": "file_exists",
		}

	if not _ready:
		return {
			"ok": true,
			"reason": "PDJE unavailable, accepted by file existence only",
			"mode": "file_only",
		}

	var pcm_data: Dictionary = engine_root.GetPCMFromMusicData({
		"musicPath": path,
	})
	var pcm = pcm_data.get("pcm", PackedFloat32Array())
	if pcm.is_empty():
		return {
			"ok": false,
			"reason": "PCM decode returned empty data",
			"mode": "pdje_pcm",
			"pcm_length": int(pcm_data.get("pcm_length", 0)),
		}

	return {
		"ok": true,
		"reason": "PCM decode succeeded",
		"mode": "pdje_pcm",
		"channel_count": int(pcm_data.get("channel_count", 0)),
		"pcm_length": int(pcm_data.get("pcm_length", 0)),
	}


func search_music(title: String, composer: String, bpm: float = -1.0) -> Array:
	if not _ready:
		return []
	return engine_root.SearchMusic(title, composer, bpm)


func register_music_asset(
	title: String,
	composer: String,
	music_path: String,
	first_beat: String,
	start_bpm: String,
	bpm_rows: Array = []
) -> Dictionary:
	if not _ready:
		return {
			"ok": false,
			"reason": "PDJE service is not ready",
		}

	if not editor_root.ConfigNewMusic(title, composer, music_path, first_beat):
		return {
			"ok": false,
			"reason": "ConfigNewMusic failed",
		}

	var initial_row_added := _add_music_bpm_row(title, start_bpm, 0)
	if not initial_row_added:
		return {
			"ok": false,
			"reason": "Failed to add initial BPM row",
		}

	for row in bpm_rows:
		var beat_text := str(row.get("beat", "")).strip_edges()
		var bpm_text := str(row.get("bpm", "")).strip_edges()
		if beat_text.is_empty() or bpm_text.is_empty():
			continue
		_add_music_bpm_row(title, bpm_text, int(beat_text.to_int()))

	return {
		"ok": true,
		"reason": "PDJE registration completed",
	}


func update_first_beat(title: String, first_beat: String) -> Dictionary:
	if not _ready:
		return {
			"ok": false,
			"reason": "PDJE service is not ready",
		}

	var ok: bool = bool(editor_root.EditMusicFirstBar(title, first_beat))
	return {
		"ok": ok,
		"reason": "EditMusicFirstBar succeeded" if ok else "EditMusicFirstBar failed",
	}


func is_music_searchable(title: String, composer: String, bpm: float = -1.0) -> bool:
	return not search_music(title, composer, bpm).is_empty()


func load_rgb_waveform(
	title: String,
	composer: String,
	bpm: float = -1.0,
	pcm_per_pixel: int = 96,
	width: int = 512,
	height: int = 160
) -> Dictionary:
	if not _ready:
		return {
			"ok": false,
			"reason": "PDJE service is not ready",
			"waveform": [],
		}

	if not is_music_searchable(title, composer, bpm):
		return {
			"ok": false,
			"reason": "Music asset is not searchable yet",
			"waveform": [],
		}

	var waveform: Array = mir_api.SoundToRGBWaveform(
		engine_root,
		cache_db,
		title,
		composer,
		bpm,
		pcm_per_pixel,
		width,
		height
	)
	return {
		"ok": not waveform.is_empty(),
		"reason": "Waveform loaded" if not waveform.is_empty() else "Waveform load returned empty data",
		"waveform": waveform,
	}


func _add_music_bpm_row(title: String, bpm_text: String, beat: int) -> bool:
	var arg := PDJE_EDITOR_ARG.new()
	arg.InitMusicArg(title, bpm_text, beat, 0, 0)
	return editor_root.AddLine(arg)


func _set_boot_status(ready_value: bool, message: String) -> void:
	_ready = ready_value
	_boot_message = message
	boot_status_changed.emit(_ready, _boot_message)
