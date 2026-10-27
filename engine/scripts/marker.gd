@tool
extends Node2D
## A non-solid route marker (e.g. "STAIR ↑") so a path reads clearly in greybox.

@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export var size := Vector2(60, 40):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.95, 0.8, 0.3, 0.55):
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), color)
	draw_string(ThemeDB.fallback_font, Vector2(-90, 5), label, HORIZONTAL_ALIGNMENT_CENTER,
			180, 14, Color(0.12, 0.09, 0.07))
