class_name MusicAssetConfigWorkspace
extends Control

signal request_return_to_mixset

const AUTOSAVE_INTERVAL := 15.0
const SAVE_STATE_LATEST := "latest"
const SAVE_STATE_MODIFIED := "modified"

@onready var _source_path_edit: LineEdit = %SourcePathEdit
@onready var _title_edit: LineEdit = %TitleEdit
@onready var _composer_edit: LineEdit = %ComposerEdit
@onready var _start_bpm_edit: LineEdit = %StartBpmEdit
@onready var _first_beat_edit: LineEdit = %FirstBeatEdit
@onready var _bpm_rows_edit: TextEdit = %BpmRowsEdit
@onready var _validation_label: RichTextLabel = %ValidationLabel
@onready var _save_state_label: Label = %SaveStateLabel
@onready var _asset_header_label: Label = %AssetHeaderLabel
@onready var _waveform_preview: Node = %WaveformPreview
@onready var _autosave_timer: Timer = %AutosaveTimer
@onready var _browse_dialog: FileDialog = %BrowseDialog
@onready var _browse_button: Button = %BrowseButton
@onready var _register_button: Button = %RegisterButton
@onready var _refresh_button: Button = %RefreshWaveformButton

var _session
var _pdje_service
var _active_asset_id := ""
var _is_dirty := false


func _ready() -> void:
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	_browse_dialog.file_selected.connect(_on_browse_dialog_file_selected)
	_apply_empty_form()


func set_context(session, pdje_service) -> void:
	_session = session
	_pdje_service = pdje_service
	if _session != null and not _session.state_changed.is_connected(_on_session_state_changed):
		_session.state_changed.connect(_on_session_state_changed)
	if _pdje_service != null and not _pdje_service.is_ready():
		_pdje_service.boot()
	_refresh_from_session()


func set_active_asset(asset_id: String) -> void:
	_active_asset_id = asset_id
	_refresh_from_session()


func save_current_context() -> bool:
	if _session == null:
		return false
	if _active_asset_id.is_empty():
		_active_asset_id = _session.selected_asset_id()
		if _active_asset_id.is_empty():
			_active_asset_id = _session.create_asset_draft()

	var validation := _validate_form()
	if not bool(validation.get("draft_valid", false)):
		_set_validation_message(validation["message"])
		return false

	var asset := _build_asset_payload(validation)

	if bool(validation.get("return_ready", false)) and _pdje_service != null:
		if not asset.get("pdje_registered", false):
			var reg_result: Dictionary = _pdje_service.register_music_asset(
				asset["music_title"],
				asset["composer"],
				asset["source_audio_path"],
				asset["first_beat"],
				asset["start_bpm"],
				asset["bpm_transition_metadata"]
			)
			if not bool(reg_result.get("ok", false)):
				_set_validation_message("PDJE registration failed: %s" % reg_result.get("reason", "unknown"))
				return false
			asset["pdje_registered"] = true
		else:
			var first_beat_result: Dictionary = _pdje_service.update_first_beat(
				asset["music_title"],
				asset["first_beat"]
			)
			if not bool(first_beat_result.get("ok", false)):
				_set_validation_message("First Beat update failed: %s" % first_beat_result.get("reason", "unknown"))
				return false

		asset["pdje_searchable_by_search_music"] = _pdje_service.is_music_searchable(
			asset["music_title"],
			asset["composer"]
		)
		asset["waveform_preview_available"] = asset["pdje_searchable_by_search_music"]
		asset["ready_for_mixset"] = asset["pdje_registered"]

	_session.upsert_asset_draft(asset, SAVE_STATE_LATEST)
	_is_dirty = false
	_refresh_save_state()
	_try_refresh_waveform(asset)
	_refresh_from_session()
	_session.persist()
	return true


func handle_return_action() -> bool:
	var saved := save_current_context()
	if not saved:
		return false

	var asset := _current_asset_from_session()
	if asset.is_empty() or not asset.get("ready_for_mixset", false):
		_set_validation_message("Return blocked: asset is not ready for mixset.")
		return false

	_session.open_mixset_editing()
	return true


