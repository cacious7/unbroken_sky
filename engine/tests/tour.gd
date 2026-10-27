extends Node
## Renders one screenshot per Act One scene for visual review (needs a window):
##   godot --path . res://tests/tour.tscn -- <output_dir>
## Opening conversations are skipped so the scene itself is visible.

## Flags that put each scene just past its arrival conversation.
const SETUP := {
	"SC02": {"sc02_intro_seen": true},
	"SC03": {"sc03_arrived": true},
	"SC04": {"sc04_arrived": true},
	"SC05": {"sc05_arrived": true},
	"SC06": {"sc06_arrived": true},
	"SC07": {"sc07_arrived": true},
	"SC08": {"sc08_talked": true},
	"SC09": {"sc09_started": true},
	"SC10": {"sc10_arrived": true},
}


func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	GameState.save_path = "user://tour_save.json"
	GameState.scene_changes_enabled = false
	for scene_id: String in SETUP:
		GameState.new_game()
		GameState.set_flag("scene_id", scene_id)
		for key: String in SETUP[scene_id]:
			GameState.set_flag(key, SETUP[scene_id][key])
		var scene: StoryScene = load(GameState.SCENES[scene_id]).instantiate()
		scene.get_node("Dialogue").auto_finish = true
		add_child(scene)
		for i in 8:
			await get_tree().process_frame
		if scene_id == "SC08":
			scene.get_node("FloodWater").level = 470.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/tour_%s.png" % [out_dir, scene_id])
		scene.queue_free()
		await get_tree().process_frame
	GameState.delete_save()
	get_tree().quit()
