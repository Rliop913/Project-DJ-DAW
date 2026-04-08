class_name MixsetEditingWorkspace
extends Control

signal request_open_asset_config(asset_id: String)
signal request_open_mixset

@onready var _track_title_label: Label = %TrackTitleLabel
@onready var _ready_asset_list: ItemList = %ReadyAssetList
@onready var _pending_asset_list: ItemList = %PendingAssetList
@onready var _placeholder_label: Label = %PlaceholderLabel
@onready var _status_label: Label = %MixsetStatusLabel
@onready var _add_asset_button: Button = %AddAssetButton
@onready var _open_asset_button: Button = %OpenAssetButton

var _session
var _pdje_service


func set_context(session, pdje_service) -> void:
	_session = session
	_pdje_service = pdje_service
	if _session != null and not _session.state_changed.is_connected(_on_session_state_changed):
		_session.state_changed.connect(_on_session_state_changed)
	_refresh()


func save_current_context() -> bool:
	if _session == null:
		return false
	return _session.persist()


func handle_return_action() -> bool:
	return false


func _ready() -> void:
	_refresh()
	_ready_asset_list.item_activated.connect(_on_ready_asset_activated)
	_pending_asset_list.item_activated.connect(_on_pending_asset_activated)


func _refresh() -> void:
	if _session == null:
		return

	var snapshot: Dictionary = _session.get_state_snapshot()
	_track_title_label.text = "Track: %s" % snapshot.get("current_track_title", "Untitled")
	_placeholder_label.text = "Automation, preview playback, and PDJE compile are intentionally not implemented in this module."
	_status_label.text = str(snapshot.get("status_message", "Ready"))

	_ready_asset_list.clear()
	_pending_asset_list.clear()

	var ready_assets: Array = _session.get_ready_assets()
	var pending_assets: Array = []
	for asset in _session.get_track_assets():
		if not asset.get("ready_for_mixset", false):
			pending_assets.append(asset)

	for asset in ready_assets:
		_ready_asset_list.add_item(_asset_label(asset))

	for asset in pending_assets:
		_pending_asset_list.add_item(_asset_label(asset))


func _on_session_state_changed(_snapshot: Dictionary) -> void:
	_refresh()


func _asset_label(asset: Dictionary) -> String:
	var title := str(asset.get("music_title", "")).strip_edges()
	if title.is_empty():
		title = "Untitled asset"
	var suffix := "ready" if asset.get("ready_for_mixset", false) else "pending"
	return "%s [%s]" % [title, suffix]


func _on_ready_asset_activated(index: int) -> void:
	_open_selected_asset(index, true)


func _on_pending_asset_activated(index: int) -> void:
	_open_selected_asset(index, false)


func _open_selected_asset(index: int, is_ready: bool) -> void:
	if _session == null:
		return

	var list := _ready_asset_list if is_ready else _pending_asset_list
	if index < 0 or index >= list.item_count:
		return

	var target_label: String = list.get_item_text(index)
	var target_id: String = _find_asset_id_by_label(target_label, is_ready)
	if target_id.is_empty():
		return

	emit_signal("request_open_asset_config", target_id)


func _find_asset_id_by_label(label: String, ready_list: bool) -> String:
	if _session == null:
		return ""

	var assets: Array = _session.get_track_assets()
	for asset in assets:
		var matches_ready: bool = bool(asset.get("ready_for_mixset", false))
		if matches_ready != ready_list:
			continue
		if _asset_label(asset) == label:
			return str(asset.get("asset_id", ""))
	return ""


func _on_add_asset_button_pressed() -> void:
	if _session == null:
		return
	var asset_id: String = str(_session.create_asset_draft())
	emit_signal("request_open_asset_config", asset_id)


func _on_open_asset_button_pressed() -> void:
	var selected_id := _selected_asset_id()
	if selected_id.is_empty():
		return
	emit_signal("request_open_asset_config", selected_id)


func _selected_asset_id() -> String:
	var selected_ready: PackedInt32Array = _ready_asset_list.get_selected_items()
	if not selected_ready.is_empty():
		var label: String = _ready_asset_list.get_item_text(selected_ready[0])
		return _find_asset_id_by_label(label, true)

	var selected_pending: PackedInt32Array = _pending_asset_list.get_selected_items()
	if not selected_pending.is_empty():
		var label: String = _pending_asset_list.get_item_text(selected_pending[0])
		return _find_asset_id_by_label(label, false)
	return ""
