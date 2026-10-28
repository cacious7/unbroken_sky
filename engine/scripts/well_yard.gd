extends StoryScene
## SC02 "A good morning to argue": take the lever pin, repair the pump, draw clear water,
## then black silt, then the whisper. Mera intervenes and the exit to the cistern opens.

@onready var mera: Interactable = $Mera


func _dialogue_file() -> String:
	return "res://data/dialogue/sc02.json"


func _start() -> void:
	_build_pump_feedback()
	var sena := world_view.figure_for("Sena")
	if sena != null and not GameState.get_flag("sc02_pump_repaired"):
		sena.play("fix")
	if not GameState.get_flag("sc02_intro_seen"):
		player.position = $Pump.position + Vector2(-35, 45)
	if not GameState.get_flag("sc02_pump_repaired"):
		$Sena.position = $Pump.position + Vector2(32, -10)
	mera.set_active(GameState.get_flag("sc02_complete"))
	if GameState.get_flag("sc02_pump_count") >= 3 and not GameState.get_flag("sc02_complete"):
		# The app closed during the reveal; play it again rather than skip it.
		await _reveal()
	elif not GameState.get_flag("sc02_intro_seen"):
		GameState.set_flag("sc02_intro_seen", true)
		_refresh_objective()
		await _say("intro")
		GameState.set_flag("sc02_intro_seen", true)
		_refresh_objective()


func _on_used(target: Interactable) -> void:
	match target.name:
		"Basket":
			if GameState.get_flag("sc02_pin_collected"):
				hud.show_caption("Caddy empty.")
			else:
				GameState.set_flag("sc02_pin_collected", true)
				hud.show_caption("Lever pin collected.")
		"Pump":
			await _use_pump()
		"Well":
			await _say("inspect_well")
		"Bird":
			world_view._life.spin_bird()
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
				hud.show_caption("Work the pump first.")


func _use_pump() -> void:
	world_view._life.pulse_pump()
	Sfx.play("pump_squeak", 0.0, 0.9 + 0.1 * GameState.get_flag("sc02_pump_count"))
	if not GameState.get_flag("sc02_pump_repaired"):
		if GameState.get_flag("sc02_pin_collected"):
			await _fit_pin()
		else:
			hud.show_caption("Missing pin.")
		return
	var count: int = GameState.get_flag("sc02_pump_count")
	if count >= 3:
		_show_water()
		return
	count += 1
	GameState.set_flag("sc02_pump_count", count)
	match count:
		1:
			_show_water()
		2:
			_show_water()
		3:
			await _reveal()


func _reveal() -> void:
	await _say("whisper")
	mera.set_active(true)
	mera.position = player.position + Vector2(28, -8)
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
		return "Find the spare pin."
	return ""


## Object cues teach the first repair without pausing at every step.
var _guide: MeshInstance3D
var _pin: MeshInstance3D
var _water: MeshInstance3D
var _water_material: StandardMaterial3D
var _flow: PumpFlow
var _status_material: StandardMaterial3D


