class_name Player
extends CharacterBody2D
## Tavo in human form: top-down movement and choosing what to interact with.
## Moves by keyboard or on-screen stick, or walks to a tapped/clicked point.
## Tapping an object walks to it and uses it on arrival.
## In combat scenes he can also strike with the repair hammer and dodge.

signal focus_changed(target: Interactable)
signal health_changed(current: int, maximum: int)
signal defeated
## "miss", "deflect", "interrupt", "hit" or "break"; see Husk.take_hammer().
## Anything in the "hammer_target" group can be struck: it provides hit_radius,
## is_threat() and take_hammer() -> String.
signal struck(result: String)

const SPEED := 150.0
const SIZE := Vector2(20, 28)
const ART := preload("res://assets/art/characters/tavo.svg")
const ART_HEIGHT := 48.0
const ARRIVE_DISTANCE := 4.0
## A tap-walk gives up after this long without real progress (e.g. blocked by a wall).
const STUCK_SECONDS := 0.35

const MAX_HEALTH := 3
## Hammer reach, measured from Tavo's centre to the target's edge.
const ATTACK_RANGE := 40.0
const ATTACK_COOLDOWN := 0.35
const DODGE_SPEED := 430.0
const DODGE_SECONDS := 0.2
const KNOCKBACK_SECONDS := 0.12
## No further damage for this long after being hit.
const HIT_GRACE_SECONDS := 0.9

## False while dialogue or a cutscene owns the controls.
var active := true
## Set by the on-screen stick; added to keyboard input.
var touch_vector := Vector2.ZERO
var combat_enabled := false
var health := MAX_HEALTH
var facing := Vector2.RIGHT

var _nearby: Array[Interactable] = []
var _focus: Interactable = null
var _walking := false
var _walk_point := Vector2.ZERO
var _walk_target: Interactable = null
## Waypoints around obstacles, from NavGrid.
var _path := PackedVector2Array()
## A husk (or other hammer target) tapped in combat: walk up to it and swing.
var _attack_target: Node2D = null
var _stuck_time := 0.0
## Dodges and knockback both move Tavo along a fixed direction for a short time.
var _dash_left := 0.0
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _grace_left := 0.0
var _cooldown_left := 0.0
var _swing_left := 0.0
var _walk_cycle := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_grace_left = maxf(_grace_left - delta, 0.0)
	_swing_left = maxf(_swing_left - delta, 0.0)
	if not active and _walking:
		cancel_walk()
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_direction * _dash_speed
	else:
		var direction := Vector2.ZERO
		if active:
			direction = _input_vector()
			if direction != Vector2.ZERO:
				cancel_walk()
			elif _walking:
				direction = _walk_direction()
			direction = direction.limit_length(1.0)
		if direction != Vector2.ZERO:
			facing = direction.normalized()
		velocity = direction * SPEED
	var before := global_position
	move_and_slide()
	if _walking:
		_check_stuck(before, delta)
	var moved := global_position.distance_to(before) > 0.1
	if moved:
		_walk_cycle += delta * 12.0
	elif _walk_cycle != 0.0:
		_walk_cycle = 0.0
		queue_redraw()
	if moved or _walking or _grace_left > 0.0 or _swing_left > 0.0:
		queue_redraw()
	_update_focus()
	if _walking and _walk_target != null and _nearby.has(_walk_target):
		var target := _walk_target
		cancel_walk()
		target.used.emit(target)
	elif _walking and _attack_target != null:
		if not _attack_target.is_threat():
			cancel_walk()
		elif _distance_to_target(_attack_target) <= ATTACK_RANGE - 4.0:
			cancel_walk()
			attack()


