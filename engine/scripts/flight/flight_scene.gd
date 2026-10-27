extends Node3D
## SC09 "The first sky" in 3D. Tavo falls through Reed Gate's broken wall and becomes an
## eagle. Three perch-to-perch links over the flooded fortress: the first is safe; the
## second crosses a gust, with an updraft to the left ("Left. The air comes up there.");
## the third reaches the release-wheel platform, where he lands human.
## If his wings tire, he touches the water, or he flies out of the fortress, he returns to
## the last perch with no other penalty. Flight assist widens landings, adds stamina and
## halves gusts.
##
## Steering: drag anywhere on a touch screen (drag up to climb), arrow keys / WASD, or
## hold the mouse button and drag. Take off: tap, click, E/Space or the FLY button.

const SPEED := 15.0
## Radians per second at full stick.
const TURN_RATE := 1.4
const MAX_BANK := 0.7
const MAX_PITCH := 0.45
## A glide slowly loses height unless the eagle climbs or rides an updraft.
const GLIDE_SINK := 1.4
const BASE_STAMINA := 9.0
const ASSIST_STAMINA := 13.0
const LANDING_RADIUS := 6.0
const LIFT_SPEED := 7.0
const LIFT_REFILL := 1.5
const WATER_Y := 0.0
const AREA_RADIUS := 300.0
const PERCH_LIFT := Vector3(0, 0.5, 0)

## Landing points on the top of each pillar, in flight order. The first link drops
## gently, so a straight glide with no steering lands safely; the second must climb.
const PERCHES := [
	{"name": "BROKEN WALL", "position": Vector3(0, 16, 0)},
	{"name": "LEDGE", "position": Vector3(28, 11, -70)},
	{"name": "TOWER STEP", "position": Vector3(-6, 22, -140)},
	{"name": "RELEASE WHEEL", "position": Vector3(26, 11, -210)},
]
## The gust sits on the straight line from LEDGE to TOWER STEP; the updraft is to its left.
const ZONES := [
	{"kind": "gust", "label": "GUST", "center": Vector3(13, 18, -105), "size": Vector3(16, 20, 18),
		"push": Vector3(10, -6, 0)},
	{"kind": "lift", "label": "UPDRAFT", "center": Vector3(-8, 15, -100), "size": Vector3(10, 30, 12)},
]

@onready var dialogue: DialogueBox = $Dialogue
@onready var hud: Hud = $Hud
@onready var touch: TouchControls = $TouchControls

var eagle: Eagle3D
var camera: Camera3D
var tavo: Sprite3D
var pause_menu: PauseMenu
var flying := false
var stamina := 0.0
var max_stamina := BASE_STAMINA

var _yaw := 0.0
var _pitch := 0.0
var _bank := 0.0
var _steer := Vector2.ZERO
var _mouse_origin := Vector2.ZERO
var _mouse_steering := false
var _busy := false
var _ring: MeshInstance3D
var _ring_time := 0.0


func _ready() -> void:
	_build_world()
	dialogue.load_file("res://data/dialogue/sc09.json")
	hud.show_key_hints = not touch.device_has_touch
	touch.stick_anywhere = true
	touch.set_action_label("FLY")
	touch.vector_changed.connect(func(vector: Vector2) -> void: _steer = Vector2(vector.x, -vector.y))
	touch.tapped.connect(func(_position: Vector2) -> void: takeoff())
	touch.interact_pressed.connect(takeoff)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	if GameState.get_flag("sc09_complete"):
		GameState.go_to("SC10")
		return
	_perch_at(link())
	if not GameState.get_flag("sc09_started"):
		await _say("fall")
		GameState.set_flag("sc09_started", true)
		await _say("hint")
	_refresh_objective()


func link() -> int:
	return GameState.get_flag("sc09_link")


func is_flying() -> bool:
	return flying


func perch_position(index: int) -> Vector3:
	return PERCHES[index].position


func landing_radius() -> float:
	return LANDING_RADIUS * (1.5 if Settings.flight_assist else 1.0)


func takeoff() -> void:
	if flying or _busy or GameState.get_flag("sc09_complete"):
		return
	if link() == 1 and not GameState.get_flag("sc09_voice_heard"):
		await _say("voice")
		GameState.set_flag("sc09_voice_heard", true)
	max_stamina = ASSIST_STAMINA if Settings.flight_assist else BASE_STAMINA
	stamina = max_stamina
	_pitch = 0.0
	flying = true
	_refresh_objective()


