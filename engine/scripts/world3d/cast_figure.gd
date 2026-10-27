class_name CastFigure
extends Node3D
## A cast member in 3D: Quaternius's CC0 animated mannequin (Universal Animation
## Library, 45 animations on a humanoid rig), recoloured to the character's skin and
## dressed from data/cast.json with clothing, hair and items attached to its bones.
## Clothing is defined between joint positions of the rest pose, so it fits the body
## and follows every animation. The figure faces -Z (the world's "up the screen").

const MODEL := preload("res://assets/third_party/quaternius_ual/ual_standard.glb")
const CAST_PATH := "res://data/cast.json"

## Gameplay name -> animation in the library.
const ANIMATIONS := {
	"idle": "Idle",
	"talk": "Idle_Talking",
	"walk": "Walk",
	"run": "Jog_Fwd",
	"strike": "Sword_Attack",
	"dodge": "Roll",
	"hit": "Hit_Chest",
	"fix": "Fixing_Kneeling",
	"interact": "Interact",
	"pick_up": "PickUp_Table",
	"death": "Death01",
}
const ONE_SHOT := ["strike", "dodge", "hit", "interact", "pick_up", "death"]

static var _cast: Dictionary = {}

var character := "tavo"
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var _model: Node3D
var _looping := "idle"
var _materials: Dictionary = {}
## Rest-pose joint positions (skeleton space) and the figure's forward/side/up.
var _joints: Dictionary = {}
var _forward := Vector3.FORWARD
var _side := Vector3.RIGHT
var _up := Vector3.UP


static func cast() -> Dictionary:
	if _cast.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAST_PATH))
		_cast = data.cast if typeof(data) == TYPE_DICTIONARY else {}
	return _cast


static func create(character_name: String) -> CastFigure:
	var figure := CastFigure.new()
	figure.character = character_name
	figure.name = character_name.capitalize()
	return figure


func _ready() -> void:
	_model = MODEL.instantiate()
	add_child(_model)
	skeleton = _model.find_children("", "Skeleton3D", true, false)[0]
	animation_player = _model.find_children("", "AnimationPlayer", true, false)[0]
	for loop_name: String in ["idle", "talk", "walk", "run", "fix"]:
		var animation := animation_player.get_animation(ANIMATIONS[loop_name])
		if animation != null:
			animation.loop_mode = Animation.LOOP_LINEAR
	animation_player.animation_finished.connect(_on_animation_finished)
	_read_joints()
	_face_forward()
	_dress(cast().get(character, cast()["tavo"]))
	play(_looping)


## Loops ("idle", "walk", "run", "talk", "fix") replace each other; one-shots
## ("strike", "dodge", "hit"...) play once and return to the current loop.
func play(action: String, speed := 1.0) -> void:
	if not is_node_ready():
		_looping = action
		return
	var clip: String = ANIMATIONS.get(action, "Idle")
	if action in ONE_SHOT:
		animation_player.play(clip, 0.1, speed)
	else:
		_looping = action
		if animation_player.current_animation != clip:
			animation_player.play(clip, 0.2, speed)
		animation_player.speed_scale = speed


func set_moving(moving: bool, speed_ratio := 1.0) -> void:
	if animation_player != null and ANIMATIONS.values().has(animation_player.current_animation) \
			and animation_player.current_animation in [ANIMATIONS.strike, ANIMATIONS.dodge, ANIMATIONS.hit]:
		return
	if moving:
		play("walk", clampf(speed_ratio, 0.6, 1.6))
	elif _looping == "walk":
		play("idle")


func _on_animation_finished(_clip: StringName) -> void:
	animation_player.play(ANIMATIONS[_looping], 0.2)


# --- Fitting clothes to the rig ---------------------------------------------------

func _read_joints() -> void:
	for i in skeleton.get_bone_count():
		_joints[skeleton.get_bone_name(i)] = skeleton.get_bone_global_rest(i).origin
	_up = (_joint("DEF-head") - _joint("DEF-hips")).normalized()
	var toe := _joint("DEF-toe.L") - _joint("DEF-foot.L")
	_forward = (toe - _up * toe.dot(_up)).normalized()
	_side = _forward.cross(_up).normalized()


## Turns the imported model so its face points along -Z like everything else.
func _face_forward() -> void:
	var model_forward := skeleton.global_transform.basis * _forward
	model_forward.y = 0.0
	if model_forward.length() > 0.01:
		_model.rotation.y = model_forward.signed_angle_to(Vector3.FORWARD, Vector3.UP)


func _joint(bone: String) -> Vector3:
	return _joints.get(bone, Vector3.ZERO)


func _attach(bone: String) -> BoneAttachment3D:
	var holder := skeleton.get_node_or_null("Wear_" + bone.replace(".", "_")) as BoneAttachment3D
	if holder == null:
		holder = BoneAttachment3D.new()
		holder.name = "Wear_" + bone.replace(".", "_")
		holder.bone_name = bone
		skeleton.add_child(holder)
	return holder


