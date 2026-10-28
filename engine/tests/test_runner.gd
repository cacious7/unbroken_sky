extends Node
## Headless checks. Run from the engine folder:
##   godot --headless --path . res://tests/test_runner.tscn
## Exits with code 0 when everything passes.

const PROLOGUE := preload("res://scenes/prologue.tscn")
const WELL_YARD := preload("res://scenes/well_yard.tscn")
const CISTERN := preload("res://scenes/cistern.tscn")
const HOME := preload("res://scenes/home.tscn")
const ASH_ROAD := preload("res://scenes/ash_road.tscn")
const FLIGHT := preload("res://scenes/flight_3d.tscn")
const CULVERT := preload("res://scenes/culvert.tscn")
const REED_GATE := preload("res://scenes/reed_gate.tscn")
const KEEPER_ROOM := preload("res://scenes/keeper_room.tscn")
const WHEEL_PLATFORM := preload("res://scenes/wheel_platform.tscn")
## Each scene script with the dialogue file it plays.
const SCENE_DIALOGUE := {
	"res://scripts/prologue.gd": "res://data/dialogue/sc01.json",
	"res://scripts/well_yard.gd": "res://data/dialogue/sc02.json",
	"res://scripts/cistern.gd": "res://data/dialogue/sc03.json",
	"res://scripts/home.gd": "res://data/dialogue/sc04.json",
	"res://scripts/ash_road.gd": "res://data/dialogue/sc05.json",
	"res://scripts/culvert.gd": "res://data/dialogue/sc06.json",
	"res://scripts/reed_gate.gd": "res://data/dialogue/sc07.json",
	"res://scripts/keeper_room.gd": "res://data/dialogue/sc08.json",
	"res://scripts/flight/flight_scene.gd": "res://data/dialogue/sc09.json",
	"res://scripts/wheel_platform.gd": "res://data/dialogue/sc10.json",
}

var _failures := 0


func _ready() -> void:
	GameState.save_path = "user://test_save.json"
	GameState.scene_changes_enabled = false
	Settings.path = "user://test_settings.json"
	_test_dialogue_files()
	_test_art_catalog()
	_test_save_recovery()
	_test_settings()
	await _test_portraits()
	await _test_prologue()
	await _test_sc02_sequence()
	await _test_sc02_resume()
	await _test_dialogue_input()
	await _test_delivery_modes()
	await _test_tap_to_walk()
	await _test_pathfinding()
	await _test_combat_controls()
	_test_action_verbs()
	await _test_sc03_paths()
	await _test_sc03_resume()
	await _test_sc04()
	await _test_husk_rules()
	await _test_husk_fights_back()
	await _test_sc05_encounter()
	await _test_flight()
	await _test_sc06()
	await _test_sc07()
	await _test_sc08()
	await _test_stairs_and_fall()
	await _test_world_reactions_and_wind()
	await _test_first_person_controls()
	await _test_sc10()
	await _test_full_chapter()
	_test_test_rooms()
	GameState.delete_save()
	DirAccess.remove_absolute(Settings.path)
	print("TESTS %s (%d failures)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("ok   ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)


# --- Data ------------------------------------------------------------------

func _test_dialogue_files() -> void:
	var ids := {}
	for script_path: String in SCENE_DIALOGUE:
		var data_path: String = SCENE_DIALOGUE[script_path]
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(data_path))
		_check(typeof(data) == TYPE_DICTIONARY, "%s parses" % data_path)
		var conversations: Dictionary = data.conversations
		var problems: Array[String] = []
		for conversation_id: String in conversations:
			for line: Dictionary in conversations[conversation_id]:
				var line_id: String = line.get("id", "")
				if line_id == "" or ids.has(line_id) or (str(line.get("text", "")) == "" and not line.has("stage")):
					problems.append("bad id/text: %s" % line_id)
				ids[line_id] = true
				if line.has("sfx") and not Sfx.SOUNDS.has(line.sfx):
					problems.append("%s: unknown sound %s" % [line_id, line.sfx])
				for key: String in line.get("if", {}):
					if not GameState.DEFAULTS.has(key):
						problems.append("%s: unknown condition %s" % [line_id, key])
				for choice: Dictionary in line.get("choices", []):
					if str(choice.get("id", "")) == "" or str(choice.get("text", "")) == "":
						problems.append("%s: choice without id or text" % line_id)
					var effects: Dictionary = choice.get("effects", {})
					for key: String in effects:
						if not GameState.DEFAULTS.has(key) or GameState._sanitise(key, effects[key]) != effects[key]:
							problems.append("%s: illegal effect %s" % [line_id, key])
		_check(problems.is_empty(), "%s lines, conditions and choices are valid %s" % [data_path, problems])
		# Every conversation the scene asks for must exist in its data file.
		var source := FileAccess.get_file_as_string(script_path)
		var pattern := RegEx.create_from_string("_say\\(\"([a-z0-9_]+)\"\\)")
		var missing: Array[String] = []
		for found in pattern.search_all(source):
			if not conversations.has(found.get_string(1)):
				missing.append(found.get_string(1))
		_check(missing.is_empty(), "every conversation used by %s exists %s" % [script_path, missing])


func _test_art_catalog() -> void:
	var missing: Array[String] = []
	for object_name: String in ArtCatalog.entries():
		var path: String = ArtCatalog.ART_ROOT + str(ArtCatalog.entries()[object_name].texture)
		if not ResourceLoader.exists(path):
			missing.append(path)
	_check(not ArtCatalog.entries().is_empty() and missing.is_empty(),
			"art catalog loads and every sprite it names exists %s" % [missing])
	var unused: Array[String] = []
	var names := {}
	for scene_path: String in GameState.SCENES.values():
		var state := (load(scene_path) as PackedScene).get_state()
		for i in state.get_node_count():
			names[str(state.get_node_name(i))] = true
	for object_name: String in ArtCatalog.entries():
		if not names.has(object_name):
			unused.append(object_name)
	_check(unused.is_empty(), "every art catalog entry matches an object in some scene %s" % [unused])


func _write_save(text: String) -> void:
	FileAccess.open(GameState.save_path, FileAccess.WRITE).store_string(text)


