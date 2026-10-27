class_name NavGrid
extends RefCounted
## Grid pathfinding for tap-to-walk. Built from the scene's solid scenery (walls and
## solid objects) each time a walk starts, so characters appearing or disappearing
## are always respected. Husks are not obstacles; Tavo walks up to them.

const CELL := 12.0
const AREA := Rect2(0, 0, 960, 540)
## Obstacles are grown by Tavo's half size so paths keep his body clear of walls.
const CLEARANCE := Vector2(10, 14)


## Returns world-space waypoints from `from` towards `to`, ending as close to `to` as
## can be reached (for example beside a solid object that was tapped).
static func find_path(scene: Node, from: Vector2, to: Vector2) -> PackedVector2Array:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, int(AREA.size.x / CELL), int(AREA.size.y / CELL))
	grid.cell_size = Vector2(CELL, CELL)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for rect in solid_rects(scene):
		var grown := rect.grow_individual(CLEARANCE.x, CLEARANCE.y, CLEARANCE.x, CLEARANCE.y)
		var first := Vector2i((grown.position / CELL).floor())
		var last := Vector2i((grown.end / CELL).ceil()) - Vector2i.ONE
		for x in range(maxi(first.x, 0), mini(last.x, grid.region.end.x - 1) + 1):
			for y in range(maxi(first.y, 0), mini(last.y, grid.region.end.y - 1) + 1):
				grid.set_point_solid(Vector2i(x, y))
	var start := _cell(grid, from)
	# If Tavo is pressed against a wall his own cell can read as solid; free it.
	grid.set_point_solid(start, false)
	var points := grid.get_point_path(start, _cell(grid, to), true)
	var path := PackedVector2Array()
	for i in points.size():
		path.append(points[i] + Vector2(CELL, CELL) / 2.0)
	if path.size() > 0:
		path.remove_at(0)
	return path


## World rectangles of everything Tavo cannot walk through.
static func solid_rects(scene: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in scene.get_children():
		if child is Interactable:
			if child.solid and child.enabled:
				rects.append(Rect2(child.global_position - child.body_size / 2.0, child.body_size))
		elif child is StaticBody2D and child.get("size") != null:
			rects.append(Rect2(child.global_position - child.size / 2.0, child.size))
	return rects


static func _cell(grid: AStarGrid2D, point: Vector2) -> Vector2i:
	var clamped := point.clamp(AREA.position, AREA.end - Vector2.ONE)
	return Vector2i((clamped / CELL).floor()).clamp(grid.region.position, grid.region.end - Vector2i.ONE)
