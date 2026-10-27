class_name WaterRope
extends Node2D
## SC06: what the counterfeit mother collapses into, a rope of water and silt held by a
## copper hook. It marks a circular sweep (get clear), sweeps, then leaves the hook
## exposed; one hammer blow on the exposed hook breaks it. Acts only while the player can.

signal state_changed(rope: WaterRope, state: int)
signal broken(rope: WaterRope)

enum State { DORMANT, TELEGRAPH, SWEEP, EXPOSED, BROKEN }

const SWEEP_RADIUS := 120.0
const TELEGRAPH_SECONDS := 1.4
const SWEEP_SECONDS := 0.3
const EXPOSED_SECONDS := 2.6

var hit_radius := 14.0
var state: State = State.DORMANT
var target: Player = null

var _left := 0.0
var _landed_hit := false


func _ready() -> void:
	add_to_group("hammer_target")


func activate(player: Player) -> void:
	target = player
	visible = true
	_enter(State.TELEGRAPH)


func reset_to_start() -> void:
	target = null
	_enter(State.DORMANT)


func is_threat() -> bool:
	return state in [State.TELEGRAPH, State.SWEEP, State.EXPOSED]


func is_hook_exposed() -> bool:
	return state == State.EXPOSED


func take_hammer() -> String:
	if state != State.EXPOSED:
		return "deflect"
	_enter(State.BROKEN)
	broken.emit(self)
	return "break"


func _physics_process(delta: float) -> void:
	if not is_threat() or target == null or not target.active:
		return
	_left -= delta
	match state:
		State.TELEGRAPH:
			if _left <= 0.0:
				_enter(State.SWEEP)
		State.SWEEP:
			if not _landed_hit and target.global_position.distance_to(global_position) <= SWEEP_RADIUS:
				_landed_hit = target.take_hit(global_position)
			if _left <= 0.0:
				_enter(State.EXPOSED)
		State.EXPOSED:
			if _left <= 0.0:
				_enter(State.TELEGRAPH)
	queue_redraw()


func _enter(new_state: State) -> void:
	state = new_state
	_landed_hit = false
	match new_state:
		State.TELEGRAPH:
			_left = TELEGRAPH_SECONDS
		State.SWEEP:
			_left = SWEEP_SECONDS
			Sfx.play("water_sweep")
		State.EXPOSED:
			_left = EXPOSED_SECONDS
		_:
			_left = 0.0
	state_changed.emit(self, new_state)
	queue_redraw()


func _draw() -> void:
	if state == State.DORMANT:
		return
	if state == State.BROKEN:
		draw_circle(Vector2.ZERO, 30.0, Color(0.2, 0.25, 0.3, 0.6))
		return
	if state == State.TELEGRAPH:
		# The marked sweep: fills in as the strike approaches.
		var progress := 1.0 - _left / TELEGRAPH_SECONDS
		draw_circle(Vector2.ZERO, SWEEP_RADIUS, Color(0.3, 0.55, 0.9, 0.08 + 0.22 * progress))
		draw_arc(Vector2.ZERO, SWEEP_RADIUS, 0.0, TAU, 48, Color(0.5, 0.75, 1.0, 0.9), 3.0)
	elif state == State.SWEEP:
		draw_circle(Vector2.ZERO, SWEEP_RADIUS, Color(0.35, 0.6, 1.0, 0.5))
	# The rope itself, then the hook anchoring it.
	draw_rect(Rect2(-9, -34, 18, 44), Color(0.18, 0.26, 0.34))
	draw_string(ThemeDB.fallback_font, Vector2(-90, -42), "WATER ROPE", HORIZONTAL_ALIGNMENT_CENTER,
			180, 13, Color(0.12, 0.09, 0.07))
	draw_arc(Vector2(0, 14), 7.0, 0.0, PI, 10, Color(0.85, 0.5, 0.2), 4.0)
	if state == State.EXPOSED:
		draw_arc(Vector2(0, 14), 14.0, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 2.0)
