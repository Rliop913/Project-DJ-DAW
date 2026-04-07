extends Panel

signal PutImg(img_arr: Array)

@onready var shmat: ShaderMaterial = material as ShaderMaterial

var edit_in: float = 0.0
var edit_out: float = 0.0
var shader_edit_io := Vector2.ZERO
var frame_now: float = 0.0
var frame_max: float = 0.0


func _ready() -> void:
	_apply_empty_waveform()


func _on_put_img(img_arr: Array) -> void:
	var imgs := _decode_webp_images(img_arr)
	if imgs.is_empty():
		_apply_empty_waveform()
		return
	_apply_waveform_images(imgs)


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		frame_now = minf(frame_now + (delta * 4.0), frame_max)
		shmat.set_shader_parameter("frame_input", frame_now)
	if Input.is_action_pressed("ui_left"):
		frame_now = maxf(frame_now - (delta * 4.0), 0.0)
		shmat.set_shader_parameter("frame_input", frame_now)


func _decode_webp_images(img_arr: Array) -> Array[Image]:
	var imgs: Array[Image] = []
	for webp in img_arr:
		var img := Image.new()
		var err := img.load_webp_from_buffer(webp)
		if err != OK:
			continue
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
	return imgs


func _apply_waveform_images(imgs: Array[Image]) -> void:
	var tex_arr := Texture2DArray.new()
	tex_arr.create_from_images(imgs)
	frame_max = maxf(float(imgs.size() - 1), 0.0)
	frame_now = clampf(frame_now, 0.0, frame_max)
	shmat.set_shader_parameter("WaveForms", tex_arr)
	shmat.set_shader_parameter("max_layers", max(imgs.size(), 1))
	shmat.set_shader_parameter("frame_input", frame_now)


func _apply_empty_waveform() -> void:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	_apply_waveform_images([img])
	frame_now = 0.0
	frame_max = 0.0
	shmat.set_shader_parameter("frame_input", 0.0)

# 기능 설명.
# 기본 디자인 - Waveform + STFT RGB
# 조작 - 마우스 클릭 및 드래그로 영역 선택(separate grab). --> 색 반전 , 좌표 기억 및 에딧 인터페이스
# idx: 1-좌클 2-우클
# Impl After Utility Module Impl
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.is_pressed():
				edit_in = event.position.x
				
				shader_edit_io.x = event.global_position.x
				shader_edit_io.y = event.global_position.x
				shmat.set_shader_parameter("EditINOUT", shader_edit_io)
				shmat.set_shader_parameter("EditShow", true)
			else:
				edit_out = event.position.x
				shader_edit_io.y = event.global_position.x
				shmat.set_shader_parameter("EditShow", false)
			pass	
		
		
	if event is InputEventMouseMotion:
		shader_edit_io.y = event.global_position.x
		
		shmat.set_shader_parameter("EditINOUT", shader_edit_io)
		shmat.set_shader_parameter("CursorPos", event.global_position)
		
	pass # Replace with function body.
