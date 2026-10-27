class_name TouchControls
extends CanvasLayer
## Touch input: a quick tap anywhere walks to that spot (or object); pressing and
## dragging on the left half of the screen becomes a floating movement stick; the
## action button at the bottom right uses whatever is in reach (or strikes in combat);
## in combat a dodge button sits beside it. Only shown on touch screens.

signal vector_changed(vector: Vector2)
signal interact_pressed
signal dodge_pressed
signal tapped(screen_position: Vector2)

const STICK_RADIUS := 56.0
const BUTTON_RADIUS := 46.0
const DODGE_RADIUS := 38.0
## A touch that moves further than this is a drag, not a tap.
const TAP_SLOP := 14.0

var device_has_touch := false

var _canvas: Control
## Touches that may still become a tap, by index: start position.
var _pending: Dictionary = {}
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_vector := Vector2.ZERO
var _combat := false
var _action_label := "USE"
## Brief highlight on the button just pressed: "action" or "dodge".
var _flash_button := ""
var _flash_left := 0.0


func _ready() -> void:
	layer = 6
	device_has_touch = DisplayServer.is_touchscreen_available()
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	set_shown(true)


## Hidden during dialogue so taps advance the conversation instead.
func set_shown(on: bool) -> void:
	visible = on and device_has_touch
	if not visible:
		_pending.clear()
		_stick_index = -1
		_set_vector(Vector2.ZERO)


func set_combat_mode(on: bool) -> void:
	_combat = on
	_canvas.queue_redraw()


func set_action_label(text: String) -> void:
	_action_label = text
	_canvas.queue_redraw()


func action_label() -> String:
	return _action_label


func _flash(button: String) -> void:
	_flash_button = button
	_flash_left = 0.15
	_canvas.queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash_button = ""
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if is_over_blocking_control(event.position):
				return
			get_viewport().set_input_as_handled()
			if event.position.distance_to(_button_centre()) <= BUTTON_RADIUS * 1.3:
				_flash("action")
				interact_pressed.emit()
			elif _combat and event.position.distance_to(_dodge_centre()) <= DODGE_RADIUS * 1.3:
				_flash("dodge")
				dodge_pressed.emit()
			else:
				_pending[event.index] = event.position
		else:
			if _pending.has(event.index):
				_pending.erase(event.index)
				tapped.emit(event.position)
			if event.index == _stick_index:
				_stick_index = -1
				_set_vector(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		if _pending.has(event.index):
			var start: Vector2 = _pending[event.index]
			if event.position.distance_to(start) <= TAP_SLOP:
				return
			_pending.erase(event.index)
			if start.x < _canvas.size.x * 0.5 and _stick_index == -1:
				_stick_index = event.index
				_stick_origin = start
		if event.index == _stick_index:
			get_viewport().set_input_as_handled()
			_set_vector(((event.position - _stick_origin) / STICK_RADIUS).limit_length(1.0))


## Buttons such as pause join the "blocks_touch" group so touching them never walks.
func is_over_blocking_control(screen_point: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("blocks_touch"):
		var control := node as Control
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen_point):
			return true
	return false


func _set_vector(vector: Vector2) -> void:
	_stick_vector = vector
	vector_changed.emit(vector)
	_canvas.queue_redraw()


func _button_centre() -> Vector2:
	return _canvas.size - Vector2(96, 96)


func _dodge_centre() -> Vector2:
	return _canvas.size - Vector2(206, 70)


func _draw_controls() -> void:
	var base := _stick_origin if _stick_index != -1 else Vector2(110, _canvas.size.y - 110)
	_canvas.draw_circle(base, STICK_RADIUS, Color(1, 1, 1, 0.15))
	_canvas.draw_circle(base + _stick_vector * STICK_RADIUS, 24, Color(1, 1, 1, 0.45))
	_draw_button(_button_centre(), BUTTON_RADIUS, _action_label, _flash_button == "action")
	if _combat:
		_draw_button(_dodge_centre(), DODGE_RADIUS, "DODGE", _flash_button == "dodge")


func _draw_button(centre: Vector2, radius: float, text: String, pressed: bool) -> void:
	_canvas.draw_circle(centre, radius * (0.92 if pressed else 1.0), Color(1, 1, 1, 0.6 if pressed else 0.3))
	_canvas.draw_arc(centre, radius, 0.0, TAU, 40, Color(0, 0, 0, 0.35), 2.0)
	var font := ThemeDB.fallback_font
	var position := centre + Vector2(-50, 7)
	_canvas.draw_string_outline(font, position, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, 4, Color(0, 0, 0, 0.6))
	_canvas.draw_string(font, position, text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, Color(1, 1, 1, 0.95))
