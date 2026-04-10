extends Tree

@onready var more_icon := preload("res://icons/more_vert_48dp_1F1F1F_FILL0_wght400_GRAD0_opsz48.png")

func GenTreeItem(root, project_name, author, created, last_edit, length):
	var itemp := create_item(root)
	itemp.set_text(0, project_name)
	itemp.set_text(1, author)
	itemp.set_text(2, created)
	itemp.set_text(3, last_edit)
	itemp.set_text(4, length)
	itemp.add_button(5, more_icon)
	#itemp.set_button(5/, 0, more_icon)
	
	pass

func _ready() -> void:
	set_column_title(0, "Project Name")
	set_column_title(1, "Author")
	set_column_title(2, "Created")
	set_column_title(3, "Last Edit")
	set_column_title(4, "Length")
	
	var root = create_item()
	for i in range(100):
		GenTreeItem(root, "sample", "1", "2", "3", "4")

	#var item1 = create_item(root)
	#item1.set_text(0, "MySong")
	#item1.set_text(1, "rop")
	#item1.set_text(2, "rop")
#
	#var item2 = create_item(root)
	#item2.set_text(0, "LiveSet")
	#item2.set_text(1, "team")
	#item2.set_text(2, "rop")

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var rect: Rect2 = get_item_area_rect(item, column, 0)
	var popup_rect := Rect2i(
		Vector2i(rect.position) + Vector2i(rect.size.x, 0),
		Vector2i(1, 1)
	)
	%"Edit_more".popup_on_parent(popup_rect)
	
	pass # Replace with function body.
