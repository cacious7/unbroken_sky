class_name PauseMenu
extends CanvasLayer
## Pause button (top right), Escape and the Android back button open a menu with
## text settings and a way back to the title screen. Pauses the scene tree.

const TITLE_SCENE := "res://scenes/main.tscn"

## Dark full-screen backdrop that holds the menu and blocks taps on the game behind it.
var _overlay: ColorRect
var _menu: PanelContainer
var _size_button: Button
var _speed_button: Button
var _assist_button: Button
var _sound_button: Button
var _shake_button: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Settings.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	get_tree().paused = false


func is_open() -> bool:
	return _overlay.visible


func open() -> void:
	_overlay.visible = true
	get_tree().paused = true
	_size_button.grab_focus.call_deferred()


func close() -> void:
	_overlay.visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle()


func _toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _refresh() -> void:
	_size_button.text = "Text size: %s" % Settings.text_size_name()
	_speed_button.text = "Text speed: %s" % Settings.text_speed_name()
	_assist_button.text = "Flight assist: %s" % ("On" if Settings.flight_assist else "Off")
	_sound_button.text = "Sound: %s" % ("On" if Settings.sound_on else "Off")
	_shake_button.text = "Shake & vibration: %s" % ("On" if Settings.shake_on else "Off")
	for button in _menu.find_children("", "Button", true, false):
		button.add_theme_font_size_override("font_size", Settings.font_size(20))


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var pause_button := Button.new()
	pause_button.text = "II"
	pause_button.custom_minimum_size = Vector2(56, 48)
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -72
	pause_button.offset_top = 12
	pause_button.offset_right = -16
	pause_button.offset_bottom = 60
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.add_to_group("blocks_touch")
	pause_button.pressed.connect(open)
	root.add_child(pause_button)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", style)
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(_menu)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_menu.add_child(column)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	column.add_child(_button("Resume", close))
	_size_button = _button("", Settings.cycle_text_size)
	column.add_child(_size_button)
	_speed_button = _button("", Settings.cycle_text_speed)
	column.add_child(_speed_button)
	_assist_button = _button("", Settings.toggle_flight_assist)
	column.add_child(_assist_button)
	_sound_button = _button("", Settings.toggle_sound)
	column.add_child(_sound_button)
	_shake_button = _button("", Settings.toggle_shake)
	column.add_child(_shake_button)
	column.add_child(_button("Title screen", _to_title))


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 46)
	button.pressed.connect(action)
	return button


func _to_title() -> void:
	close()
	get_tree().change_scene_to_file(TITLE_SCENE)
