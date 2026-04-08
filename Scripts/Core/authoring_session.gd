class_name AuthoringSession
extends RefCounted

signal state_changed(snapshot: Dictionary)

const AUTHORING_STORE_SCRIPT := preload("res://Scripts/Core/authoring_store.gd")

const SCENE_WORKSPACE_SELECTION := "workspace_selection"
const SCENE_AUTHORING := "authoring"

const SUBSCENE_MIXSET_EDITING := "mixset_editing"
const SUBSCENE_MUSIC_ASSET_CONFIG := "music_asset_config"

const SAVE_STATE_LATEST := "latest"
const SAVE_STATE_MODIFIED := "modified"
const SAVE_STATE_SAVING := "saving"
const SAVE_STATE_RECENTLY_SAVED := "recently_saved"

var _store: RefCounted = AUTHORING_STORE_SCRIPT.new()
var _state: Dictionary = {}


func bootstrap() -> void:
	randomize()
	_state = _normalize_state(_store.load_state())
	_emit_state_changed()


func get_state_snapshot() -> Dictionary:
	return _state.duplicate(true)


func get_tracks() -> Array[Dictionary]:
	var tracks: Array[Dictionary] = []
	for track in _state.get("authored_tracks", []):
		if typeof(track) == TYPE_DICTIONARY:
			tracks.append(track.duplicate(true))
	return tracks


func get_recent_track_titles() -> Array:
	return _state.get("recent_track_titles", []).duplicate()


func get_track_assets(track_title: String = "") -> Array[Dictionary]:
	var resolved_title := track_title
	if resolved_title.is_empty():
		resolved_title = _state.get("current_track_title", "")

	var track := _find_track(resolved_title)
	if track.is_empty():
		return []

	var assets: Array[Dictionary] = []
	for asset_id in track.get("asset_ids", []):
		var asset := get_asset_draft(asset_id)
		if not asset.is_empty():
			assets.append(asset)
	return assets


func get_ready_assets(track_title: String = "") -> Array[Dictionary]:
	var ready_assets: Array[Dictionary] = []
	for asset in get_track_assets(track_title):
		if asset.get("ready_for_mixset", false):
			ready_assets.append(asset)
	return ready_assets


func get_asset_draft(asset_id: String) -> Dictionary:
	for asset in _state.get("assets", []):
		if asset.get("asset_id", "") == asset_id:
			return asset.duplicate(true)
	return {}


func ensure_track(track_title: String) -> void:
	var normalized_title := track_title.strip_edges()
	if normalized_title.is_empty():
		return
	if not _find_track(normalized_title).is_empty():
		return

	var tracks: Array = _state.get("authored_tracks", [])
	tracks.append({
		"track_title": normalized_title,
		"asset_ids": [],
		"last_opened_asset_id": "",
	})
	_state["authored_tracks"] = tracks
	if str(_state.get("current_track_title", "")).is_empty():
		_state["current_track_title"] = normalized_title
	_remember_recent_track(normalized_title)
	_mark_modified("Created track %s" % normalized_title)


func open_track(track_title: String) -> void:
	ensure_track(track_title)
	_state["current_track_title"] = track_title
	_state["current_scene"] = SCENE_AUTHORING
	_state["current_subscene"] = SUBSCENE_MIXSET_EDITING
	_remember_recent_track(track_title)
	_mark_latest("Opened track %s" % track_title)


func return_to_workspace_selection() -> void:
	_state["current_scene"] = SCENE_WORKSPACE_SELECTION
	_state["current_subscene"] = SUBSCENE_MIXSET_EDITING
	_state["selected_asset_id"] = ""
	_mark_latest("Returned to workspace selection")


func open_mixset_editing() -> void:
	_state["current_scene"] = SCENE_AUTHORING
	_state["current_subscene"] = SUBSCENE_MIXSET_EDITING
	_mark_latest("Opened mixset editing")


func open_asset_config(asset_id: String = "") -> String:
	var resolved_asset_id := asset_id
	if resolved_asset_id.is_empty():
		resolved_asset_id = create_asset_draft()

	_state["current_scene"] = SCENE_AUTHORING
	_state["current_subscene"] = SUBSCENE_MUSIC_ASSET_CONFIG
	_state["selected_asset_id"] = resolved_asset_id
	_set_track_last_opened_asset(_state.get("current_track_title", ""), resolved_asset_id)
	_mark_latest("Opened asset config")
	return resolved_asset_id


