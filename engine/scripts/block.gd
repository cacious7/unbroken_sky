@tool
extends StaticBody2D
## Solid scenery such as walls and buildings. Draws mud-brick until given a sprite
## (see ArtCatalog), in which case the sprite is drawn over the same collision box.

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

var texture: Texture2D = null
var art_height := 0.0
var art_feet := false
var show_label := true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)


func set_art(art_texture: Texture2D, height: float, feet: bool, labelled: bool) -> void:
	texture = art_texture
	art_height = height
	art_feet = feet
	show_label = labelled
	queue_redraw()


func _draw() -> void:
	if texture != null:
		Placeholder.draw_art(self, texture, Placeholder.art_rect(texture, size, art_height, art_feet),
				label if show_label else "")
	elif label != "":
		Placeholder.draw_box(self, size, color, label)
	else:
		Placeholder.draw_bricks(self, size, color)
