extends Control
## Title screen: continue a saved game or start a new one.


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.1, 0.07, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var title := Label.new()
	title.text = "The Unbroken Sky"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Chapter One · prototype"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	GameState.use_story_save()
	if GameState.has_save():
		column.add_child(_button("Continue", _continue))
	column.add_child(_button("New game", _new_game))
	if OS.is_debug_build():
		# Prototype rooms for testing on the phone; they use their own save.
		var rooms := HBoxContainer.new()
		rooms.alignment = BoxContainer.ALIGNMENT_CENTER
		rooms.add_theme_constant_override("separation", 10)
		for room: Array in [["Test: husk fight", "SC05"], ["Test: eagle flight", "SC09"]]:
			var button := _button(room[0], GameState.start_test_room.bind(room[1]))
			button.custom_minimum_size = Vector2(200, 44)
			button.add_theme_font_size_override("font_size", 16)
			rooms.add_child(button)
		column.add_child(rooms)


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 56)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	return button


func _continue() -> void:
	GameState.load_game()
	get_tree().change_scene_to_file(GameState.current_scene_path())


func _new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(GameState.current_scene_path())