func create_asset_draft() -> String:
	var asset_id := _generate_asset_id()
	var assets: Array = _state.get("assets", [])
	assets.append(_default_asset_draft(asset_id))
	_state["assets"] = assets
	_attach_asset_to_current_track(asset_id)
	_state["selected_asset_id"] = asset_id
	_mark_modified("Created asset draft")
	return asset_id


func upsert_asset_draft(asset_data: Dictionary, save_state: String = SAVE_STATE_MODIFIED) -> Dictionary:
	var asset_id := str(asset_data.get("asset_id", "")).strip_edges()
	if asset_id.is_empty():
		asset_id = create_asset_draft()

	var merged := _default_asset_draft(asset_id)
	for key in asset_data.keys():
		merged[key] = asset_data[key]

	var assets: Array = _state.get("assets", [])
	var replaced := false
	for index in range(assets.size()):
		var candidate: Dictionary = assets[index]
		if candidate.get("asset_id", "") == asset_id:
			assets[index] = merged
			replaced = true
			break
	if not replaced:
		assets.append(merged)
	_state["assets"] = assets

	_attach_asset_to_current_track(asset_id)
	_state["selected_asset_id"] = asset_id

	if save_state == SAVE_STATE_LATEST:
		_mark_latest("Updated asset draft")
	else:
		_mark_modified("Updated asset draft")
	return merged.duplicate(true)


func persist() -> bool:
	_state["save_state"] = SAVE_STATE_SAVING
	_emit_state_changed()

	var ok: bool = _store.save_state(_state)
	if ok:
		_state["save_state"] = SAVE_STATE_RECENTLY_SAVED
		_state["status_message"] = "State saved to local JSON"
	else:
		_state["save_state"] = SAVE_STATE_MODIFIED
		_state["status_message"] = "Failed to save local JSON state"
	_emit_state_changed()
	return ok


func acknowledge_recent_save() -> void:
	if _state.get("save_state", "") != SAVE_STATE_RECENTLY_SAVED:
		return
	_state["save_state"] = SAVE_STATE_LATEST
	_emit_state_changed()


func set_status_message(message: String) -> void:
	_state["status_message"] = message
	_emit_state_changed()


func mark_current_context_modified(message: String = "Modified current context") -> void:
	_mark_modified(message)


func set_current_track_title(track_title: String) -> void:
	ensure_track(track_title)
	_state["current_track_title"] = track_title
	_remember_recent_track(track_title)
	_mark_modified("Changed current track")


func selected_asset_id() -> String:
	return _state.get("selected_asset_id", "")


func is_authoring_scene() -> bool:
	return _state.get("current_scene", "") == SCENE_AUTHORING


func is_asset_config_scene() -> bool:
	return _state.get("current_subscene", "") == SUBSCENE_MUSIC_ASSET_CONFIG


func _normalize_state(raw_state: Dictionary) -> Dictionary:
	var state := _default_state()
	for key in raw_state.keys():
		state[key] = raw_state[key]

	if typeof(state.get("authored_tracks", null)) != TYPE_ARRAY:
		state["authored_tracks"] = []
	if typeof(state.get("assets", null)) != TYPE_ARRAY:
		state["assets"] = []
	if typeof(state.get("recent_track_titles", null)) != TYPE_ARRAY:
		state["recent_track_titles"] = []

	if state["authored_tracks"].is_empty():
		state["authored_tracks"] = [{
			"track_title": "Demo Mixset",
			"asset_ids": [],
			"last_opened_asset_id": "",
		}]

	for track_index in range(state["authored_tracks"].size()):
		var track: Dictionary = state["authored_tracks"][track_index]
		if track.get("track_title", "").is_empty():
			track["track_title"] = "Track %d" % (track_index + 1)
		if typeof(track.get("asset_ids", null)) != TYPE_ARRAY:
			track["asset_ids"] = []
		if not track.has("last_opened_asset_id"):
			track["last_opened_asset_id"] = ""
		state["authored_tracks"][track_index] = track

	for asset_index in range(state["assets"].size()):
		var raw_asset: Dictionary = state["assets"][asset_index]
		var asset_id := str(raw_asset.get("asset_id", "")).strip_edges()
		if asset_id.is_empty():
			asset_id = _generate_asset_id()
		var merged_asset := _default_asset_draft(asset_id)
		for key in raw_asset.keys():
			merged_asset[key] = raw_asset[key]
		state["assets"][asset_index] = merged_asset

	if str(state.get("current_track_title", "")).is_empty():
		state["current_track_title"] = state["authored_tracks"][0]["track_title"]

	if str(state.get("current_scene", "")).is_empty():
		state["current_scene"] = SCENE_WORKSPACE_SELECTION
	if str(state.get("current_subscene", "")).is_empty():
		state["current_subscene"] = SUBSCENE_MIXSET_EDITING
	if not state.has("save_state"):
		state["save_state"] = SAVE_STATE_LATEST
	if not state.has("status_message"):
		state["status_message"] = "Ready"

	if not get_asset_draft_from_state(state, state.get("selected_asset_id", "")).is_empty():
		return state
	state["selected_asset_id"] = ""
	return state


