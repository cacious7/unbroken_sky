class_name PumpFlow
extends Node3D
## A short gravity-fed stream, anchored to the actual outlet rather than the pump centre.

var stream: MeshInstance3D
var _material: ShaderMaterial
var _left := 0.0
var _leaking := true


func _ready() -> void:
	stream = MeshInstance3D.new()
	stream.name = "SpoutStream"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in 16:
		for side in 8:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var t := float(step + corner.x) / 16.0
				var angle := float(side + corner.y) / 8.0 * TAU
				var point := Vector3(0, -0.8 * t * t, 0.42 * t)
				var tangent := Vector3(0, -1.6 * t, 0.42).normalized()
				var radial := Vector3.RIGHT * cos(angle) + tangent.cross(Vector3.RIGHT) * sin(angle)
				surface.set_uv(Vector2(float(side + corner.y) / 8.0, t))
				surface.set_normal(radial)
				surface.add_vertex(point + radial * lerpf(0.028, 0.018, t))
	stream.mesh = surface.commit()
	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/shaders/pump_flow.gdshader")
	stream.material_override = _material
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stream)


func set_condition(repaired: bool, contaminated: bool) -> void:
	_leaking = not repaired
	_material.set_shader_parameter("water_color", Color("#211e28") if contaminated else Color("#72bccc"))
	stream.visible = _leaking or _left > 0.0


func pulse() -> void:
	_left = 0.9
	stream.visible = true


func _process(delta: float) -> void:
	_left = maxf(0, _left - delta)
	stream.visible = _leaking or _left > 0
	stream.scale.x = 0.45 if _leaking else minf(1.0, _left * 6.0)
	stream.scale.z = 0.8 if _leaking else 1.0
