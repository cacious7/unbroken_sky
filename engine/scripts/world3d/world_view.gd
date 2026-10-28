class_name WorldView
extends Node3D
## The 3D presentation of a story scene. The scene's 2D layout stays the gameplay
## model (movement, collisions, reach, combat, saves and tests are unchanged); this
## view rebuilds it in 3D and follows it every frame: ground and walls, props and
## characters (Props3D / CastFigure), Tavo, husks, the water rope, the flood, markers,
## lighting and a camera following Tavo. Taps on the 3D ground map back to 2D.
## One 2D pixel = 2.5 cm, so a 960x540 room is 24 m x 13.5 m.

const METRES_PER_PIXEL := 1.0 / 40.0
const ROOM := Vector2(24.0, 13.5)
const CAMERA_OFFSET := Vector3(0, 7.8, 7.4)

## Lighting per scene (keyed by the scene's root node name).
const MOODS := {
	"WellYard": {"hdri": "qwantani_dawn_puresky", "sky": "#7fa8d0", "horizon": "#f2cf98", "sun": Vector3(-38, -30, 0), "sun_color": "#ffe2b8", "energy": 1.15, "ambient": 0.55, "outdoor": true, "fog": 0.0015},
	"Cistern": {"hdri": "qwantani_noon_puresky", "sky": "#86b2d8", "horizon": "#f0d6a8", "sun": Vector3(-55, -20, 0), "sun_color": "#fff0d8", "energy": 1.2, "ambient": 0.55, "outdoor": true, "fog": 0.0},
	"Home": {"sky": "#3a2a20", "horizon": "#6a4a30", "sun": Vector3(-62, 25, 0), "sun_color": "#ffd8a0", "energy": 0.9, "ambient": 0.7, "outdoor": false, "fog": 0.0},
	"AshRoad": {"hdri": "qwantani_noon_puresky", "sky": "#a8c4dc", "horizon": "#f8e0b0", "sun": Vector3(-68, -10, 0), "sun_color": "#fff6e0", "energy": 1.35, "ambient": 0.5, "outdoor": true, "fog": 0.0},
	"Culvert": {"hdri": "mpumalanga_veld_puresky", "sky": "#8a90b8", "horizon": "#f0a870", "sun": Vector3(-22, -55, 0), "sun_color": "#ffb878", "energy": 1.1, "ambient": 0.45, "outdoor": true, "fog": 0.004},
	"ReedGate": {"hdri": "qwantani_sunrise_puresky", "sky": "#8a96a4", "horizon": "#c8c0b0", "sun": Vector3(-45, 30, 0), "sun_color": "#e8e4dc", "energy": 0.85, "ambient": 0.6, "outdoor": true, "fog": 0.0},
	"KeeperRoom": {"sky": "#141a20", "horizon": "#26303a", "sun": Vector3(-70, 10, 0), "sun_color": "#a8c0d8", "energy": 0.55, "ambient": 0.35, "outdoor": false, "fog": 0.0},
	"WheelPlatform": {"hdri": "mpumalanga_veld_puresky", "sky": "#5a6a9a", "horizon": "#e89a68", "sun": Vector3(-20, 40, 0), "sun_color": "#ffb080", "energy": 1.0, "ambient": 0.5, "outdoor": true, "fog": 0.0},
}

var scene: StoryScene
var camera: Camera3D
var tavo: CastFigure
var shake_offset := Vector2.ZERO
## [2D node, 3D node, Label3D or null] for objects whose visibility or label can change.
var _mirrors: Array = []
var _husks: Array[Husk3D] = []
var _rope: Node3D
var _rope_ring: MeshInstance3D
var _rope_column: MeshInstance3D
var _flood: MeshInstance3D
var _focus_ring: MeshInstance3D
var _last_health := Player.MAX_HEALTH
var _shot: Dictionary = {}
var _speaking: CastFigure
var _carried_pipe: MeshInstance3D
var _life: Node3D
var first_person: Node3D
var _collapsing := false
var _collapse_time := 0.0


static func to_3d(point: Vector2, height := 0.0) -> Vector3:
	return Vector3(point.x * METRES_PER_PIXEL, height, point.y * METRES_PER_PIXEL)


