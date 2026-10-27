@tool
class_name Placeholder
extends RefCounted
## Draws labelled boxes for greybox scenes until real art replaces them.

const LABEL_COLOR := Color(0.12, 0.09, 0.07)


static func draw_box(item: CanvasItem, size: Vector2, color: Color, label: String) -> void:
	var rect := Rect2(-size / 2.0, size)
	item.draw_rect(rect, color)
	item.draw_rect(rect, color.darkened(0.45), false, 2.0)
	if label != "":
		item.draw_string(ThemeDB.fallback_font, Vector2(-90, -size.y / 2.0 - 6), label,
				HORIZONTAL_ALIGNMENT_CENTER, 180, 13, LABEL_COLOR)
