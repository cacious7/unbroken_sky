extends StoryScene
## SC03 "The last clean water": choice C1 over twelve jars (reserve, share or joint
## repair). The joint path adds a shared pipe repair that sets water_compact.
## All paths reconverge on Mera reading Eren's seal; the exit leads home (SC04).

const JARS_LEFT := {"": 12, "reserve": 12, "share": 6, "joint": 10}

@onready var jars: Interactable = $Jars
@onready var pipe: Interactable = $Pipe
@onready var spring: Interactable = $Spring


func _dialogue_file() -> String:
	return "res://data/dialogue/sc03.json"


func _start() -> void:
	_refresh_props()
	if not GameState.get_flag("sc03_arrived"):
		await _say("arrive")
		GameState.set_flag("sc03_arrived", true)
		_refresh_objective()
	elif _ready_to_conclude() and not GameState.get_flag("sc03_complete"):
		# The app closed before the scene's closing conversation finished.
		await _conclude()


func _on_used(target: Interactable) -> void:
	var policy: String = GameState.get_flag("water_policy")
	match target.name:
		"Daru":
			if policy == "":
				await _say("choice")
				_refresh_props()
				if _ready_to_conclude():
					await _conclude()
			else:
				await _say("daru_after")
		"Nali":
			await _say("nali")
		"Jars":
			await _say("inspect_jars")
		"Mera":
			if GameState.get_flag("sc03_complete"):
				await _say("mera_after")
			else:
				await _say("mera_waiting")
		"Pipe":
			GameState.set_flag("sc03_pipe_taken", true)
			pipe.set_active(false)
			await _say("pipe_take")
		"Spring":
			if not GameState.get_flag("sc03_pipe_taken"):
				await _say("spring_needs_pipe")
				return
			GameState.set_flag("sc03_repair_done", true)
			GameState.set_flag("water_compact", true)
			await _say("spring_repair")
			_refresh_props()
			await _conclude()
		"Exit":
			if GameState.get_flag("sc03_complete"):
				_go_to("SC04")
			else:
				await _say("exit_locked")


func _ready_to_conclude() -> bool:
	var policy: String = GameState.get_flag("water_policy")
	return policy in ["reserve", "share"] or (policy == "joint" and GameState.get_flag("sc03_repair_done"))


func _conclude() -> void:
	await _say("conclude")
	GameState.set_flag("sc03_complete", true)
	_refresh_objective()


func _refresh_props() -> void:
	var policy: String = GameState.get_flag("water_policy")
	jars.label = "JARS ×%d" % JARS_LEFT[policy]
	var repairing: bool = policy == "joint" and not GameState.get_flag("sc03_repair_done")
	pipe.set_active(repairing and not GameState.get_flag("sc03_pipe_taken"))
	spring.set_active(policy == "joint")


func _objective() -> String:
	if GameState.get_flag("sc03_complete"):
		return "Get the release wheel from Reed Gate and find its keeper."
	if GameState.get_flag("water_policy") == "joint" and not GameState.get_flag("sc03_repair_done"):
		if GameState.get_flag("sc03_pipe_taken"):
			return "Fit the pipe at the old spring."
		return "Carry the pipe to the old spring."
	if GameState.get_flag("sc03_arrived"):
		return "Decide what happens to the water. Talk to Daru."
	return ""