static func to_2d(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z) / METRES_PER_PIXEL


func _init(story_scene: StoryScene) -> void:
	scene = story_scene
	name = "WorldView"


func _ready() -> void:
	var mood: Dictionary = MOODS.get(String(scene.name), MOODS.WellYard)
	_build_environment(mood)
	for child in scene.get_children():
		_build_object(child)
	if String(scene.name) in ["WellYard", "Cistern", "AshRoad", "Culvert"]:
		_scatter_nature()
	_dress_surroundings()
	_build_player()
	_build_focus_ring()
	_build_story_props()
	_life = preload("res://scripts/world3d/world_life.gd").new()
	_life.configure(self)
	add_child(_life)
	if scene.name == "KeeperRoom":
		_build_keeper_landings()
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 200.0
	add_child(camera)
	camera.current = true
	first_person = preload("res://scripts/world3d/first_person_rig.gd").new()
	first_person.configure(self, camera)
	add_child(first_person)
	_update_camera(0.0, true)


## Screen position (e.g. a tap) -> point on the 2D gameplay plane, or null if the tap
## does not hit the ground.
func screen_to_world_2d(screen_point: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_point)
	var direction := camera.project_ray_normal(screen_point)
	if absf(direction.y) < 0.0001:
		return null
	if scene.name == "KeeperRoom":
		var best := INF
		var hit: Variant = null
		for i in 31:
			var height := i * 0.15
			var along := (height - origin.y) / direction.y
			if along <= 0.0 or along >= best:
				continue
			var point := to_2d(origin + direction * along)
			if absf(keeper_height(point) - height) < 0.02:
				best = along
				hit = point
		return hit
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return null
	return to_2d(origin + direction * distance)


func _process(delta: float) -> void:
	if _collapsing:
		_collapse_time += delta
		tavo.position.y -= (1.0 + _collapse_time * 12.0) * delta
		tavo.rotation.z += delta * 0.5
	else:
		_sync_player()
	var player_3d := to_3d(scene.player.global_position)
	for husk_view in _husks:
		husk_view.sync(to_3d, player_3d)
	for mirror: Array in _mirrors:
		var source: CanvasItem = mirror[0]
		var model := mirror[1] as Node3D
		model.visible = source.visible
		if source is Interactable:
			if model is Label3D:
				model.position = to_3d(source.global_position, 2.3)
				model.visible = false # Context comes from the aimed HUD prompt, not floating names.
			else:
				model.position = to_3d(source.global_position)
		if mirror[2] != null and source.get("label") != null:
			(mirror[2] as Label3D).text = source.label
	_sync_rope()
	_sync_flood()
	_sync_focus()
	_sync_story_props(delta)
	_update_camera(delta)


# --- Building ---------------------------------------------------------------------

func _build_environment(mood: Dictionary) -> void:
	var environment := Environment.new()
	if mood.outdoor:
		# A real photographed sky (Poly Haven HDRI, mostly shot in South Africa) both
		# shows above the horizon and lights the scene with its true colours.
		var sky_material := PanoramaSkyMaterial.new()
		sky_material.panorama = load("res://assets/third_party/polyhaven/hdri/%s_1k.hdr" % mood.hdri)
		var sky := Sky.new()
		sky.sky_material = sky_material
		environment.background_mode = Environment.BG_SKY
		environment.sky = sky
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		environment.ambient_light_energy = mood.ambient * 0.9
	else:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(mood.sky)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(mood.horizon).lightened(0.4)
		environment.ambient_light_energy = mood.ambient * 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.3
	environment.glow_bloom = 0.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.05
	if mood.fog > 0.0:
		environment.fog_enabled = true
		environment.fog_light_color = Color(mood.horizon)
		environment.fog_density = mood.fog
		environment.fog_sky_affect = 0.1
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = mood.sun
	sun.light_color = Color(mood.sun_color)
	sun.light_energy = mood.energy * 0.9
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)


