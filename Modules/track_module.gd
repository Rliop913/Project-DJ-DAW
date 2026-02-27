extends Panel

var shmat := $".".material as ShaderMaterial
var edit_in:float
var edit_out:float
var shader_edit_io:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
