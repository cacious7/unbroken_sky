class_name DialogueBox
extends CanvasLayer
## Plays conversations from a scene's dialogue JSON. Advances on interact, click or tap,
## never on a timer. A line may carry "if" (state it requires) and "choices"; each
## choice's "effects" are applied through GameState and later lines reconverge.

signal finished
signal choice_made(choice_id: String)

## Tests set this to run conversations instantly, picking choices by id from
## test_choices (or the first choice when the list is empty).
var auto_finish := false
var test_choices: Array[String] = []

var _conversations: Dictionary = {}
var _lines: Array = []
var _index := -1
var _revealed := 0.0
var _choosing := false

var _speaker: Label
var _text: Label
var _hint: Label
var _choices: VBoxContainer
var _portrait: TextureRect
var _portrait_frame: PanelContainer
## Speaker name (upper case) -> portrait texture, or null when there is no sprite.
var _portraits: Dictionary = {}


func _ready() -> void:
	layer = 10
	_build()
	visible = false
	Settings.changed.connect(_apply_text_size)
	_apply_text_size()


func load_file(path: String) -> bool:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("conversations")) != TYPE_DICTIONARY:
		push_error("Dialogue file unreadable: %s" % path)
		return false
	_conversations = data.conversations
	return true


func is_open() -> bool:
	return visible


func play(conversation_id: String) -> void:
	_lines = _conversations.get(conversation_id, [])
	if _lines.is_empty() or auto_finish:
		if _lines.is_empty():
			push_error("Missing conversation: %s" % conversation_id)
		else:
			_run_instantly()
		finished.emit.call_deferred()
		return
	_index = -1
	visible = true
	_next_line()


func _next_index(after: int) -> int:
	for i in range(after + 1, _lines.size()):
		if GameState.matches(_lines[i].get("if", {})):
			return i
	return -1


func _next_line() -> void:
	_index = _next_index(_index)
	if _index == -1:
		visible = false
		finished.emit()
		return
	_show_line(_lines[_index])


func _run_instantly() -> void:
	var i := _next_index(-1)
	while i != -1:
		var choices: Array = _lines[i].get("choices", [])
		if not choices.is_empty():
			var wanted: String = test_choices.pop_front() if not test_choices.is_empty() else ""
			var picked: Dictionary = choices[0]
			for choice: Dictionary in choices:
				if choice.get("id") == wanted:
					picked = choice
			_apply_choice(picked)
		i = _next_index(i)


func _apply_choice(choice: Dictionary) -> void:
	GameState.apply_effects(choice.get("effects", {}))
	choice_made.emit(choice.get("id", ""))


func _show_line(line: Dictionary) -> void:
	var speaker: String = line.get("speaker", "")
	var caption: String = line.get("caption", "")
	_speaker.text = speaker
	_speaker.visible = speaker != ""
	var portrait := portrait_for(speaker)
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null
	_text.text = (caption + "\n" if caption != "" else "") + str(line.get("text", ""))
	# Narration (no speaker) is set apart from spoken lines by colour.
	_text.add_theme_color_override("font_color",
			Color(0.95, 0.92, 0.85) if speaker != "" else Color(0.75, 0.82, 0.9))
	_revealed = 0.0
	_text.visible_characters = 0 if Settings.chars_per_second() > 0.0 else -1
	if line.has("sfx"):
		Sfx.play(str(line.sfx))

	for old in _choices.get_children():
		_choices.remove_child(old)
		old.queue_free()
	var choices: Array = line.get("choices", [])
	_choosing = not choices.is_empty()
	_choices.visible = _choosing
	_hint.visible = not _choosing
	if _choosing:
		_text.visible_characters = -1
		for choice: Dictionary in choices:
			_choices.add_child(_choice_button(choice))
		_choices.get_child(0).grab_focus.call_deferred()


## The speaker's head, cut from their character sprite (assets/art/characters/<name>.svg,
## imported at 3x so the close-up stays sharp). Null for voices without a sprite.
func portrait_for(speaker: String) -> Texture2D:
	if speaker == "":
		return null
	if not _portraits.has(speaker):
		var path := "res://assets/art/characters/%s.svg" % speaker.to_lower()
		var portrait: AtlasTexture = null
		if ResourceLoader.exists(path):
			var sprite: Texture2D = load(path)
			var scale := sprite.get_width() / 64.0
			portrait = AtlasTexture.new()
			portrait.atlas = sprite
			portrait.region = Rect2(Vector2(12, 0) * scale, Vector2(40, 40) * scale)
		_portraits[speaker] = portrait
	return _portraits[speaker]


func _choice_button(choice: Dictionary) -> Button:
	var button := Button.new()
	var preview: String = choice.get("preview", "")
	button.text = str(choice.get("text", "")) + ("\n" + preview if preview != "" else "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_size_override("font_size", Settings.font_size(17))
	button.pressed.connect(_on_choice_pressed.bind(choice))
	return button


func _on_choice_pressed(choice: Dictionary) -> void:
	if not _choosing:
		return
	_choosing = false
	_apply_choice(choice)
	_next_line()


func _process(delta: float) -> void:
	if not visible or _text.visible_characters == -1:
		return
	_revealed += delta * Settings.chars_per_second()
	if Settings.chars_per_second() <= 0.0 or _revealed >= _text.get_total_character_count():
		_text.visible_characters = -1
	else:
		_text.visible_characters = int(_revealed)


func _advance() -> void:
	if _choosing:
		return
	if _text.visible_characters != -1:
		_text.visible_characters = -1
		return
	_next_line()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()


func _on_tap(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _apply_text_size() -> void:
	_speaker.add_theme_font_size_override("font_size", Settings.font_size(18))
	_text.add_theme_font_size_override("font_size", Settings.font_size(21))
	_hint.add_theme_font_size_override("font_size", Settings.font_size(13))
	for button in _choices.get_children():
		button.add_theme_font_size_override("font_size", Settings.font_size(17))


func _build() -> void:
	# A full-screen catcher so a tap anywhere advances the conversation.
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.gui_input.connect(_on_tap)
	add_child(catcher)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchored to the bottom and growing upwards, so larger text makes it taller.
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -160
	panel.offset_bottom = -16
	catcher.add_child(panel)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.85, 0.72, 0.5)
	frame_style.set_corner_radius_all(6)
	frame_style.set_content_margin_all(3)
	_portrait_frame = PanelContainer.new()
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.visible = false
	row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(84, 84)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)

	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	column.add_child(_speaker)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_text)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 8)
	_choices.visible = false
	column.add_child(_choices)

	_hint = Label.new()
	_hint.text = "tap or E ▸"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
	column.add_child(_hint)
