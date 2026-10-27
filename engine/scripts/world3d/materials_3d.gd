class_name Materials3D
extends RefCounted
## Physically based materials from CC0 Poly Haven texture sets (1k: colour, normal,
## and AO/roughness/metal packed into one "arm" map). Mapped in world space
## (triplanar), so any wall, floor or box gets correctly scaled, seamless texture
## without UVs. `metres` is how much ground one copy of the texture covers.

const ROOT := "res://assets/third_party/polyhaven/textures/"

const SETS := {
	"red_earth": {"id": "red_laterite_soil_stones", "metres": 3.0},
	"cracked_earth": {"id": "cracked_red_ground", "metres": 3.0},
	"dry_ground": {"id": "dry_ground_01", "metres": 3.0},
	"mud_brick": {"id": "clay_block_wall", "metres": 2.0},
	"plaster": {"id": "clay_plaster", "metres": 2.5},
	"thatch": {"id": "thatch_roof_angled", "metres": 1.6},
	"stone": {"id": "old_stone_wall", "metres": 2.5},
	"mossy_stone": {"id": "mossy_stone_wall", "metres": 2.5},
	"planks": {"id": "weathered_planks", "metres": 1.5},
}

static var _cache: Dictionary = {}


static func get_material(set_name: String, tint := Color.WHITE) -> StandardMaterial3D:
	var key := set_name + tint.to_html()
	if _cache.has(key):
		return _cache[key]
	var entry: Dictionary = SETS[set_name]
	var id: String = entry.id
	var base := ROOT + id + "/" + id
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(base + "_diff_1k.jpg")
	material.albedo_color = tint
	material.normal_enabled = true
	material.normal_texture = load(base + "_nor_gl_1k.jpg")
	var packed: Texture2D = load(base + "_arm_1k.jpg")
	material.ao_enabled = true
	material.ao_texture = packed
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness_texture = packed
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic = 0.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / float(entry.metres)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = material
	return material


## Still, dark river water that reflects the sky.
static func water() -> StandardMaterial3D:
	if _cache.has("water"):
		return _cache["water"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.09, 0.17, 0.22, 0.88)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.04
	material.metallic = 0.2
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_cache["water"] = material
	return material


## Polished, slightly aged copper for the covenant's machinery.
static func copper() -> StandardMaterial3D:
	if _cache.has("copper"):
		return _cache["copper"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#b8693a")
	material.metallic = 0.85
	material.roughness = 0.38
	_cache["copper"] = material
	return material


## Which ground texture a flat surface gets, from its scene and name.
static func for_surface(scene_name: String, surface_name: String, color: Color) -> Material:
	if color.b > color.r:
		return water()
	match surface_name:
		"Road", "DryChannel":
			return get_material("cracked_earth")
		"Floor":
			return get_material("dry_ground", Color(1.0, 0.92, 0.85))
		"Platform", "Reservoir":
			return get_material("stone")
	match scene_name:
		"KeeperRoom":
			return get_material("mossy_stone", Color(0.75, 0.78, 0.8))
		"ReedGate", "WheelPlatform":
			return get_material("dry_ground", Color(0.85, 0.82, 0.78))
		"Culvert":
			return get_material("dry_ground")
		"AshRoad":
			return get_material("red_earth", Color(1.0, 0.92, 0.85))
	return get_material("red_earth")
