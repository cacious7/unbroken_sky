@tool
class_name Perch
extends Node2D
## A landing target for eagle flight. Generous by design; flight assist widens it.

@export var radius := 42.0:
	set(value):
		radius = value
		queue_redraw()
@export var label := "":
	set(value):
		label = value
		queue_redraw()

## The perch the eagle is currently flying to is drawn brighter.
var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()


func _ready() -> void:
	z_index = -5


func landing_radius() -> float:
	return radius * (1.5 if Settings.flight_assist else 1.0)


func _draw() -> void:
	var assist_radius := radius * 1.5
	if not Engine.is_editor_hint() and Settings.flight_assist:
		draw_circle(Vector2.ZERO, assist_radius, Color(0.9, 0.85, 0.6, 0.15))
	# A worn stone ledge: flagstones inside a rim.
	draw_circle(Vector2.ZERO, radius, Color(0.62, 0.58, 0.52))
	for i in 6:
		var angle := TAU * i / 6.0 + 0.3
		draw_line(Vector2.ZERO, Vector2.from_angle(angle) * radius, Color(0.48, 0.45, 0.4), 1.5)
	draw_circle(Vector2.ZERO, radius * 0.35, Color(0.68, 0.64, 0.58))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.4, 0.37, 0.33), 4.0)
	if highlighted:
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 40, Color(1, 0.9, 0.5), 3.0)
	if label != "":
		Placeholder.draw_label(self, Vector2(0, -radius - 8), label)
