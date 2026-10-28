class_name RepairTiming
extends CanvasLayer
## Two controlled taps seat the pin against the moving pump handle. Misses only
## splash; the window widens after repeated misses. No lost items or health.

signal completed
## Fired once per deliberate tap, after the timing result is known.
signal tapped(success: bool)

var phase := 0.0
var hits := 0
var misses := 0
var _done := false
var _last_success := false
var _canvas: Control
var _result: Label
var _fingers: Dictionary = {}


func _ready() -> void:
	layer = 12
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_gauge)
	add_child(_canvas)
	_result = Label.new()
	_result.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_result.offset_left = -260
	_result.offset_right = 260
	_result.offset_top = -150
	_result.offset_bottom = -110
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.add_theme_font_size_override("font_size", Settings.font_size(21))
	_result.add_theme_color_override("font_outline_color", Color.BLACK)
	_result.add_theme_constant_override("outline_size", 5)
	_result.text = "SET PIN  ·  Tap in the gold"
	_canvas.add_child(_result)


func _process(delta: float) -> void:
	if not _done:
		phase = fmod(phase + delta * 0.65, 1.0)
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	var owned := false
	if event is InputEventScreenTouch:
		owned = _fingers.has(event.index)
	elif event is InputEventMouseButton:
		owned = _fingers.has(-1)
	if not owned and (event is InputEventScreenTouch or event is InputEventMouseButton):
		for node in get_tree().get_nodes_in_group("blocks_touch"):
			var control := node as Control
			if control != null and control.is_visible_in_tree() and control.get_global_rect().has_point(event.position):
				return
	if event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		if event.pressed:
			_fingers[event.index] = true
			strike()
		else:
			_fingers.erase(event.index)
			_release_if_done()
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			_fingers[-1] = true
			strike()
		else:
			_fingers.erase(-1)
			_release_if_done()
	elif event.is_action("interact"):
		get_viewport().set_input_as_handled()
		if event.is_pressed() and not event.is_echo():
			_fingers[-2] = true
			strike()
		elif not event.is_pressed():
			_fingers.erase(-2)
			_release_if_done()


func window_half_width() -> float:
	return 0.12 + minf(misses * 0.04, 0.2)


func strike() -> void:
	if _done:
		return
	var needle := 0.5 - cos(phase * TAU) * 0.5
	_last_success = absf(needle - 0.72) <= window_half_width()
	if _last_success:
		hits += 1
		Sfx.play("hammer_clang", -8.0, 1.2)
		_result.text = "One more." if hits == 1 else "Got it."
		phase = 0.0
		if hits >= 2:
			_done = true
	else:
		misses += 1
		Sfx.play("water_sweep", -12.0, 1.4)
		_result.text = "Steady. Tap in the gold."
	tapped.emit(_last_success)
	_canvas.queue_redraw()
	_release_if_done()


func _release_if_done() -> void:
	if _done and _fingers.is_empty():
		set_process_input(false)
		completed.emit()
		queue_free()


func _draw_gauge() -> void:
	var origin := Vector2(_canvas.size.x * 0.5 - 170, _canvas.size.y - 100)
	_canvas.draw_style_box(_style(), Rect2(origin - Vector2(12, 12), Vector2(364, 52)))
	var half := window_half_width()
	_canvas.draw_rect(Rect2(origin + Vector2((0.72 - half) * 340, 0), Vector2(half * 680, 28)), Color("#dbb45f"))
	var needle := 0.5 - cos(phase * TAU) * 0.5
	_canvas.draw_rect(Rect2(origin + Vector2(needle * 340 - 3, -5), Vector2(6, 38)), Color.WHITE)
	for i in 2:
		_canvas.draw_circle(origin + Vector2(145 + i * 24, 66), 6, Color("#dbb45f") if hits > i else Color("#4a4640"))


func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.06, 0.9)
	style.set_corner_radius_all(8)
	return style
