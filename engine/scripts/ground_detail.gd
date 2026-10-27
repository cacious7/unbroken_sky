extends Node2D
## Texture for a flat colour area, added as a child of its ColorRect so it sits exactly
## on that surface: soft tonal patches, pebbles and dry grass on earth; ripples on
## water. Deterministic for a given seed.

var base := Color(0.7, 0.55, 0.42)
var area := Rect2(0, 0, 960, 540)
var seed_value := 1


static func attach(surface: ColorRect, seed_value: int) -> void:
	var detail := new()
	detail.base = surface.color
	detail.area = Rect2(Vector2.ZERO, surface.size)
	detail.seed_value = seed_value
	surface.add_child(detail)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count_scale := area.get_area() / (960.0 * 540.0)
	if base.b > base.r:
		_draw_water(rng, count_scale)
		return
	for i in int(24 * count_scale):
		var shade := base.darkened(0.08) if rng.randf() < 0.5 else base.lightened(0.06)
		draw_circle(_random_point(rng), rng.randf_range(30.0, 70.0), Color(shade, 0.12))
	for i in int(170 * count_scale):
		draw_circle(_random_point(rng), rng.randf_range(0.8, 2.2),
				Color(base.darkened(rng.randf_range(0.2, 0.35)), 0.6))
	# Dry grass on warm, earthy ground.
	if base.r > base.b + 0.15:
		var grass := Color(0.55, 0.52, 0.28, 0.75)
		for i in int(40 * count_scale):
			var p := _random_point(rng)
			for blade in 3:
				draw_line(p, p + Vector2(rng.randf_range(-4.0, 4.0), -rng.randf_range(4.0, 8.0)), grass, 1.2)


func _draw_water(rng: RandomNumberGenerator, count_scale: float) -> void:
	var ripple := Color(base.lightened(0.35), 0.35)
	for i in int(70 * count_scale):
		var p := _random_point(rng)
		var w := rng.randf_range(10.0, 26.0)
		draw_polyline(PackedVector2Array([p, p + Vector2(w * 0.5, -2.5), p + Vector2(w, 0)]), ripple, 1.5)


func _random_point(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
