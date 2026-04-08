class_name AppRoot
extends Control

const WORKSPACE_SELECTION_SCENE := "res://Scenes/Workspaces/workspace_selection_view.tscn"
const AUTHORING_SCENE := "res://Scenes/Workspaces/authoring_view.tscn"
const AUTHORING_SESSION_SCRIPT := preload("res://Scripts/Core/authoring_session.gd")
const PDJE_SERVICE_SCRIPT := preload("res://Scripts/Core/pdje_service.gd")
const SCENE_WORKSPACE_SELECTION := "workspace_selection"
const SCENE_AUTHORING := "authoring"

var session := AUTHORING_SESSION_SCRIPT.new()
var pdje_service := PDJE_SERVICE_SCRIPT.new()

var current_view: Node
var current_mode := SCENE_WORKSPACE_SELECTION

@onready var top_context_label: Label = %TopContextLabel
@onready var top_boot_label: Label = %TopBootLabel
@onready var local_action_container: HBoxContainer = %LocalActionContainer
@onready var content_host: VBoxContainer = %ContentHost
@onready var bottom_status_label: Label = %BottomStatusLabel
@onready var bottom_save_label: Label = %BottomSaveLabel
@onready var bottom_hover_label: Label = %BottomHoverLabel


func _ready() -> void:
	session.state_changed.connect(_on_session_state_changed)
	pdje_service.boot_status_changed.connect(_on_boot_status_changed)
	session.bootstrap()
	pdje_service.boot()
	_apply_snapshot(session.get_state_snapshot())


func _on_session_state_changed(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)


func _on_boot_status_changed(_ready: bool, message: String) -> void:
	if top_boot_label:
		top_boot_label.text = message


func _apply_snapshot(snapshot: Dictionary) -> void:
	current_mode = str(snapshot.get("current_scene", SCENE_WORKSPACE_SELECTION))
	_update_top_bar(snapshot)
	_update_local_bezel(snapshot)
	_update_bottom_bar(snapshot)
	_swap_content(snapshot)


func _update_top_bar(snapshot: Dictionary) -> void:
	if top_context_label:
		var root_summary := str(snapshot.get("root_summary", "res://TempRoot"))
		var track_title := str(snapshot.get("current_track_title", ""))
		var scene_name := str(snapshot.get("current_scene", "workspace_selection"))
		var subscene_name := str(snapshot.get("current_subscene", "mixset_editing"))
		top_context_label.text = "%s / %s / %s / %s" % [root_summary, track_title if not track_title.is_empty() else "No Track", scene_name, subscene_name]

	if top_boot_label:
		top_boot_label.text = pdje_service.get_boot_message() if pdje_service else "PDJE service unavailable"


func _update_local_bezel(snapshot: Dictionary) -> void:
	_clear_children(local_action_container)
	if current_mode == SCENE_WORKSPACE_SELECTION:
		_add_local_label("Workspace Selection")
		_add_local_button("Open Authoring", func() -> void:
			var tracks := session.get_tracks()
			if tracks.is_empty():
				session.ensure_track("Demo Mixset")
				tracks = session.get_tracks()
			if not tracks.is_empty():
				session.open_track(str(tracks[0].get("track_title", "Demo Mixset")))
		)
		_add_local_button("New Track", func() -> void:
			session.ensure_track("New Track")
			session.open_track("New Track")
		)
		return

	var return_button := _add_local_button("ReturnAction", func() -> void:
		if current_view != null and current_view.has_method("handle_return_action"):
			current_view.handle_return_action()
	)
	return_button.disabled = str(snapshot.get("current_subscene", "")) != "music_asset_config"

	_add_local_button("SaveIcon", func() -> void:
		if current_view != null and current_view.has_method("save_current_context"):
			current_view.save_current_context()
			return
		session.persist()
	)
	_add_local_label(str(snapshot.get("current_track_title", "Track")))
	_add_local_label(str(snapshot.get("current_subscene", "mixset_editing")))
	_add_local_label(str(snapshot.get("save_state", "latest")))


func _update_bottom_bar(snapshot: Dictionary) -> void:
	if bottom_status_label:
		bottom_status_label.text = str(snapshot.get("status_message", "Ready"))
	if bottom_save_label:
		bottom_save_label.text = "Save: %s" % str(snapshot.get("save_state", "latest"))
	if bottom_hover_label:
		bottom_hover_label.text = "Hover: ready"


func _swap_content(snapshot: Dictionary) -> void:
	_clear_children(content_host)
	if current_mode == SCENE_WORKSPACE_SELECTION:
		var selection_view := _load_workspace_selection_view()
		content_host.add_child(selection_view)
		if selection_view.has_method("set_context"):
			selection_view.set_context(session, pdje_service)
		if selection_view.has_signal("track_open_requested"):
			selection_view.track_open_requested.connect(_on_track_open_requested)
		if selection_view.has_signal("new_track_requested"):
			selection_view.new_track_requested.connect(_on_new_track_requested)
		if selection_view.has_signal("refresh_requested"):
			selection_view.refresh_requested.connect(_on_selection_refresh_requested)
		current_view = selection_view
		return

	var authoring_view := _load_authoring_view()
	content_host.add_child(authoring_view)
	if authoring_view.has_method("set_context"):
		authoring_view.set_context(session, pdje_service)
	current_view = authoring_view


func _load_workspace_selection_view() -> Node:
	var packed := load(WORKSPACE_SELECTION_SCENE)
	if packed is PackedScene:
		return packed.instantiate()
	return _make_placeholder("Workspace selection scene missing")


func _load_authoring_view() -> Node:
	var packed := load(AUTHORING_SCENE)
	if packed is PackedScene:
		return packed.instantiate()
	return _make_placeholder("Authoring scene missing")


func _make_placeholder(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	return panel


func _on_track_open_requested(track_title: String) -> void:
	session.open_track(track_title)


func _on_new_track_requested(track_title: String) -> void:
	session.ensure_track(track_title)
	session.open_track(track_title)


func _on_selection_refresh_requested() -> void:
	session.mark_current_context_modified("Refreshed workspace selection")


func _add_local_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	local_action_container.add_child(button)
	return button


func _add_local_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	local_action_container.add_child(label)


func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
