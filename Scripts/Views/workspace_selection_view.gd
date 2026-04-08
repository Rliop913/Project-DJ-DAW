class_name WorkspaceSelectionView
extends Control

signal track_open_requested(track_title: String)
signal new_track_requested(track_title: String)
signal refresh_requested

var _session: Object
var _pdje_service: Object

@onready var root_summary_label: Label = %RootSummaryLabel
@onready var boot_status_label: Label = %BootStatusLabel
@onready var track_list_container: VBoxContainer = %TrackListContainer
@onready var recent_list_container: VBoxContainer = %RecentListContainer
@onready var new_track_line_edit: LineEdit = %NewTrackLineEdit
@onready var open_button: Button = %OpenButton
@onready var create_button: Button = %CreateButton
@onready var refresh_button: Button = %RefreshButton


func set_context(session: Object, pdje_service: Object) -> void:
	_session = session
	_pdje_service = pdje_service
	_refresh_view()


func _ready() -> void:
	if open_button:
		open_button.pressed.connect(_on_open_pressed)
	if create_button:
		create_button.pressed.connect(_on_create_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if new_track_line_edit:
		new_track_line_edit.text_submitted.connect(_on_new_track_text_submitted)
	_refresh_view()


func _refresh_view() -> void:
	if root_summary_label:
		root_summary_label.text = _session.get_state_snapshot().get("root_summary", "res://TempRoot") if _session else "res://TempRoot"

	if boot_status_label:
		if _pdje_service:
			boot_status_label.text = _pdje_service.get_boot_message()
		else:
			boot_status_label.text = "PDJE service unavailable"

	_clear_children(track_list_container)
	_clear_children(recent_list_container)

	if not _session:
		_add_placeholder(track_list_container, "Session unavailable")
		_add_placeholder(recent_list_container, "No session")
		return

	var tracks: Array = _session.get_tracks()
	if tracks.is_empty():
		_add_placeholder(track_list_container, "No authored tracks yet")
	else:
		for track in tracks:
			_add_track_row(track)

	var recent_titles: Array = _session.get_state_snapshot().get("recent_track_titles", [])
	if recent_titles.is_empty():
		_add_placeholder(recent_list_container, "No recent tracks")
	else:
		for track_title in recent_titles:
			_add_recent_row(str(track_title))


func _add_track_row(track: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = str(track.get("track_title", "Track"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var button := Button.new()
	button.text = "Open"
	button.pressed.connect(func() -> void:
		track_open_requested.emit(str(track.get("track_title", "")))
	)
	row.add_child(button)
	track_list_container.add_child(row)


func _add_recent_row(track_title: String) -> void:
	var label := Label.new()
	label.text = track_title
	recent_list_container.add_child(label)


func _add_placeholder(container: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	container.add_child(label)


func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func _on_open_pressed() -> void:
	var track_title := new_track_line_edit.text.strip_edges() if new_track_line_edit else ""
	if track_title.is_empty() and _session:
		var tracks: Array = _session.get_tracks()
		if not tracks.is_empty():
			track_title = str(tracks[0].get("track_title", ""))
	if not track_title.is_empty():
		track_open_requested.emit(track_title)


func _on_create_pressed() -> void:
	var track_title := new_track_line_edit.text.strip_edges() if new_track_line_edit else ""
	if track_title.is_empty():
		track_title = "New Track"
	new_track_requested.emit(track_title)


func _on_refresh_pressed() -> void:
	refresh_requested.emit()
	_refresh_view()


func _on_new_track_text_submitted(_text: String) -> void:
	_on_create_pressed()
