extends Node3D
## Small reactions make the same village layout worth exploring. No story locks.
var _view: Node3D
var _scene: Node2D
var _player: Player
var animals: Array[Dictionary] = []
var _plants: Array[Node3D] = []
var _blocked: Array[Rect2] = []
var _dust: CPUParticles3D
var _step_left := 0.0
var _time := 0.0
var _pump_tween: Tween
var _bird_tween: Tween


func configure(view: Node3D) -> void:
	_view = view
	_scene = view.get("scene") as Node2D
	_player = _scene.get_node("Player")


func _ready() -> void:
	if String(_scene.name) in ["WellYard", "Cistern", "AshRoad", "Culvert"]:
		_build_landscape()
		_build_dust()
		_blocked = NavGrid.solid_rects(_scene)
	for child in _view.get_children():
		if child.has_meta("reactive_chicken"):
			_register_chicken(child)
		elif child.has_meta("wind_plant"):
			_plants.append(child)
	if String(_scene.name) in ["WellYard", "Cistern"]:
		_clear_paved_plants()
	if _scene.name == "WellYard":
		_path([Vector3(5.5, 0.006, 10), Vector3(8.5, 0.006, 9), Vector3(10.5, 0.006, 6.7), Vector3(12.5, 0.006, 5.7)])
		_path([Vector3(12.5, 0.007, 5.7), Vector3(15.4, 0.007, 8), Vector3(17.5, 0.007, 12.7)])


func _register_chicken(holder: Node3D) -> void:
	var clips := {"run": "", "idle": ""}
	var animator: AnimationPlayer
	for found: AnimationPlayer in holder.find_children("", "AnimationPlayer", true, false):
		animator = found
		for clip in animator.get_animation_list():
			if clip.ends_with("Run"):
				clips.run = clip
			elif clip.ends_with("Idle_Peck"):
				clips.idle = clip
	animals.append({"node": holder, "home": holder.position, "panic": 0.0, "animator": animator, "clips": clips})


func _process(delta: float) -> void:
	_time += delta
	var player := Vector3(_player.position.x * 0.025, 0, _player.position.y * 0.025)
	for animal: Dictionary in animals:
		_update_animal(animal, player, delta)
	for i in _plants.size():
		var plant := _plants[i]
		var brush := maxf(0.0, 1.0 - plant.position.distance_to(player)) * 0.15
		plant.rotation.z = sin(_time * 1.4 + i * 0.7) * 0.035 + brush
	if _dust != null:
		var moving := _player.active and _player.velocity.length() > 45.0
		_dust.emitting = moving
		_dust.position = player + Vector3(0, 0.03, 0)
		_step_left -= delta
		if moving and _step_left <= 0.0:
			_step_left = 0.27
			Sfx.play("sand_step", -21.0, 0.9 + sin(_time * 7.0) * 0.1)


func _update_animal(animal: Dictionary, player: Vector3, delta: float) -> void:
	var holder := animal.node as Node3D
	var away := holder.position - player
	away.y = 0.0
	if _player.active and away.length() < 2.0:
		animal.panic = 0.85
	animal.panic = maxf(0.0, animal.panic - delta)
	var direction := Vector3.ZERO
	var speed := 0.0
	if animal.panic > 0.0:
		direction = away.normalized() if away.length() > 0.05 else Vector3.RIGHT
		speed = 2.8
	elif holder.position.distance_to(animal.home) > 0.3:
		direction = (animal.home as Vector3) - holder.position
		direction = direction.normalized()
		speed = 0.65
	if speed > 0.0:
		var proposed := holder.position + direction * speed * delta
		proposed.x = clampf(proposed.x, 1.0, 23.0)
		proposed.z = clampf(proposed.z, 1.0, 12.6)
		var point := Vector2(proposed.x, proposed.z) / 0.025
		if not _blocked.any(func(rect: Rect2) -> bool: return rect.grow(8.0).has_point(point)):
			holder.position = proposed
			holder.rotation.y = lerp_angle(holder.rotation.y, atan2(-direction.x, -direction.z), minf(delta * 10.0, 1.0))
	var animator := animal.animator as AnimationPlayer
	if animator != null:
		var clip: String = animal.clips.run if speed > 0.0 else animal.clips.idle
		if clip != "" and animator.current_animation != clip:
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			animator.play(clip, 0.12)
		animator.speed_scale = 1.2 if animal.panic > 0.0 else (0.5 if speed > 0.0 else 1.0)


