class_name Hud
extends CanvasLayer
## Objective, interaction prompt and the end-of-scene card.

signal restart_requested
signal title_requested

## Keyboard hints are hidden on touch devices, which use the on-screen button.
var show_key_hints := true

var _objective: Label
var _objective_panel: PanelContainer
var _prompt: Label
var _end_card: PanelContainer
var _end_title: Label
var _end_body: Label
var _health_row: HBoxContainer
var _caption: Label
var _caption_tween: Tween
var _combat_hint: Label
## [control, base font size] pairs rescaled when the text size setting changes.
var _scaled: Array = []


func _ready() -> void:
	layer = 5
	_build()
	Settings.changed.connect(_apply_text_size)
	_apply_text_size()


func set_objective(text: String) -> void:
	_objective.text = text
	_objective_panel.visible = text != ""


func show_prompt(target: Interactable) -> void:
	_prompt.visible = target != null
	if target != null:
		_prompt.text = ("[E]  " if show_key_hints else "") + target.prompt


func show_end_card(title: String, body: String) -> void:
	_prompt.visible = false
	_end_title.text = title
	_end_body.text = body
	_end_card.visible = true


func is_end_card_visible() -> bool:
	return _end_card.visible


## Health pips and keyboard combat hints, shown only during encounters.
func set_combat_visible(on: bool) -> void:
	_health_row.visible = on
	_combat_hint.visible = on and show_key_hints


func set_health(current: int, maximum: int) -> void:
	for child in _health_row.get_children():
		_health_row.remove_child(child)
		child.queue_free()
	for i in maximum:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(22, 22)
		pip.color = Color(0.85, 0.3, 0.25) if i < current else Color(0.2, 0.15, 0.12, 0.7)
		_health_row.add_child(pip)


## Brief on-screen text for sounds and combat feedback, so nothing relies on audio.
func show_caption(text: String) -> void:
	_caption.text = text
	_caption.modulate.a = 1.0
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_interval(1.4)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.4)


func caption_text() -> String:
	return _caption.text if _caption.modulate.a > 0.0 else ""


func _apply_text_size() -> void:
	for entry: Array in _scaled:
		(entry[0] as Control).add_theme_font_size_override("font_size", Settings.font_size(entry[1]))


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.8)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_objective_panel = PanelContainer.new()
	_objective_panel.add_theme_stylebox_override("panel", _panel_style())
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_panel.position = Vector2(16, 16)
	root.add_child(_objective_panel)
	_objective = Label.new()
	_objective_panel.add_child(_objective)
	_scaled.append([_objective, 18])

	_prompt = Label.new()
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_left = -240
	_prompt.offset_right = 240
	_prompt.offset_top = -64
	_prompt.offset_bottom = -32
	_prompt.visible = false
	root.add_child(_prompt)
	_scaled.append([_prompt, 20])

	_health_row = HBoxContainer.new()
	_health_row.position = Vector2(16, 72)
	_health_row.add_theme_constant_override("separation", 6)
	_health_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_row.visible = false
	root.add_child(_health_row)

	_caption = Label.new()
	_caption.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 6)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_caption.offset_left = -300
	_caption.offset_right = 300
	_caption.offset_top = 76
	_caption.offset_bottom = 110
	_caption.modulate.a = 0.0
	root.add_child(_caption)
	_scaled.append([_caption, 19])

	_combat_hint = Label.new()
	_combat_hint.text = "J / E  strike      K / Shift  dodge"
	_combat_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_combat_hint.add_theme_constant_override("outline_size", 5)
	_combat_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_combat_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_combat_hint.offset_left = 16
	_combat_hint.offset_top = -40
	_combat_hint.offset_bottom = -12
	_combat_hint.visible = false
	root.add_child(_combat_hint)
	_scaled.append([_combat_hint, 15])

	_end_card = PanelContainer.new()
	_end_card.add_theme_stylebox_override("panel", _panel_style())
	_end_card.set_anchors_preset(Control.PRESET_CENTER)
	_end_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_card.custom_minimum_size = Vector2(480, 0)
	_end_card.visible = false
	root.add_child(_end_card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_end_card.add_child(column)
	_end_title = Label.new()
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_end_title)
	_scaled.append([_end_title, 26])
	_end_body = Label.new()
	_end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_end_body)
	_scaled.append([_end_body, 18])
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	for entry: Array in [["Play again", restart_requested], ["Title screen", title_requested]]:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(160, 52)
		button.pressed.connect((entry[1] as Signal).emit)
		buttons.add_child(button)
		_scaled.append([button, 18])