func _build_object(child: Node) -> void:
	if child is ColorRect:
		_build_surface(child)
	elif child is Interactable:
		var size: Vector2 = child.body_size * METRES_PER_PIXEL
		var model := Props3D.build(String(child.name), size)
		if model == null:
			model = Props3D.wall(size, true, 0.6)
		model.position = to_3d(child.global_position)
		add_child(model)
		var tag: Label3D = null
		if child.show_label or child.name == "Exit" or Props3D.FIGURES.has(String(child.name)):
			tag = _label(child.label, model.position + Vector3(0, 2.3, 0))
		_mirrors.append([child, model, tag])
		if tag != null:
			_mirrors.append([child, tag, null])
	elif child is Husk:
		var view := Husk3D.new(child)
		add_child(view)
		_husks.append(view)
	elif child is WaterRope:
		_build_rope(child)
	elif child is FloodWater:
		_build_flood()
	elif child is StaticBody2D and child.get("size") != null:
		_build_block(child)
	elif child is Node2D and child.get_script() == preload("res://scripts/marker.gd"):
		_build_marker(child)


func _build_surface(rect: ColorRect) -> void:
	var size := rect.size * METRES_PER_PIXEL
	var center := to_3d(rect.position + rect.size / 2.0)
	var layer := -0.06 if rect.name == "Ground" else -0.04 + 0.002 * rect.get_index() / 10.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.1, size.y)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = Materials3D.for_surface(String(scene.name), String(rect.name), rect.color)
	instance.position = center + Vector3(0, layer, 0)
	add_child(instance)


func _build_block(block: Node2D) -> void:
	var size: Vector2 = block.size * METRES_PER_PIXEL
	var model := Props3D.build(String(block.name), size)
	if model == null:
		var stone := String(scene.name) in ["ReedGate", "KeeperRoom", "WheelPlatform", "AshRoad", "Culvert"]
		# Walls stay low (a cutaway) so the overhead camera always sees Tavo; only the
		# fortress wall along the far edge stands tall.
		var height := 1.0
		if block.name.begins_with("Ledge"):
			height = {"LedgeLow": 1.5, "LedgeMiddle": 3.0, "LedgeHigh": 4.5}.get(String(block.name), 0.8) if scene.name == "KeeperRoom" else 0.8
		elif block.label == "FORTRESS WALL":
			height = 3.2
		elif block.name.begins_with("Edge"):
			height = 0.7
		model = Props3D.wall(size, stone, height)
	model.position = to_3d(block.global_position)
	add_child(model)
	if scene.name != "KeeperRoom" and block.label != "" and block.get("show_label") != false and not Props3D.FIGURES.has(String(block.name)) \
			and block.label != "FORTRESS WALL":
		_label(block.label, model.position + Vector3(0, 2.0, 0))
	elif Props3D.FIGURES.has(String(block.name)) and scene.name != "KeeperRoom":
		_label(block.label, model.position + Vector3(0, 2.3, 0))


func _build_marker(marker: Node2D) -> void:
	if scene.name == "KeeperRoom":
		if String(marker.name).begins_with("Stair"):
			var levels := {"StairOne": 0.0, "StairTwo": 1.5, "StairThree": 3.0}
			var stairs := Props3D.staircase(5.1)
			stairs.name = marker.name + "3D"
			stairs.position = to_3d(marker.position + Vector2(0, 48), levels[String(marker.name)])
			add_child(stairs)
			return
		if marker.name == "BrokenWall":
			_build_broken_exit(marker.position)
			return
	var size: Vector2 = marker.size * METRES_PER_PIXEL
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.04, size.y)
	plate.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(marker.color, 1.0)
	material.emission_enabled = true
	material.emission = Color(marker.color, 1.0) * 0.3
	plate.material_override = material
	plate.position = to_3d(marker.global_position, 0.02)
	add_child(plate)
	_label(marker.label, plate.position + Vector3(0, 0.6, 0))


