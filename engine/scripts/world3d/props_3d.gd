class_name Props3D
extends RefCounted
## Builds the 3D version of each scene object by its node name. Uses CC0 Kenney models
## (assets/third_party/kenney) where one fits, and simple built-in shapes for things no
## pack has (the well, pump, mud-brick house, cistern, cart, culvert, bypass wheel...).
## `size` is the object's footprint in metres (x across, y depth).

const THIRD_PARTY := "res://assets/third_party/"

## Characters standing in as scene objects.
const FIGURES := {
	"Sena": "sena", "Mera": "mera", "Figure": "figure", "Daru": "daru", "Nali": "nali",
	"NaliBlock": "nali", "Veya": "veya", "Kesi": "kesi", "Orun": "orun", "Lio": "lio",
	"Merchant": "merchant",
}


static func build(object_name: String, size: Vector2) -> Node3D:
	var root := Node3D.new()
	root.name = object_name + "3D"
	if FIGURES.has(object_name):
		var figure := CastFigure.create(FIGURES[object_name])
		root.add_child(figure)
		return root
	match object_name:
		"Well":
			_cyl(root, 0.85, 0.95, 0.65, Color.WHITE, Vector3(0, 0.325, 0)).material_override = Materials3D.civic("shell")
			_cyl(root, 0.93, 0.93, 0.12, Color.WHITE, Vector3(0, 0.66, 0)).material_override = Materials3D.civic("metal")
			_cyl(root, 0.62, 0.62, 0.02, Color("#214b52"), Vector3(0, 0.73, 0))
			_torus(root, 0.65, 0.72, Color.WHITE, Vector3(0, 0.74, 0)).material_override = Materials3D.civic("bronze")
			for i in 4:
				var angle := i * PI / 2.0
				_box(root, Vector3(0.13, 0.6, 0.18), Color.WHITE, Vector3(cos(angle) * 0.87, 0.32, sin(angle) * 0.87)).material_override = Materials3D.civic("teal")
		"Pump":
			_cyl(root, 0.35, 0.4, 0.15, Color("#8a847a"), Vector3(0, 0.07, 0))
			_cyl(root, 0.12, 0.13, 1.1, Color.WHITE, Vector3(0, 0.6, 0)).material_override = Materials3D.civic("shell")
			_box(root, Vector3(0.08, 0.08, 0.55), Color.WHITE, Vector3(0, 0.95, 0.30)).material_override = Materials3D.civic("bronze")
			var outlet := _cyl(root, 0.055, 0.055, 0.13, Color.WHITE, Vector3(0, 0.90, 0.575))
			outlet.material_override = Materials3D.civic("bronze")
			var nozzle := Marker3D.new()
			nozzle.name = "WaterOutlet"
			nozzle.position = Vector3(0, 0.835, 0.575)
			root.add_child(nozzle)
			var handle := _box(root, Vector3(0.05, 0.05, 0.8), Color("#5f6b75"), Vector3(0, 1.25, 0.25))
			handle.name = "PumpHandle"
			handle.rotation.x = -0.5
			_box(root, Vector3(0.40, 0.80, 0.34), Color.WHITE, Vector3(0.30, 0.52, 0)).material_override = Materials3D.civic("teal")
			var status := _box(root, Vector3(0.28, 0.08, 0.02), Color.WHITE, Vector3(0.30, 0.80, 0.18))
			status.name = "ServiceStatus"
			status.material_override = Materials3D.civic("light")
			var gauge := _cyl(root, 0.1, 0.1, 0.02, Color("#e4decd"), Vector3(0.3, 0.6, 0.18))
			gauge.rotation.x = PI / 2.0
			_box(root, Vector3(0.012, 0.12, 0.02), Color("#b54c38"), Vector3(0.3, 0.6, 0.205)).rotation.z = 0.35
			_sphere(root, 0.07, Color("#c97a36"), Vector3(0, 1.15, 0))
		"Basket":
			_box(root, Vector3(0.66, 0.36, 0.48), Color.WHITE, Vector3(0, 0.18, 0)).material_override = Materials3D.civic("teal")
			_box(root, Vector3(0.55, 0.015, 0.37), Color.WHITE, Vector3(0, 0.37, 0)).material_override = Materials3D.civic("metal")
			for side: float in [-1.0, 1.0]:
				_box(root, Vector3(0.68, 0.07, 0.055), Color.WHITE, Vector3(0, 0.39, side * 0.24)).material_override = Materials3D.civic("shell")
				_box(root, Vector3(0.055, 0.12, 0.48), Color.WHITE, Vector3(side * 0.33, 0.36, 0)).material_override = Materials3D.civic("bronze")
			_model(root, "kenney/survival/tool-hammer.glb", 0.38, Vector3(0.08, 0.40, 0), Vector3(0, 0, 0.6))
		"Bird":
			_model(root, "kenney/survival/campfire-pit.glb", 0.9)
			_cyl(root, 0.015, 0.015, 0.5, Color("#8a6a44"), Vector3(0, 0.45, 0))
			var toy := Node3D.new()
			toy.name = "CopperBird"
			root.add_child(toy)
			_ornament_wings(toy)
			_sphere(toy, 0.07, Color("#d98a46"), Vector3(0, 0.74, 0))
		"Home":
			_house(root, size)
		"ShadeCloth":
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				_cyl(root, 0.05, 0.05, 2.2, Color("#6b4f33"), Vector3(corner.x * size.x * 0.45, 1.1, corner.y * size.y * 0.45))
			var fabric := PlaneMesh.new()
			fabric.size = size
			fabric.subdivide_width = 12
			fabric.subdivide_depth = 6
			var cloth := MeshInstance3D.new()
			cloth.name = "WindCanopy"
			cloth.mesh = fabric
			cloth.position = Vector3(0, 2.15, 0)
			var fabric_material := ShaderMaterial.new()
			fabric_material.shader = load("res://assets/shaders/wind_cloth.gdshader")
			cloth.material_override = fabric_material
			root.add_child(cloth)
		"Exit":
			_model(root, "kenney/survival/signpost-single.glb", 1.0)
		"Door":
			_box(root, Vector3(1.2, 2.0, 0.12), Color("#17120e"), Vector3(0, 1.0, 0))
			for side: float in [-1.0, 1.0]:
				_skin(_box(root, Vector3(0.15, 2.15, 0.22), Color.WHITE, Vector3(side * 0.67, 1.075, 0)), "planks")
			_skin(_box(root, Vector3(1.5, 0.18, 0.22), Color.WHITE, Vector3(0, 2.15, 0)), "planks")
		"Cistern":
			_skin(_box(root, Vector3(size.x, 1.1, size.y), Color("#8f8a82"), Vector3(0, 0.55, 0)), "stone")
			_box(root, Vector3(size.x - 0.4, 0.04, size.y - 0.4), Color("#2c4a5e"), Vector3(0, 1.11, 0)).material_override = Materials3D.water()
		"Jars":
			for i in 12:
				_model(root, "polypizza/pot_ceramic_large.glb", 0.5, Vector3((i % 4 - 1.5) * 0.55, 0, (i / 4) * 0.55), Vector3(0, i * 1.3, 0))
		"Gate":
			_skin(_box(root, Vector3(maxf(size.x, 0.3), 2.2, size.y), Color("#6b4f33"), Vector3(0, 1.1, 0)), "planks")
			for z in [-0.35, 0.0, 0.35]:
				_box(root, Vector3(maxf(size.x, 0.3) + 0.04, 0.12, 0.12), Color("#4a3424"), Vector3(0, 1.6, z * size.y))
		"Refugees":
			for i in 3:
				var person := CastFigure.create(["merchant", "lio", "eren"][i])
				person.position = Vector3((i - 1) * 0.7, 0, (i % 2) * 0.6)
				person.rotation.y = PI / 2.0 + (i - 1) * 0.3
				root.add_child(person)
		"Pipe":
			var pipe := _cyl(root, 0.12, 0.12, size.x, Color("#b0704a"), Vector3(0, 0.12, 0))
			pipe.rotation.z = PI / 2.0
		"Spring":
			_model(root, "kenney/nature/path_stoneCircle.glb", size.x + 0.4)
			_cyl(root, size.x * 0.32, size.x * 0.32, 0.03, Color("#2e5a70"), Vector3(0, 0.06, 0)).name = "SpringWater"
		"Workbench":
			_model(root, "kenney/survival/workbench-anvil.glb", 1.5)
		"Hearth":
			_model(root, "kenney/nature/campfire_stones.glb", size.x * 0.9)
		"Bag":
			var leather := _sphere(root, 0.3, Color("#784c2e"), Vector3(0, 0.28, 0))
			leather.scale = Vector3(1.2, 0.85, 0.5)
			_box(root, Vector3(0.58, 0.16, 0.15), Color("#63391f"), Vector3(0, 0.43, 0.02))
			_box(root, Vector3(0.05, 0.12, 0.025), Color("#b78c43"), Vector3(0, 0.36, 0.105))
			var strap := _torus(root, 0.24, 0.265, Color("#49301f"), Vector3(0, 0.55, 0))
			strap.rotation.x = PI / 2.0
		"CoolStone":
			var boulder := _skin(_sphere(root, size.x * 0.5, Color.WHITE, Vector3(0, size.x * 0.2, 0)), "stone", Color(0.9, 0.82, 0.75))
		"Shade":
			_model(root, "polypizza/acacia.glb", 4.2)
		"WayStation":
			# Carved stone: a gilded hand on one side, a worn bowl on the other.
			_skin(_box(root, Vector3(size.x, 0.95, size.y), Color.WHITE, Vector3(0, 0.47, 0)), "stone")
			for finger in 4:
				_box(root, Vector3(0.05, 0.28, 0.03), Color("#d4af37"), Vector3(-size.x * 0.3 + finger * 0.07, 0.62, size.y / 2.0 + 0.01))
			_skin(_cyl(root, 0.28, 0.2, 0.1, Color.WHITE, Vector3(size.x * 0.25, 1.0, 0)), "stone")
		"Cart", "Carts":
			_cart(root, size)
		"Traveller":
			_model(root, "kenney/survival/bedroll.glb", size.x)
		"CulvertMouth":
			_skin(_box(root, Vector3(size.x, 1.8, size.y), Color("#7d776e"), Vector3(0, 0.9, 0)), "stone")
			_box(root, Vector3(size.x * 0.55, 1.3, 0.1), Color("#151c22"), Vector3(0, 0.65, size.y / 2.0 + 0.01))
		"Reflection":
			var puddle := _cyl(root, size.x * 0.5, size.x * 0.5, 0.02, Color("#2c4a63"), Vector3(0, 0.02, 0), 40)
			puddle.scale.z = size.y / size.x * 1.4
		"Hook":
			var hook := _torus(root, 0.08, 0.12, Color("#c97a36"), Vector3(0, 0.3, 0))
			hook.rotation.x = PI / 2.0
			_cyl(root, 0.03, 0.03, 0.4, Color("#c97a36"), Vector3(0, 0.55, 0))
		"Order":
			_box(root, Vector3(size.x, 0.6, 0.06), Color("#d9c7a0"), Vector3(0, 1.8, 0))
			_box(root, Vector3(0.08, 1.8, 0.08), Color("#6b4f33"), Vector3(0, 0.9, 0.05))
		"SideChannel":
			_skin(_box(root, Vector3(size.x, 0.4, size.y), Color("#7d776e"), Vector3(0, 0.2, 0)), "stone")
			_box(root, Vector3(size.x, 0.02, size.y * 0.5), Color("#2e5a70"), Vector3(0, 0.41, 0)).material_override = Materials3D.water()
			var valve := _torus(root, 0.18, 0.24, Color("#c97a36"), Vector3(0, 0.75, 0))
			valve.rotation.x = PI / 2.0
		"Brace":
			_model(root, "kenney/nature/log.glb", size.x)
		"SluiceLock":
			_model(root, "kenney/survival/chest.glb", size.x)
		"Grille":
			_box(root, Vector3(size.x, 1.8, 0.2), Color("#1a1612"), Vector3(0, 0.9, 0.2))
			for i in 7:
				_box(root, Vector3(0.06, 1.8, 0.06), Color("#b8692e"), Vector3((i - 3) * size.x / 7.0, 0.9, -0.05))
			var eren := CastFigure.create("eren")
			eren.position = Vector3(0, 0, 0.5)
			eren.ready.connect(func() -> void: eren.play("fix"))
			root.add_child(eren)
		"Bypass":
			_skin(_box(root, Vector3(size.x * 1.4, 0.4, 0.5), Color("#7d776e"), Vector3(0, 0.2, 0)), "stone")
			var wheel := _torus(root, 0.55, 0.7, Color("#b8692e"), Vector3(0, 0.95, 0))
			wheel.rotation.x = PI / 2.0
			for angle in [0.0, PI / 2.0, PI / 4.0, -PI / 4.0]:
				var spoke := _box(root, Vector3(1.2, 0.06, 0.06), Color("#c97a36"), Vector3(0, 0.95, 0))
				spoke.rotation.z = angle
		_:
			return null
	return root


