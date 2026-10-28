class_name Civilisation3D
extends RefCounted
## A fallen advanced civilisation: shared engineered construction survives in
## both maintained districts and crowded, patched neighbourhoods. Original forms.

static func block(width: float, depth: float, floors := 2, variant := 0) -> Node3D:
	var root := Node3D.new()
	root.name = "UrbanHabitat"
	root.set_meta("civilisation_role", "inherited_housing")
	var height := floors * 2.6
	_box(root, Vector3(width + 0.18, 0.28, depth + 0.18), Vector3(0, 0.14, 0), "metal")
	_box(root, Vector3(width, height, depth), Vector3(0, height * 0.5 + 0.28, 0), "shell")
	for side: float in [-1.0, 1.0]:
		_box(root, Vector3(0.18, height, 0.14), Vector3(side * width * 0.40, height * 0.5 + 0.28, depth * 0.5 + 0.04), "bronze")
		_box(root, Vector3(0.12, height * 0.85, 0.16), Vector3(side * width * 0.5, height * 0.5, -depth * 0.25), "teal")
	for floor_index in floors:
		var y := 1.65 + floor_index * 2.6
		_box(root, Vector3(width * 0.80, 0.84, 0.07), Vector3(0, y, depth * 0.5 + 0.05), "glass")
		_box(root, Vector3(width * 0.86, 0.12, 0.28), Vector3(0, y - 0.48, depth * 0.5 + 0.12), "teal")
		for pane in 3:
			_box(root, Vector3(0.04, 0.84, 0.12), Vector3((pane - 1) * width * 0.20, y, depth * 0.5 + 0.08), "bronze")
	_box(root, Vector3(0.95, 2.0, 0.09), Vector3(-width * 0.19, 1.27, depth * 0.5 + 0.08), "metal")
	_box(root, Vector3(0.06, 0.65, 0.10), Vector3(-width * 0.19 + 0.25, 1.25, depth * 0.5 + 0.15), "light")
	_box(root, Vector3(width + 0.32, 0.24, depth + 0.32), Vector3(0, height + 0.36, 0), "teal")
	_box(root, Vector3(width * 0.80, 0.10, depth * 0.74), Vector3(0, height + 0.54, 0), "metal")
	_box(root, Vector3(width * 0.31, 0.65, depth * 0.37), Vector3(width * 0.2, height + 0.85, -depth * 0.15), "shell")
	_box(root, Vector3(width * 0.25, 0.08, depth * 0.32), Vector3(width * 0.2, height + 1.22, -depth * 0.15), "glass")
	if variant % 3 != 1:
		_box(root, Vector3(width * 0.23, 0.22, depth * 0.30), Vector3(-width * 0.26, height + 0.65, 0), "metal")
		for i in 3:
			_box(root, Vector3(width * 0.08, 0.30, depth * 0.25), Vector3(-width * 0.32 + i * width * 0.065, height + 0.88, 0), "leaf")
	# Repair sheets and exposed service trunks vary between blocks.
	_box(root, Vector3(width * 0.28, 0.62, 0.08), Vector3(width * 0.22, 0.82 + (variant % 2) * 2.6, depth * 0.5 + 0.12), "patch")
	for i in 2:
		_box(root, Vector3(0.075, height * 0.75, 0.075), Vector3(width * 0.5 + 0.06, height * 0.42, (i - 0.5) * 0.24), "bronze")
	batch(root)
	return root


static func relay(height := 11.0) -> Node3D:
	var root := Node3D.new()
	root.name = "DistrictRelay"
	root.set_meta("civilisation_role", "water_energy_relay")
	_box(root, Vector3(2.8, 0.5, 2.8), Vector3(0, 0.25, 0), "metal")
	for side: float in [-1.0, 1.0]:
		var column := _box(root, Vector3(0.35, height, 0.6), Vector3(side * 0.95, height * 0.5, 0), "shell")
		column.rotation.z = side * 0.04
		_box(root, Vector3(0.10, height * 0.75, 0.16), Vector3(side * 0.95, height * 0.5, 0.35), "bronze")
		_box(root, Vector3(0.06, height * 0.45, 0.04), Vector3(side * 0.95, height * 0.5, 0.45), "light")
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.4
	torus.outer_radius = 1.65
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = Materials3D.civic("bronze")
	ring.position.y = height * 0.82
	root.add_child(ring)
	_box(root, Vector3(0.55, height * 0.45, 0.55), Vector3(0, height * 0.60, 0), "teal")
	batch(root)
	return root


static func service_line(length: float) -> Node3D:
	var root := Node3D.new()
	root.name = "InheritedConduit"
	_box(root, Vector3(length, 0.04, 0.28), Vector3(0, 0.025, 0), "metal")
	_box(root, Vector3(length, 0.065, 0.055), Vector3(0, 0.065, -0.065), "bronze")
	_box(root, Vector3(length, 0.045, 0.04), Vector3(0, 0.055, 0.065), "teal")
	for i in int(length):
		_box(root, Vector3(0.16, 0.08, 0.34), Vector3(-length * 0.5 + i + 0.5, 0.06, 0), "shell")
		if i % 3 != 1:
			_box(root, Vector3(0.10, 0.015, 0.055), Vector3(-length * 0.5 + i + 0.5, 0.11, 0.065), "light")
	batch(root)
	return root