func _test_save_recovery() -> void:
	_write_save("{not json")
	_check(not GameState.load_game() and GameState.get_flag("sc02_pump_count") == 0,
			"corrupt save starts a fresh game")
	_write_save('{"version": 99, "flags": {}}')
	_check(not GameState.load_game(), "unknown save version starts a fresh game")
	_write_save('{"version": 1, "flags": {"sc02_pump_count": "lots", "sc02_pin_collected": true}}')
	_check(GameState.load_game() and GameState.get_flag("sc02_pump_count") == 0
			and GameState.get_flag("sc02_pin_collected") == true,
			"wrong-typed values fall back to defaults")
	_write_save('{"version": 1, "flags": {"sc02_pump_count": 99}}')
	GameState.load_game()
	_check(GameState.get_flag("sc02_pump_count") == 3 and GameState.get_flag("sc02_pin_collected"),
			"out-of-range pump count is clamped and kept consistent")
	_write_save('{"version": 1, "flags": {"water_policy": "steal", "scene_id": "SC99"}}')
	GameState.load_game()
	_check(GameState.get_flag("water_policy") == "" and GameState.get_flag("scene_id") == "SC02",
			"illegal water policy or scene id resets safely")
	GameState.new_game()
	GameState.set_flag("sc02_pin_collected", true)
	GameState.reset()
	_check(GameState.load_game() and GameState.get_flag("sc02_pin_collected"),
			"saved flags survive a reload")


func _test_settings() -> void:
	Settings.text_size = 0
	Settings.cycle_text_size()
	_check(Settings.font_size(20) == 25, "large text scales fonts by 1.25")
	Settings.text_size = 0
	Settings.text_speed = 1
	Settings.cycle_text_speed()
	_check(Settings.chars_per_second() == 0.0, "instant text speed shows lines at once")
	Settings.text_speed = 0
	Settings.load_settings()
	_check(Settings.text_speed == 2, "settings reload from disk")
	Settings.text_size = 0
	Settings.text_speed = 0


# --- Scene helpers ----------------------------------------------------------

func _spawn(scene: PackedScene, choices: Array[String] = []) -> StoryScene:
	var instance: StoryScene = scene.instantiate()
	var dialogue: DialogueBox = instance.get_node("Dialogue")
	dialogue.auto_finish = true
	dialogue.test_choices = choices
	add_child(instance)
	await _settle()
	return instance


func _use(scene: StoryScene, node_name: String) -> void:
	scene.use(scene.get_node(node_name))
	await _settle()


func _settle() -> void:
	for i in 4:
		await get_tree().process_frame


func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _close(scene: Node) -> void:
	scene.queue_free()
	await _settle()


# --- Portraits and SC01 -------------------------------------------------------

func _test_portraits() -> void:
	var box := DialogueBox.new()
	add_child(box)
	await _settle()
	var mera := box.portrait_for("MERA")
	_check(mera != null and mera.get_width() >= 90.0, "portraits: Mera's portrait is cut from her sprite at high resolution")
	_check(box.portrait_for("WHISPER") == null and box.portrait_for("") == null,
			"portraits: voices without a sprite show no portrait")
	box.queue_free()
	await _settle()


func _spawn_prologue(instant := true) -> Node:
	var prologue := PROLOGUE.instantiate()
	prologue.instant = instant
	prologue.get_node("Dialogue").auto_finish = true
	add_child(prologue)
	await _settle()
	return prologue


func _test_prologue() -> void:
	GameState.new_game()
	_check(GameState.get_flag("scene_id") == "SC02", "a new game starts in the playable pump emergency")
	var prologue := await _spawn_prologue()
	_check(GameState.get_flag("scene_id") == "SC02", "SC01: the prologue plays through to SC02")
	await _close(prologue)

	GameState.new_game()
	var skipped := await _spawn_prologue(false)
	skipped._finish()
	skipped._finish()
	_check(GameState.get_flag("scene_id") == "SC02", "SC01: Skip goes straight to SC02 (once)")
	await _close(skipped)


# --- SC02 ---------------------------------------------------------------------

func _test_sc02_sequence() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	_check(GameState.get_flag("sc02_intro_seen"), "intro plays on a new game")
	_check(not yard.get_node("Mera").visible, "Mera is absent at the start")

	await _use(yard, "Pump")
	_check(not GameState.get_flag("sc02_pump_repaired"), "pump cannot be repaired without the pin")
	await _use(yard, "Exit")
	_check(GameState.get_flag("scene_id") != "SC03", "exit is locked before the reveal")

	await _use(yard, "Basket")
	await _use(yard, "Basket")
	_check(GameState.get_flag("sc02_pin_collected"), "pin collected from the basket")

	await _use(yard, "Pump")
	_check(GameState.get_flag("sc02_pump_repaired") and GameState.get_flag("sc02_pump_count") == 0,
			"fitting the pin repairs the pump without drawing water")
	await _use(yard, "Pump")
	await _use(yard, "Pump")
	_check(not GameState.get_flag("sc02_complete"), "two pulls are not enough for the reveal")
	await _use(yard, "Pump")
	_check(GameState.get_flag("sc02_complete") and yard.get_node("Mera").visible,
			"third pull triggers the whisper and Mera arrives")
	await _use(yard, "Pump")
	_check(GameState.get_flag("sc02_pump_count") == 3, "extra pulls never push the count past three")

	await _use(yard, "Exit")
	_check(GameState.get_flag("scene_id") == "SC03", "exit after the reveal moves on to SC03")
	await _close(yard)


func _test_sc02_resume() -> void:
	# Simulates the app closing between the third pull and the end of the reveal.
	GameState.new_game()
	for key: String in ["sc02_intro_seen", "sc02_pin_collected", "sc02_pump_repaired"]:
		GameState.set_flag(key, true)
	GameState.set_flag("sc02_pump_count", 3)
	GameState.load_game()
	var yard := await _spawn(WELL_YARD)
	_check(GameState.get_flag("sc02_complete") and yard.get_node("Mera").visible,
			"an interrupted reveal replays and completes on resume")
	await _close(yard)


func _test_tap_to_walk() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	var player: Player = yard.get_node("Player")

	var spot := player.global_position + Vector2(80, 0)
	player.walk_to(spot)
	await _physics_frames(90)
	_check(player.global_position.distance_to(spot) <= Player.ARRIVE_DISTANCE + 1.0
			and not player.is_walking(), "tapping the ground walks there and stops")

	player.walk_to(yard.get_node("Basket").global_position)
	await _physics_frames(180)
	await _settle()
	_check(GameState.get_flag("sc02_pin_collected"), "tapping an object walks to it and uses it")

	player.walk_to(player.global_position + Vector2(0, -120))
	player.touch_vector = Vector2.RIGHT
	await _physics_frames(2)
	player.touch_vector = Vector2.ZERO
	_check(not player.is_walking(), "stick or keyboard movement cancels a tap-walk")

	var mera: Interactable = yard.get_node("Mera")
	_check(not mera.hit_test(mera.global_position), "hidden characters cannot be tapped")
	await _close(yard)


