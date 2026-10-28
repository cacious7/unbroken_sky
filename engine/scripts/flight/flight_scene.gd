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
var tavo: CastFigure
var _shape_tween: Tween
var _transforming := false
var _form_blend := 0.0:
	set(value):
		_form_blend = value
		if _transforming and tavo != null and eagle != null:
			# Visibility is supported by the mobile renderer; per-instance fade is not.
			tavo.visible = value < 0.5
			eagle.visible = value >= 0.5
var _fall_debris: CPUParticles3D
var _feathers: CPUParticles3D
var _nali: CastFigure
var _kesi: CastFigure
var _landing_subject: CastFigure
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
var course: Node3D
var _boost_left := 0.0
var _boost_trail: CPUParticles3D
var _obstacles: Array[Dictionary] = []


func _ready() -> void:
	_build_world()
	course = preload("res://scripts/flight/flight_course.gd").new()
	add_child(course)
	course.configure(PERCHES)
	course.collected.connect(_on_wind_gate)
	hud.set_wind_progress(0, 2)
	_build_boost_trail()
	dialogue.load_file("res://data/dialogue/sc09.json")
	dialogue.line_started.connect(_on_dialogue_line)
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
		_finish_transformation()
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
		_say("voice")
		GameState.set_flag("sc09_voice_heard", true)
	max_stamina = ASSIST_STAMINA if Settings.flight_assist else BASE_STAMINA
	stamina = max_stamina
	_pitch = 0.0
	flying = true
	eagle.grounded = false
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
	_boost_left = maxf(0.0, _boost_left - delta)
	if _boost_trail != null:
		_boost_trail.emitting = flying and _boost_left > 0.0
		_boost_trail.position = eagle.position
		_boost_trail.direction = -_forward()
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
	var before := eagle.position
	var velocity := forward * (SPEED + (6.0 if _boost_left > 0.0 else 0.0)) + Vector3(0, -GLIDE_SINK, 0)
	var wind := wind_at(eagle.position)
	velocity += wind[0]
	velocity.y += wind[1]
	if wind[2]:
		stamina = minf(stamina + LIFT_REFILL * delta, max_stamina)
	# Climbing costs extra effort.
	stamina -= delta * (1.0 + maxf(input.y, 0.0))
	eagle.position += velocity * delta
	course.sweep_collect(before, eagle.position)
	eagle.rotation = Vector3(_pitch, _yaw, 0)
	eagle.bank = _bank
	eagle.flap = clampf(0.25 + 0.75 * maxf(input.y, 0.0) + (0.3 if wind[2] else 0.0), 0.0, 1.0)
	hud.set_meter("WINGS", stamina / max_stamina)

	var next: Vector3 = perch_position(link() + 1)
	if eagle.position.distance_to(next + PERCH_LIFT) <= landing_radius():
		_land(link() + 1)
	elif hits_ruin(before, eagle.position):
		_fall("Clipped stone. Try another line.")
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


func _fall(reason := "Back to the last perch.") -> void:
	flying = false
	_boost_left = 0.0
	_steer = Vector2.ZERO
	_mouse_steering = false
	course.reset_leg(link())
	hud.set_wind_progress(course.current_count(), 2)
	hud.hide_meter()
	hud.show_caption(reason)
	_perch_at(link())
	_refresh_objective()


func _perch_at(index: int) -> void:
	if course != null:
		course.set_leg(index)
		hud.set_wind_progress(course.current_count(), 2)
	_boost_left = 0.0
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
	eagle.grounded = true
	eagle.set_first_person(true)
	_update_camera(0.0, true)


func _become_human() -> void:
	eagle.visible = false
	hud.set_wind_progress(course.current_count(), 2, false)
	_ring.visible = false
	tavo.position = perch_position(PERCHES.size() - 1) + Vector3(0, 0.3, 0)
	tavo.visible = true
	tavo._model.visible = false
	_nali.visible = true
	_landing_subject = _nali


func _update_camera(delta: float, snap := false) -> void:
	if _transforming:
		var center := tavo.position + Vector3(0, 0.8, 0)
		camera.position = camera.position.lerp(center + Vector3(3.6, 1.4, 6.2), 1.0 if snap else 1.0 - exp(-10.0 * delta))
		camera.look_at(center, Vector3.UP)
		camera.fov = lerpf(camera.fov, 72.0, minf(delta * 4.0, 1.0))
		return
	if tavo.visible:
		var eye := tavo.position + Vector3(0, 1.68, 0)
		camera.position = eye
		var subject := _landing_subject if _landing_subject != null else _nali
		var target := subject.position + Vector3(0, 1.35, 0)
		camera.look_at(target, Vector3.UP)
		camera.fov = 72.0
		return
	var eye := eagle.position + Vector3.UP * 0.30 + _forward() * 0.12
	camera.position = eye
	camera.look_at(eye + _forward() * 15.0, Vector3.UP)
	if Settings.shake_on:
		camera.rotate_object_local(Vector3.FORWARD, _bank * 0.16)
	camera.fov = lerpf(camera.fov, (88.0 if _boost_left > 0.0 else 82.0) if flying else 76.0, minf(delta * 7.0, 1.0))



func _say(conversation_id: String) -> void:
	_busy = dialogue.blocks_controls(conversation_id)
	touch.set_shown(not _busy)
	hud.set_dialogue_active(true, _busy)
	dialogue.play(conversation_id)
	await dialogue.finished
	hud.set_dialogue_active(false)
	touch.set_shown(true)
	_busy = false


func _refresh_objective() -> void:
	if flying:
		hud.set_objective("Reach the next ledge.")
	elif GameState.get_flag("sc09_started"):
		hud.set_objective("Take off  /  Tap or E")
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
	sky_material.sky_top_color = Color("#426f99")
	sky_material.sky_horizon_color = Color("#b9cfd2")
	sky_material.ground_horizon_color = Color("#8c9d9a")
	sky_material.ground_bottom_color = Color("#314c54")
	sky_material.sun_angle_max = 1.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.65
	environment.fog_enabled = true
	environment.fog_light_color = Color("#b4c3c0")
	environment.fog_density = 0.0012
	environment.fog_sky_affect = 0.2
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
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
	var water_material := ShaderMaterial.new()
	water_material.shader = load("res://assets/shaders/river_water.gdshader")
	water.material_override = water_material

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
		hill.material_override = Materials3D.get_material("red_earth", Color("#c2a582"))
		hill.scale = Vector3(1.0, rng.randf_range(0.25, 0.45), 1.0)
		hill.position = Vector3(cos(angle) * 380.0, -5.0, sin(angle) * 380.0 - 100.0)
		add_child(hill)

	_build_ruins(rng)
	_build_fall_opening()
	_build_civic_skyline()
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var arcade := Props3D.ruined_arch()
			arcade.position = Vector3(-32.0 if side < 0 else 44.0, 0, -55.0 - i * 24.0)
			arcade.rotation.y = PI / 2.0
			arcade.scale = Vector3(1.3, 1.75, 1.0)
			add_child(arcade)
			for shape: Dictionary in arcade.get_meta("collision_shapes", []):
				_register_obstacle(shape.bounds, arcade.transform * (shape.transform as Transform3D), -1)
	for i in PERCHES.size():
		_build_perch(i)
	for zone: Dictionary in ZONES:
		_build_zone(zone)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.5
	torus.outer_radius = 3.66
	_ring.mesh = torus
	var ring_material := _material(Color("#ffe08a"))
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = ring_material
	add_child(_ring)

	eagle = Eagle3D.new()
	eagle.scale = Vector3.ONE * 1.6
	add_child(eagle)
	tavo = CastFigure.create("tavo")
	tavo.visible = false
	add_child(tavo)
	_nali = CastFigure.create("nali")
	_nali.position = perch_position(3) + Vector3(-1.3, 0.3, 0)
	_nali.visible = false
	add_child(_nali)
	_kesi = CastFigure.create("kesi")
	_kesi.position = perch_position(3) + Vector3(2.4, 0.3, 0.8)
	_kesi.visible = false
	add_child(_kesi)
	camera = Camera3D.new()
	camera.far = 900.0
	add_child(camera)
	camera.make_current()


