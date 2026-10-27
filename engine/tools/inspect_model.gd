extends SceneTree
## Prints a glTF/scene's node tree, skeleton bones and animations, for wiring up assets.
##   godot --headless --path . --script res://tools/inspect_model.gd -- res://path/to/model.glb

func _init() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Cannot load %s" % path)
		quit(1)
		return
	var scene: Node = packed.instantiate()
	_print_tree(scene, 0)
	for skeleton: Skeleton3D in scene.find_children("", "Skeleton3D", true, false):
		var names: Array[String] = []
		for i in skeleton.get_bone_count():
			names.append(skeleton.get_bone_name(i))
		print("BONES (%d): %s" % [names.size(), ", ".join(names)])
	for player: AnimationPlayer in scene.find_children("", "AnimationPlayer", true, false):
		print("ANIMATIONS: %s" % ", ".join(player.get_animation_list()))
	for mesh: MeshInstance3D in scene.find_children("", "MeshInstance3D", true, false):
		print("MESH %s aabb=%s surfaces=%d" % [mesh.name, mesh.get_aabb(), mesh.mesh.get_surface_count()])
	scene.free()
	quit()


func _print_tree(node: Node, depth: int) -> void:
	if depth > 4:
		return
	print("  ".repeat(depth) + "%s (%s)" % [node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, depth + 1)