## Wall-like blocks: low mud-brick for town walls, stone for fortress walls and ledges.
static func wall(size: Vector2, _stone: bool, height := 1.1) -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(size.x, height, size.y), Color.WHITE, Vector3(0, height * 0.5, 0)).material_override = Materials3D.civic("shell")
	_box(root, Vector3(size.x + 0.05, 0.12, size.y + 0.05), Color.WHITE, Vector3(0, 0.06, 0)).material_override = Materials3D.civic("metal")
	_box(root, Vector3(size.x + 0.06, 0.07, size.y + 0.06), Color.WHITE, Vector3(0, height, 0)).material_override = Materials3D.civic("teal")
	for i in int(size.x / 2.0):
		_box(root, Vector3(0.025, height, size.y + 0.02), Color.WHITE, Vector3(-size.x * 0.5 + 1.0 + i * 2.0, height * 0.5, 0)).material_override = Materials3D.civic("bronze")
	Civilisation3D.batch(root)
	return root



static func _house(root: Node3D, size: Vector2) -> void:
	root.add_child(Civilisation3D.block(size.x, size.y, 2, 1))


## Kept as a compatibility entry point for earlier scene-dressing scripts.
static func round_hut(radius: float) -> Node3D:
	return Civilisation3D.block(radius * 1.8, radius * 1.6, 2)



