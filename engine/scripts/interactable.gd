@tool
class_name Interactable
extends Area2D
## Something the player can use when standing close to it.

signal used(target: Interactable)

@export var body_size := Vector2(32, 32):
	set(value):
		body_size = value
		queue_redraw()
@export var color := Color(0.55, 0.55, 0.55):
	set(value):
		color = value
		queue_redraw()
@export var label := "":
	set(value):
		label = value
		queue_redraw()
## Short action text shown in the prompt, e.g. "Search the basket".
@export var prompt := "Use"
@export var solid := true
## How far beyond its body the player can stand and still use it.
@export var reach := 22.0

## Extra margin around the body that still counts as tapping it, for fingers.
const TAP_PADDING := 16.0

var enabled := true
var _body: StaticBody2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("interactable")
	var reach_rect := RectangleShape2D.new()
	reach_rect.size = body_size + Vector2.ONE * reach * 2.0
	var reach_shape := CollisionShape2D.new()
	reach_shape.shape = reach_rect
	add_child(reach_shape)
	if solid:
		var body_rect := RectangleShape2D.new()
		body_rect.size = body_size
		var body_shape := CollisionShape2D.new()
		body_shape.shape = body_rect
		_body = StaticBody2D.new()
		_body.add_child(body_shape)
		add_child(_body)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _draw() -> void:
	Placeholder.draw_box(self, body_size, color, label)


## True if a tap or click at this world position should select this object.
func hit_test(world_point: Vector2) -> bool:
	var padded := body_size + Vector2.ONE * TAP_PADDING * 2.0
	return enabled and Rect2(global_position - padded / 2.0, padded).has_point(world_point)


## Shows or hides the object, including its collision, e.g. a character arriving.
func set_active(on: bool) -> void:
	enabled = on
	visible = on
	if _body != null:
		_body.collision_layer = 1 if on else 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.enter_reach(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.exit_reach(self)
