class_name Husk3D
extends Node3D
## The 3D body of a Husk: a clay-and-copper maintenance shell (invented design, not a
## mask or ceremonial figure). Mirrors the gameplay Husk's state every frame:
## approach (lumbering bob), windup (orange glow, leaning back, light), strike (red,
## lunging), recovery (copper connector ringed in white), broken (toppled, dark).

var husk: Husk
var _body: Node3D
var _shell: StandardMaterial3D
var _glow: OmniLight3D
var _ring: MeshInstance3D
var _time := 0.0

const CLAY := Color("#8c7b6c")
const COPPER := Color("#b8692e")


func _init(source: Husk) -> void:
	husk = source


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_shell = StandardMaterial3D.new()
	_shell.albedo_color = CLAY
	_shell.roughness = 0.9
	var vessel := _mesh(_capsule(0.42, 1.25), Vector3(0, 0.95, 0))
	vessel.material_override = _shell
	vessel.scale = Vector3(1.0, 1.0, 0.85)
	for y: float in [0.75, 1.2]:
		_mesh(_torus(0.4, 0.46), Vector3(0, y, 0), COPPER)
	_mesh(_box(Vector3(0.36, 0.07, 0.05)), Vector3(0, 1.35, -0.36), Color("#2a2420"))
	var slit := _mesh(_box(Vector3(0.18, 0.04, 0.02)), Vector3(0, 1.35, -0.39), Color("#ffb060"))
	(slit.material_override as StandardMaterial3D).emission_enabled = true
	(slit.material_override as StandardMaterial3D).emission = Color("#ff9a40")
	_mesh(_sphere(0.1), Vector3(0, 1.0, -0.37), Color("#c97a36"))
	for side: float in [-1.0, 1.0]:
		_mesh(_capsule(0.1, 0.5), Vector3(0.22 * side, 0.25, 0), Color("#6e6158"))
		var arm := _mesh(_capsule(0.08, 0.7), Vector3(0.52 * side, 0.85, -0.05), Color("#6e6158"))
		arm.rotation.z = 0.35 * side
		_mesh(_box(Vector3(0.14, 0.1, 0.14)), Vector3(0.65 * side, 0.5, -0.05), COPPER)
	_ring = _mesh(_torus(0.15, 0.2), Vector3(0, 1.0, -0.4), Color.WHITE)
	_ring.rotation.x = PI / 2.0
	var ring_material := _ring.material_override as StandardMaterial3D
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow = OmniLight3D.new()
	_glow.light_color = Color("#ff9a30")
	_glow.omni_range = 3.0
	_glow.position = Vector3(0, 1.1, -0.5)
	add_child(_glow)


func sync(to_3d: Callable, player_position: Vector3) -> void:
	_time += get_process_delta_time()
	visible = husk.visible
	position = to_3d.call(husk.global_position)
	var to_player := player_position - position
	to_player.y = 0.0
	if husk.state != Husk.State.BROKEN and to_player.length() > 0.1:
		rotation.y = atan2(-to_player.x, -to_player.z)
	var progress := 0.0
	_glow.visible = false
	_ring.visible = false
	_shell.emission_enabled = false
	_shell.albedo_color = CLAY
	_body.rotation = Vector3.ZERO
	_body.position = Vector3.ZERO
	_body.scale = Vector3.ONE
	match husk.state:
		Husk.State.APPROACH:
			_body.position.y = absf(sin(_time * 5.0)) * 0.06
			_body.rotation.z = sin(_time * 5.0) * 0.06
		Husk.State.WINDUP:
			progress = 1.0 - husk._left / Husk.WINDUP_SECONDS
			_shell.emission_enabled = true
			_shell.emission = Color("#ff8a20")
			_shell.emission_energy_multiplier = 0.4 + 1.6 * progress
			_glow.visible = true
			_glow.light_energy = 1.0 + 3.0 * progress
			_body.rotation.x = 0.35 * progress
		Husk.State.STRIKE:
			_shell.albedo_color = Color("#b85a40")
			_body.rotation.x = -0.45
		Husk.State.RECOVERY:
			_ring.visible = true
			_ring.scale = Vector3.ONE * (1.0 + 0.15 * sin(_time * 10.0))
			_body.rotation.x = -0.15
		Husk.State.BROKEN:
			_body.rotation.x = PI / 2.2
			_body.position = Vector3(0, -0.3, 0.4)
			_shell.albedo_color = CLAY.darkened(0.45)
		Husk.State.DORMANT:
			_body.rotation.x = 0.5
			_body.position.y = -0.4


func _mesh(mesh: Mesh, position: Vector3, color := CLAY) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	instance.material_override = material
	instance.position = position
	_body.add_child(instance)
	return instance


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh


func _torus(inner: float, outer: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	return mesh


func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh
