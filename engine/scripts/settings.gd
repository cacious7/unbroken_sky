extends Node
## Player preferences, stored apart from story saves so starting a new game keeps them.

signal changed

const TEXT_SIZES := [1.0, 1.25, 1.5]
const TEXT_SIZE_NAMES := ["Normal", "Large", "Largest"]
## Characters per second; 0 shows each line at once.
const TEXT_SPEEDS := [45.0, 90.0, 0.0]
const TEXT_SPEED_NAMES := ["Normal", "Fast", "Instant"]

var path := "user://settings.json"
var text_size := 0
var text_speed := 0
## Wider landing zones, longer airtime and weaker gusts for eagle flight.
var flight_assist := false
var sound_on := true
## Screen shake and phone vibration on hits. Off for players sensitive to motion.
var shake_on := true


func _ready() -> void:
	load_settings()


func font_size(base: int) -> int:
	return roundi(base * TEXT_SIZES[text_size])


func chars_per_second() -> float:
	return TEXT_SPEEDS[text_speed]


func text_size_name() -> String:
	return TEXT_SIZE_NAMES[text_size]


func text_speed_name() -> String:
	return TEXT_SPEED_NAMES[text_speed]


func cycle_text_size() -> void:
	text_size = (text_size + 1) % TEXT_SIZES.size()
	_save_and_notify()


func cycle_text_speed() -> void:
	text_speed = (text_speed + 1) % TEXT_SPEEDS.size()
	_save_and_notify()


func toggle_flight_assist() -> void:
	flight_assist = not flight_assist
	_save_and_notify()


func toggle_sound() -> void:
	sound_on = not sound_on
	_apply_sound()
	_save_and_notify()


func toggle_shake() -> void:
	shake_on = not shake_on
	_save_and_notify()


func _apply_sound() -> void:
	AudioServer.set_bus_mute(0, not sound_on)


func load_settings() -> void:
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	text_size = _index_or_default(data.get("text_size"), TEXT_SIZES.size())
	text_speed = _index_or_default(data.get("text_speed"), TEXT_SPEEDS.size())
	flight_assist = data.get("flight_assist") == true
	sound_on = data.get("sound_on") != false
	shake_on = data.get("shake_on") != false
	_apply_sound()


func _index_or_default(value: Variant, count: int) -> int:
	if typeof(value) in [TYPE_INT, TYPE_FLOAT] and int(value) >= 0 and int(value) < count:
		return int(value)
	return 0


func _save_and_notify() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"text_size": text_size, "text_speed": text_speed, "flight_assist": flight_assist,
			"sound_on": sound_on, "shake_on": shake_on}))
	changed.emit()
