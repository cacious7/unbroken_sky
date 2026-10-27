class_name StoryScene
extends Node2D
## Shared wiring for playable story scenes: player, dialogue, HUD, touch and pause.
## A scene overrides _dialogue_file(), _start(), _on_used() and _objective().

@onready var player: Player = $Player
@onready var dialogue: DialogueBox = $Dialogue
@onready var hud: Hud = $Hud
@onready var touch: TouchControls = $TouchControls

var pause_menu: PauseMenu
## Scenes with their own pointer handling (eagle flight) turn the touch layer off.
var touch_enabled := true
var _busy := false


func _ready() -> void:
	dialogue.load_file(_dialogue_file())
	for child in get_children():
		if child is Interactable:
			child.used.connect(use)
	player.focus_changed.connect(hud.show_prompt)
	player.focus_changed.connect(_update_action_label.unbind(1))
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.health, Player.MAX_HEALTH)
	hud.show_key_hints = not touch.device_has_touch
	hud.restart_requested.connect(_restart)
	hud.title_requested.connect(get_tree().change_scene_to_file.bind(PauseMenu.TITLE_SCENE))
	touch.vector_changed.connect(func(vector: Vector2) -> void: player.touch_vector = vector)
	touch.interact_pressed.connect(player.try_interact)
	touch.dodge_pressed.connect(player.dodge)
	touch.tapped.connect(player.walk_to_screen)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	_refresh_objective()
	_start()


## Called when the player uses an object. Ignored while a conversation is running.
func use(target: Interactable) -> void:
	if _busy:
		return
	await _on_used(target)
	_refresh_objective()


func _dialogue_file() -> String:
	return ""


## Runs once the scene is ready; may play an opening conversation.
func _start() -> void:
	pass


func _on_used(_target: Interactable) -> void:
	pass


func _objective() -> String:
	return ""


func _refresh_objective() -> void:
	hud.set_objective(_objective())


func _say(conversation_id: String) -> void:
	_busy = true
	player.active = false
	touch.set_shown(false)
	dialogue.play(conversation_id)
	await dialogue.finished
	player.active = true
	touch.set_shown(touch_enabled)
	_busy = false


## Turns encounter controls on or off: hammer and dodge, health pips, dodge button.
func set_combat(on: bool) -> void:
	player.combat_enabled = on
	touch.set_combat_mode(on)
	hud.set_combat_visible(on)
	_update_action_label()


func _update_action_label() -> void:
	touch.set_action_label("STRIKE" if player.combat_enabled and not player.has_focus_target() else "USE")


func _go_to(scene_id: String) -> void:
	_busy = true
	player.active = false
	GameState.go_to(scene_id)


func _show_end_card(title: String, body: String) -> void:
	_busy = true
	player.active = false
	touch.set_shown(false)
	hud.show_end_card(title, body)


func _restart() -> void:
	if GameState.save_path == GameState.TEST_ROOM_SAVE_PATH:
		GameState.start_test_room(GameState.get_flag("scene_id"))
		return
	GameState.new_game()
	get_tree().change_scene_to_file(GameState.current_scene_path())
