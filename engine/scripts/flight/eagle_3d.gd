class_name Eagle3D
extends Node3D
## Fish-eagle silhouette: arched feathered wings, separated primaries, fan tail,
## hooked bill and tucked feet. Feather geometry is batched per moving wing part.

const BODY := Color("#743b24")
const WHITE := Color("#eee9dc")
const WING := Color("#30291f")
const WING_TIP := Color("#171915")
const BEAK := Color("#dca92d")

var flap := 0.2
var bank := 0.0
var grounded := true
var _model: Node3D
var _left_wing: Node3D
var _right_wing: Node3D
var _left_tip: Node3D
var _right_tip: Node3D
var _feet: Node3D
var _time := 0.0
var _materials: Dictionary = {}


func _ready() -> void:
	_model = Node3D.new()
	_model.name = "EagleBody"
	add_child(_model)
	_ellipsoid(BODY, Vector3(0, 0, 0.05), Vector3(0.19, 0.19, 0.45))
	_ellipsoid(WHITE, Vector3(0, 0.035, -0.25), Vector3(0.16, 0.185, 0.23))
	_ellipsoid(WHITE, Vector3(0, 0.15, -0.43), Vector3(0.105, 0.15, 0.15))
	_ellipsoid(WHITE, Vector3(0, 0.20, -0.54), Vector3(0.12, 0.11, 0.155))
	_build_bill()
	for side: float in [-1.0, 1.0]:
		_ellipsoid(BEAK, Vector3(side * 0.106, 0.225, -0.58), Vector3(0.022, 0.026, 0.034))
		_ellipsoid(Color("#11130e"), Vector3(side * 0.123, 0.231, -0.59), Vector3(0.009, 0.012, 0.015))
		_ellipsoid(WHITE, Vector3(side * 0.123, 0.24, -0.596), Vector3(0.003, 0.003, 0.004))
		var brow := _ellipsoid(WHITE, Vector3(side * 0.105, 0.264, -0.59), Vector3(0.028, 0.013, 0.065))
		brow.rotation.z = side * -0.2
	_left_wing = _wing(-1.0)
	_right_wing = _wing(1.0)
	_left_tip = _left_wing.get_node("Wrist")
	_right_tip = _right_wing.get_node("Wrist")
	var tail := SurfaceTool.new()
	tail.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var angle := (i - 3) * 0.13
		_blade(tail, Vector3((i - 3) * 0.025, -0.035, 0.33),
				Vector3(sin(angle) * 0.65, -0.04, 0.89 - absf(i - 3) * 0.025), 0.065, WHITE.darkened(absf(i - 3) * 0.015))
	_finish_surface(tail, _model, "FanTail")
	_feet = Node3D.new()
	_feet.name = "Feet"
	_model.add_child(_feet)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(BODY, Vector3(side * 0.10, -0.12, 0.19), Vector3(0.08, 0.09, 0.13), _feet)
		_ellipsoid(BEAK, Vector3(side * 0.10, -0.23, 0.18), Vector3(0.028, 0.07, 0.025), _feet)
		for toe in 3:
			var foot := Vector3(side * 0.1 + (toe - 1) * 0.032, -0.28, 0.11)
			_ellipsoid(BEAK, foot, Vector3(0.012, 0.014, 0.07), _feet)
			_ellipsoid(WING_TIP, foot + Vector3(0, -0.01, -0.065), Vector3(0.009, 0.018, 0.022), _feet)


func _process(delta: float) -> void:
	_time += delta * (3.5 + 8.0 * flap)
	var beat := sin(_time) * (0.10 + 0.5 * flap)
	var fold := 1.05 if grounded else 0.0
	_left_wing.rotation.y = lerpf(_left_wing.rotation.y, -fold, minf(delta * 5.0, 1.0))
	_right_wing.rotation.y = -_left_wing.rotation.y
	_left_wing.rotation.z = -beat - (0.38 if grounded else 0.0)
	_right_wing.rotation.z = beat + (0.38 if grounded else 0.0)
	var wrist := sin(_time - 0.55) * (0.04 + flap * 0.16)
	_left_tip.rotation.z = -wrist
	_right_tip.rotation.z = wrist
	_model.rotation.z = bank
	_model.rotation.x = lerpf(_model.rotation.x, -0.28 if grounded else 0.0, minf(delta * 4.0, 1.0))
	_feet.rotation.x = lerpf(_feet.rotation.x, 0.0 if grounded else -1.1, minf(delta * 5.0, 1.0))


