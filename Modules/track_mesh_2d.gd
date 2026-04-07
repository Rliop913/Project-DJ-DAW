extends Area2D

signal PutImg(img_arr: Array)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var surface: Sprite2D = $Surface
@onready var shmat: ShaderMaterial = surface.material as ShaderMaterial

var edit_in: float = 0.0
var edit_out: float = 0.0
var shader_edit_io := Vector2.ZERO
var frame_now: float = 0.0
var frame_max: float = 0.0


func _ready() -> void:
	input_pickable = true
	_ensure_surface_texture()
	_apply_empty_waveform()


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		frame_now = minf(frame_now + (delta * 4.0), frame_max)
		shmat.set_shader_parameter("frame_input", frame_now)
	if Input.is_action_pressed("ui_left"):
		frame_now = maxf(frame_now - (delta * 4.0), 0.0)
		shmat.set_shader_parameter("frame_input", frame_now)


func _on_put_img(img_arr: Array) -> void:
	var imgs: Array[Image] = []
	var total_width := 0.0
	var max_height := 0.0
	for webp in img_arr:
		var img := Image.new()
		var err := img.load_webp_from_buffer(webp)
		if err != OK:
			continue
		img.convert(Image.FORMAT_RGBA8)
		imgs.append(img)
		total_width += img.get_width()
		max_height = maxf(max_height, float(img.get_height()))

	if imgs.is_empty():
		_apply_empty_waveform()
		return

	var tex_arr := Texture2DArray.new()
	tex_arr.create_from_images(imgs)
	frame_max = maxf(float(imgs.size() - 1), 0.0)
	frame_now = clampf(frame_now, 0.0, frame_max)
	shmat.set_shader_parameter("WaveForms", tex_arr)
	shmat.set_shader_parameter("max_layers", max(imgs.size(), 1))
	shmat.set_shader_parameter("frame_input", frame_now)
	_resize_surface(Vector2(total_width, max_height))


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			edit_in = event.position.x
			shader_edit_io.x = event.global_position.x
			shader_edit_io.y = event.global_position.x
			shmat.set_shader_parameter("EditINOUT", shader_edit_io)
			shmat.set_shader_parameter("EditShow", true)
		else:
			edit_out = event.position.x
			shader_edit_io.y = event.global_position.x
			shmat.set_shader_parameter("EditShow", false)

	if event is InputEventMouseMotion:
		shader_edit_io.y = event.global_position.x
		shmat.set_shader_parameter("EditINOUT", shader_edit_io)
		shmat.set_shader_parameter("CursorPos", event.global_position)


func _apply_empty_waveform() -> void:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var tex_arr := Texture2DArray.new()
	tex_arr.create_from_images([img])
	shmat.set_shader_parameter("WaveForms", tex_arr)
	shmat.set_shader_parameter("max_layers", 1)
	frame_now = 0.0
	frame_max = 0.0
	shmat.set_shader_parameter("frame_input", 0.0)
	_resize_surface(Vector2.ONE)


func _ensure_surface_texture() -> void:
	if surface.texture != null:
		return
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	surface.texture = ImageTexture.create_from_image(img)
	surface.centered = false


func _resize_surface(size: Vector2) -> void:
	var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	surface.position = Vector2.ZERO
	surface.scale = safe_size
	var rect := collision_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		collision_shape.shape = rect
	rect.size = safe_size
	collision_shape.position = safe_size * 0.5