func _build_rope(rope: WaterRope) -> void:
	_rope = Node3D.new()
	add_child(_rope)
	_rope.set_meta("source", rope)
	_rope_column = _simple(CylinderMesh.new(), Color("#1f3346"), Vector3(0, 0.9, 0))
	(_rope_column.mesh as CylinderMesh).top_radius = 0.18
	(_rope_column.mesh as CylinderMesh).bottom_radius = 0.32
	(_rope_column.mesh as CylinderMesh).height = 1.8
	_rope.add_child(_rope_column)
	var hook := _simple(TorusMesh.new(), Color("#c97a36"), Vector3(0, 0.45, -0.3))
	(hook.mesh as TorusMesh).inner_radius = 0.08
	(hook.mesh as TorusMesh).outer_radius = 0.13
	hook.rotation.x = PI / 2.0
	hook.name = "Hook"
	_rope.add_child(hook)
	_rope_ring = _simple(CylinderMesh.new(), Color(0.35, 0.6, 1.0, 0.3), Vector3(0, 0.03, 0))
	var radius := WaterRope.SWEEP_RADIUS * METRES_PER_PIXEL
	(_rope_ring.mesh as CylinderMesh).top_radius = radius
	(_rope_ring.mesh as CylinderMesh).bottom_radius = radius
	(_rope_ring.mesh as CylinderMesh).height = 0.02
	var ring_material := _rope_ring.material_override as StandardMaterial3D
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rope.add_child(_rope_ring)


func _build_flood() -> void:
	_flood = _simple(BoxMesh.new(), Color(0.1, 0.18, 0.26, 0.85), Vector3.ZERO)
	var material := _flood.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	add_child(_flood)


func _build_player() -> void:
	tavo = CastFigure.create("tavo")
	add_child(tavo)
	scene.player.struck.connect(func(_result: String) -> void: tavo.play("strike", 1.3))
	scene.player.dodged.connect(func() -> void: tavo.play("dodge", 1.4))


func _build_focus_ring() -> void:
	_focus_ring = _simple(TorusMesh.new(), Color(1.0, 0.9, 0.5), Vector3.ZERO)
	(_focus_ring.mesh as TorusMesh).inner_radius = 0.55
	(_focus_ring.mesh as TorusMesh).outer_radius = 0.65
	(_focus_ring.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_focus_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_focus_ring)


## What lies around each scene, mostly beyond its walls: Red Hollow's round thatched
## huts and baobab, chickens and goats in the yard, a donkey on the road, reeds and
## boats in the river world. (CC0 Quaternius animals; CC-BY huts, trees and reeds are
## credited in ASSET_REGISTER.md.)
func _dress_surroundings() -> void:
	match String(scene.name):
		"WellYard", "Cistern":
			# Red Hollow: round thatched huts beyond the compound walls.
			for spot: Array in [[-2.5, -3.0, 2.0], [5.0, -4.5, 2.3], [12.0, -3.5, 1.8], [19.5, -4.2, 2.2],
					[27.0, -2.0, 2.0], [-3.5, 6.0, 1.8], [27.5, 9.0, 2.1], [8.5, -8.0, 1.6], [16.0, -9.0, 2.0]]:
				var hut := Civilisation3D.block(spot[2] * 1.8, spot[2] * 1.6, 2 + int(spot[0] + 20) % 2, int(spot[0] + 20))
				hut.position = Vector3(spot[0], 0, spot[1])
				hut.rotation.y = atan2(ROOM.x / 2.0 - spot[0], ROOM.y / 2.0 - spot[1])
				add_child(hut)
			var relay := Civilisation3D.relay(12.0)
			relay.position = Vector3(12, 0, -13)
			add_child(relay)
			for location: Vector3 in [Vector3(12, 0, 4.8), Vector3(10.8, 0, 1.8)]:
				var line := Civilisation3D.service_line(7.0)
				line.position = location
				if location.x < 12:
					line.rotation.y = PI / 2.0
				add_child(line)
			_place("polypizza/baobab.glb", Vector3(-6.0, 0, -6.0), 7.0)
			for i in 3:
				_animal("polypizza/chicken.glb", "Idle_Peck", Vector3(14.0 + i * 1.3, 0, 10.5 - i * 0.8), 0.45, i * 1.7)
			if String(scene.name) == "Cistern":
				_utility_carrier(Vector3(25.5, 0, 3.0), -1.2)
		"AshRoad":
			_place("polypizza/acacia.glb", Vector3(4.0, 0, -3.5), 6.0)
			_place("polypizza/acacia.glb", Vector3(17.0, 0, -4.0), 7.0, 1.3)
			_place("polypizza/savanna_tree.glb", Vector3(26.5, 0, 6.0), 4.0)
			_utility_carrier(Vector3(19.5, 0, 11.2), 0.4)
			_utility_carrier(Vector3(10.5, 0, 12.6), 0.3)
		"Culvert":
			_place("polypizza/acacia.glb", Vector3(-3.0, 0, 2.0), 6.0)
			_place("polypizza/savanna_tree.glb", Vector3(27.0, 0, 10.0), 4.0, 2.0)
		"ReedGate":
			for i in 9:
				_place("polypizza/cattail.glb", Vector3(1.5 + i * 2.6, 0, 2.6 + (i % 2) * 0.4), 1.1, i * 0.8)
			_place("polypizza/boat.glb", Vector3(15.0, 0.05, 1.2), 3.0, 0.3)
			_place("polypizza/stone_wall_towers.glb", Vector3(12.0, 0, -6.0), 22.0)
		"WheelPlatform":
			_place("polypizza/canoe.glb", Vector3(-1.5, 0.05, 6.0), 3.5, 1.4)
			_place("polypizza/dock_wide.glb", Vector3(24.2, 0, 10.5), 3.0, PI / 2.0)
			for i in 6:
				_place("polypizza/cattail.glb", Vector3(0.6, 0, 1.0 + i * 2.2), 1.2, i)