## Places a mesh, given in skeleton (rest pose) space, on a bone so it follows it.
func _place(bone: String, mesh: Mesh, color: Color, rest_transform: Transform3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	var bone_rest := skeleton.get_bone_global_rest(skeleton.find_bone(bone))
	instance.transform = bone_rest.affine_inverse() * rest_transform
	_attach(bone).add_child(instance)
	return instance


## A capsule from one rest-pose point to another, riding on `bone`.
func _segment(bone: String, from: Vector3, to: Vector3, radius: float, color: Color,
		squash := Vector2.ONE) -> MeshInstance3D:
	var direction := (to - from).normalized()
	var helper := _side if absf(direction.dot(_side)) < 0.9 else _forward
	var x_axis := helper.cross(direction).normalized()
	var z_axis := x_axis.cross(direction).normalized()
	var basis := Basis(x_axis * squash.x, direction, z_axis * squash.y)
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(from.distance_to(to) + radius * 2.0, radius * 2.0)
	mesh.radial_segments = 12
	mesh.rings = 4
	return _place(bone, mesh, color, Transform3D(basis, (from + to) / 2.0))


func _ball(bone: String, center: Vector3, radius: float, color: Color, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 7
	var basis := Basis(_side * scale.x, _up * scale.y, -_forward * scale.z)
	return _place(bone, mesh, color, Transform3D(basis, center))


func _cone(bone: String, center: Vector3, top: float, bottom: float, height: float, color: Color,
		depth_scale := 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 14
	var basis := Basis(_side, _up, -_forward * depth_scale)
	return _place(bone, mesh, color, Transform3D(basis, center))


func _block(bone: String, center: Vector3, size: Vector3, color: Color, tilt := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var basis := Basis(_side, _up, -_forward).rotated(_forward, tilt)
	return _place(bone, mesh, color, Transform3D(basis, center))


func _dress(c: Dictionary) -> void:
	var extras: Array = c.get("extras", [])
	var skin := Color(c.skin)
	var top := Color(c.top)
	var accent := Color(c.accent)
	var bottom := Color(c.bottom)
	var hair := Color(c.hair_color)
	if extras.has("wet"):
		skin = skin.lerp(Color("#3a4a5a"), 0.35)
		top = top.lerp(Color("#2c4a63"), 0.3)
		bottom = bottom.lerp(Color("#2c4a63"), 0.3)
	# The mannequin itself becomes the character's skin (two surfaces: body and joints).
	for mesh_instance: MeshInstance3D in _model.find_children("", "MeshInstance3D", true, false):
		for surface in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(surface, _material(skin if surface == 0 else skin.darkened(0.12)))

	var hips := _joint("DEF-hips")
	var chest_top := _joint("DEF-neck")
	var head := _joint("DEF-head")
	var head_center := head + _up * 0.1

	# Trousers or bare legs, and shoes.
	for side: String in ["L", "R"]:
		var thigh := _joint("DEF-thigh." + side)
		var knee := _joint("DEF-shin." + side)
		var ankle := _joint("DEF-foot." + side)
		var toe := _joint("DEF-toe." + side)
		if c.lower == "trousers":
			_segment("DEF-thigh." + side, thigh, knee, 0.105, bottom)
			_segment("DEF-shin." + side, knee, ankle, 0.085, bottom)
		_segment("DEF-foot." + side, ankle - _up * 0.04, toe + _forward * 0.03, 0.055, Color("#2b1d13"))
	match c.lower:
		"wrap":
			var length := hips.y - 0.18
			_cone("DEF-hips", hips - _up * (length / 2.0 - 0.05), 0.2, 0.3, length, bottom, 0.8)
			_cone("DEF-hips", hips - _up * (length - 0.03), 0.302, 0.305, 0.07, accent, 0.8)
		"robe":
			var length := chest_top.y - 0.12
			_cone("DEF-spine.003", chest_top - _up * (length / 2.0), 0.2, 0.36, length, bottom, 0.8)
			_block("DEF-spine.003", chest_top - _up * (length / 2.0) + _forward * 0.25, Vector3(0.06, length * 0.95, 0.02), accent)

	# Shirt over the torso, with a sash at the waist.
	_segment("DEF-spine.001", hips + _up * 0.05, _joint("DEF-spine.003"), 0.16, top, Vector2(1.25, 0.85))
	_segment("DEF-spine.003", _joint("DEF-spine.003"), chest_top - _up * 0.03, 0.17, top, Vector2(1.3, 0.9))
	if c.lower != "robe":
		_cone("DEF-spine.001", hips + _up * 0.12, 0.185, 0.19, 0.08, accent, 0.75)
	for side: String in ["L", "R"]:
		var shoulder := _joint("DEF-upper_arm." + side)
		var elbow := _joint("DEF-forearm." + side)
		_segment("DEF-upper_arm." + side, shoulder, shoulder.lerp(elbow, 0.7), 0.075, top)

	# Face and hair (the mannequin's head is smooth).
	for sign: float in [-1.0, 1.0]:
		_ball("DEF-head", head_center + _forward * 0.105 + _side * 0.042 * sign + _up * 0.02, 0.019, Color("#120c08"))
	_hair(c.hair, hair, head_center)

	# Items.
	var right_hand := _joint("DEF-hand.R")
	var hand_forward := right_hand + _forward * 0.05
	if extras.has("hammer"):
		_segment("DEF-hand.R", hand_forward - _forward * 0.05, hand_forward + _forward * 0.32, 0.018, Color("#8a6a44"))
		_block("DEF-hand.R", hand_forward + _forward * 0.34, Vector3(0.08, 0.08, 0.16), Color("#9aa2a8"))
	if extras.has("spear"):
		_segment("DEF-hand.R", right_hand - _up * 0.9, right_hand + _up * 1.0, 0.018, Color("#7a5a3a"))
		_cone("DEF-hand.R", right_hand + _up * 1.1, 0.0, 0.045, 0.2, Color("#9aa2a8"))
	if extras.has("tongs"):
		_segment("DEF-hand.R", right_hand, right_hand + _forward * 0.35, 0.012, Color("#5f666b"))
	if extras.has("spanner"):
		_segment("DEF-hand.R", right_hand, right_hand + _forward * 0.28, 0.015, Color("#8a9096"))
	if extras.has("satchel") or extras.has("medbag"):
		var bag := Color("#e8e2d0") if extras.has("medbag") else Color("#9a6230")
		_block("DEF-hips", hips + _side * 0.22 + _up * 0.02, Vector3(0.08, 0.2, 0.26), bag)
		_segment("DEF-spine.003", _joint("DEF-shoulder.L") + _up * 0.03, hips + _side * 0.22 + _up * 0.1, 0.02, Color("#6b411c"))
		if extras.has("medbag"):
			_block("DEF-hips", hips + _side * 0.265 + _up * 0.02, Vector3(0.01, 0.07, 0.07), Color("#4f8a4a"))
	if extras.has("apron"):
		_block("DEF-spine.001", hips + _up * 0.2 + _forward * 0.13, Vector3(0.32, 0.55, 0.025), accent)
	if extras.has("scarf"):
		_cone("DEF-neck", chest_top + _up * 0.02, 0.1, 0.13, 0.08, Color("#c96f3b"))
		_block("DEF-spine.003", chest_top - _up * 0.2 + _forward * 0.15 + _side * 0.07, Vector3(0.09, 0.35, 0.025), Color("#c96f3b"))
	if extras.has("shawl"):
		_cone("DEF-spine.003", chest_top - _up * 0.12, 0.17, 0.27, 0.32, hair, 0.85)
	if extras.has("beard"):
		_ball("DEF-head", head_center + _forward * 0.07 - _up * 0.07, 0.085, hair, Vector3(1.0, 0.75, 0.8))
	if extras.has("waterskin"):
		_ball("DEF-hips", hips - _side * 0.22, 0.09, Color("#8a6a44"), Vector3(0.8, 1.2, 0.8))
	if extras.has("goggles"):
		_cone("DEF-head", head_center + _up * 0.07, 0.125, 0.125, 0.03, Color("#5a4a3a"))
	if extras.has("armband"):
		var shoulder := _joint("DEF-upper_arm.L")
		_segment("DEF-upper_arm.L", shoulder.lerp(_joint("DEF-forearm.L"), 0.72), shoulder.lerp(_joint("DEF-forearm.L"), 0.82), 0.08, accent)
	if extras.has("wrist_cuts"):
		var wrist := _joint("DEF-hand.L")
		for i in 3:
			_ball("DEF-forearm.L", wrist.lerp(_joint("DEF-forearm.L"), 0.1 + i * 0.05) + _forward * 0.035, 0.008, Color("#3a2214"))


func _hair(style: String, color: Color, center: Vector3) -> void:
	match style:
		"short":
			_ball("DEF-head", center + _up * 0.04 - _forward * 0.01, 0.112, color, Vector3(1.0, 0.75, 1.05))
		"braids":
			_ball("DEF-head", center + _up * 0.04 - _forward * 0.01, 0.115, color, Vector3(1.02, 0.78, 1.06))
			for offset: float in [-0.08, -0.04, 0.04, 0.08]:
				_segment("DEF-head", center + _side * offset - _forward * 0.06, center + _side * offset * 1.3 - _forward * 0.08 - _up * 0.24, 0.018, color)
		"bun":
			_ball("DEF-head", center + _up * 0.04 - _forward * 0.01, 0.112, color, Vector3(1.0, 0.75, 1.05))
			_ball("DEF-head", center + _up * 0.1 - _forward * 0.08, 0.055, color)
		"wrap":
			_ball("DEF-head", center + _up * 0.07 - _forward * 0.01, 0.13, color, Vector3(1.05, 0.85, 1.1))
			_ball("DEF-head", center + _up * 0.16 + _side * 0.06, 0.05, color)
		"hood":
			_ball("DEF-head", center + _up * 0.02 - _forward * 0.03, 0.14, color, Vector3(1.05, 1.05, 1.0))


func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.8
		_materials[key] = material
	return _materials[key]
