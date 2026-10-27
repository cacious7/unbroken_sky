extends Control
## Title screen over the dawn backdrop: continue a saved game or start a new one.


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.09, 0.14, 0.23)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://assets/art/title_backdrop.svg")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var title := Label.new()
	title.text = "The Unbroken Sky"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.55))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 36
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Chapter One"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	subtitle.add_theme_constant_override("outline_size", 6)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 104
	add_child(subtitle)

	# Buttons sit over the dark upland at the bottom left, clear of the eagle and sun.
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_left = 48
	column.offset_bottom = -36
	column.add_theme_constant_override("separation", 12)
	add_child(column)

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