static func _cart(root: Node3D, _size: Vector2) -> void:
	root.add_child(Civilisation3D.service_cart())



## Loads a Kenney model and scales it so its footprint's longer side is `fit` metres.
static func _model(root: Node3D, path: String, fit: float, offset := Vector3.ZERO, rotation := Vector3.ZERO) -> Node3D:
	var packed := load(THIRD_PARTY + path) as PackedScene
	if packed == null:
		push_error("Missing model: %s" % path)
		return null
	var model: Node3D = packed.instantiate()
	_restyle(model)
	var bounds := _bounds(model)
	var longest := maxf(bounds.size.x, bounds.size.z)
	var scale := fit / longest if longest > 0.001 else 1.0
	model.scale = Vector3.ONE * scale
	model.position = offset - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale
	model.rotation = rotation
	root.add_child(model)
	return model


## Kenney's Nature Kit colours its grass and leaves teal and marks every material as
## fully metallic. Recolour to dry-season savanna tones and make everything matte.
const PALETTE := {
	"grass": Color("#7a8240"),
	"leafs": Color("#6f8a3e"),
	"leafsDark": Color("#56703a"),
	"leafsFall": Color("#b0903a"),
	"dirt": Color("#6e4a36"),
	"dirtDark": Color("#7a4a30"),
}
static var _restyled: Dictionary = {}


