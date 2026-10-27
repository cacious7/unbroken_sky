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
const CAMERA_OFFSET := Vector3(0, 9.0, 5.8)

## Lighting per scene (keyed by the scene's root node name).
const MOODS := {
	"WellYard": {"sky": "#7fa8d0", "horizon": "#f2cf98", "sun": Vector3(-38, -30, 0), "sun_color": "#ffe2b8", "energy": 1.15, "ambient": 0.55, "outdoor": true, "fog": 0.0},
	"Cistern": {"sky": "#86b2d8", "horizon": "#f0d6a8", "sun": Vector3(-55, -20, 0), "sun_color": "#fff0d8", "energy": 1.2, "ambient": 0.55, "outdoor": true, "fog": 0.0},
	"Home": {"sky": "#3a2a20", "horizon": "#6a4a30", "sun": Vector3(-62, 25, 0), "sun_color": "#ffd8a0", "energy": 0.9, "ambient": 0.7, "outdoor": false, "fog": 0.0},
	"AshRoad": {"sky": "#a8c4dc", "horizon": "#f8e0b0", "sun": Vector3(-68, -10, 0), "sun_color": "#fff6e0", "energy": 1.35, "ambient": 0.5, "outdoor": true, "fog": 0.0},
	"Culvert": {"sky": "#8a90b8", "horizon": "#f0a870", "sun": Vector3(-22, -55, 0), "sun_color": "#ffb878", "energy": 1.1, "ambient": 0.45, "outdoor": true, "fog": 0.004},
	"ReedGate": {"sky": "#8a96a4", "horizon": "#c8c0b0", "sun": Vector3(-45, 30, 0), "sun_color": "#e8e4dc", "energy": 0.85, "ambient": 0.6, "outdoor": true, "fog": 0.0},
	"KeeperRoom": {"sky": "#141a20", "horizon": "#26303a", "sun": Vector3(-70, 10, 0), "sun_color": "#a8c0d8", "energy": 0.55, "ambient": 0.35, "outdoor": false, "fog": 0.0},
	"WheelPlatform": {"sky": "#5a6a9a", "horizon": "#e89a68", "sun": Vector3(-20, 40, 0), "sun_color": "#ffb080", "energy": 1.0, "ambient": 0.5, "outdoor": true, "fog": 0.0},
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
## Tall objects that fade out when they stand between the camera and Tavo.
var _tall: Array[Node3D] = []


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
	if mood.outdoor:
		_scatter_nature()
	_build_player()
	_build_focus_ring()
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 200.0
	add_child(camera)
	camera.current = true
	_update_camera(0.0, true)


## Screen position (e.g. a tap) -> point on the 2D gameplay plane, or null if the tap
## does not hit the ground.
func screen_to_world_2d(screen_point: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_point)
	var direction := camera.project_ray_normal(screen_point)
	if absf(direction.y) < 0.0001:
		return null
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return null
	return to_2d(origin + direction * distance)


func _process(delta: float) -> void:
	_sync_player()
	var player_3d := to_3d(scene.player.global_position)
	for husk_view in _husks:
		husk_view.sync(to_3d, player_3d)
	for mirror: Array in _mirrors:
		var source: CanvasItem = mirror[0]
		(mirror[1] as Node3D).visible = source.visible
		if mirror[2] != null and source.get("label") != null:
			(mirror[2] as Label3D).text = source.label
	_sync_rope()
	_sync_flood()
	_sync_focus()
	_fade_occluders()
	_update_camera(delta)


## Tall props between the camera (to the south) and Tavo turn see-through.
func _fade_occluders() -> void:
	var player_3d := to_3d(scene.player.global_position)
	for node in _tall:
		var in_front := node.position.z > player_3d.z + 0.8 and node.position.z < player_3d.z + 7.0 \
				and absf(node.position.x - player_3d.x) < 4.0
		var fade := 0.7 if in_front else 0.0
		for mesh: GeometryInstance3D in node.find_children("", "GeometryInstance3D", true, false):
			mesh.transparency = fade


func _register_if_tall(node: Node3D) -> void:
	if Props3D._bounds(node).size.y > 1.2:
		_tall.append(node)


# --- Building ---------------------------------------------------------------------

func _build_environment(mood: Dictionary) -> void:
	var environment := Environment.new()
	if mood.outdoor:
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color(mood.sky)
		sky_material.sky_horizon_color = Color(mood.horizon)
		sky_material.ground_horizon_color = Color(mood.horizon).darkened(0.2)
		sky_material.ground_bottom_color = Color(mood.horizon).darkened(0.5)
		var sky := Sky.new()
		sky.sky_material = sky_material
		environment.background_mode = Environment.BG_SKY
		environment.sky = sky
		# A warm, neutral fill rather than the blue sky: sky ambient tints every upward
		# face blue (green plants turn cyan, warm earth turns white).
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(mood.horizon).lerp(Color("#9a9080"), 0.5)
	else:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(mood.sky)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(mood.horizon).lightened(0.4)
	# Kept well below 1: bright sky ambient plus sun washes the warm ground out to white.
	environment.ambient_light_energy = mood.ambient * 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.85
	if mood.fog > 0.0:
		environment.fog_enabled = true
		environment.fog_light_color = Color(mood.horizon)
		environment.fog_density = mood.fog
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = mood.sun
	sun.light_color = Color(mood.sun_color)
	sun.light_energy = mood.energy * 0.7
	sun.shadow_enabled = true
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
	var material := StandardMaterial3D.new()
	material.albedo_color = rect.color
	material.roughness = 0.25 if rect.color.b > rect.color.r else 0.95
	instance.material_override = material
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
			height = 0.8
		elif block.label == "FORTRESS WALL":
			height = 3.2
		elif block.name.begins_with("Edge"):
			height = 0.7
		model = Props3D.wall(size, stone, height)
	model.position = to_3d(block.global_position)
	add_child(model)
	if not Props3D.FIGURES.has(String(block.name)):
		_register_if_tall(model)
	if block.label != "" and block.get("show_label") != false and not Props3D.FIGURES.has(String(block.name)) \
			and block.label != "FORTRESS WALL":
		_label(block.label, model.position + Vector3(0, 2.0, 0))
	elif Props3D.FIGURES.has(String(block.name)):
		_label(block.label, model.position + Vector3(0, 2.3, 0))


func _build_marker(marker: Node2D) -> void:
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
	var small := ["nature/grass.glb", "nature/grass_large.glb", "nature/grass_leafs.glb", "nature/plant_bushSmall.glb",
			"nature/rock_smallA.glb", "nature/rock_smallB.glb", "nature/rock_smallFlatA.glb", "nature/plant_flatShort.glb",
			"survival/rock-sand-a.glb", "survival/rock-sand-b.glb"]
	var placed := 0
	var attempts := 0
	while placed < 46 and attempts < 600:
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
		Props3D._model(tree, "nature/tree_plateau.glb", rng.randf_range(2.4, 3.2))


# --- Following the gameplay -------------------------------------------------------

func _sync_player() -> void:
	var player := scene.player
	tavo.visible = player.visible
	tavo.position = to_3d(player.global_position)
	var facing := player.facing
	if facing.length() > 0.1:
		var target := atan2(-facing.x, -facing.y)
		tavo.rotation.y = lerp_angle(tavo.rotation.y, target, 0.25)
	tavo.set_moving(player.velocity.length() > 10.0, player.velocity.length() / Player.SPEED)
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
	_flood.position = Vector3(ROOM.x / 2.0, 0.2, (top + bottom) / 2.0)


func _sync_focus() -> void:
	var target := scene.player.focus_target()
	_focus_ring.visible = target != null and scene.player.active
	if target != null:
		_focus_ring.position = to_3d(target.global_position, 0.05)
		var radius := maxf(target.body_size.x, target.body_size.y) * METRES_PER_PIXEL * 0.5 + 0.35
		_focus_ring.scale = Vector3(radius / 0.6, 1.0, radius / 0.6)


func _update_camera(delta: float, snap := false) -> void:
	var focus := to_3d(scene.player.global_position)
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
