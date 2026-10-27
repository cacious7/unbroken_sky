extends Node2D
## Renders the vector art sample next to the greybox placeholders for comparison:
##   godot --path . res://tests/showcase.tscn -- <output_dir>

# Held as members: textures loaded inside _draw() would be freed before the frame renders.
var tavo: Texture2D = load("res://assets/art/tavo.svg")
var husk: Texture2D = load("res://assets/art/husk.svg")
var eagle: Texture2D = load("res://assets/art/eagle.svg")


func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	queue_redraw()
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/art_sample.png" % out_dir)
	get_tree().quit()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 960, 540), Color(0.7, 0.55, 0.42))
	draw_rect(Rect2(0, 200, 960, 200), Color(0.8, 0.7, 0.58))
	draw_rect(Rect2(318, 0, 4, 540), Color(0.2, 0.15, 0.1))
	draw_string(font, Vector2(0, 40), "GREYBOX NOW", HORIZONTAL_ALIGNMENT_CENTER, 320, 22, Color.BLACK)
	draw_string(font, Vector2(320, 40), "VECTOR ART SAMPLE (in-game size, then 2x)", HORIZONTAL_ALIGNMENT_CENTER, 640, 22, Color.BLACK)

	# Left: what the game uses today.
	draw_set_transform(Vector2(90, 300))
	Placeholder.draw_box(self, Vector2(20, 28), Color(0.25, 0.35, 0.6), "TAVO")
	draw_set_transform(Vector2(170, 300))
	Placeholder.draw_box(self, Vector2(28, 36), Color(0.45, 0.47, 0.5), "HUSK")
	draw_set_transform(Vector2.ZERO)

	# Right: SVG sprites at the scale they'd have in game, then enlarged.
	draw_texture_rect(tavo, Rect2(370, 270, 32, 48), false)
	draw_texture_rect(husk, Rect2(430, 264, 40, 54), false)
	draw_texture_rect(eagle, Rect2(500, 268, 80, 60), false)
	draw_texture_rect(tavo, Rect2(620, 150, 128, 192), false)
	draw_texture_rect(husk, Rect2(760, 160, 144, 192), false)
	draw_texture_rect(eagle, Rect2(640, 380, 256, 192 * 0.75), false)
