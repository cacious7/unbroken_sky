@tool
extends StaticBody2D
## Solid placeholder scenery such as walls and buildings.

@export var size := Vector2(64, 64):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.55, 0.38, 0.25):
	set(value):
		color = value
		queue_redraw()
@export var label := "":
	set(value):
		label = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)


func _draw() -> void:
	Placeholder.draw_box(self, size, color, label)
