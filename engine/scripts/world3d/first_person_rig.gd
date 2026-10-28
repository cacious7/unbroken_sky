extends Node3D
## Eye-level play; scripted story shots may temporarily own the camera.
const HAND_REST := Vector3(0.12, -0.15, 0.06)
## Husks closer than this (world units) and outside the view get a ring cue.
const THREAT_CUE_RANGE := 260.0
## Half the horizontal view, in radians, treated as "seen" for that cue.
const THREAT_CUE_HALF_VIEW := 0.85

var _view: Node3D
var _camera: Camera3D
var _player: Player
var yaw := 0.0
var pitch := -0.08
var _hands: Node3D
var _sway: Node3D
var _hand_actor: CastFigure
var _sleeves: Array[MeshInstance3D] = []
var _pin: MeshInstance3D
var _gesture: Tween
var _repairing := false
var _time := 0.0
var _aim: CanvasLayer
var _aim_canvas: Control
var _distance: Label
var _goal_angle := 0.0
var _has_goal := false
var _body_geometry: Array[GeometryInstance3D] = []
var _last_body_cinematic := false
var _damage_left := 0.0
var _damage_source := Vector2.ZERO
var _hit_left := 0.0
var _hit_color := Color.WHITE


func configure(view: Node3D, camera: Camera3D) -> void:
	_view = view
	_camera = camera
	_player = (view.get("scene") as Node).get_node("Player")


func _ready() -> void:
	add_to_group("first_person_rig")
	_player.first_person_controls = true
	_camera.near = 0.035
	_camera.fov = 72.0
	for mesh: GeometryInstance3D in (_view.get("tavo") as Node3D).find_children("", "GeometryInstance3D", true, false):
		_body_geometry.append(mesh)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_build_hands()
	_build_aim()
	_player.struck.connect(_on_struck)
	_player.hit_received.connect(_on_hit_received)
	_player.dodged.connect(func() -> void: gesture(false))
	update_camera(0.0, true)
	capture_mouse_if_active()


func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func capture_mouse_if_active() -> void:
	if DisplayServer.get_name() == "headless" or DisplayServer.is_touchscreen_available():
		return
	var active := _player.active and not get_tree().paused and (_view.get("_shot") as Dictionary).is_empty()
	var wanted := Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != wanted:
		Input.mouse_mode = wanted


func look_delta(delta: Vector2) -> void:
	if not _player.active or get_tree().paused or not (_view.get("_shot") as Dictionary).is_empty():
		return
	yaw -= delta.x * 0.004
	pitch = clampf(pitch - delta.y * 0.0035, -1.15, 1.15)
	_player.view_yaw = yaw
	_player.aim_direction = Vector2(-sin(yaw), -cos(yaw))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event.device != InputEvent.DEVICE_ID_EMULATION:
		look_delta(event.relative * 0.65)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time += delta
	_damage_left = maxf(0.0, _damage_left - delta)
	_hit_left = maxf(0.0, _hit_left - delta)
	var moving := minf(_player.velocity.length() / Player.SPEED, 1.0) if Settings.shake_on and _player.active else 0.0
	_sway.position = Vector3(sin(_time * 9.0) * 0.006, absf(sin(_time * 14.0)) * -0.008, 0) * moving
	_update_sleeves()
	capture_mouse_if_active()
	_player.view_yaw = yaw
	_player.aim_direction = Vector2(-sin(yaw), -cos(yaw))
	var cinematic: bool = not (_view.get("_shot") as Dictionary).is_empty() or _view.get("_collapsing")
	(_view.get("tavo") as Node3D).visible = _player.visible
	if cinematic != _last_body_cinematic:
		for mesh in _body_geometry:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cinematic else GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		_last_body_cinematic = cinematic
	_hands.visible = not cinematic and (_player.active or _repairing)
	_pin.visible = GameState.get_flag("sc02_pin_collected") and not GameState.get_flag("sc02_pump_repaired")
	_aim.visible = _player.active and not cinematic
	var scene: Node = _view.get("scene")
	var goal: Node2D = scene.guidance_target()
	_has_goal = goal != null
	if goal != null:
		var toward := goal.global_position - _player.global_position
		_goal_angle = -wrapf(atan2(-toward.x, -toward.y) - yaw, -PI, PI)
		_distance.text = "%dm" % maxi(1, roundi(toward.length() * 0.025))
	_distance.visible = _has_goal
	_aim_canvas.queue_redraw()


