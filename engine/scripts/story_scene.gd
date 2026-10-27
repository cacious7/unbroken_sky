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


var world_view: WorldView


func _ready() -> void:
	_dress_scene()
	# The game is presented in 3D: the 2D layout keeps running as the gameplay model
	# (hidden), and WorldView shows it. CanvasLayer UI is unaffected by this modulate.
	modulate = Color(1, 1, 1, 0)
	world_view = WorldView.new(self)
	add_child(world_view)
	player.screen_to_world = world_view.screen_to_world_2d
	dialogue.load_file(_dialogue_file())
	for child in get_children():
		if child is Interactable:
			child.used.connect(use)
	player.focus_changed.connect(hud.show_prompt)
	player.focus_changed.connect(_update_action_label.unbind(1))
	player.health_changed.connect(hud.set_health)
	player.struck.connect(_on_strike)
	player.health_changed.connect(_on_health_changed)
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


## Combat feedback by result: a light ring off a shell; a solid hit with a moment of
## hit-stop, a small shake and a buzz on a connector; bigger for a break.
func _on_strike(result: String) -> void:
	match result:
		"deflect":
			Sfx.play("hammer_clang", -8.0, 1.35)
		"interrupt", "hit":
			Sfx.play("hammer_clang")
			hit_stop(0.06)
			shake(3.0)
			_vibrate(30)
		"break":
			Sfx.play("hammer_clang", 2.0, 0.75)
			hit_stop(0.12)
			shake(6.0)
			_vibrate(60)


var _last_health := Player.MAX_HEALTH


func _on_health_changed(current: int, _maximum: int) -> void:
	if current < _last_health:
		hud.flash_damage()
		shake(5.0)
		_vibrate(80)
	_last_health = current


## Freezes the action for a moment so a hit lands with weight.
func hit_stop(seconds: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


## Shakes the view only (the viewport's canvas transform), so nothing's real position
## changes and taps, paths and collisions are unaffected.
var shake_offset := Vector2.ZERO:
	set(value):
		shake_offset = value
		if is_inside_tree():
			get_viewport().canvas_transform = Transform2D(0.0, value)


func shake(strength: float) -> void:
	if not Settings.shake_on:
		return
	var tween := create_tween().set_ignore_time_scale()
	# Strength is in screen pixels; the 3D camera shakes by an equivalent small offset.
	for i in 4:
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * 0.012
		tween.tween_property(world_view, "shake_offset", offset, 0.03)
	tween.tween_property(world_view, "shake_offset", Vector2.ZERO, 0.03)


func _vibrate(milliseconds: int) -> void:
	if Settings.shake_on:
		Input.vibrate_handheld(milliseconds)


func _exit_tree() -> void:
	# Never leave the game slowed down or the view offset if the scene changes mid-effect.
	Engine.time_scale = 1.0
	get_viewport().canvas_transform = Transform2D.IDENTITY


## The touch action button names what it will do: the first word of the object's prompt
## ("TALK", "SEARCH", "LOOK"...), STRIKE in combat with nothing in reach, else USE.
func _update_action_label() -> void:
	touch.set_action_label(action_verb(player.focus_target(), player.combat_enabled))


static func action_verb(target: Interactable, in_combat: bool) -> String:
	if target != null:
		var verb := target.prompt.get_slice(" ", 0).to_upper()
		return verb if verb.length() <= 7 else "USE"
	return "STRIKE" if in_combat else "USE"


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