# --- Controls -----------------------------------------------------------------

func _point_in_solid(scene: Node, point: Vector2) -> bool:
	for rect in NavGrid.solid_rects(scene):
		if rect.has_point(point):
			return true
	return false


func _test_pathfinding() -> void:
	# The flood room's zig-zag stair: one path from the bottom to the broken wall.
	_start_at("SC08")
	GameState.set_flag("sc08_talked", true)
	var room := await _spawn(KEEPER_ROOM)
	room.get_node("FloodWater").rising = false
	var path := NavGrid.find_path(room, room.ROUTE_START, Vector2(480, 60))
	var blocked := 0
	for point in path:
		if _point_in_solid(room, point):
			blocked += 1
	_check(path.size() > 10 and path[-1].y < 120.0 and blocked == 0,
			"pathfinding: tap-walk finds the zig-zag stair route without crossing walls")
	await _close(room)

	# Walking round the well to a spot directly behind it, which a straight line can't reach.
	GameState.new_game()
	GameState.set_flag("sc02_intro_seen", true)
	var yard := await _spawn(WELL_YARD)
	var player: Player = yard.player
	player.global_position = Vector2(430, 290)
	player.walk_to(Vector2(430, 172))
	await _physics_frames(150)
	_check(player.global_position.distance_to(Vector2(430, 172)) < 8.0,
			"pathfinding: Tavo walks around the well instead of stopping at it")
	await _close(yard)


func _test_combat_controls() -> void:
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	var road := await _spawn(ASH_ROAD)
	var husk: Husk = road.get_node("HuskOne")
	var player: Player = road.player
	road._fighting = true
	road.set_combat(true)
	husk.activate(player)
	husk._enter(Husk.State.RECOVERY)
	husk._left = 5.0
	player.global_position = husk.global_position + Vector2(-110, 0)
	var swings := []
	player.struck.connect(func(result: String) -> void: swings.append(result))
	player.walk_to(husk.global_position)
	await _physics_frames(60)
	_check(swings.has("hit"), "combat: tapping a husk walks up to it and strikes")
	_check(husk.global_position.x > husk._start_position.x, "combat: a hammer hit knocks the husk back")

	await _physics_frames(10)
	_check(is_equal_approx(Engine.time_scale, 1.0), "combat: hit-stop always returns to normal speed")
	road.shake(5.0)
	await _physics_frames(20)
	_check(road.get_viewport().canvas_transform.origin == Vector2.ZERO and road.position == Vector2.ZERO,
			"combat: screen shake moves only the view and settles back to rest")
	await _close(road)


func _test_action_verbs() -> void:
	var sena := Interactable.new()
	sena.prompt = "Talk to Sena"
	var pipe := Interactable.new()
	pipe.prompt = "Lift the pipe together"
	_check(StoryScene.action_verb(sena, false) == "TALK" and StoryScene.action_verb(pipe, true) == "LIFT"
			and StoryScene.action_verb(null, true) == "STRIKE" and StoryScene.action_verb(null, false) == "USE",
			"touch: the action button names the action (TALK, LIFT, STRIKE, USE)")
	sena.free()
	pipe.free()


# --- SC03 ---------------------------------------------------------------------

func _start_sc03() -> void:
	GameState.new_game()
	GameState.set_flag("scene_id", "SC03")


func _test_sc03_paths() -> void:
	for policy: String in ["reserve", "share"]:
		_start_sc03()
		var cistern := await _spawn(CISTERN, ["c1_" + policy])
		_check(GameState.get_flag("sc03_arrived"), "%s: arrival conversation plays" % policy)
		await _use(cistern, "Exit")
		_check(GameState.get_flag("water_policy") == "" and not cistern.hud.is_end_card_visible(),
				"%s: cannot leave before deciding" % policy)
		await _use(cistern, "Daru")
		_check(GameState.get_flag("water_policy") == policy and GameState.get_flag("sc03_complete")
				and not GameState.get_flag("water_compact"),
				"%s: choice recorded, scene concludes, no water compact" % policy)
		_check(cistern.get_node("Jars").label == ("JARS ×12" if policy == "reserve" else "JARS ×6"),
				"%s: jar count shown" % policy)
		await _use(cistern, "Daru")
		_check(GameState.get_flag("water_policy") == policy, "%s: choice cannot be made twice" % policy)
		await _use(cistern, "Exit")
		_check(GameState.get_flag("scene_id") == "SC04", "%s: exit leads home (SC04) after the seal reveal" % policy)
		await _close(cistern)

	_start_sc03()
	var joint := await _spawn(CISTERN, ["c1_joint"])
	_check(not joint.get_node("Pipe").visible, "joint: no pipe before the choice")
	await _use(joint, "Daru")
	_check(GameState.get_flag("water_policy") == "joint" and not GameState.get_flag("sc03_complete")
			and not GameState.get_flag("water_compact"),
			"joint: choice recorded but compact waits for the repair")
	_check(joint.get_node("Jars").label == "JARS ×10", "joint: two jars go to treatment first")
	await _use(joint, "Spring")
	_check(not GameState.get_flag("sc03_repair_done"), "joint: spring needs the pipe first")
	await _use(joint, "Pipe")
	await _use(joint, "Spring")
	_check(GameState.get_flag("water_compact") and GameState.get_flag("sc03_complete"),
			"joint: shared repair sets water_compact and concludes")
	await _close(joint)


func _start_at(scene_id: String) -> void:
	GameState.new_game()
	GameState.set_flag("scene_id", scene_id)


# --- SC04 ---------------------------------------------------------------------

func _test_sc04() -> void:
	_start_at("SC04")
	var home := await _spawn(HOME)
	_check(GameState.get_flag("sc04_arrived"), "SC04: packing conversation plays")
	await _use(home, "Door")
	_check(GameState.get_flag("scene_id") == "SC04", "SC04: cannot leave without the key")
	await _use(home, "Sena")
	_check(GameState.get_flag("has_key") and GameState.get_flag("has_bird")
			and GameState.get_flag("sc04_complete"), "SC04: Sena's key and bird, then Mera's admission")
	await _use(home, "Door")
	_check(GameState.get_flag("scene_id") == "SC05", "SC04: Daru at the gate, then on to SC05")
	await _close(home)


# --- Combat -------------------------------------------------------------------