func update_camera(delta: float, snap := false) -> void:
	var scene: Node = _view.get("scene")
	var height: float = _view.keeper_height(_player.position) if scene.name == "KeeperRoom" else 0.0
	var target := Vector3(_player.global_position.x * 0.025, height + 1.68, _player.global_position.y * 0.025)
	_camera.position.x = target.x
	_camera.position.z = target.z
	_camera.position.y = target.y if snap else lerpf(_camera.position.y, target.y, 1.0 - exp(-18.0 * delta))
	_camera.rotation = Vector3(pitch, yaw, 0)
	_camera.fov = lerpf(_camera.fov, 72.0, minf(delta * 10.0, 1.0)) if not snap else 72.0


func face_point(point: Vector3) -> void:
	var direction := point - _camera.position
	yaw = atan2(-direction.x, -direction.z)
	pitch = clampf(atan2(direction.y, Vector2(direction.x, direction.z).length()), -1.15, 1.15)


func set_repairing(on: bool) -> void:
	_repairing = on


func gesture(strike := false) -> void:
	_hand_actor.play("strike" if strike else "interact", 1.25)
	if _gesture != null:
		_gesture.kill()
	_gesture = create_tween()
	_gesture.tween_property(_hands, "position", HAND_REST + (Vector3(-0.10, 0.10, -0.17) if strike else Vector3(-0.04, 0.03, -0.08)), 0.10)
	_gesture.tween_property(_hands, "position", HAND_REST, 0.16)


