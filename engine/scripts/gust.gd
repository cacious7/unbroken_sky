@tool
class_name Gust
extends Node2D
## A rectangular air zone for eagle flight. A gust pushes the eagle off course; a lift
## zone (updraft) restores airtime instead. Drawn with streaks so it reads without sound.

@export var size := Vector2(100, 100):
	set(value):
		size = value
		queue_redraw()
## Pixels per second added to the eagle's movement while inside.
@export var force := Vector2(0, 120):
	set(value):
		force = value
		queue_redraw()
@export var lift := false:
	set(value):
		lift = value
		queue_redraw()
@export var label := ""


func _ready() -> void:
	z_index = -4


func contains(world_point: Vector2) -> bool:
	return Rect2(global_position - size / 2.0, size).has_point(world_point)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	var tint := Color(0.5, 0.9, 0.6) if lift else Color(0.75, 0.85, 1.0)
	draw_rect(rect, Color(tint, 0.18))
	draw_rect(rect, Color(tint, 0.6), false, 2.0)
	# Streaks along the push direction (upwards for lift).
	var direction := Vector2.UP if lift else force.normalized()
	for i in 5:
		var start := rect.position + Vector2(size.x * (i + 0.5) / 5.0, size.y * (0.3 + 0.1 * (i % 3)))
		draw_line(start, start + direction * 26.0, Color(tint, 0.8), 2.0)
	if label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-90, -size.y / 2.0 - 6), label,
				HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(0.95, 0.92, 0.85))