func _test_husk_rules() -> void:
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	var road := await _spawn(ASH_ROAD)
	var husk: Husk = road.get_node("HuskOne")
	husk.activate(road.player)
	_check(husk.take_hammer() == "deflect", "husk: hammer glances off while it approaches")
	husk._enter(Husk.State.WINDUP)
	_check(husk.take_hammer() == "interrupt" and husk.is_connector_exposed(),
			"husk: hit during windup interrupts and exposes the connector")
	_check(husk.take_hammer() == "hit" and husk.health == 2, "husk: exposed connector takes damage")
	husk._enter(Husk.State.RECOVERY)
	husk.take_hammer()
	_check(husk.take_hammer() == "break" and not husk.is_threat(), "husk: third connector hit breaks it")

	var player: Player = road.player
	player.restore_health()
	_check(player.take_hit(Vector2.ZERO) and player.health == 2, "player: a strike costs one health")
	_check(not player.take_hit(Vector2.ZERO), "player: no second hit during the grace period")
	await _physics_frames(70)
	player.combat_enabled = true
	player.dodge()
	_check(player.is_protected() and not player.take_hit(Vector2.ZERO), "player: dodging avoids a strike")
	await _close(road)


func _test_husk_fights_back() -> void:
	# Real time: an idle Tavo next to an active husk gets hit by its full attack cycle.
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	var road := await _spawn(ASH_ROAD)
	var husk: Husk = road.get_node("HuskOne")
	road.player.global_position = husk.global_position + Vector2(-50, 0)
	road.set_combat(true)
	husk.activate(road.player)
	await _physics_frames(90)
	_check(road.player.health < Player.MAX_HEALTH, "husk: windup then strike lands on a player who stands still")
	await _close(road)

	# A practice strike shows the full tell, falls short, and only the next one is real.
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	road = await _spawn(ASH_ROAD)
	husk = road.get_node("HuskOne")
	road.player.global_position = husk.global_position + Vector2(-50, 0)
	road.set_combat(true)
	var feints := []
	husk.feinted.connect(func(_h: Husk) -> void: feints.append(true))
	husk.practice_strikes = 1
	husk.activate(road.player)
	await _physics_frames(90)
	_check(road.player.health == Player.MAX_HEALTH and feints.size() == 1
			and road.hud.caption_text().contains("falls short"),
			"husk: the practice lunge plays its tell but cannot hurt")
	await _physics_frames(200)
	_check(road.player.health < Player.MAX_HEALTH and feints.size() == 1,
			"husk: the strike after the practice is real")
	await _close(road)

	# An interrupted practice windup does not report a feint.
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	road = await _spawn(ASH_ROAD)
	husk = road.get_node("HuskOne")
	feints = []
	husk.feinted.connect(func(_h: Husk) -> void: feints.append(true))
	husk.practice_strikes = 1
	husk.activate(road.player)
	husk._enter(Husk.State.WINDUP)
	_check(husk.take_hammer() == "interrupt" and feints.is_empty() and husk.practice_strikes == 0,
			"husk: interrupting the practice windup spends it without a false feint")
	await _close(road)

	# Flanking: far away the approach curves to one side; close in it heads straight.
	_start_at("SC05")
	GameState.set_flag("sc05_arrived", true)
	road = await _spawn(ASH_ROAD)
	husk = road.get_node("HuskTwo")
	road.player.global_position = husk.global_position + Vector2(-300, 0)
	husk.activate(road.player)
	await _physics_frames(2)
	var toward: Vector2 = road.player.global_position - husk.global_position
	_check(absf(husk.velocity.angle_to(toward)) > 0.5, "husk: a distant husk curves in from the side")
	husk.global_position = road.player.global_position + Vector2(Husk.ATTACK_DISTANCE + 4, 0)
	await _physics_frames(1)
	toward = road.player.global_position - husk.global_position
	_check(husk.state != Husk.State.APPROACH or absf(husk.velocity.angle_to(toward)) < 0.1,
			"husk: the flank straightens out at striking distance")
	await _close(road)


func _test_sc05_encounter() -> void:
	_start_at("SC05")
	var road := await _spawn(ASH_ROAD)
	var one: Husk = road.get_node("HuskOne")
	var two: Husk = road.get_node("HuskTwo")
	_check(GameState.get_flag("sc05_arrived") and not two.visible, "SC05: arrival; second husk not yet on the road")
	await _use(road, "Exit")
	_check(not road.hud.is_end_card_visible(), "SC05: cannot leave while husks are on the road")

	road.player.global_position = Vector2(320, 290)
	await _physics_frames(3)
	await _settle()
	_check(one.is_threat() and road.player.combat_enabled, "SC05: walking up the road wakes the first husk")
	_check(one.practice_strikes == 1, "SC05: the ambush opens with a safe practice lunge")

	one._enter(Husk.State.RECOVERY)
	for i in 3:
		one.take_hammer()
	await _settle()
	_check(GameState.get_flag("sc05_husk_one_down") and two.visible and two.is_threat(),
			"SC05: second husk enters only after the first breaks")
	var from_player: Vector2 = two.global_position - road.player.global_position
	_check(from_player.normalized().dot(road.player.aim_direction) < 0.0 and road.ROAD_BOUNDS.has_point(two.global_position),
			"SC05: the second husk enters behind Tavo, inside the road")
	var rig: Node3D = road.world_view.first_person
	_check(rig.offscreen_threats().has(two), "SC05: an unseen husk marks the reticle ring on its side")
	rig.yaw = atan2(-from_player.x, -from_player.y)
	rig._process(0.0)
	_check(not rig.offscreen_threats().has(two), "SC05: the ring cue clears once Tavo turns to face it")

	# Defeat: back to the entrance, full health, husk reset, nothing else lost.
	two._enter(Husk.State.RECOVERY)
	two.take_hammer()
	road.player.health = 1
	road.player.take_hit(Vector2.ZERO)
	await _settle()
	_check(road.player.health == Player.MAX_HEALTH and road.player.global_position == road.ENTRANCE
			and two.health == two.max_health and GameState.get_flag("sc05_husk_one_down"),
			"SC05: defeat restarts the encounter with full health and no other penalty")

	two._enter(Husk.State.RECOVERY)
	for i in 3:
		two.take_hammer()
	await _settle()
	_check(GameState.get_flag("sc05_fight_done") and GameState.get_flag("sc05_merchant_done")
			and not road.player.combat_enabled, "SC05: both husks broken, merchant scene, combat off")
	await _use(road, "Nali")
	await _use(road, "Exit")
	_check(GameState.get_flag("sc05_complete") and GameState.get_flag("scene_id") == "SC06",
			"SC05: Nali joins and the road continues to SC06")
	await _close(road)


# --- Flight -------------------------------------------------------------------

