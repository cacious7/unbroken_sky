class_name Husk
extends CharacterBody2D
## An abandoned covenant maintenance shell (FINAL_SCRIPT.md, SC05 encounter notes).
## Every attack has a visible windup, an active strike and a recovery. Its copper
## connector is exposed, and breakable, only during recovery. A hammer hit during
## the windup interrupts the strike and goes straight to recovery.
## Husks act only while the player can act, so dialogue and pauses freeze them.

signal state_changed(husk: Husk, state: int)
signal broken(husk: Husk)

enum State { DORMANT, APPROACH, WINDUP, STRIKE, RECOVERY, BROKEN }

const RADIUS := 16.0
const SIZE := Vector2(28, 36)
const SPEED := 60.0
const ATTACK_DISTANCE := 64.0
const WINDUP_SECONDS := 0.85
const STRIKE_SECONDS := 0.22
const STRIKE_SPEED := 340.0
const RECOVERY_SECONDS := 1.2
## The strike lands if Tavo is this close to the husk's edge during the lunge.
const HIT_DISTANCE := 26.0

@export var max_health := 3

var hit_radius := RADIUS
var state: State = State.DORMANT
var health := 3
var target: Player = null

var _left := 0.0
var _lunge := Vector2.RIGHT
var _landed_hit := false
var _start_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("hammer_target")
	motion_mode = MOTION_MODE_FLOATING
	_start_position = position
	health = max_health
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)


func activate(player: Player) -> void:
	target = player
	visible = true
	collision_layer = 1
	if state == State.DORMANT:
		_enter(State.APPROACH)


## Returns the husk to its starting place and full health, waiting to be activated.
func reset_to_start() -> void:
	position = _start_position
	health = max_health
	target = null
	collision_layer = 1
	_enter(State.DORMANT)


## Shows the husk already broken, e.g. when resuming a save.
func set_broken() -> void:
	health = 0
	collision_layer = 0
	_enter(State.BROKEN)


func is_threat() -> bool:
	return state != State.DORMANT and state != State.BROKEN


func is_connector_exposed() -> bool:
	return state == State.RECOVERY


## Resolves one hammer blow: "interrupt", "hit", "break" or "deflect".
func take_hammer() -> String:
	match state:
		State.WINDUP:
			_enter(State.RECOVERY)
			return "interrupt"
		State.RECOVERY:
			health -= 1
			if health > 0:
				queue_redraw()
				return "hit"
			collision_layer = 0
			_enter(State.BROKEN)
			broken.emit(self)
			return "break"
	return "deflect"


func _physics_process(delta: float) -> void:
	if not is_threat() or target == null or not target.active:
		return
	_left -= delta
	var to_target := target.global_position - global_position
	match state:
		State.APPROACH:
			velocity = to_target.normalized() * SPEED
			if to_target.length() <= ATTACK_DISTANCE:
				_enter(State.WINDUP)
		State.WINDUP:
			velocity = Vector2.ZERO
			# Track Tavo early in the windup, then commit so the strike can be dodged.
			if _left > WINDUP_SECONDS * 0.35:
				_lunge = to_target.normalized()
			if _left <= 0.0:
				_enter(State.STRIKE)
		State.STRIKE:
			velocity = _lunge * STRIKE_SPEED
			if not _landed_hit and to_target.length() - RADIUS <= HIT_DISTANCE:
				_landed_hit = target.take_hit(global_position)
			if _left <= 0.0:
				_enter(State.RECOVERY)
		State.RECOVERY:
			velocity = Vector2.ZERO
			if _left <= 0.0:
				_enter(State.APPROACH)
	move_and_slide()
	queue_redraw()


func _enter(new_state: State) -> void:
	state = new_state
	_landed_hit = false
	match new_state:
		State.WINDUP:
			_left = WINDUP_SECONDS
		State.STRIKE:
			_left = STRIKE_SECONDS
		State.RECOVERY:
			_left = RECOVERY_SECONDS
		_:
			_left = 0.0
	velocity = Vector2.ZERO
	state_changed.emit(self, new_state)
	queue_redraw()


func _draw() -> void:
	if state == State.BROKEN:
		draw_rect(Rect2(-SIZE.x / 2.0 - 4, 4, SIZE.x + 8, 10), Color(0.3, 0.3, 0.32))
		return
	var body := Color(0.45, 0.47, 0.5)
	if state == State.STRIKE:
		body = Color(0.75, 0.35, 0.25)
	Placeholder.draw_box(self, SIZE, body, "HUSK")
	var rect := Rect2(-SIZE / 2.0, SIZE)
	if state == State.WINDUP:
		# Glow grows through the windup: the main visual tell.
		var progress := 1.0 - _left / WINDUP_SECONDS
		draw_rect(rect.grow(3.0 + 5.0 * progress), Color(1.0, 0.6, 0.1, 0.45 + 0.55 * progress),
				false, 2.0 + 3.0 * progress)
		draw_string(ThemeDB.fallback_font, Vector2(-20, -SIZE.y / 2.0 - 22), "!",
				HORIZONTAL_ALIGNMENT_CENTER, 40, 26, Color(1.0, 0.55, 0.1))
	if state == State.RECOVERY:
		draw_circle(Vector2(0, -4), 8.0, Color(0.9, 0.55, 0.2))
		draw_arc(Vector2(0, -4), 11.0, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 2.0)
	for i in max_health:
		var pip := Rect2(-12 + i * 9, SIZE.y / 2.0 + 4, 7, 4)
		draw_rect(pip, Color(0.9, 0.55, 0.2) if i < health else Color(0.2, 0.2, 0.2, 0.5))
