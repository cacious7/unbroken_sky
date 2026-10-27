class_name Eagle3D
extends Node3D
## Tavo's eagle form: a low-poly model built in code, facing -Z. Colouring follows the
## African fish eagle (white head, chest and tail; chestnut body; dark wings).
## The flight scene sets `flap` (0 glide .. 1 hard flapping) and `bank` (radians).

const BODY := Color("#7a3b1e")
const WHITE := Color("#f4f1ea")
const WING := Color("#2a2018")
const WING_TIP := Color("#16110c")
const BEAK := Color("#e3b33a")

var flap := 0.2
var bank := 0.0

var _model: Node3D
var _left_wing: Node3D
var _right_wing: Node3D
var _time := 0.0


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	var body := _part(CapsuleMesh.new(), BODY, Vector3.ZERO, Vector3(PI / 2.0, 0, 0))
	(body.mesh as CapsuleMesh).radius = 0.18
	(body.mesh as CapsuleMesh).height = 0.95
	var chest := _part(SphereMesh.new(), WHITE, Vector3(0, 0.03, -0.28))
	chest.scale = Vector3(0.95, 0.9, 1.3)
	(chest.mesh as SphereMesh).radius = 0.17
	(chest.mesh as SphereMesh).height = 0.34
	var head := _part(SphereMesh.new(), WHITE, Vector3(0, 0.09, -0.52))
	(head.mesh as SphereMesh).radius = 0.14
	(head.mesh as SphereMesh).height = 0.28
	var beak := _part(CylinderMesh.new(), BEAK, Vector3(0, 0.06, -0.68), Vector3(-PI / 2.0, 0, 0))
	(beak.mesh as CylinderMesh).top_radius = 0.0
	(beak.mesh as CylinderMesh).bottom_radius = 0.05
	(beak.mesh as CylinderMesh).height = 0.16
	var tail := _part(BoxMesh.new(), WHITE, Vector3(0, 0.0, 0.56))
	(tail.mesh as BoxMesh).size = Vector3(0.3, 0.035, 0.32)
	_left_wing = _wing(-1.0)
	_right_wing = _wing(1.0)


func _process(delta: float) -> void:
	_time += delta * (4.0 + 9.0 * flap)
	var beat := sin(_time) * (0.12 + 0.55 * flap)
	_left_wing.rotation.z = -beat
	_right_wing.rotation.z = beat
	_model.rotation.z = bank


func _wing(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.15 * side, 0.06, -0.05)
	_model.add_child(pivot)
	var inner := _part(BoxMesh.new(), WING, Vector3(0.42 * side, 0, 0), Vector3.ZERO, pivot)
	(inner.mesh as BoxMesh).size = Vector3(0.85, 0.07, 0.5)
	var outer := _part(BoxMesh.new(), WING_TIP, Vector3(1.05 * side, -0.02, 0.06), Vector3(0, -0.18 * side, -0.08 * side), pivot)
	(outer.mesh as BoxMesh).size = Vector3(0.7, 0.05, 0.38)
	return pivot


func _part(mesh: Mesh, color: Color, position: Vector3, rotation: Vector3 = Vector3.ZERO,
		parent: Node3D = null) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation = rotation
	(parent if parent != null else _model).add_child(instance)
	return instance
