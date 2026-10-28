class_name Husk
extends CharacterBody2D
## An abandoned covenant maintenance shell (FINAL_SCRIPT.md, SC05 encounter notes).
## Every attack has a visible windup, an active strike and a recovery. Its copper
## connector is exposed, and breakable, only during recovery. A hammer hit during
## the windup interrupts the strike and goes straight to recovery.
## Husks act only while the player can act, so dialogue and pauses freeze them.
## A practice strike plays the full tell but lunges short, so the first attack teaches
## the rhythm without costing health.

signal state_changed(husk: Husk, state: int)
signal broken(husk: Husk)
## A practice lunge has fallen short.
signal feinted(husk: Husk)

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
## Stagger after a hammer hit: about 12 px of travel.
const KNOCKBACK_SPEED := 180.0
const KNOCKBACK_DECEL := 1400.0
## A practice lunge travels this fraction of a real one and cannot land.
const FEINT_SPEED_SCALE := 0.3
## Beyond this distance the approach curves by the full flank angle; closer in it straightens.
const FLANK_RANGE := 160.0

@export var max_health := 3
## Approach curve in radians, so the husk comes in from one side rather than head on.
@export var flank := 0.0

## Windups left that end in a harmless short lunge.
var practice_strikes := 0

var hit_radius := RADIUS
var state: State = State.DORMANT
var health := 3
var target: Player = null

var _left := 0.0
var _lunge := Vector2.RIGHT
var _landed_hit := false
var _knockback := Vector2.ZERO
var _start_position := Vector2.ZERO
var _feint := false


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


## 0 as a windup begins, rising to 1 as it strikes.
func windup_progress() -> float:
	return 1.0 - _left / WINDUP_SECONDS if state == State.WINDUP else 0.0


## Resolves one hammer blow: "interrupt", "hit", "break" or "deflect".
func take_hammer() -> String:
	match state:
		State.WINDUP:
			_enter(State.RECOVERY)
			_knock_back()
			return "interrupt"
		State.RECOVERY:
			health -= 1
			if health > 0:
				_knock_back()
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
			var curve := flank * clampf((to_target.length() - ATTACK_DISTANCE) / FLANK_RANGE, 0.0, 1.0)
			velocity = to_target.normalized().rotated(curve) * SPEED
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
			velocity = _lunge * STRIKE_SPEED * (FEINT_SPEED_SCALE if _feint else 1.0)
			if not _feint and not _landed_hit and to_target.length() - RADIUS <= HIT_DISTANCE:
				_landed_hit = target.take_hit(global_position)
			if _left <= 0.0:
				_enter(State.RECOVERY)
		State.RECOVERY:
			# A short stagger backwards after a hit, small enough to stay in hammer reach.
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECEL * delta)
			if _left <= 0.0:
				_enter(State.APPROACH)
	move_and_slide()
	queue_redraw()


func _knock_back() -> void:
	if target != null:
		_knockback = (global_position - target.global_position).normalized() * KNOCKBACK_SPEED


func _enter(new_state: State) -> void:
	var feint_finished := state == State.STRIKE and _feint
	state = new_state
	_landed_hit = false
	_knockback = Vector2.ZERO
	if new_state != State.STRIKE:
		_feint = false
	match new_state:
		State.WINDUP:
			_left = WINDUP_SECONDS
			_feint = practice_strikes > 0
			practice_strikes = maxi(0, practice_strikes - 1)
			Sfx.play("husk_windup")
		State.STRIKE:
			_left = STRIKE_SECONDS
		State.RECOVERY:
			_left = RECOVERY_SECONDS
		_:
			_left = 0.0
	velocity = Vector2.ZERO
	state_changed.emit(self, new_state)
	if feint_finished:
		feinted.emit(self)
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