## Broken walls and towers rising from the flood, kept clear of the flight path.
func _build_ruins(rng: RandomNumberGenerator) -> void:
	var placed := 0
	var attempts := 0
	while placed < 28 and attempts < 400:
		attempts += 1
		var point := Vector3(rng.randf_range(-110, 130), 0, rng.randf_range(-280, 50))
		if _distance_to_route(point) < 14.0:
			continue
		if point.z < -30 and point.z > -130 and (absf(point.x + 32) < 18 or absf(point.x - 44) < 18):
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
			tower.material_override = Materials3D.civic("shell")
			tower.position = point + Vector3(0, height / 2.0, 0)
			add_child(tower)
			_register_obstacle(tower.mesh.get_aabb(), tower.transform, -1)
		else:
			var wall := _box(Vector3(rng.randf_range(6, 18), height, rng.randf_range(1.5, 3)), stone,
					point + Vector3(0, height / 2.0, 0))
			wall.rotation.y = rng.randf_range(0, PI)
			wall.material_override = Materials3D.civic("patch")
			_register_obstacle(wall.mesh.get_aabb(), wall.transform, -1)


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
	pillar.material_override = Materials3D.civic("shell")
	pillar.position = Vector3(top.x, top.y / 2.0, top.z)
	add_child(pillar)
	_register_obstacle(pillar.mesh.get_aabb(), pillar.transform, index)
	var cap := _box(Vector3(cylinder.top_radius * 2.0, 0.5, cylinder.top_radius * 2.0), Color("#9a8e7c"),
			top + Vector3(0, 0.25, 0))
	cap.rotation.y = PI / 4.0
	cap.material_override = Materials3D.civic("teal")
	for band in 3:
		var cornice := _box(Vector3(cylinder.top_radius * 2.1, 0.22, cylinder.top_radius * 2.1), Color.WHITE,
				top + Vector3(0, -0.35 - band * 0.35, 0))
		cornice.material_override = Materials3D.civic("bronze")
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var merlon := _box(Vector3(0.08, 0.85, 0.08), Color.WHITE,
					top + Vector3(side * cylinder.top_radius * 0.8, 0.65, (i - 1) * 1.3))
			merlon.material_override = Materials3D.civic("bronze")
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



func _build_zone(zone: Dictionary) -> void:
	var lift: bool = zone.kind == "lift"
	var tint := Color(0.55, 0.95, 0.65) if lift else Color(0.75, 0.88, 1.0)
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
	streaks.amount = 48
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


func _on_dialogue_line(line: Dictionary) -> void:
	if line.get("stage", "") == "transform":
		_start_falling_transformation()
	elif line.get("speaker", "") == "KESI":
		_kesi.visible = true
		_landing_subject = _kesi
		_kesi.play("talk")
	elif line.get("speaker", "") == "NALI":
		_landing_subject = _nali
		_nali.play("talk")
	elif line.get("speaker", "") == "TAVO":
		tavo.play("talk")


func _finish_transformation() -> void:
	if _shape_tween != null and _shape_tween.is_running():
		_shape_tween.kill()
	_transforming = false
	_form_blend = 1.0
	tavo.visible = false
	tavo.scale = Vector3.ONE
	tavo.rotation = Vector3.ZERO
	eagle.scale = Vector3.ONE * 1.6
	eagle.position = perch_position(link()) + PERCH_LIFT
	eagle.rotation.x = 0.0
	eagle.grounded = true
	eagle.set_first_person(true)
	eagle.visible = true
	for mesh: GeometryInstance3D in tavo.find_children("", "GeometryInstance3D", true, false):
		mesh.transparency = 0.0


