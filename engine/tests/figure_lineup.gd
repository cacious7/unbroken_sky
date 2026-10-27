extends Node3D
## Renders the whole cast in a row for visual review (needs a window):
##   godot --path . res://tests/figure_lineup.tscn -- <output_dir>

const ORDER := ["tavo", "sena", "mera", "daru", "nali", "veya", "kesi", "orun", "lio", "eren", "merchant", "figure"]


func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#c9a87a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8c0a0")
	environment.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 20)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#b08a5a")
	ground.material_override = ground_material
	add_child(ground)

	for i in ORDER.size():
		var figure := CastFigure.create(ORDER[i])
		figure.position = Vector3((i - (ORDER.size() - 1) / 2.0) * 1.15, 0, 0)
		add_child(figure)
		if ORDER[i] == "tavo":
			figure.rotation.y = PI * 0.25
		label(ORDER[i], figure.position)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.2, 9.5)
	add_child(camera)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	await _shot(out_dir + "/lineup_front.png")

	camera.position = Vector3(5, 2.0, -6.5)
	camera.look_at(Vector3(2, 0.95, 0))
	await _shot(out_dir + "/lineup_back.png")

	# Animation check: walk, strike, dodge on the first three.
	camera.position = Vector3(-4.5, 1.6, 4.0)
	camera.look_at(Vector3(-5.5, 0.9, 0))
	var figures := get_children().filter(func(n: Node) -> bool: return n is CastFigure)
	figures[0].play("strike")
	figures[1].play("walk")
	figures[2].play("talk")
	await get_tree().create_timer(0.35).timeout
	await _shot(out_dir + "/lineup_action.png")
	get_tree().quit()


func label(text: String, at: Vector3) -> void:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at + Vector3(0, 2.1, 0)
	tag.pixel_size = 0.004
	tag.font_size = 48
	tag.outline_size = 10
	add_child(tag)


func _shot(path: String) -> void:
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
