class_name AuthoringView
extends Control

@onready var _mixset_workspace = %MixsetEditingWorkspace
@onready var _asset_config_workspace = %MusicAssetConfigWorkspace

var _session
var _pdje_service


func _ready() -> void:
	_update_visible_workspace()
	_bind_workspace_buttons()


func set_context(session, pdje_service) -> void:
	_session = session
	_pdje_service = pdje_service

	if _session != null and _session.get_state_snapshot().is_empty():
		_session.bootstrap()
	if _pdje_service != null and not _pdje_service.is_ready():
		_pdje_service.boot()

	if _session != null and not _session.state_changed.is_connected(_on_session_state_changed):
		_session.state_changed.connect(_on_session_state_changed)

	if _mixset_workspace != null:
		_mixset_workspace.set_context(_session, _pdje_service)
	if _asset_config_workspace != null:
		_asset_config_workspace.set_context(_session, _pdje_service)

	if _session != null:
		_on_session_state_changed(_session.get_state_snapshot())


func save_current_context() -> bool:
	if _is_asset_config_active():
		return _asset_config_workspace.save_current_context()
	if _mixset_workspace != null:
		return _mixset_workspace.save_current_context()
	if _session != null:
		return _session.persist()
	return false


func handle_return_action() -> bool:
	if _is_asset_config_active():
		if not _asset_config_workspace.handle_return_action():
			return false
		_session.open_mixset_editing()
		_update_visible_workspace()
		return true
	return false


func open_asset_config(asset_id: String = "") -> void:
	if _session == null:
		return
	var resolved_asset_id: String = str(_session.open_asset_config(asset_id))
	_asset_config_workspace.set_active_asset(resolved_asset_id)
	_update_visible_workspace()


func open_mixset_editing() -> void:
	if _session == null:
		return
	_session.open_mixset_editing()
	_update_visible_workspace()


func _bind_workspace_buttons() -> void:
	if _mixset_workspace != null:
		_mixset_workspace.request_open_asset_config.connect(open_asset_config)
		_mixset_workspace.request_open_mixset.connect(open_mixset_editing)


func _update_visible_workspace() -> void:
	if _session == null:
		return

	var is_asset_config := _is_asset_config_active()
	if _mixset_workspace != null:
		_mixset_workspace.visible = not is_asset_config
	if _asset_config_workspace != null:
		_asset_config_workspace.visible = is_asset_config


func _on_session_state_changed(snapshot: Dictionary) -> void:
	_update_visible_workspace()


func _is_asset_config_active() -> bool:
	if _session == null:
		return false
	return _session.is_asset_config_scene()
