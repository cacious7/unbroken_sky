class_name Eagle
extends Node2D
## Tavo's eagle form for constrained perch-to-perch flight. Flies at a steady speed,
## turns towards the steering direction, and has limited airtime per link.

const SPEED := 190.0
## Radians per second.
const TURN_RATE := 3.2

var heading := Vector2.RIGHT
var airtime := 0.0
var max_airtime := 1.0
var flying := false


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
	queue_redraw()


func _draw() -> void:
	var forward := heading
	var side := heading.orthogonal()
	var body := PackedVector2Array([forward * 24.0, -forward * 15.0 + side * 9.0, -forward * 15.0 - side * 9.0])
	var wings := PackedVector2Array([forward * 4.0, -forward * 9.0 + side * 34.0, -forward * 6.0,
			-forward * 9.0 - side * 34.0])
	draw_colored_polygon(wings, Color(0.3, 0.2, 0.14))
	draw_colored_polygon(body, Color(0.85, 0.6, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(-40, -40), "EAGLE", HORIZONTAL_ALIGNMENT_CENTER,
			80, 13, Color(0.95, 0.92, 0.85))
	if flying:
		# Airtime bar: how long until the wings give out.
		var fraction := airtime / max_airtime if max_airtime > 0.0 else 0.0
		draw_rect(Rect2(-26, 32, 52, 6), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-26, 32, 52 * fraction, 6),
				Color(0.9, 0.8, 0.3) if fraction > 0.3 else Color(0.95, 0.35, 0.25))
