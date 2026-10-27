extends StoryScene
## SC04 "The promise at the door": Mera packs Tavo's bag and warns him; Sena gives him
## the key and the copper bird; Mera admits there is more about his childhood sickness.
## Daru meets him at the gate and the road to Reed Gate begins (SC05).


func _dialogue_file() -> String:
	return "res://data/dialogue/sc04.json"


func _start() -> void:
	if not GameState.get_flag("sc04_arrived"):
		await _say("arrive")
		GameState.set_flag("sc04_arrived", true)
		_refresh_objective()
	elif GameState.get_flag("has_key") and not GameState.get_flag("sc04_complete"):
		# The app closed between Sena's gift and Mera's admission.
		await _admission()


func _on_used(target: Interactable) -> void:
	match target.name:
		"Sena":
			if GameState.get_flag("has_key"):
				await _say("sena_after")
			else:
				GameState.set_flag("has_key", true)
				GameState.set_flag("has_bird", true)
				await _say("gift")
				await _admission()
		"Mera":
			if GameState.get_flag("sc04_complete"):
				await _say("mera_after")
			else:
				await _say("mera_waiting")
		"Bag":
			await _say("inspect_bag")
		"Door":
			if GameState.get_flag("sc04_complete"):
				await _say("gate")
				_go_to("SC05")
			else:
				await _say("door_locked")


func _admission() -> void:
	await _say("seven")
	GameState.set_flag("sc04_complete", true)
	_refresh_objective()


func _objective() -> String:
	if GameState.get_flag("sc04_complete"):
		return "Leave for Reed Gate."
	if GameState.get_flag("sc04_arrived"):
		return "Take the key from Sena."
	return ""