func _spawn_flight() -> Node3D:
	var flight: Node3D = FLIGHT.instantiate()
	flight.get_node("Dialogue").auto_finish = true
	add_child(flight)
	await _settle()
	return flight


func _land_on(flight: Node3D, index: int) -> void:
	flight.eagle.position = flight.perch_position(index) + flight.PERCH_LIFT
	await _physics_frames(2)
	await _settle()


func _test_flight() -> void:
	_start_at("SC09")
	var flight := await _spawn_flight()
	var eagle: Eagle3D = flight.eagle
	_check(GameState.get_flag("sc09_started") and not flight.tavo.visible and not flight.is_flying()
			and eagle.position.distance_to(flight.perch_position(0)) < 1.0,
			"SC09 (3D): Tavo falls and perches as an eagle on the broken wall")

	await flight.takeoff()
	await _physics_frames(330)
	_check(flight.link() == 1 and not flight.is_flying(),
			"SC09 (3D): the first link is safe with no steering at all")

	await flight.takeoff()
	_check(GameState.get_flag("sc09_voice_heard") and flight.is_flying(),
			"SC09 (3D): the voice speaks before the gust link")
	flight.stamina = 0.0
	await _physics_frames(2)
	_check(flight.link() == 1 and not flight.is_flying()
			and eagle.position.distance_to(flight.perch_position(1)) < 1.0,
			"SC09 (3D): tired wings return the eagle to the last perch")

	await flight.takeoff()
	eagle.position = Vector3(0, 3, -100)
	eagle.position.y = 0.2
	await _physics_frames(2)
	_check(not flight.is_flying() and flight.link() == 1, "SC09 (3D): touching the water returns to the perch")

	await flight.takeoff()
	eagle.position = Vector3(500, 20, 0)
	await _physics_frames(2)
	_check(not flight.is_flying(), "SC09 (3D): leaving the fortress returns to the perch")

	var gust: Dictionary = flight.ZONES[0]
	var lift: Dictionary = flight.ZONES[1]
	var gust_wind: Array = flight.wind_at(gust.center)
	var lift_wind: Array = flight.wind_at(lift.center)
	_check(gust_wind[0].x > 5.0 and gust_wind[0].y < 0.0 and not gust_wind[2],
			"SC09 (3D): the gust shoves the eagle sideways and down")
	_check(lift_wind[1] > 0.0 and lift_wind[2] and lift.center.x < gust.center.x,
			"SC09 (3D): the updraft lifts, and it is to the left of the gust")
	var straight_line_midpoint: Vector3 = (flight.perch_position(1) + flight.perch_position(2)) / 2.0
	_check(flight.wind_at(straight_line_midpoint)[0] != Vector3.ZERO,
			"SC09 (3D): the gust sits on the straight line between the perches")

	Settings.flight_assist = true
	var assisted: float = flight.landing_radius()
	var assisted_gust: Vector3 = flight.wind_at(gust.center)[0]
	Settings.flight_assist = false
	_check(assisted > flight.landing_radius() and assisted_gust.length() < gust_wind[0].length(),
			"SC09 (3D): flight assist widens landings and weakens the gust")

	await flight.takeoff()
	await _land_on(flight, 2)
	await flight.takeoff()
	await _land_on(flight, 3)
	_check(GameState.get_flag("sc09_complete") and GameState.get_flag("eagle_unlocked")
			and flight.tavo.visible and not eagle.visible and GameState.get_flag("scene_id") == "SC10",
			"SC09 (3D): landing on the wheel platform turns Tavo human, unlocks the eagle, on to SC10")
	await _close(flight)


# --- SC06 to SC10 -------------------------------------------------------------

func _break_rope(culvert: StoryScene) -> void:
	var rope: WaterRope = culvert.get_node("WaterRope")
	rope._enter(WaterRope.State.EXPOSED)
	rope.take_hammer()
	await _settle()


func _test_sc06() -> void:
	_start_at("SC06")
	var culvert := await _spawn(CULVERT)
	var rope: WaterRope = culvert.get_node("WaterRope")
	await _use(culvert, "Figure")
	_check(not GameState.get_flag("sc06_asked") and not rope.is_threat(),
			"SC06: approaching the figure reveals danger without starting a fight")
	await _use(culvert, "Reflection")
	await _use(culvert, "Figure")
	_check(GameState.get_flag("sc06_asked") and rope.is_threat() and not culvert.get_node("Figure").visible,
			"SC06: after the reflection, the question collapses her into the water rope")
	_check(rope.take_hammer() == "deflect", "SC06: the hook cannot be broken while it is marking a sweep")

	# Standing inside the ring through a whole sweep costs health; outside it does not.
	culvert.player.global_position = rope.global_position + Vector2(-60, 0)
	rope._enter(WaterRope.State.SWEEP)
	await _physics_frames(3)
	_check(culvert.player.health == Player.MAX_HEALTH - 1, "SC06: the sweep hits inside the marked ring")
	culvert.player.restore_health()
	culvert.player.global_position = rope.global_position + Vector2(-200, 0)
	rope._enter(WaterRope.State.SWEEP)
	await _physics_frames(3)
	_check(culvert.player.health == Player.MAX_HEALTH, "SC06: getting clear of the ring avoids the sweep")

	await _break_rope(culvert)
	_check(GameState.get_flag("sc06_complete") and culvert.get_node("Hook").visible
			and not culvert.player.combat_enabled, "SC06: the hook breaks, Nali explains, the hook can be inspected")
	await _use(culvert, "Exit")
	_check(GameState.get_flag("scene_id") == "SC07", "SC06: on to Reed Gate")
	await _close(culvert)


func _test_sc07() -> void:
	_start_at("SC07")
	var gate := await _spawn(REED_GATE)
	await _use(gate, "SluiceLock")
	await _use(gate, "Brace")
	_check(not GameState.get_flag("sc07_braced") and GameState.get_flag("scene_id") == "SC07",
			"SC07: brace and key refuse until the channel is drained")
	await _use(gate, "SideChannel")
	await _use(gate, "SluiceLock")
	_check(not GameState.get_flag("sc07_complete"), "SC07: key refuses until the gate is braced")
	await _use(gate, "Brace")
	await _use(gate, "SluiceLock")
	_check(GameState.get_flag("sc07_complete") and GameState.get_flag("scene_id") == "SC08",
			"SC07: drain, brace, key reveals the sleeping man and leads to SC08")
	await _close(gate)


