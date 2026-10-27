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
			_skin(_cyl(root, 0.85, 0.95, 0.75, Color("#9a9288"), Vector3(0, 0.37, 0)), "stone")
			_cyl(root, 0.62, 0.62, 0.77, Color("#1d2a33"), Vector3(0, 0.38, 0))
			_cyl(root, 0.6, 0.6, 0.02, Color("#2c4a5e"), Vector3(0, 0.6, 0))
		"Pump":
			_cyl(root, 0.35, 0.4, 0.15, Color("#8a847a"), Vector3(0, 0.07, 0))
			_cyl(root, 0.12, 0.13, 1.1, Color("#4d5a66"), Vector3(0, 0.6, 0))
			_box(root, Vector3(0.08, 0.08, 0.35), Color("#3a444d"), Vector3(0, 0.95, -0.2))
			var handle := _box(root, Vector3(0.05, 0.05, 0.8), Color("#5f6b75"), Vector3(0, 1.25, 0.25))
			handle.rotation.x = -0.5
			_sphere(root, 0.07, Color("#c97a36"), Vector3(0, 1.15, 0))
		"Basket":
			# A woven basket: thatch texture on a tapered drum, tools sticking out.
			_model(root, "kenney/survival/tool-hammer.glb", 0.5, Vector3(0.1, 0.35, 0), Vector3(0, 0, 0.6))
		"Bird":
			_model(root, "kenney/survival/campfire-pit.glb", 0.9)
			_cyl(root, 0.015, 0.015, 0.5, Color("#8a6a44"), Vector3(0, 0.45, 0))
			_box(root, Vector3(0.5, 0.03, 0.12), Color("#c97a36"), Vector3(0, 0.72, 0))
			_sphere(root, 0.07, Color("#d98a46"), Vector3(0, 0.74, 0))
		"Home":
			_house(root, size)
		"ShadeCloth":
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				_cyl(root, 0.05, 0.05, 2.2, Color("#6b4f33"), Vector3(corner.x * size.x * 0.45, 1.1, corner.y * size.y * 0.45))
			var cloth := _box(root, Vector3(size.x, 0.04, size.y), Color("#e6dcc4"), Vector3(0, 2.15, 0))
			cloth.rotation.x = 0.08
		"Exit", "Door":
			_model(root, "kenney/survival/signpost-single.glb", 1.0)
		"Cistern":
			_skin(_box(root, Vector3(size.x, 1.1, size.y), Color("#8f8a82"), Vector3(0, 0.55, 0)), "stone")
			_box(root, Vector3(size.x - 0.4, 0.04, size.y - 0.4), Color("#2c4a5e"), Vector3(0, 1.11, 0)).material_override = Materials3D.water()
		"Jars":
			for i in 4:
				_model(root, "polypizza/pot_ceramic_large.glb", 0.6, Vector3((i - 1.5) * 0.66, 0, 0), Vector3(0, i * 1.3, 0))
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
			_cyl(root, size.x * 0.32, size.x * 0.32, 0.03, Color("#2e5a70"), Vector3(0, 0.06, 0))
		"Workbench":
			_model(root, "kenney/survival/workbench-anvil.glb", 1.5)
		"Hearth":
			_model(root, "kenney/nature/campfire_stones.glb", size.x * 0.9)
		"Bag":
			_model(root, "kenney/survival/chest.glb", 0.7)
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
			var puddle := _cyl(root, size.x * 0.5, size.x * 0.5, 0.02, Color("#2c4a63"), Vector3(0, 0.02, 0))
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
static func wall(size: Vector2, stone: bool, height := 1.1) -> Node3D:
	var root := Node3D.new()
	var color := Color("#8f8576") if stone else Color("#a8714a")
	_skin(_box(root, Vector3(size.x, height, size.y), color, Vector3(0, height / 2.0, 0)), "stone" if stone else "mud_brick")
	_skin(_box(root, Vector3(size.x + 0.06, 0.08, size.y + 0.06), color.darkened(0.15), Vector3(0, height, 0)), "stone" if stone else "plaster", Color(0.85, 0.8, 0.75))
	return root


static func _house(root: Node3D, size: Vector2) -> void:
	var wall_height := 2.4
	_skin(_box(root, Vector3(size.x, wall_height, size.y), Color("#a8714a"), Vector3(0, wall_height / 2.0, 0)), "plaster", Color(1.0, 0.85, 0.72))
	_box(root, Vector3(0.8, 1.7, 0.05), Color("#3a2618"), Vector3(0, 0.85, size.y / 2.0 + 0.02))
	# Thatched roof: a four-sided cone over the walls.
	var roof := _cyl(root, 0.0, maxf(size.x, size.y) * 0.78, 1.6, Color("#b89a5a"), Vector3(0, wall_height + 0.8, 0), 4)
	roof.rotation.y = PI / 4.0
	roof.scale = Vector3(size.x / maxf(size.x, size.y), 1.0, size.y / maxf(size.x, size.y))


## A round mud hut with a conical thatched roof, as in Zambian villages: plastered
## walls, a low doorway, a thatch cone with a little overhang.
static func round_hut(radius: float) -> Node3D:
	var root := Node3D.new()
	var wall_height := radius * 0.85
	_skin(_cyl(root, radius, radius * 1.03, wall_height, Color.WHITE, Vector3(0, wall_height / 2.0, 0), 20), "plaster", Color(1.0, 0.86, 0.74))
	_box(root, Vector3(radius * 0.45, wall_height * 0.75, 0.1), Color("#2a1a10"), Vector3(0, wall_height * 0.37, radius - 0.02))
	var roof := _cyl(root, 0.02, radius * 1.32, radius * 1.05, Color.WHITE, Vector3(0, wall_height + radius * 0.5, 0), 20)
	_skin(roof, "thatch")
	return root


static func _cart(root: Node3D, size: Vector2) -> void:
	_skin(_box(root, Vector3(size.x, 0.5, size.y), Color("#8a6a44"), Vector3(0, 0.75, 0)), "planks")
	for x: float in [-0.3, 0.3]:
		var wheel := _cyl(root, 0.4, 0.4, 0.1, Color("#4a3424"), Vector3(x * size.x, 0.4, size.y / 2.0 + 0.06))
		wheel.rotation.x = PI / 2.0
	_box(root, Vector3(0.08, 0.08, 1.0), Color("#5a4229"), Vector3(-size.x / 2.0 - 0.4, 0.6, 0)).rotation.y = PI / 2.0


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
