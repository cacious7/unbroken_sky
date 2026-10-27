extends Node
## Plays short sound effects by name. Sounds are in assets/sfx/, made by
## tools/generate_sounds.gd. Every sound also has a visual or caption equivalent, so
## the game stays playable muted.

const SOUNDS := {
	"hammer_clang": preload("res://assets/sfx/hammer_clang.wav"),
	"husk_windup": preload("res://assets/sfx/husk_windup.wav"),
	"whisper_present": preload("res://assets/sfx/whisper_present.wav"),
	"water_sweep": preload("res://assets/sfx/water_sweep.wav"),
	"pump_squeak": preload("res://assets/sfx/pump_squeak.wav"),
}
const VOICES := 6

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not SOUNDS.has(sound_name):
		push_error("Unknown sound: %s" % sound_name)
		return
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = SOUNDS[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
