class_name FloodWater
extends Node2D
## Dark water rising from the bottom of the screen. Everything below `level` is flooded.

const BOTTOM := 560.0
const WIDTH := 1000.0

## Pixels per second the surface rises while `rising` is true.
@export var rise_speed := 24.0
@export var start_level := 540.0

var level := 540.0
var rising := false


func _ready() -> void:
	level = start_level


func reset() -> void:
	level = start_level
	queue_redraw()


func covers(world_point: Vector2) -> bool:
	return world_point.y >= level


func _physics_process(delta: float) -> void:
	if rising:
		level -= rise_speed * delta
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-20, level, WIDTH, BOTTOM - level + 40), Color(0.1, 0.14, 0.2, 0.85))
	draw_line(Vector2(-20, level), Vector2(WIDTH, level), Color(0.5, 0.7, 0.9, 0.9), 3.0)
