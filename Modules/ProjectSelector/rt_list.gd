extends Tree

@onready var more_icon := preload("res://icons/more_vert_48dp_1F1F1F_FILL0_wght400_GRAD0_opsz48.png")


func GenRootItem(root, name):
	var itemp := create_item(root)
	itemp.set_text(0, name)
	itemp.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)
	itemp.add_button(1, more_icon)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root = create_item()
	for i in range(100):
		GenRootItem(root, "tempfwdanuciwanviln")
		#GenTreeItem(root, "sample", "1", "2", "3", "4")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