func _place(path: String, at: Vector3, fit: float, turn := 0.0) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = turn
	add_child(holder)
	Props3D._model(holder, path, fit)
	return holder


func _animal(path: String, clip_suffix: String, at: Vector3, fit: float, turn := 0.0) -> void:
	var holder := _place(path, at, fit, turn)
	if path.ends_with("chicken.glb"):
		holder.set_meta("reactive_chicken", true)
	for player: AnimationPlayer in holder.find_children("", "AnimationPlayer", true, false):
		for clip in player.get_animation_list():
			if clip.ends_with(clip_suffix):
				player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				player.play(clip)
				player.seek(randf() * 2.0)
				break


## Grass, bushes, rocks and a few acacias on open ground, clear of walls, objects and
## the spaces people walk through.
func _scatter_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(scene.name))
	var blocked: Array[Rect2] = []
	for rect in NavGrid.solid_rects(scene):
		blocked.append(rect.grow(36))
	for child in scene.get_children():
		if child is Interactable or child is Husk or child is WaterRope:
			blocked.append(Rect2(child.global_position - Vector2(70, 70), Vector2(140, 140)))
	blocked.append(Rect2(scene.player.global_position - Vector2(80, 80), Vector2(160, 160)))
	# Mostly dry grass and low bushes; just a few small stones.
	var small := ["kenney/nature/grass.glb", "kenney/nature/grass_large.glb", "kenney/nature/grass_leafs.glb", "kenney/nature/plant_bushSmall.glb",
			"kenney/nature/grass_large.glb", "kenney/nature/plant_flatShort.glb", "kenney/nature/grass.glb", "kenney/nature/rock_smallFlatA.glb"]
	var placed := 0
	var attempts := 0
	while placed < 30 and attempts < 600:
		attempts += 1
		var point := Vector2(rng.randf_range(40, 920), rng.randf_range(40, 500))
		if blocked.any(func(rect: Rect2) -> bool: return rect.has_point(point)):
			continue
		var path: String = small[rng.randi() % small.size()]
		var holder := Node3D.new()
		holder.position = to_3d(point)
		holder.rotation.y = rng.randf() * TAU
		add_child(holder)
		Props3D._model(holder, path, rng.randf_range(0.4, 0.9))
		if not path.contains("rock"):
			holder.set_meta("wind_plant", true)
		placed += 1
	# A few acacias along the far (top) edge, where they frame the scene without
	# blocking the camera's view of Tavo.
	for x: float in [90.0, 470.0, 860.0]:
		var spot := Vector2(x + rng.randf_range(-40, 40), rng.randf_range(30, 70))
		if blocked.any(func(rect: Rect2) -> bool: return rect.has_point(spot)):
			continue
		var tree := Node3D.new()
		tree.position = to_3d(spot)
		add_child(tree)
		Props3D._model(tree, "polypizza/savanna_tree.glb", rng.randf_range(3.0, 4.0))