func _start_falling_transformation() -> void:
	_transforming = true
	eagle.set_first_person(false)
	tavo._model.visible = true
	var landing := perch_position(0) + PERCH_LIFT
	var start := landing + Vector3(0, 8.5, 2.0)
	tavo.position = start
	tavo.visible = true
	tavo.animation_player.play("Jump", 0.1, 0.8)
	tavo.rotation.x = -0.35
	eagle.position = start + Vector3.UP * 0.7
	eagle.scale = Vector3.ONE * 1.6
	eagle.visible = true
	eagle.grounded = false
	eagle.flap = 1.0
	_form_blend = 0.0
	_update_camera(0.0, true)
	_fall_debris = _burst(start + Vector3(0, 0.2, 0.5), false)
	_feathers = _burst(start + Vector3(0, -4.5, -0.5), true)
	_feathers.emitting = false
	_shape_tween = create_tween().set_parallel()
	_shape_tween.tween_property(tavo, "position", landing - Vector3.UP * 0.4, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_shape_tween.tween_property(eagle, "position", landing, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_shape_tween.tween_property(self, "_form_blend", 1.0, 0.45).set_delay(0.75)
	_shape_tween.tween_callback(_feathers.restart).set_delay(0.8)


func _burst(at: Vector3, feathers: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "FeatherBurst" if feathers else "FallingStone"
	particles.amount = 18 if feathers else 24
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = 0.85 if feathers else 1.8
	particles.direction = Vector3(0, 0, -1)
	particles.spread = 80.0
	particles.initial_velocity_min = 0.7
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0, -3.0 if feathers else -18.0, 0)
	var shape := BoxMesh.new()
	shape.size = Vector3(0.035, 0.008, 0.2) if feathers else Vector3(0.25, 0.18, 0.3)
	particles.mesh = shape
	particles.material_override = _material(Color("#e8e2d1")) if feathers else Materials3D.get_material("stone")
	particles.position = at
	add_child(particles)
	return particles


func _build_fall_opening() -> void:
	var origin := perch_position(0) + Vector3(0, 8.5, 2.0)
	for side: float in [-1.0, 1.0]:
		var lip := _box(Vector3(2.4, 0.35, 2.2), Color.WHITE, origin + Vector3(side * 1.9, 0, 0.5))
		lip.material_override = Materials3D.get_material("stone")
		for i in 5:
			var brick := _box(Vector3(0.6, 0.5, 0.6), Color.WHITE, origin + Vector3(side * 1.8, 0.4 + i * 0.5, 1.2))
			brick.rotation.z = side * i * 0.025
			brick.material_override = Materials3D.get_material("stone")


func _on_wind_gate(total: int, clean: bool) -> void:
	stamina = minf(max_stamina, stamina + (2.6 if clean else 1.8))
	_boost_left = 1.1 if clean else 0.8
	hud.set_wind_progress(course.current_count(), 2)
	hud.show_caption("Clean pass!" if clean else "Wind caught!")
	Sfx.play("wind_gain", -12.0, 1.1 if clean else 1.0)
	if Settings.shake_on:
		Input.vibrate_handheld(18)


## Swept checks catch fast movement; separate arch blocks leave their holes open.
func hits_ruin(from: Vector3, to: Vector3) -> bool:
	for obstacle: Dictionary in _obstacles:
		if obstacle.perch == link() and from.y >= perch_position(link()).y - 0.1:
			if Vector2(from.x - perch_position(link()).x, from.z - perch_position(link()).z).length() < 7.0:
				continue
		var bounds: AABB = obstacle.bounds
		if bounds.grow(0.45).intersects_segment(from, to) == null:
			continue
		var inverse: Transform3D = obstacle.inverse
		var local_bounds: AABB = obstacle.local_bounds
		if local_bounds.grow(float(obstacle.margin)).intersects_segment(inverse * from, inverse * to) != null:
			return true
	return false


func _build_boost_trail() -> void:
	_boost_trail = CPUParticles3D.new()
	_boost_trail.amount = 20
	_boost_trail.lifetime = 0.35
	_boost_trail.local_coords = false
	_boost_trail.gravity = Vector3.ZERO
	_boost_trail.initial_velocity_min = 2.0
	_boost_trail.initial_velocity_max = 4.0
	_boost_trail.spread = 10.0
	_boost_trail.particle_flag_align_y = true
	var streak := BoxMesh.new()
	streak.size = Vector3(0.025, 0.25, 0.025)
	_boost_trail.mesh = streak
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#b7f2e0")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_boost_trail.material_override = material
	_boost_trail.emitting = false
	add_child(_boost_trail)


func _register_obstacle(bounds: AABB, transform: Transform3D, perch: int) -> void:
	var scale := transform.basis.get_scale().abs()
	_obstacles.append({"bounds": transform * bounds, "local_bounds": bounds,
		"inverse": transform.affine_inverse(), "margin": 0.45 / minf(scale.x, minf(scale.y, scale.z)), "perch": perch})


func _build_civic_skyline() -> void:
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var tower := Civilisation3D.highrise(38.0 + (i % 3) * 12.0, i)
			tower.position = Vector3(side * (72.0 + (i % 2) * 8.0), 0, -35.0 - i * 70.0)
			tower.rotation.y = side * 0.12
			add_child(tower)
			for shape: Dictionary in tower.get_meta("major_solids", []):
				_register_obstacle(shape.bounds, tower.transform * (shape.transform as Transform3D), -1)
			if i < 3:
				var bridge := Civilisation3D.broken_skybridge()
				bridge.position = Vector3(side * 76.0, 24.0, -70.0 - i * 70.0)
				add_child(bridge)
				for shape: Dictionary in bridge.get_meta("major_solids", []):
					_register_obstacle(shape.bounds, bridge.transform * (shape.transform as Transform3D), -1)
