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


func _ready() -> void:
	z_index = -5


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), color)
	# Chevrons pointing up the route.
	for i in 3:
		var x := -size.x / 2.0 + size.x * (i + 0.5) / 3.0
		draw_polyline(PackedVector2Array([Vector2(x - 6, 6), Vector2(x, 0), Vector2(x + 6, 6)]),
				Color(0.2, 0.15, 0.1, 0.6), 2.0)
	Placeholder.draw_label(self, Vector2(0, -size.y / 2.0 - 4), label)
