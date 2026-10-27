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
const ART := preload("res://assets/art/husk.svg")
const ART_HEIGHT := 58.0
## Where the copper connector sits in the sprite, as a fraction of its size.
const CONNECTOR := Vector2(0.5, 50.0 / 96.0)
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
			Sfx.play("husk_windup")
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
	var rect := Placeholder.art_rect(ART, Vector2(RADIUS, RADIUS) * 2.0, ART_HEIGHT, true)
	if state == State.BROKEN:
		# Collapsed: the shell slumped flat and dark.
		var slumped := Rect2(rect.position.x - 6, rect.end.y - rect.size.y * 0.35,
				rect.size.x + 12, rect.size.y * 0.35)
		draw_texture_rect(ART, slumped, false, Color(0.45, 0.42, 0.4))
		return
	var tint := Color.WHITE
	if state == State.WINDUP:
		# Glow grows through the windup: the main visual tell.
		var progress := 1.0 - _left / WINDUP_SECONDS
		draw_circle(rect.get_center(), rect.size.y * (0.45 + 0.15 * progress),
				Color(1.0, 0.6, 0.1, 0.25 + 0.45 * progress))
		tint = Color(1.0, 0.85 - 0.25 * progress, 0.6 - 0.3 * progress)
	elif state == State.STRIKE:
		tint = Color(1.0, 0.55, 0.45)
	draw_texture_rect(ART, rect, false, tint)
	if state == State.WINDUP:
		var mark := Vector2(-20, rect.position.y - 4)
		draw_string_outline(ThemeDB.fallback_font, mark, "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 28, 5,
				Placeholder.LABEL_OUTLINE)
		draw_string(ThemeDB.fallback_font, mark, "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 28, Color(1.0, 0.55, 0.1))
	if state == State.RECOVERY:
		# Ring the exposed connector (its position in the sprite).
		var connector := rect.position + rect.size * CONNECTOR
		draw_arc(connector, 9.0, 0.0, TAU, 20, Color(1, 1, 1, 0.95), 2.5)
		draw_arc(connector, 12.0, 0.0, TAU, 20, Color(1.0, 0.75, 0.3, 0.7), 2.0)
	for i in max_health:
		var pip := Rect2(-12 + i * 9, RADIUS + 4, 7, 4)
		draw_rect(pip, Color(0.9, 0.55, 0.2) if i < health else Color(0.2, 0.2, 0.2, 0.5))
