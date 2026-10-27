extends Node
## Renders UI states to PNG for visual review (needs a window, not --headless):
##   godot --path . res://tests/screenshot.tscn -- <output_dir>

func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	GameState.save_path = "user://screenshot_save.json"
	GameState.scene_changes_enabled = false
	Settings.path = "user://screenshot_settings.json"
	for size in [0, 2]:
		Settings.text_size = size
		GameState.new_game()
		GameState.set_flag("scene_id", "SC03")
		GameState.set_flag("sc03_arrived", true)
		var cistern: StoryScene = load("res://scenes/cistern.tscn").instantiate()
		add_child(cistern)
		await _frames(5)
		await _shot("%s/cistern_%d.png" % [out_dir, size])
		cistern.use(cistern.get_node("Daru"))
		await _frames(5)
		await _shot("%s/choice_%d.png" % [out_dir, size])
		cistern.pause_menu.open()
		await _frames(5)
		await _shot("%s/pause_%d.png" % [out_dir, size])
		cistern.pause_menu.close()
		cistern.queue_free()
		await _frames(2)
	Settings.text_size = 0

	# Combat tells: windup glow, then the exposed connector.
	GameState.new_game()
	GameState.set_flag("sc05_arrived", true)
	var road: StoryScene = load("res://scenes/ash_road.tscn").instantiate()
	add_child(road)
	await _frames(3)
	var husk: Husk = road.get_node("HuskOne")
	road.player.global_position = husk.global_position + Vector2(-60, 10)
	road.set_combat(true)
	husk.activate(road.player)
	husk._enter(Husk.State.WINDUP)
	husk._left = 0.3
	road.hud.show_caption("[husk creaks: winding up]")
	husk.queue_redraw()
	await _frames(2)
	husk.set_physics_process(false)
	await _shot("%s/combat_windup.png" % out_dir)
	husk._enter(Husk.State.RECOVERY)
	road.hud.show_caption("[strike interrupted: connector exposed]")
	await _shot("%s/combat_recovery.png" % out_dir)
	road.queue_free()
	await _frames(2)


	GameState.delete_save()
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
