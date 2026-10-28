extends CanvasLayer
## Short input-safe fades hide room replacement; resources load while fading.
## Lives under GameState so its tween survives freeing the outgoing room.
var changing := false
var _cover: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cover = ColorRect.new()
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.color = Color(0.035, 0.045, 0.055, 0)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_cover)
	visible = false


func _input(_event: InputEvent) -> void:
	if changing:
		get_viewport().set_input_as_handled()


func change_to(path: String) -> void:
	if changing:
		return
	changing = true
	visible = true
	get_tree().paused = false
	var old := get_tree().current_scene
	var old_mode := Node.PROCESS_MODE_INHERIT
	if old != null:
		old_mode = old.process_mode
		old.process_mode = Node.PROCESS_MODE_DISABLED
	var request := ResourceLoader.load_threaded_request(path, "PackedScene")
	var fade := create_tween().set_ignore_time_scale()
	fade.tween_property(_cover, "color:a", 1.0, 0.12)
	await fade.finished
	var incoming: Node
	var incoming_mode := Node.PROCESS_MODE_INHERIT
	var status := ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path)
	if request == OK and status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(path) as PackedScene
		var result := get_tree().change_scene_to_packed(packed)
		if result != OK and is_instance_valid(old):
			old.process_mode = old_mode
			push_error("Could not open scene: %s" % path)
		if result == OK:
			await get_tree().scene_changed
			incoming = get_tree().current_scene
			if incoming != null:
				incoming_mode = incoming.process_mode
				incoming.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if is_instance_valid(old):
			old.process_mode = old_mode
		push_error("Could not load scene: %s" % path)
	fade = create_tween().set_ignore_time_scale()
	fade.tween_property(_cover, "color:a", 0.0, 0.12)
	await fade.finished
	if is_instance_valid(incoming):
		incoming.process_mode = incoming_mode
	visible = false
	changing = false
