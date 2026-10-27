extends Node
## Headless checks. Run from the engine folder:
##   godot --headless --path . res://tests/test_runner.tscn
## Exits with code 0 when everything passes.

const PROLOGUE := preload("res://scenes/prologue.tscn")
const WELL_YARD := preload("res://scenes/well_yard.tscn")
const CISTERN := preload("res://scenes/cistern.tscn")
const HOME := preload("res://scenes/home.tscn")
const ASH_ROAD := preload("res://scenes/ash_road.tscn")
const FLIGHT := preload("res://scenes/fortress_flight.tscn")
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
	"res://scripts/fortress_flight.gd": "res://data/dialogue/sc09.json",
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
				if line_id == "" or ids.has(line_id) or str(line.get("text", "")) == "":
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
	_check(GameState.get_flag("water_policy") == "" and GameState.get_flag("scene_id") == "SC01",
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
	_check(GameState.get_flag("scene_id") == "SC01", "a new game starts with the SC01 prologue")
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

	one._enter(Husk.State.RECOVERY)
	for i in 3:
		one.take_hammer()
	await _settle()
	_check(GameState.get_flag("sc05_husk_one_down") and two.visible and two.is_threat(),
			"SC05: second husk enters only after the first breaks")

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

func _test_flight() -> void:
	_start_at("SC09")
	var flight := await _spawn(FLIGHT)
	var eagle: Eagle = flight.get_node("Eagle")
	var perches: Array = [flight.get_node("Perch0"), flight.get_node("Perch1"),
			flight.get_node("Perch2"), flight.get_node("Perch3")]
	_check(GameState.get_flag("sc09_started") and not flight.player.visible and not eagle.flying,
			"SC09: Tavo falls and perches as an eagle")

	await flight.takeoff()
	await _physics_frames(150)
	_check(flight.link() == 1 and not eagle.flying, "SC09: first link is safe without steering")

	await flight.takeoff()
	_check(GameState.get_flag("sc09_voice_heard") and eagle.flying, "SC09: the voice speaks before the gust link")
	eagle.airtime = 0.0
	await _physics_frames(2)
	_check(flight.link() == 1 and not eagle.flying and eagle.global_position == perches[1].global_position,
			"SC09: tired wings return the eagle to the last perch")

	await flight.takeoff()
	eagle.global_position = Vector2(2000, 2000)
	await _physics_frames(2)
	_check(not eagle.flying and flight.link() == 1, "SC09: leaving the area also returns to the perch")

	# The gust pushes the eagle down compared with still air.
	var gust: Gust = flight.get_node("Gust")
	eagle.perch_at(gust.global_position, Vector2.RIGHT)
	eagle.launch(Vector2.RIGHT, 3.0)
	var start_y := eagle.global_position.y
	eagle.fly(0.1, Vector2.ZERO, flight._wind(0.1))
	_check(eagle.global_position.y > start_y + 10.0, "SC09: the gust pushes the eagle off course")
	var updraft: Gust = flight.get_node("Updraft")
	eagle.global_position = updraft.global_position
	eagle.airtime = 1.0
	flight._wind(0.5)
	_check(eagle.airtime > 1.0, "SC09: the updraft restores airtime")

	Settings.flight_assist = true
	_check(is_equal_approx(perches[2].landing_radius(), perches[2].radius * 1.5), "SC09: assist widens landings")
	Settings.flight_assist = false

	flight._perch_at(1)
	await flight.takeoff()
	eagle.global_position = perches[2].global_position
	await _physics_frames(2)
	await flight.takeoff()
	eagle.global_position = perches[3].global_position
	await _physics_frames(2)
	await _settle()
	_check(GameState.get_flag("sc09_complete") and GameState.get_flag("eagle_unlocked")
			and flight.player.visible and not eagle.visible,
			"SC09: landing on the wheel platform turns Tavo human and unlocks the eagle")
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
			"SC09":
				for perch_name: String in ["Perch1", "Perch2", "Perch3"]:
					await scene.takeoff()
					scene.get_node("Eagle").global_position = scene.get_node(perch_name).global_position
					await _physics_frames(2)
					await _settle()
			"SC10":
				await _use(scene, "Bypass")
		await _close(scene)
	_check(visited == ["SC01", "SC02", "SC03", "SC04", "SC05", "SC06", "SC07", "SC08", "SC09", "SC10"],
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
