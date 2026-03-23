extends Control

var EngineRoot:PDJE_Wrapper
var EditorRoot:EditorWrapper
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EngineRoot = PDJE_Wrapper.new()
	EngineRoot.InitEngine("res://TempRoot")#temp root path. change later
	if not EngineRoot.InitEditor("void", "void", "res://EditTempRoot"):
		printerr("failed to init editor")
	else:
		EditorRoot = EngineRoot.GetEditor()
	
	var any_music := EngineRoot.SearchMusic("","")
	print(any_music)
	if any_music.is_empty():
		EditorRoot.ConfigNewMusic("tempmusic", "camellia", "res://DMCA_FREE_DEMO_MUSIC/miku_temp.wav")
		var temparg := PDJE_EDITOR_ARG.new()
		temparg.InitMusicArg("tempmusic", "130", 0, 0, 0)
		EditorRoot.AddLine(temparg)
		print(EditorRoot.render("temptitle"))
		EditorRoot.pushToRootDB("tempmusic", "camellia")
	
	var util_api := PDJE_HighLevelUtilAPI.new()
	var webps = util_api.SoundToWaveform(EngineRoot, "res://img_cache_db", any_music[0], 96)
	$bg/Vertical/VSplitContainer/MasterTrack.emit_signal("PutImg", webps)