# --- Following the gameplay -------------------------------------------------------

func _sync_player() -> void:
	var player := scene.player
	tavo.visible = player.visible
	tavo.position = to_3d(player.global_position, keeper_height(player.global_position) if scene.name == "KeeperRoom" else 0.0)
	var facing := player.facing
	if facing.length() > 0.1:
		var target := atan2(-facing.x, -facing.y)
		tavo.rotation.y = lerp_angle(tavo.rotation.y, target, 0.25)
	tavo.set_moving(player.velocity.length() > 10.0, player.velocity.length() / Player.SPEED, player.velocity.length() > Player.SPEED * 0.8)
	if player.health < _last_health:
		tavo.play("hit")
	_last_health = player.health
	# Brief transparency while protected after a hit.
	tavo.visible = player.visible and not (player.is_protected() and int(Time.get_ticks_msec() / 80) % 2 == 0 \
			and player.health < Player.MAX_HEALTH and not player.is_dodging())


func _sync_rope() -> void:
	if _rope == null:
		return
	var rope: WaterRope = _rope.get_meta("source")
	_rope.visible = rope.visible
	_rope.position = to_3d(rope.global_position)
	_rope_ring.visible = rope.state in [WaterRope.State.TELEGRAPH, WaterRope.State.SWEEP]
	var ring_material := _rope_ring.material_override as StandardMaterial3D
	if rope.state == WaterRope.State.TELEGRAPH:
		var progress := 1.0 - rope._left / WaterRope.TELEGRAPH_SECONDS
		ring_material.albedo_color = Color(0.35, 0.6, 1.0, 0.12 + 0.3 * progress)
	elif rope.state == WaterRope.State.SWEEP:
		ring_material.albedo_color = Color(0.4, 0.7, 1.0, 0.6)
	_rope_column.visible = rope.state != WaterRope.State.BROKEN and rope.state != WaterRope.State.DORMANT
	var hook := _rope.get_node("Hook") as MeshInstance3D
	(hook.material_override as StandardMaterial3D).albedo_color = \
			Color("#ffd080") if rope.state == WaterRope.State.EXPOSED else Color("#c97a36")


func _sync_flood() -> void:
	if _flood == null:
		return
	var flood: FloodWater = scene.get_node("FloodWater")
	var top := flood.level * METRES_PER_PIXEL
	var bottom := ROOM.y + 0.5
	(_flood.mesh as BoxMesh).size = Vector3(ROOM.x, 0.5, maxf(bottom - top, 0.01))
	var water_top := maxf(0.25, (520.0 - flood.level) * 0.0125) if scene.name == "KeeperRoom" else 0.45
	(_flood.mesh as BoxMesh).size.y = water_top + 0.5
	_flood.position = Vector3(ROOM.x / 2.0, (water_top - 0.5) * 0.5, (top + bottom) / 2.0)


func _sync_focus() -> void:
	var target := scene.player.focus_target()
	_focus_ring.visible = target != null and scene.player.active and first_person == null
	if target != null:
		_focus_ring.position = to_3d(target.global_position, 0.05)
		var radius := maxf(target.body_size.x, target.body_size.y) * METRES_PER_PIXEL * 0.5 + 0.35
		_focus_ring.scale = Vector3(radius / 0.6, 1.0, radius / 0.6)


