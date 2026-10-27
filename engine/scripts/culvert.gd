extends StoryScene
## SC06 "The woman at the crossing": a figure in Mera's scarf calls from a dry culvert.
## Approaching reveals danger without instant death; inspecting the reflection shows
## it is wrong; Tavo's question collapses it into a water rope. Retreat from its marked
## sweep, then break the exposed copper hook. Defeat restarts the encounter only.

const ENTRANCE := Vector2(250, 300)
const RESULT_CAPTIONS := {
	"deflect": "[the hammer splashes through water]",
	"break": "[the copper hook snaps]",
}

@onready var figure: Interactable = $Figure
@onready var rope: WaterRope = $WaterRope
@onready var hook: Interactable = $Hook


func _dialogue_file() -> String:
	return "res://data/dialogue/sc06.json"


func _start() -> void:
	rope.broken.connect(_on_rope_broken)
	rope.state_changed.connect(_on_rope_state)
	player.defeated.connect(_on_defeated)
	player.struck.connect(_on_struck)
	_refresh_props()
	if not GameState.get_flag("sc06_arrived"):
		await _say("arrive")
		GameState.set_flag("sc06_arrived", true)
		_refresh_objective()
	elif GameState.get_flag("sc06_asked") and not GameState.get_flag("sc06_hook_broken"):
		player.global_position = ENTRANCE
		_begin_fight()


func _on_used(target: Interactable) -> void:
	match target.name:
		"Reflection":
			await _say("reflection")
			GameState.set_flag("sc06_inspected", true)
		"Figure":
			if not GameState.get_flag("sc06_inspected"):
				await _say("figure_plead")
				return
			await _say("question")
			GameState.set_flag("sc06_asked", true)
			_refresh_props()
			_begin_fight()
		"Nali":
			if GameState.get_flag("sc06_complete"):
				await _say("nali_after")
			else:
				await _say("nali_before")
		"Hook":
			await _say("inspect_hook")
		"Exit":
			if GameState.get_flag("sc06_complete"):
				_go_to("SC07")
			else:
				await _say("exit_locked")


func _begin_fight() -> void:
	set_combat(true)
	_refresh_objective()
	rope.activate(player)


func _on_rope_broken(_rope: WaterRope) -> void:
	GameState.set_flag("sc06_hook_broken", true)
	set_combat(false)
	_refresh_props()
	await _say("after")
	GameState.set_flag("sc06_complete", true)
	_refresh_objective()


func _on_defeated() -> void:
	await _say("defeat")
	player.global_position = ENTRANCE
	player.restore_health()
	rope.reset_to_start()
	rope.activate(player)


func _on_struck(result: String) -> void:
	if RESULT_CAPTIONS.has(result):
		hud.show_caption(RESULT_CAPTIONS[result])


func _on_rope_state(_rope: WaterRope, state: int) -> void:
	if state == WaterRope.State.TELEGRAPH:
		hud.show_caption("[the water rope draws back: get clear of the ring]")
	elif state == WaterRope.State.EXPOSED:
		hud.show_caption("[the copper hook is exposed]")


func _refresh_props() -> void:
	var asked: bool = GameState.get_flag("sc06_asked")
	var broken: bool = GameState.get_flag("sc06_hook_broken")
	figure.set_active(not asked)
	hook.set_active(broken)
	rope.visible = asked and not broken


func _objective() -> String:
	if GameState.get_flag("sc06_complete"):
		return "Continue to Reed Gate."
	if GameState.get_flag("sc06_asked"):
		return "Get clear of the marked ring, then strike the copper hook."
	if GameState.get_flag("sc06_inspected"):
		return "Ask the figure something only Mera could answer."
	if GameState.get_flag("sc06_arrived"):
		return "Find out what the figure is. Look closely."
	return ""
