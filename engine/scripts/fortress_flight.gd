extends StoryScene
## SC09 "The first sky" greybox: three perch-to-perch eagle links above Reed Gate.
## The first is safe; the second crosses a gust, with an updraft to the left; the third
## reaches the release wheel. If the wings give out or the eagle leaves the area, it
## returns to the last perch with no other penalty. Landing on the wheel platform
## turns Tavo human again and unlocks the eagle form.
##
## Steering: keyboard direction, or hold a finger/mouse button where you want to go.
## Take off: E/Space, the screen, or the mouse.

const BASE_AIRTIME := 3.5
const ASSIST_AIRTIME := 5.5
const LIFT_REFILL_PER_SECOND := 1.5
const AREA := Rect2(-20, -20, 1000, 580)

@onready var eagle: Eagle = $Eagle
@onready var perches: Array[Perch] = [$Perch0, $Perch1, $Perch2, $Perch3]

var _zones: Array[Gust] = []
var _steering := false
var _steer_screen := Vector2.ZERO


func _dialogue_file() -> String:
	return "res://data/dialogue/sc09.json"


func _start() -> void:
	touch_enabled = false
	touch.set_shown(false)
	for child in get_children():
		if child is Gust:
			_zones.append(child)
	if GameState.get_flag("sc09_complete"):
		_go_to("SC10")
		return
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	_perch_at(GameState.get_flag("sc09_link"))
	if not GameState.get_flag("sc09_started"):
		await _say("fall")
		GameState.set_flag("sc09_started", true)
		await _say("hint")
	_refresh_objective()


func link() -> int:
	return GameState.get_flag("sc09_link")


func is_flying() -> bool:
	return eagle.flying


func takeoff() -> void:
	if eagle.flying or _busy or GameState.get_flag("sc09_complete"):
		return
	if link() == 1 and not GameState.get_flag("sc09_voice_heard"):
		await _say("voice")
		GameState.set_flag("sc09_voice_heard", true)
	var next := perches[link() + 1]
	eagle.launch(next.global_position - eagle.global_position,
			ASSIST_AIRTIME if Settings.flight_assist else BASE_AIRTIME)
	_refresh_objective()


func _physics_process(delta: float) -> void:
	if not eagle.flying or _busy:
		return
	var steer := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if steer == Vector2.ZERO and _steering:
		var target := get_canvas_transform().affine_inverse() * _steer_screen
		steer = (target - eagle.global_position).normalized()
	eagle.fly(delta, steer, _wind(delta))
	var next := perches[link() + 1]
	if eagle.global_position.distance_to(next.global_position) <= next.landing_radius():
		_land(link() + 1)
	elif eagle.airtime <= 0.0 or not AREA.has_point(eagle.global_position):
		_fall()


func _wind(delta: float) -> Vector2:
	var push := Vector2.ZERO
	for zone in _zones:
		if not zone.contains(eagle.global_position):
			continue
		if zone.lift:
			eagle.airtime = minf(eagle.airtime + LIFT_REFILL_PER_SECOND * delta, eagle.max_airtime)
		else:
			push += zone.force * (0.5 if Settings.flight_assist else 1.0)
	return push


func _land(index: int) -> void:
	eagle.flying = false
	GameState.set_flag("sc09_link", index)
	if index == perches.size() - 1:
		_become_human()
		await _say("land")
		GameState.set_flag("eagle_unlocked", true)
		GameState.set_flag("sc09_complete", true)
		_go_to("SC10")
	else:
		_perch_at(index)
		_refresh_objective()


func _fall() -> void:
	hud.show_caption("[the wings give out: back to the last perch]")
	_perch_at(link())
	_refresh_objective()


func _perch_at(index: int) -> void:
	var facing := Vector2.RIGHT
	if index + 1 < perches.size():
		facing = perches[index + 1].global_position - perches[index].global_position
	eagle.max_airtime = ASSIST_AIRTIME if Settings.flight_assist else BASE_AIRTIME
	eagle.perch_at(perches[index].global_position, facing)
	for i in perches.size():
		perches[i].highlighted = i == index + 1


func _become_human() -> void:
	eagle.visible = false
	for perch in perches:
		perch.highlighted = false
	player.global_position = perches[-1].global_position
	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT


func _unhandled_input(event: InputEvent) -> void:
	if _busy or GameState.get_flag("sc09_complete"):
		return
	var pointer_down := false
	var pointer_up := false
	if event is InputEventScreenTouch:
		if event.pressed and touch.is_over_blocking_control(event.position):
			return
		pointer_down = event.pressed
		pointer_up = not event.pressed
		_steer_screen = event.position
	elif event is InputEventScreenDrag:
		_steer_screen = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		pointer_down = event.pressed
		pointer_up = not event.pressed
		_steer_screen = event.position
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_steer_screen = event.position
	if pointer_down:
		get_viewport().set_input_as_handled()
		if eagle.flying:
			_steering = true
		else:
			takeoff()
	elif pointer_up:
		_steering = false
	elif event.is_action_pressed("interact") and not eagle.flying:
		get_viewport().set_input_as_handled()
		takeoff()


func _objective() -> String:
	if GameState.get_flag("sc09_complete"):
		return "Bring the release wheel to the bypass."
	if eagle != null and eagle.flying:
		return "Fly to the bright perch before your wings tire."
	if GameState.get_flag("sc09_started"):
		return "Take off towards the bright perch (tap, click or E)."
	return ""
