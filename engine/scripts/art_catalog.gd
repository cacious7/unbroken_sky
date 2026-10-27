class_name ArtCatalog
extends RefCounted
## Gives scene objects their sprites by node name, from data/art_catalog.json, so art
## can be added or swapped without editing every scene file.

const PATH := "res://data/art_catalog.json"
const ART_ROOT := "res://assets/art/"

static var _entries: Dictionary = {}


static func entries() -> Dictionary:
	if _entries.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(data) == TYPE_DICTIONARY and typeof(data.get("objects")) == TYPE_DICTIONARY:
			_entries = data.objects
		else:
			push_error("Art catalog unreadable: %s" % PATH)
	return _entries


static func apply(scene: Node) -> void:
	for child in scene.get_children():
		if not child.has_method("set_art") or not entries().has(child.name):
			continue
		var entry: Dictionary = entries()[child.name]
		var texture: Texture2D = load(ART_ROOT + str(entry.texture))
		if texture == null:
			push_error("Missing art for %s: %s" % [child.name, entry.texture])
			continue
		child.set_art(texture, float(entry.get("height", 0)), entry.get("feet", false) == true,
				entry.get("label", true) == true)