static func _box(root: Node3D, size: Vector3, at: Vector3, kind: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = Materials3D.civic(kind)
	root.add_child(part)
	return part


## Each material becomes one mesh rather than a draw call for every panel.
static func batch(root: Node3D) -> void:
	var groups := {}
	var materials := {}
	for child in root.get_children():
		var part := child as MeshInstance3D
		if part == null:
			continue
		var material := part.material_override
		var key := material.get_instance_id()
		if not groups.has(key):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = surface
			materials[key] = material
		(groups[key] as SurfaceTool).append_from(part.mesh, 0, part.transform)
		root.remove_child(part)
		part.free()
	for key: int in groups:
		var combined := MeshInstance3D.new()
		combined.mesh = (groups[key] as SurfaceTool).commit()
		combined.material_override = materials[key]
		root.add_child(combined)


static func highrise(height: float, variant := 0) -> Node3D:
	var root := Node3D.new()
	root.name = "FallenCivicTower"
	root.set_meta("civilisation_role", "capital_highrise")
	var solids: Array[Dictionary] = []
	for tier in 3:
		var width := 12.0 - tier * 2.4
		var y := height * (tier + 0.5) / 3.0
		var body := _box(root, Vector3(width, height / 3.0, width * 0.78), Vector3(tier * 0.25, y, 0), "shell")
		solids.append({"bounds": body.mesh.get_aabb(), "transform": body.transform})
		_box(root, Vector3(width * 0.74, height / 3.0 - 0.8, 0.12), Vector3(tier * 0.25, y, width * 0.39 + 0.07), "glass")
		_box(root, Vector3(0.12, height / 3.0 - 0.8, width * 0.55), Vector3(width * 0.5 + tier * 0.25 + 0.06, y, 0), "glass")
		_box(root, Vector3(width + 0.6, 0.35, width * 0.78 + 0.6), Vector3(tier * 0.25, height * (tier + 1) / 3.0, 0), "teal")
		for rib in 5:
			_box(root, Vector3(0.09, height / 3.0, 0.15), Vector3(tier * 0.25 + (rib - 2) * width * 0.16, y, width * 0.39 + 0.14), "bronze")
		# Broken facade insert: a different repair history on each tower.
		_box(root, Vector3(width * 0.23, height * 0.09, 0.16), Vector3(width * 0.2, y + (variant % 2) * 1.2, width * 0.39 + 0.12), "patch")
	_box(root, Vector3(0.16, height * 0.65, 0.2), Vector3(-4.6, height * 0.52, 2.8), "light")
	root.set_meta("major_solids", solids)
	batch(root)
	return root


static func broken_skybridge() -> Node3D:
	var root := Node3D.new()
	root.name = "BrokenTransitLink"
	var solids: Array[Dictionary] = []
	for side: float in [-1.0, 1.0]:
		var deck := _box(root, Vector3(3.4, 0.5, 26.0), Vector3(0, 0, side * 22), "metal")
		solids.append({"bounds": deck.mesh.get_aabb(), "transform": deck.transform})
		for edge: float in [-1.0, 1.0]:
			_box(root, Vector3(0.08, 0.9, 26), Vector3(edge * 1.6, 0.55, side * 22), "bronze")
		_box(root, Vector3(3.3, 0.08, 0.10), Vector3(0, 0.31, side * 9.0), "light")
	root.set_meta("major_solids", solids)
	batch(root)
	return root


static func service_cart() -> Node3D:
	var root := Node3D.new()
	root.name = "UtilityCarrier"
	_box(root, Vector3(1.6, 0.22, 1.0), Vector3(0, 0.42, 0), "metal")
	_box(root, Vector3(1.15, 0.70, 0.82), Vector3(-0.16, 0.88, 0), "shell")
	_box(root, Vector3(0.25, 0.65, 0.9), Vector3(0.7, 0.82, 0), "teal")
	_box(root, Vector3(0.8, 0.06, 0.04), Vector3(-0.15, 1.12, 0.43), "light")
	for side: float in [-1.0, 1.0]:
		for end: float in [-1.0, 1.0]:
			var wheel := CylinderMesh.new()
			wheel.top_radius = 0.22
			wheel.bottom_radius = 0.22
			wheel.height = 0.14
			var part := MeshInstance3D.new()
			part.mesh = wheel
			part.position = Vector3(end * 0.53, 0.23, side * 0.55)
			part.rotation.x = PI / 2.0
			part.material_override = Materials3D.civic("metal")
			root.add_child(part)
	batch(root)
	return root
