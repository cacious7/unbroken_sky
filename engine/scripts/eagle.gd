class_name Eagle
extends Node2D
## Tavo's eagle form for constrained perch-to-perch flight. Flies at a steady speed,
## turns towards the steering direction, and has limited airtime per link.

const ART := preload("res://assets/art/eagle.svg")
const ART_SIZE := Vector2(96, 72)
const SPEED := 190.0
## Radians per second.
const TURN_RATE := 3.2

var heading := Vector2.RIGHT
var airtime := 0.0
var max_airtime := 1.0
var flying := false
var _flap := 0.0


func _ready() -> void:
	z_index = 5


func perch_at(world_position: Vector2, facing: Vector2) -> void:
	global_position = world_position
	heading = facing.normalized()
	flying = false
	airtime = max_airtime
	queue_redraw()


func launch(direction: Vector2, seconds: float) -> void:
	heading = direction.normalized()
	max_airtime = seconds
	airtime = seconds
	flying = true


## steer: desired direction (zero keeps the current heading); push: wind in px/s.
func fly(delta: float, steer: Vector2, push: Vector2) -> void:
	if steer != Vector2.ZERO:
		var turn := clampf(heading.angle_to(steer), -TURN_RATE * delta, TURN_RATE * delta)
		heading = heading.rotated(turn)
	global_position += (heading * SPEED + push) * delta
	airtime = maxf(airtime - delta, 0.0)
	_flap += delta * 7.0
	queue_redraw()


func _draw() -> void:
	# Shadow on the water below, then the bird turned to its heading. Wingbeats while
	# flying are a gentle squash across the wings.
	draw_set_transform(Vector2(6, 10), heading.angle(), Vector2(0.9, 0.5))
	draw_texture_rect(ART, Rect2(-ART_SIZE / 2.0, ART_SIZE), false, Color(0, 0, 0, 0.3))
	var flap := 1.0 - 0.18 * absf(sin(_flap)) if flying else 0.8
	draw_set_transform(Vector2.ZERO, heading.angle(), Vector2(1.0, flap))
	draw_texture_rect(ART, Rect2(-ART_SIZE / 2.0, ART_SIZE), false)
	draw_set_transform(Vector2.ZERO)
	if flying:
		# Airtime bar: how long until the wings give out.
		var fraction := airtime / max_airtime if max_airtime > 0.0 else 0.0
		draw_rect(Rect2(-26, 32, 52, 6), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-26, 32, 52 * fraction, 6),
				Color(0.9, 0.8, 0.3) if fraction > 0.3 else Color(0.95, 0.35, 0.25))
