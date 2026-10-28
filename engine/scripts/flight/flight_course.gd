class_name FlightCourse
extends Node3D
## Optional wind gates reward steering, not waiting or repeated farming.
signal collected(total: int, clean: bool)
const RADIUS := 2.6
var gates: Array[Dictionary] = []
var active_leg := 0
var total := 0
var _time := 0.0


func configure(perches: Array) -> void:
	var positions: Array[Vector3] = [
		perches[0].position.lerp(perches[1].position, 0.35) + Vector3(-6, 1, 0),
		perches[0].position.lerp(perches[1].position, 0.68) + Vector3(7, 0, 0),
		Vector3(-8, 17, -100), Vector3(-14, 22, -123),
		perches[2].position.lerp(perches[3].position, 0.32) + Vector3(5, 1, 0),
		perches[2].position.lerp(perches[3].position, 0.68) + Vector3(-6, 1, 0)]
	for i in positions.size():
		var leg: int = i / 2
		var normal: Vector3 = (perches[leg + 1].position - perches[leg].position).normalized()
		var holder := Node3D.new()
		holder.name = "WindGate%d" % i
		holder.position = positions[i]
		add_child(holder)
		holder.look_at(positions[i] + normal, Vector3.UP)
		var mesh := TorusMesh.new()
		mesh.inner_radius = RADIUS - 0.07
		mesh.outer_radius = RADIUS + 0.07
		mesh.rings = 32
		mesh.ring_segments = 8
		var ring := MeshInstance3D.new()
		ring.mesh = mesh
		ring.rotation.x = PI / 2.0
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#87e6d3")
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(ring)
		gates.append({"leg": leg, "position": positions[i], "normal": normal, "taken": false, "visual": holder, "tween": null})
	set_leg(0)


func set_leg(leg: int) -> void:
	active_leg = leg
	for gate: Dictionary in gates:
		(gate.visual as Node3D).visible = gate.leg == leg and not gate.taken


func reset_leg(leg: int) -> void:
	for gate: Dictionary in gates:
		if gate.leg != leg:
			continue
		if gate.tween != null:
			(gate.tween as Tween).kill()
		if gate.taken:
			total -= 1
		gate.taken = false
		(gate.visual as Node3D).scale = Vector3.ONE
	set_leg(leg)


func sweep_collect(from: Vector3, to: Vector3) -> int:
	var picked := 0
	for gate: Dictionary in gates:
		if gate.taken or gate.leg != active_leg:
			continue
		var center: Vector3 = gate.position
		var normal: Vector3 = gate.normal
		var before := (from - center).dot(normal)
		var after := (to - center).dot(normal)
		if before > 0.0 or after <= 0.0 or after - before < 0.0001:
			continue
		var crossing := from.lerp(to, -before / (after - before))
		if crossing.distance_to(center) > RADIUS:
			continue
		gate.taken = true
		total += 1
		picked += 1
		var visual := gate.visual as Node3D
		var tween := create_tween()
		gate.tween = tween
		tween.tween_property(visual, "scale", Vector3.ONE * 1.2, 0.08)
		tween.tween_property(visual, "scale", Vector3.ZERO, 0.14)
		collected.emit(total, crossing.distance_to(center) < 0.9)
	return picked


func _process(delta: float) -> void:
	_time += delta
	for i in gates.size():
		var gate: Dictionary = gates[i]
		if gate.leg == active_leg and not gate.taken:
			(gate.visual as Node3D).scale = Vector3.ONE * (1.0 + sin(_time * 2.2 + i) * 0.025)


func current_count() -> int:
	var count := 0
	for gate: Dictionary in gates:
		if gate.leg == active_leg and gate.taken:
			count += 1
	return count
