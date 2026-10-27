extends StoryScene
## SC10 "The wheel and the witness": Veya confronts Kesi; Orun and Lio arrive with relief
## workers; Tavo fits the wheel to the repaired bypass and clean water flows uplands.
## Orun notices Tavo's wrist, news arrives of Mera's detention, and Act One ends.

@onready var bypass: Interactable = $Bypass
@onready var channel: ColorRect = $Channel


func _dialogue_file() -> String:
	return "res://data/dialogue/sc10.json"


func _start() -> void:
	_refresh_props()
	if GameState.get_flag("sc10_complete"):
		_end_of_chapter()
	elif not GameState.get_flag("sc10_arrived"):
		await _say("arrive")
		GameState.set_flag("sc10_arrived", true)
		_refresh_objective()
	elif GameState.get_flag("sc10_wheel_fitted"):
		await _conclude()


func _on_used(target: Interactable) -> void:
	match target.name:
		"Bypass":
			if GameState.get_flag("sc10_wheel_fitted"):
				await _say("bypass_after")
				return
			GameState.set_flag("sc10_wheel_fitted", true)
			await _say("wheel")
			_refresh_props()
			await _conclude()
		"Veya":
			await _say("veya")
		"Kesi":
			await _say("kesi")
		"Orun":
			await _say("orun")
		"Nali":
			await _say("nali")


func _conclude() -> void:
	await _say("news")
	GameState.set_flag("sc10_complete", true)
	_end_of_chapter()


func _end_of_chapter() -> void:
	_refresh_objective()
	_show_end_card("End of Chapter One",
			"THE WATER REACHED HOME BEFORE THE TRUTH DID.\n\nChapter Two is coming. Tell us what you thought.")


func _refresh_props() -> void:
	var flowing: bool = GameState.get_flag("sc10_wheel_fitted")
	bypass.label = "BYPASS (FLOWING)" if flowing else "REPAIRED BYPASS"
	channel.color = Color(0.3, 0.55, 0.75) if flowing else Color(0.4, 0.36, 0.32)


func _objective() -> String:
	if GameState.get_flag("sc10_complete"):
		return "Act One complete."
	if GameState.get_flag("sc10_arrived"):
		return "Fit the release wheel to the repaired bypass."
	return ""