## Wind at a point: [push in m/s, lift in m/s, in_lift_zone].
func wind_at(point: Vector3) -> Array:
	var push := Vector3.ZERO
	var lift := 0.0
	var in_lift := false
	for zone: Dictionary in ZONES:
		if not AABB(zone.center - zone.size / 2.0, zone.size).has_point(point):
			continue
		if zone.kind == "gust":
			push += zone.push * (0.5 if Settings.flight_assist else 1.0)
		else:
			lift += LIFT_SPEED
			in_lift = true
	return [push, lift, in_lift]


func _physics_process(delta: float) -> void:
	_ring_time += delta
	if _ring != null:
		_ring.scale = Vector3.ONE * (1.0 + 0.06 * sin(_ring_time * 3.0))
	if not flying or _busy:
		_update_camera(delta)
		return
	var input := Input.get_vector("move_left", "move_right", "move_down", "move_up") + _steer
	input = input.limit_length(1.0)
	_yaw -= input.x * TURN_RATE * delta
	_bank = lerpf(_bank, -input.x * MAX_BANK, 1.0 - exp(-5.0 * delta))
	_pitch = lerpf(_pitch, input.y * MAX_PITCH, 1.0 - exp(-3.0 * delta))
	var forward := _forward()
	var velocity := forward * SPEED + Vector3(0, -GLIDE_SINK, 0)
	var wind := wind_at(eagle.position)
	velocity += wind[0]
	velocity.y += wind[1]
	if wind[2]:
		stamina = minf(stamina + LIFT_REFILL * delta, max_stamina)
	# Climbing costs extra effort.
	stamina -= delta * (1.0 + maxf(input.y, 0.0))
	eagle.position += velocity * delta
	eagle.rotation = Vector3(_pitch, _yaw, 0)
	eagle.bank = _bank
	eagle.flap = clampf(0.25 + 0.75 * maxf(input.y, 0.0) + (0.3 if wind[2] else 0.0), 0.0, 1.0)
	hud.set_meter("WINGS", stamina / max_stamina)

	var next: Vector3 = perch_position(link() + 1)
	if eagle.position.distance_to(next + PERCH_LIFT) <= landing_radius():
		_land(link() + 1)
	elif eagle.position.y <= WATER_Y + 0.6 or stamina <= 0.0 \
			or Vector2(eagle.position.x, eagle.position.z).length() > AREA_RADIUS:
		_fall()
	_update_camera(delta)


func _forward() -> Vector3:
	return Basis.from_euler(Vector3(_pitch, _yaw, 0)) * Vector3.FORWARD


func _land(index: int) -> void:
	flying = false
	hud.hide_meter()
	GameState.set_flag("sc09_link", index)
	if index == PERCHES.size() - 1:
		_become_human()
		await _say("land")
		GameState.set_flag("eagle_unlocked", true)
		GameState.set_flag("sc09_complete", true)
		GameState.go_to("SC10")
	else:
		_perch_at(index)
		_refresh_objective()


func _fall() -> void:
	flying = false
	hud.hide_meter()
	hud.show_caption("[the wings give out: back to the last perch]")
	_perch_at(link())
	_refresh_objective()


func _perch_at(index: int) -> void:
	var here: Vector3 = perch_position(index)
	eagle.position = here + PERCH_LIFT
	if index + 1 < PERCHES.size():
		var to_next: Vector3 = perch_position(index + 1) - here
		_yaw = atan2(-to_next.x, -to_next.z)
		# Stand the ring upright, facing the approach, so it reads as a hoop to fly through.
		_ring.position = perch_position(index + 1) + Vector3(0, 2.5, 0)
		_ring.rotation = Vector3(PI / 2.0, 0, 0)
		_ring.rotate_y(_yaw)
		_ring.visible = true
	_pitch = 0.0
	_bank = 0.0
	eagle.rotation = Vector3(0, _yaw, 0)
	eagle.bank = 0.0
	eagle.flap = 0.1
	_update_camera(0.0, true)


func _become_human() -> void:
	eagle.visible = false
	_ring.visible = false
	tavo.position = perch_position(PERCHES.size() - 1) + Vector3(0, 1.2, 0)
	tavo.visible = true