func _test_sc08() -> void:
	_start_at("SC08")
	var room := await _spawn(KEEPER_ROOM)
	var flood: FloodWater = room.get_node("FloodWater")
	_check(GameState.get_flag("sc08_talked") and flood.rising, "SC08: Eren's conversation, then the water rises")
	flood.level = room.player.global_position.y - 5.0
	await _physics_frames(2)
	_check(room.player.global_position == room.ROUTE_START and flood.level >= flood.start_level - 5.0
			and GameState.get_flag("scene_id") == "SC08", "SC08: caught by the water, only the climb restarts")
	room.player.global_position = Vector2(480, 80)
	await _physics_frames(2)
	await _settle()
	_check(GameState.get_flag("sc08_complete") and GameState.get_flag("scene_id") == "SC09",
			"SC08: reaching the broken wall leads to the fall in SC09")
	await _close(room)

	# Resuming SC08 does not replay the keeper conversation.
	_start_at("SC08")
	GameState.set_flag("sc08_talked", true)
	var resumed := await _spawn(KEEPER_ROOM)
	_check(resumed.get_node("FloodWater").rising, "SC08: resume goes straight back to the climb")
	await _close(resumed)


func _test_sc10() -> void:
	_start_at("SC10")
	var platform := await _spawn(WHEEL_PLATFORM)
	_check(GameState.get_flag("sc10_arrived") and not platform.hud.is_end_card_visible(),
			"SC10: Veya, Kesi and Orun's arrival")
	await _use(platform, "Bypass")
	_check(GameState.get_flag("sc10_wheel_fitted") and GameState.get_flag("sc10_complete")
			and platform.hud.is_end_card_visible(), "SC10: the wheel turns, the news arrives, Act One ends")
	await _close(platform)


## One continuous save from the well to the end of Act One, using each scene's
## real hand-over (scene_id) rather than setting up flags by hand.
func _test_full_chapter() -> void:
	GameState.new_game()
	var visited: Array[String] = []
	var guard := 0
	while not GameState.get_flag("sc10_complete") and guard < 12:
		guard += 1
		var scene_id: String = GameState.get_flag("scene_id")
		visited.append(scene_id)
		if scene_id == "SC01":
			await _close(await _spawn_prologue())
			continue
		if scene_id == "SC09":
			var flight := await _spawn_flight()
			for perch in [1, 2, 3]:
				await flight.takeoff()
				await _land_on(flight, perch)
			await _close(flight)
			continue
		var scene := await _spawn(load(GameState.SCENES[scene_id]), ["c1_joint"])
		match scene_id:
			"SC02":
				for target: String in ["Basket", "Pump", "Pump", "Pump", "Pump", "Exit"]:
					await _use(scene, target)
			"SC03":
				for target: String in ["Daru", "Pipe", "Spring", "Exit"]:
					await _use(scene, target)
			"SC04":
				for target: String in ["Sena", "Door"]:
					await _use(scene, target)
			"SC05":
				scene.player.global_position = Vector2(320, 290)
				await _physics_frames(3)
				await _settle()
				for husk_name: String in ["HuskOne", "HuskTwo"]:
					var husk: Husk = scene.get_node(husk_name)
					husk._enter(Husk.State.RECOVERY)
					for i in 3:
						husk.take_hammer()
					await _settle()
				for target: String in ["Nali", "Exit"]:
					await _use(scene, target)
			"SC06":
				for target: String in ["Reflection", "Figure"]:
					await _use(scene, target)
				await _break_rope(scene)
				await _use(scene, "Exit")
			"SC07":
				for target: String in ["SideChannel", "Brace", "SluiceLock"]:
					await _use(scene, target)
			"SC08":
				scene.player.global_position = Vector2(480, 80)
				await _physics_frames(2)
				await _settle()
			"SC10":
				await _use(scene, "Bypass")
		await _close(scene)
	_check(visited == ["SC02", "SC03", "SC04", "SC05", "SC06", "SC07", "SC08", "SC09", "SC10"],
			"full chapter: every scene hands over to the next in order %s" % [visited])
	_check(GameState.get_flag("sc10_complete") and GameState.get_flag("water_policy") == "joint"
			and GameState.get_flag("water_compact") and GameState.get_flag("eagle_unlocked")
			and GameState.get_flag("has_key"),
			"full chapter: Act One completes with choice, compact, key and eagle remembered")


func _test_test_rooms() -> void:
	var story_path := GameState.save_path
	GameState.start_test_room("SC09")
	_check(GameState.save_path == GameState.TEST_ROOM_SAVE_PATH and GameState.get_flag("scene_id") == "SC09"
			and not GameState.get_flag("sc09_started"), "test rooms start fresh in their own save")
	GameState.delete_save()
	GameState.save_path = story_path


func _test_sc03_resume() -> void:
	# Choice made, app closed before the closing conversation.
	_start_sc03()
	GameState.set_flag("sc03_arrived", true)
	GameState.set_flag("water_policy", "share")
	GameState.load_game()
	var cistern := await _spawn(CISTERN)
	_check(GameState.get_flag("sc03_complete"), "interrupted SC03 conclusion replays on resume")
	await _close(cistern)

	# Joint chosen, pipe carried, app closed: the pipe stays carried.
	_start_sc03()
	for key: String in ["sc03_arrived", "sc03_pipe_taken"]:
		GameState.set_flag(key, true)
	GameState.set_flag("water_policy", "joint")
	GameState.load_game()
	cistern = await _spawn(CISTERN)
	_check(not cistern.get_node("Pipe").visible and cistern.get_node("Spring").visible
			and not GameState.get_flag("sc03_complete"), "joint repair resumes with the pipe in hand")
	await _close(cistern)