func _update_camera(delta: float, snap := false) -> void:
	if _collapsing:
		var center := tavo.position + Vector3.UP
		camera.position = camera.position.lerp(center + Vector3(3.5, 2.0, 4.5), minf(delta * 8.0, 1.0))
		camera.look_at(center, Vector3.UP)
		return
	if not _shot.is_empty():
		var subject := scene.get_node_or_null(str(_shot.get("target", "Player"))) as Node2D
		if subject != null:
			var focus := to_3d(subject.global_position, float(_shot.get("height", 1.2)))
			if _shot.has("bone"):
				var figure := figure_for(str(_shot.get("target", "Player")))
				if figure != null:
					focus = figure.bone_position(str(_shot.bone))
			var offset := Vector3(float(_shot.get("side", 1.4)), float(_shot.get("rise", 0.6)), float(_shot.get("distance", 3.0)))
			var actor := figure_for(str(_shot.get("target", "Player")))
			if actor != null:
				if _shot.has("bone"):
					var outward := focus - actor.global_position
					outward.y = 0.0
					outward = outward.normalized()
					offset = outward * 0.25 + Vector3.UP * float(_shot.get("rise", 0.2)) - actor.global_basis.z * float(_shot.get("distance", 0.8))
				else:
					offset = actor.global_basis * Vector3(offset.x, offset.y, -offset.z)
			camera.position = camera.position.lerp(focus + offset, 1.0 if snap else 1.0 - exp(-7.0 * delta))
			camera.look_at(focus, Vector3.UP)
			camera.fov = lerpf(camera.fov, float(_shot.get("fov", 44.0)), 0.2)
			return
	if first_person != null:
		first_person.update_camera(delta, snap)
		return
	camera.fov = lerpf(camera.fov, 50.0, 0.15)
	var focus := to_3d(scene.player.global_position, keeper_height(scene.player.global_position) if scene.name == "KeeperRoom" else 0.0)
	focus.x = clampf(focus.x, 5.0, ROOM.x - 5.0)
	focus.z = clampf(focus.z, 2.5, ROOM.y - 1.0)
	var target := focus + CAMERA_OFFSET
	var weight := 1.0 if snap else 1.0 - exp(-4.0 * delta)
	camera.position = camera.position.lerp(target, weight)
	camera.look_at(camera.position - CAMERA_OFFSET + Vector3(0, 0.6, 0), Vector3.UP)
	camera.h_offset = shake_offset.x
	camera.v_offset = shake_offset.y


# --- Helpers ------------------------------------------------------------------------

func _label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.visible = false
	tag.position = at
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.pixel_size = 0.006
	tag.font_size = 48
	tag.outline_size = 12
	tag.no_depth_test = true
	tag.fixed_size = false
	add_child(tag)
	return tag


