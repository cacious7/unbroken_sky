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


func landing_radius() -> float:
	return radius * (1.5 if Settings.flight_assist else 1.0)


func _draw() -> void:
	var assist_radius := radius * 1.5
	if not Engine.is_editor_hint() and Settings.flight_assist:
		draw_circle(Vector2.ZERO, assist_radius, Color(0.9, 0.85, 0.6, 0.15))
	draw_circle(Vector2.ZERO, radius, Color(0.75, 0.68, 0.55, 0.9 if highlighted else 0.55))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32,
			Color(1, 0.9, 0.5) if highlighted else Color(0.3, 0.25, 0.2), 3.0 if highlighted else 2.0)
	if label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-90, -radius - 6), label,
				HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(0.95, 0.92, 0.85))
