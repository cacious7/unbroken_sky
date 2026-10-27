class_name Character3D
extends Node3D
## A stylised low-poly person built in code from data/cast.json, facing -Z, feet at y = 0,
## about 1.7 m tall. Simple procedural animation: walking swings arms and legs, idle
## breathes, `swing()` raises the right arm for a hammer blow.

const CAST_PATH := "res://data/cast.json"

static var _cast: Dictionary = {}

var walking := false
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _body: Node3D
var _time := 0.0
var _swing_left := 0.0
var _materials: Dictionary = {}


static func cast() -> Dictionary:
	if _cast.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAST_PATH))
		_cast = data.cast if typeof(data) == TYPE_DICTIONARY else {}
	return _cast


static func create(character: String) -> Character3D:
	var figure := Character3D.new()
	figure.name = character.capitalize()
	figure._build(cast().get(character, cast()["tavo"]))
	return figure


func swing() -> void:
	_swing_left = 0.25


func _process(delta: float) -> void:
	_time += delta
	_swing_left = maxf(_swing_left - delta, 0.0)
	var stride := sin(_time * 9.0) * 0.55 if walking else 0.0
	if _legs.size() == 2:
		_legs[0].rotation.x = stride
		_legs[1].rotation.x = -stride
	if _arms.size() == 2:
		_arms[0].rotation.x = -stride * 0.7
		_arms[1].rotation.x = stride * 0.7
		if _swing_left > 0.0:
			# Hammer blow: right arm up and over.
			_arms[1].rotation.x = -2.4 * sin(PI * _swing_left / 0.25)
	_body.position.y = absf(sin(_time * 9.0)) * 0.04 if walking else sin(_time * 2.0) * 0.008


