@tool
class_name Placeholder
extends RefCounted
## Shared drawing for world objects: sprite art where it exists, labelled boxes where it
## doesn't yet, and outlined labels that stay readable on light and dark ground.

const LABEL_COLOR := Color(0.98, 0.96, 0.9)
const LABEL_OUTLINE := Color(0.1, 0.07, 0.05, 0.85)


static func draw_box(item: CanvasItem, size: Vector2, color: Color, label: String) -> void:
	var rect := Rect2(-size / 2.0, size)
	item.draw_rect(rect, color)
	item.draw_rect(rect, color.darkened(0.45), false, 2.0)
	if label != "":
		draw_label(item, Vector2(0, -size.y / 2.0 - 6), label)


## A mud-brick wall: base colour with staggered mortar lines.
static func draw_bricks(item: CanvasItem, size: Vector2, color: Color) -> void:
	var rect := Rect2(-size / 2.0, size)
	item.draw_rect(rect, color)
	if size.x < 12.0 or size.y < 12.0:
		item.draw_rect(rect, color.darkened(0.35), false, 1.5)
		return
	var mortar := color.darkened(0.3)
	var row := 0
	var y := rect.position.y
	while y < rect.end.y:
		item.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), mortar, 1.0)
		var x := rect.position.x + (8.0 if row % 2 == 1 else 0.0)
		while x < rect.end.x:
			item.draw_line(Vector2(x, y), Vector2(x, minf(y + 8.0, rect.end.y)), mortar, 1.0)
			x += 16.0
		y += 8.0
		row += 1
	item.draw_rect(rect, color.darkened(0.45), false, 1.5)


## Where a sprite sits relative to its object's body: its own aspect ratio at `height`
## pixels tall (or the body's height), centred, or standing on the body's bottom edge.
static func art_rect(texture: Texture2D, body_size: Vector2, height: float, feet: bool) -> Rect2:
	var h := height if height > 0.0 else body_size.y
	var size := Vector2(h * texture.get_width() / float(texture.get_height()), h)
	var top := body_size.y / 2.0 - size.y if feet else -size.y / 2.0
	return Rect2(Vector2(-size.x / 2.0, top), size)


static func draw_art(item: CanvasItem, texture: Texture2D, rect: Rect2, label: String,
		modulate: Color = Color.WHITE) -> void:
	item.draw_texture_rect(texture, rect, false, modulate)
	if label != "":
		draw_label(item, Vector2(0, rect.position.y - 4), label)


static func draw_label(item: CanvasItem, bottom_centre: Vector2, label: String) -> void:
	var font := ThemeDB.fallback_font
	var position := bottom_centre + Vector2(-90, 0)
	item.draw_string_outline(font, position, label, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, 4, LABEL_OUTLINE)
	item.draw_string(font, position, label, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, LABEL_COLOR)
