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
## Sprite art, assigned by ArtCatalog; without it a labelled box is drawn.
var texture: Texture2D = null
var art_height := 0.0
var art_feet := false
var show_label := true
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


func set_art(art_texture: Texture2D, height: float, feet: bool, labelled: bool) -> void:
	texture = art_texture
	art_height = height
	art_feet = feet
	show_label = labelled
	queue_redraw()


func _draw() -> void:
	if texture != null:
		Placeholder.draw_art(self, texture, Placeholder.art_rect(texture, body_size, art_height, art_feet),
				label if show_label else "")
	else:
		Placeholder.draw_box(self, body_size, color, label)


## True if a tap or click at this world position should select this object.
## Covers the padded body and, when there is art, the whole sprite.
func hit_test(world_point: Vector2) -> bool:
	if not enabled:
		return false
	var area := Rect2(-body_size / 2.0, body_size).grow(TAP_PADDING)
	if texture != null:
		area = area.merge(Placeholder.art_rect(texture, body_size, art_height, art_feet))
	return area.has_point(world_point - global_position)


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