# Native input, including the final gesture that hands controls back to gameplay.
func _test_dialogue_input() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	yard.touch.device_has_touch = true
	yard.touch.set_shown(true)
	yard.dialogue.auto_finish = false
	yard.player.walk_to(Vector2(350, 320))
	yard._say("inspect_bird")
	_check(not yard.player.is_walking() and not yard.player.active,
			"dialogue: opening immediately cancels an existing walk")
	var before := yard.player.position
	var finger := InputEventScreenTouch.new()
	finger.index = 2
	finger.position = Vector2(400, 200)
	finger.pressed = true
	get_viewport().push_input(finger, true)
	_check(yard.dialogue.is_open() and yard.dialogue._text.visible_characters == -1,
			"dialogue: native touch reveals text without skipping it")
	finger = finger.duplicate()
	finger.pressed = false
	get_viewport().push_input(finger, true)
	finger = finger.duplicate()
	finger.pressed = true
	get_viewport().push_input(finger, true)
	_check(not yard.dialogue.is_open() and yard.player.active,
			"dialogue: next touch closes the final line")
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(450, 200)
	get_viewport().push_input(drag, true)
	finger = finger.duplicate()
	finger.pressed = false
	get_viewport().push_input(finger, true)
	await _physics_frames(3)
	_check(not yard.player.is_walking() and yard.player.position.is_equal_approx(before),
			"dialogue: final touch, drag and release never move the player")
	yard._say("inspect_well")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(400, 200)
	click.pressed = true
	get_viewport().push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	get_viewport().push_input(click, true)
	click = click.duplicate()
	click.pressed = true
	get_viewport().push_input(click, true)
	await _physics_frames(2)
	_check(not yard.dialogue.is_open() and not yard.player.is_walking(),
			"dialogue: mouse clicks advance without starting a walk")
	await _use(yard, "Basket")
	_check(not yard.dialogue.is_open() and yard._pin.visible == false,
			"SC02: collecting the visible pin needs no dialogue dismissal")
	await _use(yard, "Pump")
	_check(yard._repair != null and not GameState.get_flag("sc02_pump_repaired"),
			"SC02: repairing starts a hands-on challenge, not a text box")
	var repair_results: Array[bool] = []
	yard._repair.tapped.connect(func(success: bool) -> void: repair_results.append(success))
	yard._repair.phase = 0.0
	yard._repair.strike()
	_check(yard._repair.hits == 0 and yard._repair.window_half_width() > 0.12,
			"SC02: a missed repair tap widens the window without losing progress")
	yard._repair.phase = 0.32
	yard._repair.strike()
	yard._repair.phase = 0.32
	var repair_finger := InputEventScreenTouch.new()
	repair_finger.index = 5
	repair_finger.position = Vector2(480, 440)
	repair_finger.pressed = true
	get_viewport().push_input(repair_finger, true)
	_check(not yard.player.active,
			"SC02: completing a repair keeps input until the final finger is released")
	repair_finger = repair_finger.duplicate()
	repair_finger.pressed = false
	get_viewport().push_input(repair_finger, true)
	await _settle()
	_check(repair_results == [false, true, true], "SC02: each repair tap reports its actual result once")
	_check(not yard._flow.stream.visible and yard._status_material.albedo_color == Color("#8cddd1"),
			"SC02: seating the pin stops the leak and restores the service indicator")
	_check(yard._pin.visible and not yard.dialogue.is_open(),
			"SC02: fitted pin is visible without a modal explanation")
	await _use(yard, "Pump")
	_check(yard._flow.stream.visible, "SC02: working the repaired pump produces a stream at the spout")
	_check(yard._water.visible and yard._water_material.albedo_color == Color("#72bccc"),
			"SC02: first pull shows clear water")
	await _use(yard, "Pump")
	_check(yard._water_material.albedo_color == Color("#161416") and not yard.dialogue.is_open(),
			"SC02: second pull visibly turns water black without dialogue")
	await _close(yard)


func _test_delivery_modes() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	yard.dialogue.auto_finish = false
	yard._say("intro")
	_check(yard.player.active and not yard._busy,
			"ambient: speech leaves movement and interactions available")
	yard.use(yard.get_node("Basket"))
	await _settle()
	_check(GameState.get_flag("sc02_pin_collected") and yard.player.active,
			"ambient: a useful action works while someone is talking")
	yard._say("mera")
	_check(not yard.player.active and not yard.world_view._shot.is_empty(),
			"cinematic: a silent wrist shot owns the camera and controls")
	var pause_click := InputEventMouseButton.new()
	pause_click.button_index = MOUSE_BUTTON_LEFT
	pause_click.position = Vector2(916, 36)
	pause_click.pressed = true
	get_viewport().push_input(pause_click, true)
	pause_click = pause_click.duplicate()
	pause_click.pressed = false
	get_viewport().push_input(pause_click, true)
	_check(yard.pause_menu.is_open(), "cinematic: pause remains clickable above the input blocker")
	yard.pause_menu.close()
	yard.dialogue.skip_scene()
	_check(yard.player.active and yard.world_view._shot.is_empty(),
			"cinematic: skip immediately restores the gameplay camera and controls")
	yard.dialogue._conversations["missing_voice"] = [{"id": "missing_voice_probe", "delivery": "ambient", "speaker": "SENA", "text": "Ready?", "duration": 0.01, "voice": "res://assets/voices/not_recorded.ogg"}]
	yard._say("missing_voice")
	yard.dialogue._process(0.02)
	_check(not yard.dialogue.is_open() and yard.player.active,
			"voice: missing recordings use timed subtitles and never stall the game")
	yard.dialogue.load_file("res://data/dialogue/sc03.json")
	yard._say("choice")
	_check(yard.dialogue._choosing and not yard.dialogue._skip.visible,
			"choices: consequential decisions never auto-select or offer scene skip")
	yard.dialogue._process(60.0)
	_check(yard.dialogue._choosing and GameState.get_flag("water_policy") == "",
			"choices: waiting does not choose a water policy")
	yard.dialogue.cancel()
	await _close(yard)


func _test_stairs_and_fall() -> void:
	_start_at("SC08")
	var room := await _spawn(KEEPER_ROOM)
	var heights: Array[float] = []
	for point: Vector2 in [Vector2(842, 450), Vector2(118, 330), Vector2(842, 210)]:
		room.player.position = point
		await _settle()
		room.world_view._update_camera(0.0, true)
		var height := room.world_view.tavo.position.y
		heights.append(height)
		var screen := room.world_view.camera.unproject_position(WorldView.to_3d(point, height))
		var tapped: Variant = room.world_view.screen_to_world_2d(screen)
		_check(tapped != null and (tapped as Vector2).distance_to(point) < 0.1,
				"stairs: tapping an elevated tread maps back to that tread")
	_check(is_equal_approx(WorldView.keeper_height(Vector2(752, 450)), 0.75)
			and is_equal_approx(WorldView.keeper_height(Vector2(208, 330)), 2.25),
			"stairs: the narrow navigation routes stay on visible treads")
	_check(heights == [0.75, 2.25, 3.75], "stairs: the player visibly climbs all three flights")
	var flight_root: Node3D = room.world_view.get_node("StairThree3D")
	var tread: MeshInstance3D = flight_root.get_node("Tread10")
	_check(is_equal_approx(flight_root.position.y + tread.position.y + tread.mesh.get_aabb().end.y, 4.5),
			"stairs: the final physical tread meets the upper landing")
	await _close(room)
	_start_at("SC09")
	var flight: Node3D = FLIGHT.instantiate()
	add_child(flight)
	await _settle()
	var initial: float = flight.tavo.position.y
	_check(flight._transforming and initial > flight.perch_position(0).y + 7.0,
			"fall: the human begins visibly above the landing")
	await _physics_frames(20)
	_check(flight.tavo.position.y < initial - 0.1 and flight.tavo.scale == Vector3.ONE,
			"fall: the body accelerates downwards at full size")
	flight.dialogue.skip_scene()
	await _settle()
	_check(not flight._transforming and flight.eagle.grounded and flight.tavo.scale == Vector3.ONE,
			"fall: skip resolves the transformation and restores a usable perch")
	await _close(flight)


