extends Node
## Renders Google Play / itch.io graphics into ../store/graphics. Needs a window:
##   godot --path . --resolution 1920x1080 res://tests/store_shots.tscn
## Produces 1920x1080 screenshots, a 1024x500 feature graphic and a 512x512 icon.

const OUT := "res://../store/graphics/"


func _ready() -> void:
	var out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out)
	GameState.save_path = "user://store_shots_save.json"
	GameState.scene_changes_enabled = false
	Settings.text_size = 0

	# Icon straight from the SVG.
	var icon: Texture2D = load("res://assets/icon.svg")
	icon.get_image().save_png(out + "icon_512.png")

	await _title(out)
	await _scene(out, "screenshot_1_well", "SC02", {"sc02_intro_seen": true}, func(s: StoryScene) -> void:
		s.player.global_position = Vector2(470, 290)
		s.dialogue.play("whisper"))
	await _scene(out, "screenshot_2_choice", "SC03", {"sc03_arrived": true}, func(s: StoryScene) -> void:
		s.player.global_position = Vector2(560, 300)
		s.dialogue.play("choice"))
	await _scene(out, "screenshot_3_husk", "SC05", {"sc05_arrived": true}, func(s: StoryScene) -> void:
		s._fighting = true
		# Store shots show the phone experience: no keyboard hints.
		s.hud.show_key_hints = false
		s.set_combat(true)
		s._refresh_objective()
		var husk: Husk = s.get_node("HuskOne")
		s.player.global_position = husk.global_position + Vector2(-58, 12)
		s.player.facing = Vector2.RIGHT
		husk.activate(s.player)
		husk._enter(Husk.State.WINDUP)
		husk._left = 0.25
		husk.set_physics_process(false)
		s.hud.show_caption("[husk creaks: winding up]"))
	await _scene(out, "screenshot_4_culvert", "SC06", {"sc06_arrived": true, "sc06_inspected": true}, func(s: StoryScene) -> void:
		s.player.global_position = Vector2(400, 300)
		s.dialogue.play("question"))
	await _flight_shot(self, out + "screenshot_5_flight.png")
	await _scene(out, "screenshot_6_reed_gate", "SC07", {"sc07_arrived": true}, func(s: StoryScene) -> void:
		s.player.global_position = Vector2(640, 250)
		s.dialogue.play("veya"))
	GameState.delete_save()
	get_tree().quit()


func _title(out: String) -> void:
	var title: Control = load("res://scenes/main.tscn").instantiate()
	add_child(title)
	await _save(out + "screenshot_0_title.png")
	title.queue_free()
	# Feature graphic: the backdrop and title at 1024x500.
	get_window().size = Vector2i(1024, 500)
	var feature := TextureRect.new()
	feature.texture = load("res://assets/art/title_backdrop.svg")
	feature.set_anchors_preset(Control.PRESET_FULL_RECT)
	feature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(feature)
	var label := Label.new()
	label.text = "The Unbroken Sky"
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
	label.add_theme_constant_override("outline_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 40
	feature.add_child(label)
	await _save(out + "feature_graphic.png", Vector2i(1024, 500))
	feature.queue_free()
	get_window().size = Vector2i(1920, 1080)


func _scene(out: String, file_name: String, scene_id: String, flags: Dictionary, setup: Callable) -> void:
	GameState.new_game()
	GameState.set_flag("scene_id", scene_id)
	for key: String in flags:
		GameState.set_flag(key, flags[key])
	var scene: StoryScene = load(GameState.SCENES[scene_id]).instantiate()
	scene.get_node("Dialogue").auto_finish = true
	add_child(scene)
	for i in 6:
		await get_tree().process_frame
	scene.get_node("Dialogue").auto_finish = false
	Settings.text_speed = 2
	setup.call(scene)
	await _save(out + file_name + ".png")
	Settings.text_speed = 0
	scene.queue_free()
	await get_tree().process_frame


## The 3D flight mid-link: banking towards the gust with the tower step ahead.
## Shared with tests/tour.gd.
static func _flight_shot(host: Node, path: String) -> void:
	GameState.new_game()
	for key: String in ["sc09_started", "sc09_voice_heard"]:
		GameState.set_flag(key, true)
	GameState.set_flag("scene_id", "SC09")
	GameState.set_flag("sc09_link", 1)
	var flight: Node3D = load("res://scenes/flight_3d.tscn").instantiate()
	flight.get_node("Dialogue").auto_finish = true
	host.add_child(flight)
	for i in 3:
		await host.get_tree().process_frame
	await flight.takeoff()
	flight.set_physics_process(false)
	flight._yaw = 0.45
	flight._pitch = 0.12
	flight._bank = 0.3
	flight.eagle.position = Vector3(22, 15, -84)
	flight.eagle.rotation = Vector3(flight._pitch, flight._yaw, 0)
	flight.eagle.bank = flight._bank
	flight.eagle.flap = 0.6
	flight.camera.fov = 80.0
	flight._update_camera(0.0, true)
	flight.hud.set_meter("WINGS", 0.7)
	flight._refresh_objective()
	for i in 20:
		await host.get_tree().process_frame
	await RenderingServer.frame_post_draw
	host.get_viewport().get_texture().get_image().save_png(path)
	flight.queue_free()
	await host.get_tree().process_frame


func _save(path: String, size := Vector2i.ZERO) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if size != Vector2i.ZERO and image.get_size() != size:
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(path)