func _simple(mesh: Mesh, color: Color, position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	instance.material_override = material
	instance.position = position
	return instance


func frame_shot(shot: Dictionary) -> void:
	_shot = shot.duplicate()


func end_shot() -> void:
	_shot.clear()
	if tavo != null:
		tavo.play("idle")
	if _speaking != null:
		_speaking.play("idle")
		_speaking = null


func figure_for(node_name: String) -> CastFigure:
	if node_name == "Tavo" or node_name == "Player":
		return tavo
	var model := get_node_or_null(node_name + "3D")
	if model != null:
		for child in model.get_children():
			if child is CastFigure:
				return child
	return null


func animate_speaker(node_name: String) -> void:
	if _speaking != null:
		_speaking.play("idle")
	_speaking = figure_for(node_name)
	if _speaking != null:
		if _speaking._looping == "fix":
			_speaking = null
			return
		_speaking.play("talk")
		if _speaking != tavo:
			var at := to_3d(scene.player.global_position, _speaking.global_position.y)
			if _speaking.global_position.distance_to(at) > 0.1:
				_speaking.look_at(at, Vector3.UP)


func _build_story_props() -> void:
	if scene.name == "Cistern":
		var pipe := CylinderMesh.new()
		pipe.top_radius = 0.1
		pipe.bottom_radius = 0.1
		pipe.height = 2.4
		_carried_pipe = _simple(pipe, Color("#b0704a"), Vector3.ZERO)
		_carried_pipe.rotation.z = PI / 2.0
		add_child(_carried_pipe)


func _sync_story_props(delta: float) -> void:
	if scene.name == "Cistern":
		var policy: String = GameState.get_flag("water_policy")
		var count: int = {"": 12, "reserve": 12, "share": 6, "joint": 10}.get(policy, 12)
		var jars := get_node_or_null("Jars3D")
		if jars != null:
			for i in jars.get_child_count():
				(jars.get_child(i) as Node3D).visible = i < count
		var repaired: bool = GameState.get_flag("sc03_repair_done")
		var water := get_node_or_null("Spring3D/SpringWater") as Node3D
		if water != null:
			water.visible = repaired
		_carried_pipe.visible = GameState.get_flag("sc03_pipe_taken")
		_carried_pipe.position = to_3d(scene.get_node("Spring").position, 0.2) if repaired else tavo.position + Vector3(0, 1.1, 0)
	elif scene.name == "ReedGate":
		var brace := get_node_or_null("Brace3D") as Node3D
		if brace != null:
			brace.rotation.z = lerpf(brace.rotation.z, 0.0 if GameState.get_flag("sc07_braced") else 0.22, minf(delta * 5.0, 1.0))


## Must match the visible tread tops and the existing zig-zag collision gaps.
static func keeper_height(point: Vector2) -> float:
	var level := 0
	var edge := 400.0
	if point.y < 160.0:
		return 4.5
	elif point.y < 280.0:
		level = 2
		edge = 160.0
	elif point.y < 400.0:
		level = 1
		edge = 280.0
	var on_stair := point.x >= 740.0 and point.x <= 944.0
	if level == 1:
		on_stair = point.x >= 16.0 and point.x <= 220.0
	if on_stair and point.y < edge + 96.0:
		return level * 1.5 + clampf(ceilf((edge + 96.0 - point.y) / 9.6), 0.0, 10.0) * 0.15
	return level * 1.5


func _build_keeper_landings() -> void:
	for point: Vector3 in [Vector3(3, 3.5, 11), Vector3(12, 7.5, 4), Vector3(21, 5.5, 8)]:
		var lamp := OmniLight3D.new()
		lamp.position = point
		lamp.light_color = Color("#f1cf9c") if point.x != 12 else Color("#b7d4e2")
		lamp.light_energy = 3.5
		lamp.omni_range = 15.0
		add_child(lamp)
	for i in 3:
		var top := (i + 1) * 1.5
		var back := 280.0 - i * 120.0 if i < 2 else 20.0
		var front := 400.0 - i * 120.0
		var slab := Props3D._box(self, Vector3(23.2, 0.22, (front - back) * METRES_PER_PIXEL), Color.WHITE,
				to_3d(Vector2(480, (front + back) * 0.5), top - 0.11))
		slab.name = "Landing%d" % (i + 1)
		Props3D._skin(slab, "stone", Color("#a89f8b"))


func _build_broken_exit(point: Vector2) -> void:
	var root := Node3D.new()
	root.name = "BrokenExit3D"
	root.position = to_3d(point, 4.5)
	add_child(root)
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var brick := Props3D._box(root, Vector3(0.55, 0.40, 0.5), Color.WHITE, Vector3(side * (1.4 + i * 0.07), 0.2 + i * 0.40, 0))
			brick.rotation.z = side * i * 0.035
			Props3D._skin(brick, "stone")
	for i in 6:
		var rubble := Props3D._box(root, Vector3(0.3, 0.18, 0.35), Color("#8d8679"), Vector3((i - 3) * 0.37, 0.08, -0.1 + (i % 2) * 0.25))
		rubble.rotation.y = i * 0.7


func begin_collapse() -> void:
	_collapsing = true
	_collapse_time = 0.0
	tavo.play("hit")
	var chunks := CPUParticles3D.new()
	chunks.name = "FallingMasonry"
	chunks.amount = 20
	chunks.lifetime = 1.0
	chunks.one_shot = true
	chunks.explosiveness = 0.95
	chunks.direction = Vector3(0, 0.3, 1)
	chunks.spread = 75.0
	chunks.initial_velocity_min = 1.0
	chunks.initial_velocity_max = 3.0
	chunks.gravity = Vector3(0, -16, 0)
	var brick := BoxMesh.new()
	brick.size = Vector3(0.22, 0.16, 0.25)
	chunks.mesh = brick
	chunks.material_override = Materials3D.get_material("stone")
	chunks.position = tavo.position + Vector3(0, 0.1, -0.2)
	add_child(chunks)


func _utility_carrier(at: Vector3, turn: float) -> void:
	var carrier := Civilisation3D.service_cart()
	carrier.position = at
	carrier.rotation.y = turn
	add_child(carrier)