func _test_world_reactions_and_wind() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	var life: Node3D = yard.world_view._life
	var terrain: MeshInstance3D = life.get_node("SurroundingHills")
	var normals: PackedVector3Array = terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	_check(normals[(15 * 32 + 15) * 6].y > 0.9,
			"village: terrain faces upward and cannot reveal the sky through its backfaces")
	_check(life.animals.size() == 3, "village: three chickens have live reactions")
	var animal: Dictionary = life.animals[0]
	var chicken := animal.node as Node3D
	var home := chicken.position
	yard.player.position = Vector2(home.x - 0.5, home.z) / 0.025
	await _settle()
	_check(chicken.position.distance_to(home) > 0.01 and animal.panic > 0.0,
			"village: approaching a chicken makes it run away without opening dialogue")
	yard.use(yard.get_node("Bird"))
	await _settle()
	_check(not yard.dialogue.is_open() and yard.player.active,
			"village: playing with the copper bird keeps gameplay active")
	await _close(yard)
	_start_at("SC09")
	var flight := await _spawn_flight()
	await flight.takeoff()
	flight.stamina = 3.0
	var gate: Dictionary = flight.course.gates[0]
	var center: Vector3 = gate.position
	var normal: Vector3 = gate.normal
	_check(flight.course.sweep_collect(center - normal * 4.0, center + normal * 4.0) == 1,
			"wind: a swept pass catches a gate even across a long frame")
	_check(flight.stamina > 5.0 and flight._boost_left > 0.0,
			"wind: a clean pass restores wings and grants a short boost")
	_check(flight.course.sweep_collect(center - normal * 4.0, center + normal * 4.0) == 0,
			"wind: one gate cannot be farmed repeatedly in the same attempt")
	var second: Dictionary = flight.course.gates[1]
	var target: Vector3 = second.position
	var heading: Vector3 = second.normal
	_check(flight.course.sweep_collect(target + heading * 4.0, target - heading * 4.0) == 0,
			"wind: flying backwards does not count as a gate pass")
	var bounds: AABB = flight._obstacles[0].bounds
	var middle := bounds.get_center()
	_check(flight.hits_ruin(middle - Vector3(bounds.size.x + 1.0, 0, 0), middle + Vector3(bounds.size.x + 1.0, 0, 0)),
			"flight: swept movement collides with solid ruins")
	var arcade: Node3D = flight.get_children().filter(func(n: Node) -> bool: return n.has_meta("collision_shapes"))[0]
	_check(not flight.hits_ruin(arcade.transform * Vector3(0, 6.6, -1.4), arcade.transform * Vector3(0, 6.6, 1.4)),
			"flight: the open middle of an arch stays flyable")
	flight._fall()
	_check(flight.course.current_count() == 0 and not flight.is_flying() and flight._boost_left == 0.0,
			"wind: retry rearms the current leg and clears stale boost")
	await _close(flight)


func _test_first_person_controls() -> void:
	GameState.new_game()
	var yard := await _spawn(WELL_YARD)
	var rig: Node3D = yard.world_view.first_person
	var camera := yard.world_view.camera
	_check(yard.player.first_person_controls and Vector2(camera.position.x, camera.position.z).distance_to(yard.player.position * 0.025) < 0.01
			and absf(camera.position.y - 1.68) < 0.02,
			"first person: the camera is at the player's eyes, not above or behind")
	_check(rig._body_geometry[0].cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,
			"first person: the body casts a shadow without drawing inside the camera")
	yard.touch.device_has_touch = true
	yard.touch.set_shown(true)
	var before := yard.player.position
	var press := InputEventScreenTouch.new()
	press.index = 30
	press.position = Vector2(700, 250)
	press.pressed = true
	get_viewport().push_input(press, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 30
	drag.position = Vector2(740, 250)
	drag.relative = Vector2(40, 0)
	get_viewport().push_input(drag, true)
	press = press.duplicate()
	press.pressed = false
	get_viewport().push_input(press, true)
	await _physics_frames(2)
	_check(rig.yaw < -0.1 and yard.player.position.is_equal_approx(before) and not yard.player.is_walking(),
			"first person: right-thumb look turns the view without moving or tap-walking")
	rig.yaw = -PI / 2.0
	rig._process(0.0)
	yard.player.touch_vector = Vector2.UP
	_check(yard.player._input_vector().x > 0.99,
			"first person: forward movement follows the direction of view")
	yard.player.touch_vector = Vector2.ZERO
	yard.player.position = Vector2(470, 230)
	await _physics_frames(3)
	yard.player._update_focus()
	_check(yard.player.focus_target() != null and yard.player.focus_target().name == "Pump",
			"first person: looking right selects the pump in front")
	rig.yaw = PI / 2.0
	rig._process(0.0)
	yard.player._update_focus()
	_check(yard.player.focus_target() != null and yard.player.focus_target().name == "Well",
			"first person: an object behind the player cannot steal the interaction")
	var source := yard.player.position + Vector2(50, 0)
	_check(yard.player.take_hit(source) and rig._damage_source == source and rig._damage_left > 0,
			"first person: an accepted hit records the attack direction")
	rig._process(0.25)
	var damage_left: float = rig._damage_left
	_check(not yard.player.take_hit(source + Vector2(10, 10)) and rig._damage_left == damage_left,
			"first person: grace-period hits do not replace the damage direction")
	rig._on_struck("miss")
	_check(rig._hit_left == 0, "first person: a missed swing has no hit confirmation")
	rig._on_struck("break")
	_check(rig._hit_left > 0 and rig._hit_color == Color("#edc57d"),
			"first person: breaking a connector confirms a successful strike")
	rig._process(1.1)
	_check(rig._damage_left == 0 and rig._hit_left == 0, "first person: combat cues expire without lingering")
	yard.dialogue.auto_finish = false
	yard._say("inspect_well")
	var held_yaw: float = rig.yaw
	rig.look_delta(Vector2(100, 0))
	_check(rig.yaw == held_yaw and yard.touch._look_index == -1,
			"first person: dialogue clears held look and blocks camera gestures")
	yard.dialogue.cancel()
	await _close(yard)