func _update_camera(delta: float, snap := false) -> void:
	var behind := Basis(Vector3.UP, _yaw) * Vector3(0, 3.6, 9.5)
	var target := eagle.position + behind
	var weight := 1.0 if snap else 1.0 - exp(-5.0 * delta)
	camera.position = camera.position.lerp(target, weight)
	var look := eagle.position + _forward() * 8.0 + Vector3(0, 0.8, 0)
	if camera.position.distance_to(look) > 0.1:
		camera.look_at(look, Vector3.UP)
	camera.rotate_object_local(Vector3.FORWARD, _bank * 0.35)
	camera.fov = lerpf(camera.fov, 80.0 if flying else 70.0, weight)


func _say(conversation_id: String) -> void:
	_busy = true
	touch.set_shown(false)
	dialogue.play(conversation_id)
	await dialogue.finished
	touch.set_shown(true)
	_busy = false


func _refresh_objective() -> void:
	if flying:
		hud.set_objective("Fly through the bright ring before your wings tire.")
	elif GameState.get_flag("sc09_started"):
		hud.set_objective("Take off towards the bright ring (tap, FLY or E).")
	else:
		hud.set_objective("")


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("interact") and not flying:
		get_viewport().set_input_as_handled()
		takeoff()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.pressed and not flying:
			takeoff()
		_mouse_steering = event.pressed
		_mouse_origin = event.position
		if not event.pressed:
			_steer = Vector2.ZERO
	elif event is InputEventMouseMotion and _mouse_steering and event.device != InputEvent.DEVICE_ID_EMULATION:
		var drag: Vector2 = (event.position - _mouse_origin) / 90.0
		_steer = Vector2(drag.x, -drag.y).limit_length(1.0)


func _exit_tree() -> void:
	get_tree().paused = false


# --- World -----------------------------------------------------------------------

func _build_world() -> void:
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#3b5d8f")
	sky_material.sky_horizon_color = Color("#f0b878")
	sky_material.ground_horizon_color = Color("#8a7a70")
	sky_material.ground_bottom_color = Color("#1d2a33")
	sky_material.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.45
	environment.fog_enabled = true
	environment.fog_light_color = Color("#b8957a")
	environment.fog_density = 0.0016
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -35, 0)
	sun.light_color = Color("#ffd8a8")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)

	var water := _box(Vector3(900, 0.2, 900), Color("#1f3a4c"), Vector3(0, -0.1, -100))
	var water_material := water.material_override as StandardMaterial3D
	water_material.roughness = 0.35
	water_material.metallic = 0.0

	# Distant hills fading into the haze give the sense of height and distance.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 14:
		var angle := TAU * i / 14.0 + rng.randf_range(-0.1, 0.1)
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(60, 110)
		sphere.height = sphere.radius * 2.0
		hill.mesh = sphere
		hill.material_override = _material(Color("#8a5a3a").lerp(Color("#6a4a3a"), rng.randf()))
		hill.scale = Vector3(1.0, rng.randf_range(0.25, 0.45), 1.0)
		hill.position = Vector3(cos(angle) * 380.0, -5.0, sin(angle) * 380.0 - 100.0)
		add_child(hill)

	_build_ruins(rng)
	for i in PERCHES.size():
		_build_perch(i)
	for zone: Dictionary in ZONES:
		_build_zone(zone)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.3
	torus.outer_radius = 4.3
	_ring.mesh = torus
	var ring_material := _material(Color("#ffe08a"))
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = ring_material
	add_child(_ring)

	eagle = Eagle3D.new()
	eagle.scale = Vector3.ONE * 1.6
	add_child(eagle)
	tavo = Sprite3D.new()
	tavo.texture = load("res://assets/art/characters/tavo.svg")
	tavo.pixel_size = 2.4 / tavo.texture.get_height()
	tavo.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	tavo.visible = false
	add_child(tavo)
	camera = Camera3D.new()
	camera.far = 900.0
	add_child(camera)
	camera.make_current()