func _build_hands() -> void:
	_hands = Node3D.new()
	_hands.name = "FirstPersonHands"
	_hands.position = HAND_REST
	_camera.add_child(_hands)
	_sway = Node3D.new()
	_hands.add_child(_sway)
	_hand_actor = CastFigure.create("tavo")
	_hand_actor.position = Vector3(0.07, -1.60, -0.30)
	_sway.add_child(_hand_actor)
	_hand_actor.show_arms_only()
	_hand_actor.play("hold_tool")
	for side: float in [-1.0, 1.0]:
		var sleeve := MeshInstance3D.new()
		var shape := CapsuleMesh.new()
		shape.radius = 0.075
		shape.height = 0.35
		shape.radial_segments = 12
		shape.rings = 5
		sleeve.mesh = shape
		var fabric := StandardMaterial3D.new()
		fabric.albedo_color = Color("#2f4f7a")
		fabric.roughness = 0.9
		sleeve.material_override = fabric
		_sway.add_child(sleeve)
		_sleeves.append(sleeve)
	var pin_mesh := CylinderMesh.new()
	pin_mesh.top_radius = 0.014
	pin_mesh.bottom_radius = 0.014
	pin_mesh.height = 0.16
	var at := _hand_actor._joint("DEF-hand.L") + _hand_actor._forward * 0.055
	_pin = _hand_actor._place("DEF-hand.L", pin_mesh, Color("#c28d54"), Transform3D(Basis.IDENTITY, at))
	_pin.material_override = Materials3D.civic("bronze")
	for mesh: GeometryInstance3D in _hands.find_children("", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_aim() -> void:
	_aim = CanvasLayer.new()
	_aim.layer = 7
	add_child(_aim)
	_aim_canvas = Control.new()
	_aim_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_aim_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aim_canvas.draw.connect(_draw_aim)
	_aim.add_child(_aim_canvas)
	_distance = Label.new()
	_distance.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_distance.offset_left = -32
	_distance.offset_right = 32
	_distance.offset_top = 48
	_distance.offset_bottom = 72
	_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_distance.add_theme_font_size_override("font_size", 15)
	_distance.add_theme_color_override("font_color", Color("#edc57d"))
	_distance.add_theme_color_override("font_outline_color", Color("#172e38"))
	_distance.add_theme_constant_override("outline_size", 3)
	_distance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aim_canvas.add_child(_distance)


func _draw_aim() -> void:
	var center := _aim_canvas.size * 0.5
	var color := Color("#edc57d") if _player.focus_target() != null else Color(0.92, 0.96, 0.94, 0.8)
	for axis: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_aim_canvas.draw_line(center + axis * 3.0, center + axis * 7.0, color, 1.5, true)
	if _hit_left > 0.0:
		var confirmation := _hit_color
		confirmation.a = minf(1.0, _hit_left * 5.0)
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			_aim_canvas.draw_line(center + corner * 11, center + corner * 17, confirmation, 2, true)
	if _damage_left > 0.0:
		var bearing := _screen_bearing(_damage_source - _player.global_position)
		_aim_canvas.draw_arc(center, 74, bearing - 0.36, bearing + 0.36, 20, Color(0.95, 0.26, 0.15, minf(0.85, _damage_left)), 5, true)
	if _player.combat_enabled and _player.active:
		_draw_offscreen_threats(center)
	if _has_goal:
		var origin := Vector2(center.x, 29)
		var points := PackedVector2Array()
		for point: Vector2 in [Vector2(-7, 7), Vector2(0, -8), Vector2(7, 7), Vector2(0, 3)]:
			points.append(origin + point.rotated(_goal_angle))
		_aim_canvas.draw_colored_polygon(points, Color("#edc57d"))


## Canvas angle on the reticle ring for a world direction; straight ahead is up.
func _screen_bearing(toward: Vector2) -> float:
	return -wrapf(atan2(-toward.x, -toward.y) - yaw, -PI, PI) - PI / 2.0


## A husk the player cannot see marks the ring on its side: faint while it closes in,
## brightening and thickening through its windup so a strike from behind is fair.
func _draw_offscreen_threats(center: Vector2) -> void:
	for husk: Husk in offscreen_threats():
		var progress := husk.windup_progress()
		var bearing := _screen_bearing(husk.global_position - _player.global_position)
		var color := Color(1.0, 0.6, 0.12, 0.35 + 0.6 * progress if husk.state == Husk.State.WINDUP else 0.3)
		_aim_canvas.draw_arc(center, 82, bearing - 0.28, bearing + 0.28, 16, color, 3.0 + 4.0 * progress, true)


## Active husks near enough to matter but outside the view.
func offscreen_threats() -> Array[Husk]:
	var found: Array[Husk] = []
	for node in get_tree().get_nodes_in_group("hammer_target"):
		var husk := node as Husk
		if husk == null or not husk.is_threat() or not husk.visible:
			continue
		var toward := husk.global_position - _player.global_position
		if toward.length() <= THREAT_CUE_RANGE and toward.normalized().dot(_player.aim_direction) < cos(THREAT_CUE_HALF_VIEW):
			found.append(husk)
	return found


func _update_sleeves() -> void:
	for i in _sleeves.size():
		var side := -1.0 if i == 0 else 1.0
		var bone := "DEF-forearm.L" if i == 0 else "DEF-forearm.R"
		var elbow := _sway.to_local(_hand_actor.bone_position(bone))
		var shoulder := Vector3(side * 0.30, -0.48, 0.12)
		var sleeve := _sleeves[i]
		(sleeve.mesh as CapsuleMesh).height = maxf(0.15, shoulder.distance_to(elbow) + 0.12)
		sleeve.position = (shoulder + elbow) * 0.5
		if shoulder.distance_to(elbow) > 0.01:
			sleeve.quaternion = Quaternion(Vector3.UP, (elbow - shoulder).normalized())


func _on_struck(result: String) -> void:
	gesture(true)
	if result != "miss":
		_hit_left = 0.28
		_hit_color = Color("#edc57d") if result in ["break", "interrupt"] else Color("#e5f3ee")


func _on_hit_received(source: Vector2) -> void:
	_damage_source = source
	_damage_left = 1.0
