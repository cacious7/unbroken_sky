extends StoryScene
## SC08 "A room remembered twice": Eren behind the grille, the memory from both sides,
## the transfer slips, then the flood. Tavo climbs one clearly marked stair route ahead
## of the rising water. If the water reaches him, only the climb restarts (the keeper
## conversation is not repeated). Eren's death is fixed by the story; nothing on screen
## promises he can be saved. Reaching the top leads to the fall in SC09.

## Reaching above this y position escapes the flood.
const ESCAPE_Y := 100.0
const ROUTE_START := Vector2(480, 490)

@onready var flood: FloodWater = $FloodWater

var _escaping := false


func _dialogue_file() -> String:
	return "res://data/dialogue/sc08.json"


func _start() -> void:
	if GameState.get_flag("sc08_complete"):
		_go_to("SC09")
		return
	if not GameState.get_flag("sc08_talked"):
		await _say("keeper")
		GameState.set_flag("sc08_talked", true)
	await _say("flood")
	_begin_escape()


func _begin_escape() -> void:
	player.global_position = ROUTE_START
	flood.reset()
	flood.rising = true
	_escaping = true
	_refresh_objective()


func _physics_process(_delta: float) -> void:
	if not _escaping or _busy:
		flood.rising = false
		return
	flood.rising = true
	if player.global_position.y <= ESCAPE_Y:
		_escape()
	elif flood.covers(player.global_position + Vector2(0, 10)):
		hud.show_caption("[the water drags Tavo back: climb again]")
		_begin_escape()


func _escape() -> void:
	_escaping = false
	flood.rising = false
	await _say("collapse")
	GameState.set_flag("sc08_complete", true)
	_go_to("SC09")


func _objective() -> String:
	if _escaping:
		return "Climb out."
	return ""
