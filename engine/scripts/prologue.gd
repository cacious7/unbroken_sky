extends Node2D
## SC01 "The child behind the wall": no play, under forty seconds. Darkness and scraping
## metal; two small hands touch either side of a copper channel in stone; a single line
## of daylight moves across the wall. Three lines between the children. A woman's sleeve
## covers the first hand, a door opens, hard cut, then the caption, then SC02.
## No faces are shown. A Skip button is always available.

const NEXT_SCENE := "SC02"
const CHANNEL_Y := 290.0
## Child one is Tavo, child two Sena (the reveal comes much later; only skin tones hint).
const CHILD_ONE_SKIN := Color("#6b4126")
const CHILD_TWO_SKIN := Color("#7a4a2c")
## The sleeve shares the colour of Mera's head wrap: a clue, never stated.
const SLEEVE := Color("#6b4f7a")

@onready var dialogue: DialogueBox = $Dialogue

## Tests set this to skip the timed staging.
var instant := false

var _light := 0.0
var _fade := 1.0
var _hands := 0.0
var _sleeve := 0.0
var _door := 0.0
var _cut := false
var _caption := 0.0
var _sound_caption := ""
var _done := false


func _ready() -> void:
	dialogue.load_file("res://data/dialogue/sc01.json")
	_build_skip_button()
	_run()


func _process(delta: float) -> void:
	_light = fmod(_light + delta * 0.07, 1.0)
	queue_redraw()


func _run() -> void:
	await _tween("_fade", 0.0, 1.5)
	_sound_caption = "[metal scraping in the dark]"
	Sfx.play("metal_scrape", -4.0)
	await _tween("_hands", 1.0, 2.2)
	await _wait(0.8)
	_sound_caption = ""
	if _done:
		return
	dialogue.play("children")
	await dialogue.finished
	await _tween("_sleeve", 1.0, 1.6)
	_sound_caption = "[a door opens]"
	Sfx.play("door_open")
	await _tween("_door", 1.0, 0.8)
	_cut = true
	_sound_caption = ""
	await _wait(0.7)
	await _tween("_caption", 1.0, 0.8)
	await _wait(2.4)
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.go_to(NEXT_SCENE)


func _tween(property: String, to: float, seconds: float) -> void:
	if instant or _done:
		set(property, to)
		return
	var tween := create_tween()
	tween.tween_property(self, property, to, seconds)
	await tween.finished


func _wait(seconds: float) -> void:
	if instant or _done:
		return
	await get_tree().create_timer(seconds).timeout


func _build_skip_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var skip := Button.new()
	skip.text = "Skip ▸"
	skip.custom_minimum_size = Vector2(96, 44)
	skip.position = Vector2(848, 12)
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_to_group("blocks_touch")
	skip.pressed.connect(_finish)
	layer.add_child(skip)


func _draw() -> void:
	var screen := Rect2(0, 0, 960, 540)
	draw_rect(screen.grow(400), Color.BLACK)
	if _cut:
		_draw_caption()
		return
	# Stone wall with faint courses.
	draw_rect(screen, Color(0.11, 0.1, 0.09))
	for y in range(30, 540, 34):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.15, 0.14, 0.12), 2.0)
	# The single line of daylight.
	var x := lerpf(120.0, 840.0, _light)
	draw_rect(Rect2(x - 14, 0, 28, 540), Color(1.0, 0.85, 0.55, 0.06))
	draw_rect(Rect2(x - 3, 0, 6, 540), Color(1.0, 0.88, 0.6, 0.35))
	# The copper channel set in the stone.
	draw_rect(Rect2(0, CHANNEL_Y - 13, 960, 26), Color(0.42, 0.24, 0.12))
	draw_line(Vector2(0, CHANNEL_Y - 9), Vector2(960, CHANNEL_Y - 9), Color(0.75, 0.45, 0.22), 2.0)
	# Two small hands, one above the channel and one below, reaching from either side.
	_draw_hand(Vector2(lerpf(250.0, 430.0, _hands), CHANNEL_Y - 24), CHILD_ONE_SKIN, 1.0)
	_draw_hand(Vector2(lerpf(710.0, 530.0, _hands), CHANNEL_Y + 24), CHILD_TWO_SKIN, -1.0)
	# The sleeve sliding over the first hand.
	if _sleeve > 0.0:
		var reach := lerpf(-60.0, 470.0, _sleeve)
		draw_colored_polygon(PackedVector2Array([Vector2(-60, CHANNEL_Y - 90), Vector2(reach, CHANNEL_Y - 60),
				Vector2(reach + 20, CHANNEL_Y - 6), Vector2(-60, CHANNEL_Y + 6)]), SLEEVE)
	# The door's light from the right, just before the cut.
	if _door > 0.0:
		draw_rect(Rect2(960 - 380 * _door, 0, 380 * _door, 540), Color(1.0, 0.92, 0.75, 0.7 * _door))
	if _sound_caption != "":
		Placeholder.draw_label(self, Vector2(480, 80), _sound_caption)
	draw_rect(screen, Color(0, 0, 0, _fade))


## A child's hand: arm from off-screen, small palm, four fingers. direction 1 reaches right.
func _draw_hand(tip: Vector2, skin: Color, direction: float) -> void:
	var d := direction
	var palm := tip - Vector2(22 * d, 0)
	var arm_end := Vector2(-80.0 if d > 0 else 1040.0, palm.y + 4)
	# Forearm in a plain sleeve, then the wrist.
	draw_line(arm_end, palm - Vector2(14 * d, -3), Color(0.32, 0.28, 0.24), 18.0)
	draw_line(palm - Vector2(16 * d, -3), palm, skin.darkened(0.1), 13.0)
	# Palm: a soft oval.
	draw_set_transform(palm, 0.0, Vector2(1.25, 1.0))
	draw_circle(Vector2.ZERO, 10.0, skin)
	draw_set_transform(Vector2.ZERO)
	# Four fingers of slightly different lengths, spread towards the channel, and a thumb.
	var lengths := [13.0, 16.0, 15.0, 11.0]
	for i in 4:
		var base := palm + Vector2(8 * d, -7.5 + i * 5.0)
		var end := base + Vector2(lengths[i] * d, (i - 1.5) * 1.5)
		draw_line(base, end, skin, 4.5)
		draw_circle(end, 2.25, skin)
	var thumb_base := palm + Vector2(2 * d, 8)
	var thumb_end := thumb_base + Vector2(9 * d, 6)
	draw_line(thumb_base, thumb_end, skin, 5.0)
	draw_circle(thumb_end, 2.5, skin)


func _draw_caption() -> void:
	var font := ThemeDB.fallback_font
	var color := Color(0.95, 0.9, 0.8, _caption)
	draw_string(font, Vector2(0, 250), "SEVENTEEN YEARS LATER.", HORIZONTAL_ALIGNMENT_CENTER, 960, 34, color)
	draw_string(font, Vector2(0, 300), "RED HOLLOW.", HORIZONTAL_ALIGNMENT_CENTER, 960, 34, color)