static func _restyle(model: Node) -> void:
	for mesh_instance: MeshInstance3D in model.find_children("", "MeshInstance3D", true, false):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var original := mesh.surface_get_material(surface) as BaseMaterial3D
			if original == null:
				continue
			var key := original.get_instance_id()
			if not _restyled.has(key):
				var material := original.duplicate() as BaseMaterial3D
				material.metallic = 0.0
				material.roughness = maxf(material.roughness, 0.85)
				if PALETTE.has(original.resource_name):
					material.albedo_color = PALETTE[original.resource_name]
				else:
					# Any other teal foliage: pull it towards olive, keeping its brightness.
					var color := material.albedo_color
					if color.b > color.r + 0.15 and color.g > color.r + 0.15:
						material.albedo_color = Color("#7f9444").lerp(Color("#556b30"), 1.0 - color.v)
				_restyled[key] = material
			mesh_instance.set_surface_override_material(surface, _restyled[key])


static func _bounds(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("", "MeshInstance3D", true, false):
		var box := _relative_transform(mesh, node) * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


static func _relative_transform(child: Node3D, ancestor: Node) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var node: Node = child
	while node != ancestor and node is Node3D:
		transform = (node as Node3D).transform * transform
		node = node.get_parent()
	return transform


## Gives a built-in shape a textured material from Materials3D.
static func _skin(instance: MeshInstance3D, set_name: String, tint := Color.WHITE) -> MeshInstance3D:
	instance.material_override = Materials3D.get_material(set_name, tint)
	return instance


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


static func _box(root: Node3D, size: Vector3, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(root, mesh, color, position)


static func _cyl(root: Node3D, top: float, bottom: float, height: float, color: Color, position: Vector3,
		segments := 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	return _add(root, mesh, color, position)


static func _sphere(root: Node3D, radius: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add(root, mesh, color, position)


static func _torus(root: Node3D, inner: float, outer: float, color: Color, position: Vector3) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	return _add(root, mesh, color, position)


static func _add(root: Node3D, mesh: Mesh, color: Color, position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = position
	root.add_child(instance)
	return instance


## A real stair flight. Each tread rises 15 cm and runs 24 cm in the keeper room.
static func staircase(width: float, rise := 1.5, depth := 2.4, count := 10) -> Node3D:
	var root := Node3D.new()
	root.name = "StairFlight"
	for i in count:
		var top: float = rise * (i + 1) / count
		var z: float = depth * 0.5 - depth * (i + 0.5) / count
		var step := _box(root, Vector3(width, top, depth / count + 0.008), Color.WHITE, Vector3(0, top * 0.5, z))
		step.name = "Tread%02d" % (i + 1)
		step.material_override = Materials3D.civic("shell")
		_box(root, Vector3(width, 0.025, 0.035), Color("#c5b89b"), Vector3(0, top + 0.012, z + depth / count * 0.4))
	for side: float in [-1.0, 1.0]:
		for i in [0, 3, 6, 9]:
			var top: float = rise * (i + 1) / count
			_cyl(root, 0.025, 0.035, 0.8, Color("#b28d5b"), Vector3(side * (width * 0.5 - 0.08), top + 0.4, depth * 0.5 - depth * (i + 0.5) / count))
		var start := Vector3(side * (width * 0.5 - 0.08), 0.15 + 0.8, depth * 0.45)
		var end := Vector3(start.x, rise + 0.8, -depth * 0.45)
		var rail := _cyl(root, 0.032, 0.032, start.distance_to(end), Color("#b28d5b"), (start + end) * 0.5)
		rail.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return root


## A recognisable structural arch, batched into one stone mesh for mobile.
static func ruined_arch() -> Node3D:
	var root := Node3D.new()
	root.name = "RuinedArcade"
	for side: float in [-1.0, 1.0]:
		_box(root, Vector3(1.15, 5.5, 1.4), Color.WHITE, Vector3(side * 3.0, 2.75, 0))
		_box(root, Vector3(1.6, 0.3, 1.8), Color.WHITE, Vector3(side * 3.0, 5.4, 0))
	for i in 11:
		var angle := PI * (i + 0.5) / 11.0
		var stone := _box(root, Vector3(0.92, 0.85, 1.4), Color.WHITE, Vector3(cos(angle) * 3.0, 5.5 + sin(angle) * 3.0, 0))
		stone.rotation.z = angle - PI / 2.0
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bounds: Array[AABB] = []
	var shapes: Array[Dictionary] = []
	for child: MeshInstance3D in root.get_children():
		bounds.append(child.transform * child.mesh.get_aabb())
		shapes.append({"bounds": child.mesh.get_aabb(), "transform": child.transform})
		surface.append_from(child.mesh, 0, child.transform)
		root.remove_child(child)
		child.free()
	var combined := MeshInstance3D.new()
	combined.mesh = surface.commit()
	root.set_meta("collision_boxes", bounds)
	root.set_meta("collision_shapes", shapes)
	combined.material_override = Materials3D.civic("shell")
	root.add_child(combined)
	return root


static func _ornament_wings(root: Node3D) -> void:
	var outline := PackedVector2Array([Vector2(-0.38, 0.10), Vector2(-0.25, -0.12), Vector2(-0.10, -0.10),
		Vector2(0, -0.025), Vector2(0.10, -0.10), Vector2(0.25, -0.12), Vector2(0.38, 0.10),
		Vector2(0.18, 0.04), Vector2(0, 0.13), Vector2(-0.18, 0.04)])
	var indices := Geometry2D.triangulate_polygon(outline)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		var point := outline[index]
		surface.add_vertex(Vector3(point.x, 0.72, point.y))
	surface.generate_normals()
	var wings := MeshInstance3D.new()
	wings.mesh = surface.commit()
	var copper := Materials3D.copper().duplicate() as StandardMaterial3D
	copper.cull_mode = BaseMaterial3D.CULL_DISABLED
	wings.material_override = copper
	root.add_child(wings)