func _build(c: Dictionary) -> void:
	var extras: Array = c.get("extras", [])
	var skin := Color(c.skin)
	var top := Color(c.top)
	var accent := Color(c.accent)
	var bottom := Color(c.bottom)
	var hair := Color(c.hair_color)
	if extras.has("wet"):
		# The counterfeit mother: darker, colder, glistening.
		skin = skin.lerp(Color("#3a4a5a"), 0.35)
		top = top.lerp(Color("#2c4a63"), 0.3)
		bottom = bottom.lerp(Color("#2c4a63"), 0.3)
	_body = Node3D.new()
	add_child(_body)

	# Legs (hidden under a wrap or robe, but still there for the walk).
	for side: float in [-1.0, 1.0]:
		var hip := _pivot(Vector3(0.1 * side, 0.82, 0))
		_capsule(hip, 0.085, 0.8, bottom, Vector3(0, -0.4, 0))
		_box(hip, Vector3(0.13, 0.07, 0.24), Color("#2b1d13"), Vector3(0, -0.8, -0.04))
		_legs.append(hip)
	match c.lower:
		"wrap":
			_cone(_body, 0.2, 0.3, 0.72, bottom, Vector3(0, 0.46, 0))
			_cone(_body, 0.302, 0.305, 0.06, accent, Vector3(0, 0.16, 0))
		"robe":
			_cone(_body, 0.22, 0.34, 1.2, bottom, Vector3(0, 0.7, 0))
			_box(_body, Vector3(0.06, 1.15, 0.02), accent, Vector3(0, 0.72, -0.27))

	# Torso, sash and arms.
	_capsule(_body, 0.2, 0.66, top, Vector3(0, 1.14, 0))
	if c.lower != "robe":
		_cone(_body, 0.205, 0.205, 0.09, accent, Vector3(0, 0.98, 0))
	for side: float in [-1.0, 1.0]:
		var shoulder := _pivot(Vector3(0.27 * side, 1.38, 0))
		_capsule(shoulder, 0.07, 0.3, top, Vector3(0, -0.12, 0))
		_capsule(shoulder, 0.06, 0.38, skin, Vector3(0, -0.4, 0))
		_arms.append(shoulder)
	var right_hand := _arms[1]

	# Neck, head, face.
	_capsule(_body, 0.06, 0.16, skin, Vector3(0, 1.5, 0))
	_sphere(_body, 0.16, skin, Vector3(0, 1.64, 0))
	for side: float in [-1.0, 1.0]:
		_sphere(_body, 0.024, Color("#120c08"), Vector3(0.058 * side, 1.66, -0.148))
	_hair(c.hair, hair)

	# Extras.
	if extras.has("satchel"):
		_box(_body, Vector3(0.08, 0.5, 0.05), Color("#7a4b22"), Vector3(0, 1.15, -0.2)).rotation.z = 0.7
		_box(_body, Vector3(0.1, 0.22, 0.28), Color("#9a6230"), Vector3(0.24, 0.86, 0))
	if extras.has("medbag"):
		_box(_body, Vector3(0.1, 0.22, 0.28), Color("#e8e2d0"), Vector3(0.24, 0.86, 0))
		_box(_body, Vector3(0.02, 0.08, 0.08), Color("#4f8a4a"), Vector3(0.3, 0.88, 0))
	if extras.has("hammer"):
		_cylinder(right_hand, 0.022, 0.4, Color("#8a6a44"), Vector3(0, -0.62, -0.12), Vector3(PI / 2.0, 0, 0))
		_box(right_hand, Vector3(0.09, 0.09, 0.18), Color("#9aa2a8"), Vector3(0, -0.62, -0.32))
	if extras.has("spear"):
		_cylinder(right_hand, 0.02, 2.0, Color("#7a5a3a"), Vector3(0, -0.15, -0.05))
		_cone(right_hand, 0.0, 0.05, 0.22, Color("#9aa2a8"), Vector3(0, 0.95, -0.05))
	if extras.has("tongs"):
		_box(right_hand, Vector3(0.03, 0.45, 0.03), Color("#5f666b"), Vector3(0, -0.75, -0.05))
	if extras.has("spanner"):
		_box(right_hand, Vector3(0.04, 0.35, 0.04), Color("#8a9096"), Vector3(0, -0.72, -0.05))
	if extras.has("waterskin"):
		_sphere(_body, 0.11, Color("#8a6a44"), Vector3(-0.26, 0.85, 0.05)).scale = Vector3(0.8, 1.2, 0.8)
	if extras.has("apron"):
		_box(_body, Vector3(0.34, 0.6, 0.03), accent, Vector3(0, 0.95, -0.2))
	if extras.has("armband"):
		_cylinder(_arms[0], 0.075, 0.06, accent, Vector3(0, -0.18, 0))
	if extras.has("scarf"):
		var scarf := _torus(_body, 0.1, 0.17, Color("#c96f3b"), Vector3(0, 1.48, 0))
		scarf.rotation.x = 0.15
		_box(_body, Vector3(0.1, 0.4, 0.03), Color("#c96f3b"), Vector3(0.1, 1.25, -0.19))
	if extras.has("shawl"):
		_cone(_body, 0.24, 0.3, 0.45, hair, Vector3(0, 1.25, 0.02))
		for spot: Vector3 in [Vector3(0.18, 1.3, -0.15), Vector3(-0.2, 1.2, -0.12), Vector3(0.05, 1.4, -0.22), Vector3(-0.1, 1.1, 0.22)]:
			_sphere(_body, 0.035, Color("#3a3024"), spot)
	if extras.has("beard"):
		_sphere(_body, 0.12, hair, Vector3(0, 1.55, -0.07)).scale = Vector3(1.0, 0.8, 0.8)
	if extras.has("goggles"):
		_torus(_body, 0.15, 0.175, Color("#5a4a3a"), Vector3(0, 1.72, 0)).rotation.x = 0.25
	if extras.has("wet"):
		for drip: Vector3 in [Vector3(0.2, 0.6, -0.2), Vector3(-0.25, 0.9, -0.1), Vector3(0.1, 0.3, -0.28), Vector3(-0.15, 1.2, -0.2)]:
			_sphere(_body, 0.03, Color("#6fa3c8"), drip)
		var pool := _cylinder(self, 0.45, 0.01, Color("#2c4a63"), Vector3(0, 0.005, 0))
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _hair(style: String, color: Color) -> void:
	match style:
		"short":
			_sphere(_body, 0.168, color, Vector3(0, 1.69, 0.02)).scale = Vector3(1.0, 0.62, 1.0)
		"braids":
			_sphere(_body, 0.17, color, Vector3(0, 1.69, 0.02)).scale = Vector3(1.02, 0.66, 1.02)
			for x: float in [-0.13, -0.07, 0.07, 0.13]:
				_capsule(_body, 0.025, 0.36, color, Vector3(x, 1.48, 0.07))
		"bun":
			_sphere(_body, 0.168, color, Vector3(0, 1.69, 0.02)).scale = Vector3(1.0, 0.62, 1.0)
			_sphere(_body, 0.08, color, Vector3(0, 1.8, 0.1))
		"wrap":
			_sphere(_body, 0.19, color, Vector3(0, 1.74, 0.02)).scale = Vector3(1.05, 0.75, 1.05)
			_sphere(_body, 0.07, color, Vector3(0.1, 1.86, 0.06))
		"hood":
			_sphere(_body, 0.2, color, Vector3(0, 1.67, 0.05)).scale = Vector3(1.05, 1.0, 1.0)


# --- Mesh helpers -----------------------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.8
		_materials[key] = material
	return _materials[key]


func _pivot(position: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = position
	_body.add_child(pivot)
	return pivot


func _add(parent: Node3D, mesh: Mesh, color: Color, position: Vector3, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = position
	instance.rotation = rotation
	parent.add_child(instance)
	return instance


func _capsule(parent: Node3D, radius: float, height: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 10
	mesh.rings = 4
	return _add(parent, mesh, color, position)


func _sphere(parent: Node3D, radius: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _add(parent, mesh, color, position)


func _box(parent: Node3D, size: Vector3, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, color, position)


func _cylinder(parent: Node3D, radius: float, height: float, color: Color, position: Vector3,
		rotation := Vector3.ZERO) -> MeshInstance3D:
	return _cone(parent, radius, radius, height, color, position, rotation)


func _cone(parent: Node3D, top_radius: float, bottom_radius: float, height: float, color: Color,
		position: Vector3, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	return _add(parent, mesh, color, position, rotation)


func _torus(parent: Node3D, inner: float, outer: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 16
	mesh.ring_segments = 6
	return _add(parent, mesh, color, position)