func pulse_pump() -> void:
	var handle := _view.get_node_or_null("Pump3D/PumpHandle") as Node3D
	if handle == null:
		return
	if _pump_tween != null:
		_pump_tween.kill()
	handle.rotation.x = -0.5
	_pump_tween = create_tween()
	_pump_tween.tween_property(handle, "rotation:x", 0.25 if GameState.get_flag("sc02_pump_repaired") else -0.35, 0.13)
	_pump_tween.tween_property(handle, "rotation:x", -0.5, 0.16)


func spin_bird() -> void:
	var toy := _view.get_node_or_null("Bird3D/CopperBird") as Node3D
	if toy == null:
		return
	if _bird_tween != null:
		_bird_tween.kill()
	_bird_tween = create_tween()
	_bird_tween.tween_property(toy, "rotation:y", toy.rotation.y + TAU * 2.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Sfx.play("wind_gain", -20.0, 1.5)


func _build_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.amount = 12
	_dust.lifetime = 0.45
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = 0.12
	_dust.direction = Vector3.UP
	_dust.spread = 65
	_dust.initial_velocity_min = 0.15
	_dust.initial_velocity_max = 0.35
	_dust.gravity = Vector3(0, -0.1, 0)
	var grain := SphereMesh.new()
	grain.radius = 0.018
	grain.height = 0.036
	grain.radial_segments = 6
	grain.rings = 3
	_dust.mesh = grain
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ae8860")
	_dust.material_override = material
	_dust.emitting = false
	add_child(_dust)


func _build_landscape() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 94
	noise.frequency = 0.035
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 32:
		for x in 32:
			var a := _terrain_point(x, z, noise)
			var b := _terrain_point(x + 1, z, noise)
			var c := _terrain_point(x, z + 1, noise)
			var d := _terrain_point(x + 1, z + 1, noise)
			for point: Vector3 in [a, b, c, b, d, c]:
				surface.add_vertex(point)
	surface.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.name = "SurroundingHills"
	terrain.mesh = surface.commit()
	terrain.material_override = Materials3D.get_material("red_earth", Color("#c1aa90"))
	add_child(terrain)


func _terrain_point(x: int, z: int, noise: FastNoiseLite) -> Vector3:
	var point := Vector3(12 + (x - 16) * 5.0, -0.12, 6 + (z - 16) * 5.0)
	var distance := Vector2(point.x - 12, point.z - 6).length()
	var hills := smoothstep(22.0, 50.0, distance)
	point.y += hills * (4.5 + noise.get_noise_2d(point.x, point.z) * 6.0)
	return point


func _path(points: Array[Vector3]) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.12
	for i in points.size():
		var previous := points[maxi(0, i - 1)]
		var next := points[mini(points.size() - 1, i + 1)]
		var tangent := (next - previous) / 6.0
		curve.add_point(points[i], -tangent, tangent)
	var baked := curve.get_baked_points()
	var sides := PackedVector3Array()
	for i in baked.size():
		var along := (baked[mini(i + 1, baked.size() - 1)] - baked[maxi(0, i - 1)]).normalized()
		sides.append(Vector3(along.z, 0, -along.x) * (0.55 + sin(i * 0.31) * 0.025))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(baked.size() - 1):
		var a := baked[i] - sides[i]
		var b := baked[i] + sides[i]
		var c := baked[i + 1] - sides[i + 1]
		var d := baked[i + 1] + sides[i + 1]
		for data: Array in [[a, Vector2(0, 0)], [b, Vector2(1, 0)], [c, Vector2(0, 1)],
				[b, Vector2(1, 0)], [d, Vector2(1, 1)], [c, Vector2(0, 1)]]:
			surface.set_uv(data[1])
			surface.add_vertex(data[0])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "WornPath"
	mesh.mesh = surface.commit()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/footpath.gdshader")
	material.set_shader_parameter("soil", load("res://assets/third_party/polyhaven/textures/red_laterite_soil_stones/red_laterite_soil_stones_diff_1k.jpg"))
	mesh.material_override = material
	add_child(mesh)
	for item in _plants.duplicate():
		var plant := item as Node3D
		if curve.get_closest_point(plant.position).distance_to(plant.position) < 0.65:
			plant.visible = false
			_plants.erase(plant)


func _clear_paved_plants() -> void:
	for item in _plants.duplicate():
		var plant := item as Node3D
		var grid := Vector2(plant.position.x * 0.8, plant.position.z * 1.6)
		grid.x += fposmod(floorf(grid.y), 2.0) * 0.5
		var cell := grid.floor()
		var random := sin(cell.dot(Vector2(127.1, 311.7))) * 43758.5453
		if random - floorf(random) >= 0.09:
			plant.visible = false
			_plants.erase(plant)
