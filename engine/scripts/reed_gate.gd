extends StoryScene
## SC07 "Reed Gate": Veya guards the release wheel from the wall. To make it safe to
## remove, Tavo repairs the bypass in a readable order: drain the side channel, shift
## the brace, turn Sena's key. Out-of-order attempts explain what is missing.
## The key reveals the sleeping man behind the grille and leads into SC08.


func _dialogue_file() -> String:
	return "res://data/dialogue/sc07.json"


func _start() -> void:
	if not GameState.get_flag("sc07_arrived"):
		await _say("arrive")
		GameState.set_flag("sc07_arrived", true)
		_refresh_objective()
	elif GameState.get_flag("sc07_complete"):
		_go_to("SC08")


func _on_used(target: Interactable) -> void:
	match target.name:
		"SideChannel":
			if GameState.get_flag("sc07_drained"):
				await _say("drain_done")
			else:
				GameState.set_flag("sc07_drained", true)
				await _say("drain")
		"Brace":
			if not GameState.get_flag("sc07_drained"):
				await _say("brace_early")
			elif GameState.get_flag("sc07_braced"):
				await _say("brace_done")
			else:
				GameState.set_flag("sc07_braced", true)
				await _say("brace")
		"SluiceLock":
			if not GameState.get_flag("sc07_braced"):
				await _say("key_early")
			else:
				await _say("key")
				GameState.set_flag("sc07_complete", true)
				_go_to("SC08")
		"Order":
			await _say("inspect_order")
		"Veya":
			await _say("veya")
		"Nali":
			await _say("nali")


func _objective() -> String:
	if GameState.get_flag("sc07_braced"):
		return "Use the key."
	if GameState.get_flag("sc07_drained"):
		return "Brace the gate."
	if GameState.get_flag("sc07_arrived"):
		return "Drain the channel."
	return ""