func _on_autosave_timeout() -> void:
	if _session == null or not _is_dirty:
		return
	if _active_asset_id.is_empty():
		_active_asset_id = _session.selected_asset_id()
		if _active_asset_id.is_empty():
			_active_asset_id = _session.create_asset_draft()
	var validation := _validate_form()
	if not bool(validation.get("draft_valid", false)):
		return
	_session.upsert_asset_draft(_build_asset_payload(validation), SAVE_STATE_MODIFIED)
	_session.persist()
	_is_dirty = false


func _on_browse_dialog_file_selected(path: String) -> void:
	_source_path_edit.text = path
	_mark_dirty()


func _refresh_from_session() -> void:
	if _session == null:
		_apply_empty_form()
		return

	var asset := _current_asset_from_session()
	if asset.is_empty():
		_apply_empty_form()
		_refresh_save_state()
		return

	_active_asset_id = str(asset.get("asset_id", ""))
	_asset_header_label.text = "Asset: %s" % (_active_asset_id if not _active_asset_id.is_empty() else "new draft")
	_source_path_edit.text = str(asset.get("source_audio_path", ""))
	_title_edit.text = str(asset.get("music_title", ""))
	_composer_edit.text = str(asset.get("composer", ""))
	_start_bpm_edit.text = str(asset.get("start_bpm", ""))
	_first_beat_edit.text = str(asset.get("first_beat", ""))
	_bpm_rows_edit.text = _serialize_bpm_rows(asset.get("bpm_transition_metadata", []))
	var pdje_registered := bool(asset.get("pdje_registered", false))
	_source_path_edit.editable = not pdje_registered
	_title_edit.editable = not pdje_registered
	_composer_edit.editable = not pdje_registered
	_refresh_save_state()
	_try_refresh_waveform(asset)
	_update_validation_preview()
	_autosave_timer.start()


func _on_session_state_changed(_snapshot: Dictionary) -> void:
	_refresh_from_session()


func _sync_form_to_session() -> void:
	if _session == null:
		return
	if _active_asset_id.is_empty():
		_active_asset_id = _session.selected_asset_id()
		if _active_asset_id.is_empty():
			_active_asset_id = _session.create_asset_draft()

	var asset: Dictionary = _build_asset_payload(_validate_form())
	_session.upsert_asset_draft(asset)


func _build_asset_payload(validation: Dictionary) -> Dictionary:
	var existing_asset := _current_asset_from_session()
	return {
		"asset_id": _active_asset_id,
		"source_audio_path": _source_path_edit.text.strip_edges(),
		"music_title": _title_edit.text.strip_edges(),
		"composer": _composer_edit.text.strip_edges(),
		"start_bpm": _start_bpm_edit.text.strip_edges(),
		"first_beat": _first_beat_edit.text.strip_edges(),
		"bpm_transition_metadata": _parse_bpm_rows(_bpm_rows_edit.text),
		"user_tags": [],
		"pdje_registered": bool(existing_asset.get("pdje_registered", false)),
		"pdje_searchable_by_search_music": bool(existing_asset.get("pdje_searchable_by_search_music", false)),
		"ready_for_mixset": bool(existing_asset.get("pdje_registered", false)) and bool(validation.get("return_ready", false)),
		"waveform_preview_available": bool(existing_asset.get("waveform_preview_available", false)),
	}


func _validate_form() -> Dictionary:
	var errors: Array[String] = []
	var source_path := _source_path_edit.text.strip_edges()
	var title := _title_edit.text.strip_edges()
	var composer := _composer_edit.text.strip_edges()
	var start_bpm := _start_bpm_edit.text.strip_edges()
	var first_beat := _first_beat_edit.text.strip_edges()
	var bpm_rows := _parse_bpm_rows(_bpm_rows_edit.text)
	var source_ok := not source_path.is_empty()

	if source_path.is_empty():
		errors.append("Source path is required.")
	if title.is_empty():
		errors.append("Title is required.")
	if composer.is_empty():
		errors.append("Composer is required.")
	if not _is_positive_number(start_bpm):
		errors.append("Start BPM must be a positive number.")
	if bpm_rows.is_empty():
		errors.append("BPM transition metadata needs at least one row.")
	if first_beat.is_empty():
		errors.append("First Beat is required for PDJE registration.")
	if _pdje_service != null and not source_path.is_empty():
		var source_validation: Dictionary = _pdje_service.validate_source_audio_path(source_path)
		if not bool(source_validation.get("ok", false)):
			errors.append(str(source_validation.get("reason", "Source validation failed.")))
			source_ok = false

	var validation := {
		"ok": errors.is_empty(),
		"draft_valid": source_ok and not title.is_empty() and not composer.is_empty() and _is_positive_number(start_bpm),
		"return_ready": errors.is_empty(),
		"searchable": false,
		"waveform_preview_available": false,
		"message": "All required fields are present." if errors.is_empty() else "\n".join(errors),
	}

	if validation["ok"] and _pdje_service != null:
		validation["searchable"] = _pdje_service.is_music_searchable(title, composer)
		validation["waveform_preview_available"] = validation["searchable"]

	return validation