## Broken walls and towers rising from the flood, kept clear of the flight path.
func _build_ruins(rng: RandomNumberGenerator) -> void:
	var placed := 0
	var attempts := 0
	while placed < 46 and attempts < 400:
		attempts += 1
		var point := Vector3(rng.randf_range(-110, 130), 0, rng.randf_range(-280, 50))
		if _distance_to_route(point) < 14.0:
			continue
		placed += 1
		var tall := rng.randf() < 0.3
		var height := rng.randf_range(14, 30) if tall else rng.randf_range(2, 9)
		var stone := Color("#7a6e60").lerp(Color("#4e4840"), rng.randf())
		if tall:
			var tower := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = rng.randf_range(2.5, 4.5)
			cylinder.bottom_radius = cylinder.top_radius * 1.1
			cylinder.height = height
			cylinder.radial_segments = 8
			tower.mesh = cylinder
			tower.material_override = _material(stone)
			tower.position = point + Vector3(0, height / 2.0, 0)
			add_child(tower)
		else:
			var wall := _box(Vector3(rng.randf_range(6, 18), height, rng.randf_range(1.5, 3)), stone,
					point + Vector3(0, height / 2.0, 0))
			wall.rotation.y = rng.randf_range(0, PI)


func _distance_to_route(point: Vector3) -> float:
	var best := INF
	var flat := Vector2(point.x, point.z)
	for i in PERCHES.size() - 1:
		var a: Vector3 = perch_position(i)
		var b: Vector3 = perch_position(i + 1)
		var closest := Geometry2D.get_closest_point_to_segment(flat, Vector2(a.x, a.z), Vector2(b.x, b.z))
		best = minf(best, flat.distance_to(closest))
	return best


func _build_perch(index: int) -> void:
	var top: Vector3 = perch_position(index)
	var last := index == PERCHES.size() - 1
	var pillar := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 3.2 if not last else 7.0
	cylinder.bottom_radius = cylinder.top_radius * 1.15
	cylinder.height = top.y
	cylinder.radial_segments = 10
	pillar.mesh = cylinder
	pillar.material_override = _material(Color("#6e655a"))
	pillar.position = Vector3(top.x, top.y / 2.0, top.z)
	add_child(pillar)
	var cap := _box(Vector3(cylinder.top_radius * 2.0, 0.5, cylinder.top_radius * 2.0), Color("#9a8e7c"),
			top + Vector3(0, 0.25, 0))
	cap.rotation.y = PI / 4.0
	if last:
		var wheel := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.0
		torus.outer_radius = 1.3
		wheel.mesh = torus
		wheel.material_override = _material(Color("#c97a36"))
		wheel.position = top + Vector3(-3, 1.4, 0)
		wheel.rotation.z = PI / 2.0
		add_child(wheel)
	var label := Label3D.new()
	label.text = PERCHES[index].name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.outline_size = 14
	label.pixel_size = 0.05
	label.position = top + Vector3(0, 4.5, 0)
	add_child(label)


func _build_zone(zone: Dictionary) -> void:
	var lift: bool = zone.kind == "lift"
	var tint := Color(0.55, 0.95, 0.65) if lift else Color(0.75, 0.88, 1.0)
	var volume := _box(zone.size, Color(tint, 0.04), zone.center)
	var volume_material := volume.material_override as StandardMaterial3D
	volume_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	volume_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	volume_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Streaks moving with the air so the wind reads without sound.
	var streaks := CPUParticles3D.new()
	var streak := BoxMesh.new()
	# Long along Y, because particle_flag_align_y points Y along the motion.
	streak.size = Vector3(0.14, 2.2, 0.14)
	var streak_material := _material(Color(tint, 0.8))
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = streak_material
	streaks.mesh = streak
	streaks.amount = 90
	streaks.lifetime = 1.2
	streaks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	streaks.emission_box_extents = zone.size / 2.0
	streaks.direction = Vector3.UP if lift else (zone.push as Vector3).normalized()
	streaks.spread = 4.0
	streaks.gravity = Vector3.ZERO
	streaks.initial_velocity_min = 10.0
	streaks.initial_velocity_max = 14.0
	streaks.particle_flag_align_y = true
	streaks.position = zone.center
	add_child(streaks)
	var label := Label3D.new()
	label.text = zone.label
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 56
	label.outline_size = 12
	label.pixel_size = 0.05
	label.modulate = tint
	label.position = zone.center + Vector3(0, zone.size.y / 2.0 + 2.0, 0)
	add_child(label)


func _box(size: Vector3, color: Color, position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = position
	add_child(instance)
	return instance


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
