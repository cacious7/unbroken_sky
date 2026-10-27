extends SceneTree
## Synthesises the prototype sound effects into assets/sfx/ as 16-bit mono WAV files.
## Everything is generated from sine waves and filtered noise, so there is nothing to
## license. Run from the engine folder:
##   godot --headless --path . --script res://tools/generate_sounds.gd

const RATE := 22050

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 7
	_save("hammer_clang", _clang())
	_save("husk_windup", _creak())
	_save("whisper_present", _whisper())
	_save("water_sweep", _sweep())
	_save("pump_squeak", _squeak())
	quit()


func _save(sound_name: String, samples: PackedFloat32Array) -> void:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.85 / peak if peak > 0.0 else 1.0
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	var path := ProjectSettings.globalize_path("res://assets/sfx/%s.wav" % sound_name)
	print("%s: %s" % [sound_name, error_string(wav.save_to_wav(path))])


func _buffer(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	return samples


## Repair hammer on a clay-and-copper shell: inharmonic metal partials plus a thud.
func _clang() -> PackedFloat32Array:
	var samples := _buffer(0.7)
	var partials := [[523.0, 1.0, 7.0], [1187.0, 0.6, 10.0], [1873.0, 0.4, 14.0], [2711.0, 0.25, 18.0]]
	for i in samples.size():
		var t := float(i) / RATE
		var value := 0.0
		for p: Array in partials:
			value += sin(TAU * p[0] * t) * p[1] * exp(-p[2] * t)
		value += sin(TAU * 90.0 * t) * 0.8 * exp(-25.0 * t)
		if t < 0.012:
			value += _rng.randf_range(-1.0, 1.0) * (1.0 - t / 0.012)
		samples[i] = value
	return samples


## Husk windup: a dry, rising creak that lasts as long as the windup (0.85 s).
func _creak() -> PackedFloat32Array:
	var samples := _buffer(0.85)
	var phase := 0.0
	var smoothed := 0.0
	for i in samples.size():
		var t := float(i) / RATE
		var pitch := lerpf(70.0, 150.0, t / 0.85) + _rng.randf_range(-12.0, 12.0)
		phase = fmod(phase + pitch / RATE, 1.0)
		var saw := phase * 2.0 - 1.0
		# Stick-slip grain: the saw only "catches" part of the time.
		var grain := 1.0 if _rng.randf() < 0.6 else 0.2
		smoothed += 0.25 * (saw * grain - smoothed)
		samples[i] = smoothed * minf(t / 0.6, 1.0)
	return samples


## "Present." as a breathy two-syllable whisper: band-limited noise shaped into syllables.
func _whisper() -> PackedFloat32Array:
	var samples := _buffer(1.1)
	var low := 0.0
	var lower := 0.0
	for i in samples.size():
		var t := float(i) / RATE
		var noise := _rng.randf_range(-1.0, 1.0)
		low += 0.35 * (noise - low)
		lower += 0.05 * (noise - lower)
		var band := low - lower
		var syllable_one := exp(-pow((t - 0.25) / 0.1, 2.0))
		var syllable_two := exp(-pow((t - 0.62) / 0.16, 2.0))
		var hiss := exp(-pow((t - 0.86) / 0.05, 2.0)) * noise * 0.4
		samples[i] = band * (syllable_one + syllable_two) + hiss
	return samples


## Water rope sweep: a whoosh whose brightness rises and falls.
func _sweep() -> PackedFloat32Array:
	var samples := _buffer(0.6)
	var low := 0.0
	for i in samples.size():
		var t := float(i) / RATE
		var shape := sin(PI * t / 0.6)
		low += (0.03 + 0.25 * shape) * (_rng.randf_range(-1.0, 1.0) - low)
		samples[i] = low * shape
	return samples


## Well pump handle: a short metallic squeak.
func _squeak() -> PackedFloat32Array:
	var samples := _buffer(0.35)
	var phase := 0.0
	for i in samples.size():
		var t := float(i) / RATE
		var pitch := 900.0 + 500.0 * sin(PI * t / 0.35) + 40.0 * sin(TAU * 31.0 * t)
		phase += TAU * pitch / RATE
		samples[i] = sin(phase) * sin(PI * t / 0.35) * (0.7 + 0.3 * sin(TAU * 13.0 * t))
	return samples