func _try_refresh_waveform(asset: Dictionary) -> void:
	if _pdje_service == null:
		return
	var title := str(asset.get("music_title", ""))
	var composer := str(asset.get("composer", ""))
	var result: Dictionary = _pdje_service.load_rgb_waveform(title, composer, -1.0)
	if not bool(result.get("ok", false)):
		return
	var waveform: Array = result.get("waveform", [])
	if waveform.is_empty():
		return
	if _waveform_preview != null and _waveform_preview.has_signal("PutImg"):
		_waveform_preview.emit_signal("PutImg", waveform)


func _current_asset_from_session() -> Dictionary:
	if _session == null:
		return {}
	if _active_asset_id.is_empty():
		_active_asset_id = _session.selected_asset_id()
	if _active_asset_id.is_empty():
		return {}
	return _session.get_asset_draft(_active_asset_id)


func _refresh_save_state() -> void:
	if _session == null:
		_save_state_label.text = "latest"
		return
	var snapshot: Dictionary = _session.get_state_snapshot()
	_save_state_label.text = "modified" if _is_dirty else str(snapshot.get("save_state", SAVE_STATE_LATEST))


func _set_validation_message(message: String) -> void:
	_validation_label.text = "[color=orange]%s[/color]" % message


func _update_validation_preview() -> void:
	var validation: Dictionary = _validate_form()
	_validation_label.text = validation["message"]


func _apply_empty_form() -> void:
	_active_asset_id = ""
	_is_dirty = false
	_asset_header_label.text = "Asset: none"
	_source_path_edit.text = ""
	_title_edit.text = ""
	_composer_edit.text = ""
	_start_bpm_edit.text = ""
	_first_beat_edit.text = ""
	_bpm_rows_edit.text = ""
	_validation_label.text = "Fill the required fields to unlock local draft save and PDJE registration."
	_save_state_label.text = SAVE_STATE_LATEST
	_source_path_edit.editable = true
	_title_edit.editable = true
	_composer_edit.editable = true
	_autosave_timer.stop()


func _serialize_bpm_rows(rows: Array) -> String:
	var lines: Array[String] = []
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var beat := str(row.get("beat", "")).strip_edges()
		var bpm := str(row.get("bpm", "")).strip_edges()
		if beat.is_empty() or bpm.is_empty():
			continue
		lines.append("%s=%s" % [beat, bpm])
	return "\n".join(lines)


func _parse_bpm_rows(text: String) -> Array:
	var rows: Array = []
	for line in text.split("\n", false):
		var cleaned := line.strip_edges()
		if cleaned.is_empty():
			continue
		var separator := "="
		if cleaned.find(":") != -1:
			separator = ":"
		elif cleaned.find(",") != -1:
			separator = ","
		var parts := cleaned.split(separator, false, 2)
		if parts.size() < 2:
			continue
		rows.append({
			"beat": parts[0].strip_edges(),
			"bpm": parts[1].strip_edges(),
		})
	return rows


func _is_positive_number(text: String) -> bool:
	var value := text.strip_edges().to_float()
	return value > 0.0


func _mark_dirty() -> void:
	_is_dirty = true
	_refresh_save_state()


func _on_field_changed(_text: String = "") -> void:
	_mark_dirty()
	_update_validation_preview()


func _on_browse_button_pressed() -> void:
	_browse_dialog.popup_centered_ratio(0.7)


func _on_register_button_pressed() -> void:
	save_current_context()


func _on_refresh_waveform_button_pressed() -> void:
	var asset := _current_asset_from_session()
	if asset.is_empty():
		_set_validation_message("Open or create an asset before fetching waveform.")
		return
	_try_refresh_waveform(asset)
