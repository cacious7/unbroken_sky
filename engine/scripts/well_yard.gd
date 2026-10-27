extends StoryScene
## SC02 "A good morning to argue": take the lever pin, repair the pump, draw clear water,
## then black silt, then the whisper. Mera intervenes and the exit to the cistern opens.

@onready var mera: Interactable = $Mera


func _dialogue_file() -> String:
	return "res://data/dialogue/sc02.json"


func _start() -> void:
	mera.set_active(GameState.get_flag("sc02_complete"))
	if GameState.get_flag("sc02_pump_count") >= 3 and not GameState.get_flag("sc02_complete"):
		# The app closed during the reveal; play it again rather than skip it.
		await _reveal()
	elif not GameState.get_flag("sc02_intro_seen"):
		await _say("intro")
		GameState.set_flag("sc02_intro_seen", true)
		_refresh_objective()


func _on_used(target: Interactable) -> void:
	match target.name:
		"Basket":
			if GameState.get_flag("sc02_pin_collected"):
				await _say("basket_empty")
			else:
				GameState.set_flag("sc02_pin_collected", true)
				await _say("basket_take")
		"Pump":
			await _use_pump()
		"Well":
			await _say("inspect_well")
		"Bird":
			await _say("inspect_bird")
		"Sena":
			if GameState.get_flag("sc02_complete"):
				await _say("sena_after")
			elif GameState.get_flag("sc02_pin_collected"):
				await _say("sena_before_pump")
			else:
				await _say("sena_before_pin")
		"Mera":
			await _say("mera_after")
		"Exit":
			if GameState.get_flag("sc02_complete"):
				_go_to("SC03")
			else:
				await _say("exit_locked")


func _use_pump() -> void:
	Sfx.play("pump_squeak", 0.0, 0.9 + 0.1 * GameState.get_flag("sc02_pump_count"))
	if not GameState.get_flag("sc02_pump_repaired"):
		if GameState.get_flag("sc02_pin_collected"):
			GameState.set_flag("sc02_pump_repaired", true)
			await _say("pump_fix")
		else:
			await _say("pump_stuck")
		return
	var count: int = GameState.get_flag("sc02_pump_count")
	if count >= 3:
		await _say("pump_after")
		return
	count += 1
	GameState.set_flag("sc02_pump_count", count)
	match count:
		1:
			await _say("pump_clear")
		2:
			await _say("pump_silt")
		3:
			await _reveal()


func _reveal() -> void:
	await _say("whisper")
	mera.set_active(true)
	await _say("mera")
	GameState.set_flag("sc02_complete", true)
	_refresh_objective()


func _objective() -> String:
	if GameState.get_flag("sc02_complete"):
		return "Meet Daru at the cistern."
	if GameState.get_flag("sc02_pump_repaired"):
		return "Work the pump."
	if GameState.get_flag("sc02_pin_collected"):
		return "Fit the lever pin to the pump."
	if GameState.get_flag("sc02_intro_seen"):
		return "Find a lever pin in the tool basket."
	return ""
