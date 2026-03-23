extends Panel

var shmat := $".".material as ShaderMaterial
var edit_in:float
var edit_out:float
var shader_edit_io:Vector2
var frame_now = 0
var frame_max = 0
signal PutImg(img_arr: Array)


func _on_put_img(img_arr: Array) -> void:
	var imgs: Array[Image] = []
	for webp in img_arr:
		var img := Image.new()
		var err := img.load_webp_from_buffer(webp)
		if err != OK:
			continue
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
	print(imgs.size(), "imgsize")
	frame_max = imgs.size()
	var tex_arr = Texture2DArray.new()
	tex_arr.create_from_images(imgs)
	shmat.set_shader_parameter("WaveForms", tex_arr)
	
	pass # Replace with function body.
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		print("right")
		frame_now += 0.01
		if frame_now > frame_max:
			frame_now = frame_max
		shmat.set_shader_parameter("frame_input", frame_now)
	if Input.is_action_pressed("ui_left"):
		frame_now -= 0.01
		if frame_now < 0:
			frame_now = 0
		shmat.set_shader_parameter("frame_input", frame_now)
	pass

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
