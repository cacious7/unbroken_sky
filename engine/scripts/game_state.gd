extends Node
## Owns narrative flags and the local save. Maps read and write state through here
## and never keep private copies of it.

signal changed(key: String, value: Variant)

const SAVE_VERSION := 1

const SCENES := {
	"SC01": "res://scenes/prologue.tscn",
	"SC02": "res://scenes/well_yard.tscn",
	"SC03": "res://scenes/cistern.tscn",
	"SC04": "res://scenes/home.tscn",
	"SC05": "res://scenes/ash_road.tscn",
	"SC06": "res://scenes/culvert.tscn",
	"SC07": "res://scenes/reed_gate.tscn",
	"SC08": "res://scenes/keeper_room.tscn",
	"SC09": "res://scenes/fortress_flight.tscn",
	"SC10": "res://scenes/wheel_platform.tscn",
}

const STORY_SAVE_PATH := "user://save.json"
const TEST_ROOM_SAVE_PATH := "user://test_room_save.json"

## Story state from Game Concept/development/CHOICES_AND_STATE.md plus per-scene progress.
## "" means a policy has not been chosen yet.
const DEFAULTS := {
	"scene_id": "SC01",
	"water_policy": "",
	"water_compact": false,
	"eagle_unlocked": false,
	"has_key": false,
	"has_bird": false,
	"sc02_intro_seen": false,
	"sc02_pin_collected": false,
	"sc02_pump_repaired": false,
	"sc02_pump_count": 0,
	"sc02_complete": false,
	"sc03_arrived": false,
	"sc03_pipe_taken": false,
	"sc03_repair_done": false,
	"sc03_complete": false,
	"sc04_arrived": false,
	"sc04_complete": false,
	"sc05_arrived": false,
	"sc05_husk_one_down": false,
	"sc05_fight_done": false,
	"sc05_merchant_done": false,
	"sc05_complete": false,
	"sc06_arrived": false,
	"sc06_inspected": false,
	"sc06_asked": false,
	"sc06_hook_broken": false,
	"sc06_complete": false,
	"sc07_arrived": false,
	"sc07_drained": false,
	"sc07_braced": false,
	"sc07_complete": false,
	"sc08_talked": false,
	"sc08_complete": false,
	"sc09_started": false,
	"sc09_voice_heard": false,
	"sc09_link": 0,
	"sc09_complete": false,
	"sc10_arrived": false,
	"sc10_wheel_fitted": false,
	"sc10_complete": false,
}

## Legal values for string fields; anything else in a save resets to the default.
const ALLOWED := {
	"scene_id": ["SC01", "SC02", "SC03", "SC04", "SC05", "SC06", "SC07", "SC08", "SC09", "SC10"],
	"water_policy": ["", "reserve", "share", "joint"],
}

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"attack": [KEY_J, KEY_F],
	"dodge": [KEY_K, KEY_SHIFT],
}

var save_path := STORY_SAVE_PATH
## Tests turn this off so scene transitions only update state.
var scene_changes_enabled := true
var flags: Dictionary = {}


func _ready() -> void:
	_setup_input()
	reset()


func reset() -> void:
	flags = DEFAULTS.duplicate(true)


func new_game() -> void:
	reset()
	delete_save()


func get_flag(key: String) -> Variant:
	return flags.get(key)


func set_flag(key: String, value: Variant) -> void:
	if flags.get(key) == value:
		return
	flags[key] = value
	changed.emit(key, value)
	save_game()


## Applies a dialogue choice's effects. Unknown keys and illegal values are rejected.
func apply_effects(effects: Dictionary) -> void:
	for key: String in effects:
		if not DEFAULTS.has(key):
			push_error("Unknown state key in dialogue effects: %s" % key)
			continue
		set_flag(key, _sanitise(key, effects[key]))


## True when every key in conditions currently has the given value.
func matches(conditions: Dictionary) -> bool:
	for key: String in conditions:
		if flags.get(key) != conditions[key]:
			return false
	return true


## Starts a scene from a fresh state in a separate save, leaving story progress alone.
func start_test_room(scene_id: String) -> void:
	save_path = TEST_ROOM_SAVE_PATH
	new_game()
	go_to(scene_id)


func use_story_save() -> void:
	save_path = STORY_SAVE_PATH


func current_scene_path() -> String:
	return SCENES[flags.scene_id]


func go_to(scene_id: String) -> void:
	set_flag("scene_id", scene_id)
	if scene_changes_enabled:
		get_tree().change_scene_to_file(SCENES[scene_id])


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "flags": flags}))


## Returns false and starts fresh when the save is missing or unreadable.
func load_game() -> bool:
	reset()
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("flags")) != TYPE_DICTIONARY:
		push_warning("Save file unreadable; starting a new game.")
		return false
	var version: Variant = data.get("version")
	if not typeof(version) in [TYPE_INT, TYPE_FLOAT] or int(version) != SAVE_VERSION:
		push_warning("Save file version not recognised; starting a new game.")
		return false
	var saved: Dictionary = data.flags
	for key: String in DEFAULTS:
		flags[key] = _sanitise(key, saved.get(key))
	# Keep the well sequence internally consistent even if the file was edited.
	flags.sc02_pump_count = clampi(flags.sc02_pump_count, 0, 3)
	if flags.sc02_complete:
		flags.sc02_pump_count = 3
	if flags.sc02_pump_count > 0:
		flags.sc02_pump_repaired = true
	if flags.sc02_pump_repaired:
		flags.sc02_pin_collected = true
	flags.sc09_link = clampi(flags.sc09_link, 0, 3)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func _sanitise(key: String, value: Variant) -> Variant:
	var fallback: Variant = DEFAULTS[key]
	match typeof(fallback):
		TYPE_BOOL:
			return value if typeof(value) == TYPE_BOOL else fallback
		TYPE_INT:
			return int(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else fallback
		TYPE_STRING:
			if typeof(value) != TYPE_STRING or (ALLOWED.has(key) and not value in ALLOWED[key]):
				return fallback
			return value
	return fallback


func _setup_input() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for keycode: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
