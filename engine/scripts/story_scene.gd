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
	_dress_scene()
	dialogue.load_file(_dialogue_file())
	for child in get_children():
		if child is Interactable:
			child.used.connect(use)
	player.focus_changed.connect(hud.show_prompt)
	player.focus_changed.connect(_update_action_label.unbind(1))
	player.health_changed.connect(hud.set_health)
	player.struck.connect(_play_strike_sound)
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


## Art and depth: flat colour areas go to the back, objects and characters are drawn
## in order of their y position (so Tavo can walk in front of or behind things), the
## ground gets texture, and objects listed in the art catalog get their sprites.
func _dress_scene() -> void:
	y_sort_enabled = true
	var detail_script := preload("res://scripts/ground_detail.gd")
	for child in get_children():
		if child is ColorRect:
			# The base ground under every other surface (roads, floors, platforms).
			child.z_index = -11 if child.name == "Ground" else -10
			detail_script.attach(child, hash(name + child.name))
	ArtCatalog.apply(self)


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


## The hammer sounds different depending on what it hits: a light ring off a shell,
## a solid clang on a connector, a deep one when something breaks.
func _play_strike_sound(result: String) -> void:
	match result:
		"deflect":
			Sfx.play("hammer_clang", -8.0, 1.35)
		"interrupt", "hit":
			Sfx.play("hammer_clang")
		"break":
			Sfx.play("hammer_clang", 2.0, 0.75)


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