func _build_pump_feedback() -> void:
	_guide = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.5
	ring.outer_radius = 0.58
	_guide.mesh = ring
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("#efc878")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_guide.material_override = glow
	world_view.add_child(_guide)
	_pin = MeshInstance3D.new()
	var pin_shape := CylinderMesh.new()
	pin_shape.top_radius = 0.05
	pin_shape.bottom_radius = 0.05
	pin_shape.height = 0.45
	_pin.mesh = pin_shape
	_pin.material_override = glow
	_pin.rotation.z = PI / 2.0
	world_view.add_child(_pin)
	_water = MeshInstance3D.new()
	var pool := CylinderMesh.new()
	pool.top_radius = 0.65
	pool.bottom_radius = 0.65
	pool.height = 0.025
	_water.mesh = pool
	_water_material = StandardMaterial3D.new()
	_water_material.roughness = 0.2
	_water.material_override = _water_material
	_water.position = WorldView.to_3d($Pump.position + Vector2(0, 26), 0.035)
	world_view.add_child(_water)
	_flow = PumpFlow.new()
	world_view.get_node("Pump3D/WaterOutlet").add_child(_flow)
	_status_material = StandardMaterial3D.new()
	_status_material.emission_enabled = true
	_status_material.emission_energy_multiplier = 0.4
	world_view.get_node("Pump3D/ServiceStatus").material_override = _status_material
	_spray = CPUParticles3D.new()
	_spray.amount = 28
	_spray.lifetime = 0.65
	_spray.direction = Vector3(0, -0.65, 0.5)
	_spray.spread = 18.0
	_spray.initial_velocity_min = 0.3
	_spray.initial_velocity_max = 1.0
	_spray.gravity = Vector3(0, -6, 0)
	var drop := SphereMesh.new()
	drop.radius = 0.025
	drop.height = 0.05
	_spray.mesh = drop
	_spray.material_override = _water_material
	_spray.position = WorldView.to_3d($Pump.position, 0.835) + Vector3(0, 0, 0.575)
	world_view.add_child(_spray)
	_refresh_objective()


func _refresh_objective() -> void:
	super._refresh_objective()
	if _guide == null:
		return
	var collected: bool = GameState.get_flag("sc02_pin_collected")
	var repaired: bool = GameState.get_flag("sc02_pump_repaired")
	_guide.visible = not GameState.get_flag("sc02_complete")
	_guide.position = WorldView.to_3d($Pump.position if collected else $Basket.position, 0.06)
	_pin.visible = not collected or repaired
	_pin.position = WorldView.to_3d($Pump.position if repaired else $Basket.position, 0.85 if repaired else 0.46)
	_water.visible = GameState.get_flag("sc02_pump_count") > 0
	_water_material.albedo_color = Color("#161416") if GameState.get_flag("sc02_pump_count") >= 2 else Color("#72bccc")
	if _flow != null:
		_flow.set_condition(repaired, GameState.get_flag("sc02_pump_count") >= 2)
		var status := Color("#8cddd1") if repaired else Color("#e5a050")
		_status_material.albedo_color = status
		_status_material.emission = status
	if _spray != null:
		_spray.emitting = not repaired


func _show_water() -> void:
	_refresh_objective()
	_flow.pulse()
	_water.scale = Vector3(0.25, 1.0, 0.25)
	var ripple := create_tween()
	ripple.tween_property(_water, "scale", Vector3.ONE, 0.45)


var _spray: CPUParticles3D
var _repair: RepairTiming


func _fit_pin() -> void:
	if not dialogue.auto_finish:
		dialogue.cancel()
		hud.set_dialogue_active(true, true)
		_busy = true
		player.active = false
		player.cancel_walk()
		touch.set_shown(false)
		world_view.first_person.face_point(WorldView.to_3d($Pump.position, 0.95))
		world_view.first_person.set_repairing(true)
		world_view.tavo.play("fix")
		_repair = RepairTiming.new()
		add_child(_repair)
		_repair.tapped.connect(func(success: bool) -> void:
			world_view.first_person.gesture(true)
			world_view._life.pulse_pump()
			if not success:
				_spray.restart()
		)
		await _repair.completed
		_repair = null
		world_view.tavo.play("idle")
		world_view.end_shot()
		world_view.first_person.set_repairing(false)
		hud.set_dialogue_active(false)
		player.active = true
		touch.set_shown(touch_enabled)
		_busy = false
	GameState.set_flag("sc02_pump_repaired", true)
	var sena := world_view.figure_for("Sena")
	if sena != null:
		sena.play("idle")
	hud.show_caption("Pin fitted.")


func _on_dialogue_line(line: Dictionary) -> void:
	super._on_dialogue_line(line)
	if line.get("stage", "") == "wrist":
		world_view.tavo.play("interact")
	elif line.get("stage", "") == "burn":
		var figure := world_view.figure_for("Mera")
		if figure != null:
			figure.play("interact")