func get_asset_draft_from_state(state: Dictionary, asset_id: String) -> Dictionary:
	for asset in state.get("assets", []):
		if asset.get("asset_id", "") == asset_id:
			return asset
	return {}


func _default_state() -> Dictionary:
	return {
		"root_summary": "res://TempRoot",
		"current_scene": SCENE_WORKSPACE_SELECTION,
		"current_subscene": SUBSCENE_MIXSET_EDITING,
		"current_track_title": "",
		"selected_asset_id": "",
		"save_state": SAVE_STATE_LATEST,
		"status_message": "Ready",
		"authored_tracks": [],
		"assets": [],
		"recent_track_titles": [],
	}


func _default_asset_draft(asset_id: String) -> Dictionary:
	return {
		"asset_id": asset_id,
		"source_audio_path": "",
		"music_title": "",
		"composer": "",
		"start_bpm": "",
		"first_beat": "",
		"bpm_transition_metadata": [],
		"user_tags": [],
		"pdje_registered": false,
		"pdje_searchable_by_search_music": false,
		"ready_for_mixset": false,
		"waveform_preview_available": false,
	}


func _find_track(track_title: String) -> Dictionary:
	for track in _state.get("authored_tracks", []):
		if track.get("track_title", "") == track_title:
			return track.duplicate(true)
	return {}


func _attach_asset_to_current_track(asset_id: String) -> void:
	var track_title: String = str(_state.get("current_track_title", ""))
	if track_title.is_empty() and not _state.get("authored_tracks", []).is_empty():
		track_title = _state["authored_tracks"][0]["track_title"]
		_state["current_track_title"] = track_title
	ensure_track(track_title)

	var tracks: Array = _state.get("authored_tracks", [])
	for index in range(tracks.size()):
		var track: Dictionary = tracks[index]
		if track.get("track_title", "") != track_title:
			continue
		var asset_ids: Array = track.get("asset_ids", [])
		if not asset_ids.has(asset_id):
			asset_ids.append(asset_id)
		track["asset_ids"] = asset_ids
		track["last_opened_asset_id"] = asset_id
		tracks[index] = track
		break
	_state["authored_tracks"] = tracks


func _set_track_last_opened_asset(track_title: String, asset_id: String) -> void:
	var tracks: Array = _state.get("authored_tracks", [])
	for index in range(tracks.size()):
		var track: Dictionary = tracks[index]
		if track.get("track_title", "") != track_title:
			continue
		track["last_opened_asset_id"] = asset_id
		tracks[index] = track
		break
	_state["authored_tracks"] = tracks


func _remember_recent_track(track_title: String) -> void:
	var recent: Array = _state.get("recent_track_titles", [])
	recent.erase(track_title)
	recent.push_front(track_title)
	while recent.size() > 5:
		recent.pop_back()
	_state["recent_track_titles"] = recent


func _mark_modified(message: String) -> void:
	_state["save_state"] = SAVE_STATE_MODIFIED
	_state["status_message"] = message
	_emit_state_changed()


func _mark_latest(message: String) -> void:
	_state["save_state"] = SAVE_STATE_LATEST
	_state["status_message"] = message
	_emit_state_changed()


func _generate_asset_id() -> String:
	return "asset_%d_%06d" % [int(Time.get_unix_time_from_system()), randi() % 1000000]


func _emit_state_changed() -> void:
	state_changed.emit(get_state_snapshot())