func _wing(side: float) -> Node3D:
	var root := Node3D.new()
	root.name = "LeftWing" if side < 0 else "RightWing"
	root.position = Vector3(side * 0.13, 0.09, -0.13)
	root.scale.x = side
	_model.add_child(root)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_prism(surface, PackedVector3Array([Vector3(0, 0, -0.10), Vector3(0.36, 0.07, -0.22),
		Vector3(0.75, 0.045, -0.14), Vector3(0.94, 0, 0.10), Vector3(0.70, -0.015, 0.28),
		Vector3(0.30, -0.015, 0.26), Vector3(0, 0, 0.15)]), 0.035, WING)
	for i in 9:
		var x := 0.13 + i * 0.074
		_blade(surface, Vector3(x, 0.035, 0.02), Vector3(x + 0.075, 0.01, 0.38 + i * 0.009),
				0.055, WING.lightened(0.025 + (i % 3) * 0.025))
	_finish_surface(surface, root, "LayeredCoverts")
	var wrist := Node3D.new()
	wrist.name = "Wrist"
	wrist.position = Vector3(0.72, 0.02, 0.03)
	root.add_child(wrist)
	var tips := SurfaceTool.new()
	tips.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var start := Vector3(0.04 + i * 0.034, 0.0, -0.11 + i * 0.045)
		var end := Vector3(0.78 - i * 0.043, -0.035 + i * 0.01, -0.08 + i * 0.112)
		_blade(tips, start, end, 0.064, WING_TIP.lightened((i % 3) * 0.018))
	_finish_surface(tips, wrist, "SeparatedPrimaries")
	return root


func _blade(surface: SurfaceTool, from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var along := to - from
	var across := Vector3(along.z, 0, -along.x).normalized() * width
	_prism(surface, PackedVector3Array([from - across * 0.45, from + along * 0.35 - across,
		from + along * 0.82 - across * 0.55, to, from + along * 0.82 + across * 0.55,
		from + along * 0.35 + across, from + across * 0.45]), 0.012, color)


func _prism(surface: SurfaceTool, outline: PackedVector3Array, thickness: float, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point in outline:
		polygon.append(Vector2(point.x, point.z))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for i in range(0, triangles.size(), 3):
		_triangle(surface, outline[triangles[i]], outline[triangles[i + 1]], outline[triangles[i + 2]], color)
		_triangle(surface, outline[triangles[i + 2]] - Vector3.UP * thickness,
				outline[triangles[i + 1]] - Vector3.UP * thickness, outline[triangles[i]] - Vector3.UP * thickness, color.darkened(0.12))
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		_triangle(surface, a, a - Vector3.UP * thickness, b, color.darkened(0.08))
		_triangle(surface, b, a - Vector3.UP * thickness, b - Vector3.UP * thickness, color.darkened(0.08))


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for point: Vector3 in [a, b, c]:
		surface.set_color(color)
		surface.add_vertex(point)


func _finish_surface(surface: SurfaceTool, parent: Node3D, node_name: String) -> void:
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.85
	mesh.material_override = material
	parent.add_child(mesh)


func _build_bill() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [Vector3(0, 0.26, -0.64), Vector3(0, 0.23, -0.76),
		Vector3(0, 0.11, -0.81), Vector3(0, 0.14, -0.71), Vector3(0, 0.15, -0.64)]
	for side: float in [-1.0, 1.0]:
		var center := Vector3(side * 0.04, 0.20, -0.69)
		for i in profile.size():
			_triangle(surface, center, profile[i] + Vector3(side * 0.025, 0, 0),
					profile[(i + 1) % profile.size()] + Vector3(side * 0.025, 0, 0), BEAK)
	for i in profile.size():
		var a: Vector3 = profile[i]
		var b: Vector3 = profile[(i + 1) % profile.size()]
		_triangle(surface, a + Vector3(0.025, 0, 0), a - Vector3(0.025, 0, 0), b + Vector3(0.025, 0, 0), BEAK)
		_triangle(surface, b + Vector3(0.025, 0, 0), a - Vector3(0.025, 0, 0), b - Vector3(0.025, 0, 0), BEAK)
	_finish_surface(surface, _model, "HookedBill")
	_ellipsoid(WING_TIP, Vector3(0, 0.125, -0.79), Vector3(0.026, 0.027, 0.025))


func _ellipsoid(color: Color, at: Vector3, dimensions: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.8
		_materials[color] = material
	instance.material_override = _materials[color]
	instance.position = at
	instance.scale = dimensions
	(parent if parent != null else _model).add_child(instance)
	return instance


func set_first_person(on: bool) -> void:
	if _model == null:
		return
	_left_wing.position.z = -0.45 if on else -0.13
	_right_wing.position.z = -0.45 if on else -0.13
	for wing: Node3D in [_left_wing, _right_wing]:
		wing.get_node("LayeredCoverts").visible = not on
	for child: Node3D in _model.get_children():
		child.visible = not on or child.name in ["LeftWing", "RightWing"]