func _draw() -> void:
	# Flicker while protected after a hit or during a dodge.
	var flicker := _grace_left > 0.0 and int(_grace_left * 20.0) % 2 == 0
	var rect := Placeholder.art_rect(ART, SIZE, ART_HEIGHT, true)
	# A small bob while walking.
	rect.position.y -= absf(sin(_walk_cycle)) * 2.0
	# Face the way he last moved.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if facing.x < -0.1 else 1.0, 1.0))
	draw_texture_rect(ART, rect, false, Color(1, 1, 1, 0.4 if flicker else 1.0))
	draw_set_transform(Vector2.ZERO)
	if _swing_left > 0.0:
		draw_arc(Vector2.ZERO, ATTACK_RANGE, facing.angle() - 0.8, facing.angle() + 0.8, 12,
				Color(1, 1, 1, 0.9), 4.0)
	if _walking and _walk_target == null and _attack_target == null:
		draw_arc(to_local(_walk_point), 9.0, 0.0, TAU, 24, Color(1, 1, 1, 0.8), 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		try_interact()
	elif combat_enabled and event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		attack()
	elif combat_enabled and event.is_action_pressed("dodge"):
		get_viewport().set_input_as_handled()
		dodge()
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		# Real mouse clicks only; touches arrive through TouchControls.
		get_viewport().set_input_as_handled()
		walk_to_screen(event.position)


## Uses whatever is in reach; in combat with nothing in reach, swings the hammer.
func try_interact() -> void:
	if not active:
		return
	if _focus != null:
		_focus.used.emit(_focus)
	elif combat_enabled:
		attack()


func has_focus_target() -> bool:
	return _focus != null


func focus_target() -> Interactable:
	return _focus


func attack() -> void:
	if not active or not combat_enabled or _cooldown_left > 0.0:
		return
	_cooldown_left = ATTACK_COOLDOWN
	_swing_left = 0.15
	var target := _nearest_target(ATTACK_RANGE)
	if target == null:
		struck.emit("miss")
	else:
		facing = (target.global_position - global_position).normalized()
		struck.emit(target.take_hammer())
	queue_redraw()


## A short dash with brief protection. Without a direction held, dodges away from
## the nearest threat.
func dodge() -> void:
	if not active or not combat_enabled or _dash_left > 0.0:
		return
	cancel_walk()
	var direction := _input_vector()
	if direction == Vector2.ZERO:
		var threat := _nearest_target(INF)
		direction = global_position - threat.global_position if threat != null else -facing
	_dash(direction, DODGE_SPEED, DODGE_SECONDS)
	_grace_left = maxf(_grace_left, DODGE_SECONDS + 0.05)


## Returns true if the hit landed (false while dodging or recently hit).
func take_hit(from: Vector2) -> bool:
	if _grace_left > 0.0 or health <= 0:
		return false
	health -= 1
	_grace_left = HIT_GRACE_SECONDS
	_dash(global_position - from, DODGE_SPEED * 0.6, KNOCKBACK_SECONDS)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		defeated.emit()
	return true


func restore_health() -> void:
	health = MAX_HEALTH
	_grace_left = 0.0
	_dash_left = 0.0
	health_changed.emit(health, MAX_HEALTH)
	queue_redraw()


func is_protected() -> bool:
	return _grace_left > 0.0


## Walk to a screen position from a tap or click.
func walk_to_screen(screen_point: Vector2) -> void:
	walk_to(get_canvas_transform().affine_inverse() * screen_point)


## Walk to a world position, finding a way around obstacles. If an object is there,
## walk to it and use it; in combat, if a husk is there, walk up to it and strike.
func walk_to(world_point: Vector2) -> void:
	if not active:
		return
	cancel_walk()
	if combat_enabled:
		var enemy := _threat_at(world_point)
		if enemy != null:
			if _distance_to_target(enemy) <= ATTACK_RANGE - 4.0:
				attack()
				return
			_attack_target = enemy
			_walk_point = enemy.global_position
			_walking = true
			return
	var target := _interactable_at(world_point)
	if target != null and _nearby.has(target):
		target.used.emit(target)
		return
	_walk_target = target
	_walk_point = target.global_position if target != null else world_point
	_path = NavGrid.find_path(get_parent(), global_position, _walk_point)
	_walking = true
	_stuck_time = 0.0
	queue_redraw()


func cancel_walk() -> void:
	_walking = false
	_walk_target = null
	_attack_target = null
	_path.clear()
	_stuck_time = 0.0
	queue_redraw()


func path_points() -> PackedVector2Array:
	return _path


func is_walking() -> bool:
	return _walking


func enter_reach(target: Interactable) -> void:
	if not _nearby.has(target):
		_nearby.append(target)


func exit_reach(target: Interactable) -> void:
	_nearby.erase(target)


func _input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_vector


func _dash(direction: Vector2, speed: float, seconds: float) -> void:
	_dash_direction = direction.normalized() if direction != Vector2.ZERO else -facing
	_dash_speed = speed
	_dash_left = seconds


func _walk_direction() -> Vector2:
	# Husks move, so head straight for them.
	if _attack_target != null:
		return (_attack_target.global_position - global_position).normalized()
	while _path.size() > 0 and global_position.distance_to(_path[0]) <= ARRIVE_DISTANCE:
		_path.remove_at(0)
	if _path.size() > 0:
		return (_path[0] - global_position).normalized()
	# Off the end of the path: close the last gap to the exact point or object.
	var offset := _walk_point - global_position
	if _walk_target == null and offset.length() <= ARRIVE_DISTANCE:
		cancel_walk()
		return Vector2.ZERO
	return offset.normalized()


func _distance_to_target(target: Node2D) -> float:
	return global_position.distance_to(target.global_position) - float(target.hit_radius)


func _threat_at(world_point: Vector2) -> Node2D:
	for node in get_tree().get_nodes_in_group("hammer_target"):
		var target := node as Node2D
		if target.is_threat() and target.global_position.distance_to(world_point) <= target.hit_radius + 26.0:
			return target
	return null


func _check_stuck(before: Vector2, delta: float) -> void:
	if global_position.distance_to(before) < SPEED * delta * 0.25:
		_stuck_time += delta
		if _stuck_time >= STUCK_SECONDS:
			cancel_walk()
	else:
		_stuck_time = 0.0


func _nearest_target(max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("hammer_target"):
		var target := node as Node2D
		var distance: float = global_position.distance_to(target.global_position) - target.hit_radius
		if target.is_threat() and distance <= max_distance and distance < best_distance:
			best_distance = distance
			best = target
	return best


func _interactable_at(world_point: Vector2) -> Interactable:
	var best: Interactable = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		var candidate := node as Interactable
		var distance := candidate.global_position.distance_squared_to(world_point)
		if candidate.hit_test(world_point) and distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func _update_focus() -> void:
	var best: Interactable = null
	if active:
		var best_distance := INF
		for target in _nearby:
			var distance := global_position.distance_squared_to(target.global_position)
			if target.enabled and distance < best_distance:
				best_distance = distance
				best = target
	if best != _focus:
		_focus = best
		focus_changed.emit(_focus)
