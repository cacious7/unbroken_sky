extends StoryScene
## SC05 "The Ash Road": the husk tutorial. One husk on first contact; the second enters
## only after the first is broken. Defeat restarts the encounter at its entrance with
## full health and no other penalty. Afterwards: the merchant, the way station and Nali.

## Walking past this x position wakes the first husk.
const AMBUSH_X := 300.0
## Where Tavo restarts after defeat: the encounter entrance.
const ENTRANCE := Vector2(250, 290)
## The second husk enters this far from Tavo, behind or beside him, where it is heard first.
const FLANK_ENTRY_DISTANCE := 200.0
## Directions tried for that entry relative to Tavo's view: behind, then the rear quarters, then the sides.
const FLANK_ENTRY_ANGLES: Array[float] = [PI, PI - 0.6, PI + 0.6, PI / 2.0, -PI / 2.0]
## Entry points stay this far inside the walls.
const ROAD_BOUNDS := Rect2(60, 60, 840, 420)

const RESULT_CAPTIONS := {
	"deflect": "[the hammer glances off the shell]",
	"interrupt": "[strike interrupted: connector exposed]",
	"hit": "[the copper connector cracks]",
	"break": "[the husk collapses]",
	"feint": "[the lunge falls short: it was finding its reach]",
}

@onready var husk_one: Husk = $HuskOne
@onready var husk_two: Husk = $HuskTwo
@onready var merchant: Interactable = $Merchant
@onready var nali: Interactable = $Nali

var _fighting := false


func _dialogue_file() -> String:
	return "res://data/dialogue/sc05.json"


func _start() -> void:
	for husk: Husk in [husk_one, husk_two]:
		husk.state_changed.connect(_on_husk_state)
		husk.broken.connect(_on_husk_broken)
		husk.feinted.connect(func(_husk: Husk) -> void: hud.show_caption(RESULT_CAPTIONS["feint"]))
	player.defeated.connect(_on_defeated)
	player.struck.connect(_on_struck)
	if GameState.get_flag("sc05_husk_one_down"):
		husk_one.set_broken()
	if GameState.get_flag("sc05_fight_done"):
		husk_two.set_broken()
	if not GameState.get_flag("sc05_husk_one_down"):
		# The second husk has not entered yet: hidden and not solid.
		husk_two.visible = false
		husk_two.collision_layer = 0
	_refresh_people()

	if not GameState.get_flag("sc05_arrived"):
		await _say("arrive")
		GameState.set_flag("sc05_arrived", true)
		_refresh_objective()
	elif GameState.get_flag("sc05_husk_one_down") and not GameState.get_flag("sc05_fight_done"):
		player.global_position = ENTRANCE
		_begin_second()
	elif GameState.get_flag("sc05_fight_done") and not GameState.get_flag("sc05_merchant_done"):
		await _after_fight()


func _physics_process(_delta: float) -> void:
	if not _fighting and not _busy and player.active \
			and GameState.get_flag("sc05_arrived") and not GameState.get_flag("sc05_husk_one_down") \
			and player.global_position.x >= AMBUSH_X:
		_begin_first()


func _begin_first() -> void:
	_fighting = true
	set_combat(true)
	_refresh_objective()
	# A husk waking fresh rehearses its tell once, harmlessly.
	if husk_one.state == Husk.State.DORMANT:
		husk_one.practice_strikes = 1
	husk_one.activate(player)
	await _say("ambush")


func _begin_second() -> void:
	_fighting = true
	set_combat(true)
	_refresh_objective()
	husk_two.activate(player)


func _on_husk_broken(husk: Husk) -> void:
	if husk == husk_one:
		GameState.set_flag("sc05_husk_one_down", true)
		_place_behind_player(husk_two)
		await _say("second")
		_begin_second()
	else:
		GameState.set_flag("sc05_fight_done", true)
		_fighting = false
		set_combat(false)
		await _after_fight()


func _after_fight() -> void:
	_refresh_people()
	await _say("merchant")
	GameState.set_flag("sc05_merchant_done", true)
	_refresh_people()
	_refresh_objective()


## Moves the husk to the first clear spot behind or beside Tavo. If none is clear it
## keeps its authored position up the road.
func _place_behind_player(husk: Husk) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = Husk.RADIUS + 4.0
	query.shape = circle
	query.exclude = [husk.get_rid(), player.get_rid()]
	var space := get_world_2d().direct_space_state
	for angle in FLANK_ENTRY_ANGLES:
		var point := player.global_position + player.aim_direction.rotated(angle) * FLANK_ENTRY_DISTANCE
		if not ROAD_BOUNDS.has_point(point):
			continue
		query.transform = Transform2D(0.0, point)
		if space.intersect_shape(query, 1).is_empty():
			husk.global_position = point
			return


func _on_defeated() -> void:
	await _say("defeat")
	player.global_position = ENTRANCE
	player.restore_health()
	var husk := husk_two if GameState.get_flag("sc05_husk_one_down") else husk_one
	husk.reset_to_start()
	husk.activate(player)


func _on_struck(result: String) -> void:
	if RESULT_CAPTIONS.has(result):
		hud.show_caption(RESULT_CAPTIONS[result])


func _on_husk_state(_husk: Husk, state: int) -> void:
	if state == Husk.State.WINDUP:
		hud.show_caption("[husk creaks: winding up]")


func _on_used(target: Interactable) -> void:
	match target.name:
		"WayStation":
			await _say("inspect_way_station")
		"Merchant":
			await _say("merchant_after")
		"Nali":
			if GameState.get_flag("sc05_complete"):
				await _say("nali_after")
			else:
				await _say("nali")
				GameState.set_flag("sc05_complete", true)
		"Exit":
			if GameState.get_flag("sc05_complete"):
				_go_to("SC06")
			elif GameState.get_flag("sc05_fight_done"):
				await _say("exit_help_first")
			else:
				await _say("exit_husks")


func _refresh_people() -> void:
	merchant.set_active(GameState.get_flag("sc05_fight_done"))
	nali.set_active(GameState.get_flag("sc05_merchant_done"))


func _objective() -> String:
	if GameState.get_flag("sc05_complete"):
		return "Continue to Reed Gate with Nali."
	if GameState.get_flag("sc05_merchant_done"):
		return "Someone is treating a traveller by the road."
	if _fighting:
		return "Break the husk's copper connector."
	if GameState.get_flag("sc05_arrived"):
		return "Follow the Ash Road towards Reed Gate."
	return ""
