extends Node3D
## SC06: the counterfeit mother's tells. The puddle at her feet holds a planar
## reflection, but what it reflects is a twin that is out of step: it mouths words
## while she is silent, falls still when she speaks, and keeps its face on Tavo.
## When Tavo's question breaks her, she slumps into a splash and the water rope rises.

## Render layer seen only by the mirrored camera.
const REFLECTION_LAYER := 1 << 19
## Reflection render size as a fraction of the screen.
const RESOLUTION := 0.5
const COLLAPSE_SECONDS := 0.9
const PUDDLE_SURFACE := 0.03

var twin: CastFigure
var collapsed := false

var _view: Node3D
var _source: Interactable
var _figure_root: Node3D
var _figure: CastFigure
var _viewport: SubViewport
var _mirror: Camera3D
var _puddle: MeshInstance3D
var _on_screen := false


func configure(view: Node3D) -> void:
	_view = view


func _ready() -> void:
	var scene: Node = _view.get("scene")
	_source = scene.get_node("Figure")
	_figure_root = _view.get_node("Figure3D")
	_figure = _view.figure_for("Figure")
	_figure_root.set_meta("staged", true)
	collapsed = not _source.visible
	_figure_root.visible = _source.visible
	(_view.get("camera") as Camera3D).cull_mask &= ~REFLECTION_LAYER

	twin = CastFigure.create("figure")
	twin.name = "ReflectionTwin"
	add_child(twin)
	for mesh: GeometryInstance3D in twin.find_children("", "GeometryInstance3D", true, false):
		mesh.layers = REFLECTION_LAYER
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.size = Vector2i((get_viewport().get_visible_rect().size * RESOLUTION).round())
	add_child(_viewport)
	_mirror = Camera3D.new()
	_mirror.cull_mask = REFLECTION_LAYER
	_viewport.add_child(_mirror)

	var reflection := _view.get_node("Reflection3D") as Node3D
	_puddle = reflection.find_children("", "MeshInstance3D", true, false)[0]
	var water := ShaderMaterial.new()
	water.shader = preload("res://assets/shaders/puddle_reflection.gdshader")
	water.set_shader_parameter("reflection", _viewport.get_texture())
	if collapsed:
		water.set_shader_parameter("strength", 0.0)
	_puddle.material_override = water
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.aabb = AABB(Vector3(-1.2, -0.1, -1.2), Vector3(2.4, 0.4, 2.4))
	notifier.screen_entered.connect(func() -> void: _on_screen = true)
	notifier.screen_exited.connect(func() -> void: _on_screen = false)
	reflection.add_child(notifier)
	_sync(true)


func _process(_delta: float) -> void:
	_sync(false)


## True while the twin is mouthing words (it talks exactly when she does not).
func twin_talking() -> bool:
	return twin._looping == "talk"


func _sync(first: bool) -> void:
	if not collapsed and not _source.visible:
		_collapse()
	var showing := not collapsed and _source.visible
	twin.visible = showing
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if showing and (_on_screen or first) \
			else SubViewport.UPDATE_DISABLED
	if not showing:
		return
	twin.global_position = _figure.global_position
	var tavo := (_view.get("tavo") as Node3D).global_position
	tavo.y = twin.global_position.y
	if twin.global_position.distance_to(tavo) > 0.1:
		twin.look_at(tavo, Vector3.UP)
	twin.play("idle" if _figure._looping == "talk" else "talk")
	_mirror_camera()


## Mirrors the main camera in the puddle plane. A reflected basis is left-handed, so
## the up axis is flipped back and the shader samples the image upside down.
func _mirror_camera() -> void:
	var main := _view.get("camera") as Camera3D
	var eye := main.global_transform
	var flip := func(v: Vector3) -> Vector3: return Vector3(v.x, -v.y, v.z)
	var origin := eye.origin
	origin.y = 2.0 * PUDDLE_SURFACE - origin.y
	_mirror.global_transform = Transform3D(Basis(flip.call(eye.basis.x), -flip.call(eye.basis.y), flip.call(eye.basis.z)), origin)
	_mirror.fov = main.fov
	_mirror.near = main.near
	_mirror.far = 40.0


func _collapse() -> void:
	collapsed = true
	twin.visible = false
	Sfx.play("water_sweep")
	_splash(_figure_root.global_position)
	# The puddle keeps the last reflected frame, so fade it out with her.
	create_tween().tween_method(func(value: float) -> void:
			(_puddle.material_override as ShaderMaterial).set_shader_parameter("strength", value),
			0.8, 0.0, COLLAPSE_SECONDS * 0.5)
	var slump := create_tween().set_parallel()
	slump.tween_property(_figure_root, "scale", Vector3(1.6, 0.03, 1.6), COLLAPSE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slump.tween_property(_figure_root, "position:y", -0.05, COLLAPSE_SECONDS)
	slump.chain().tween_callback(func() -> void: _figure_root.visible = false)
	# The rope rises out of where she stood.
	var column := _view.get("_rope_column") as MeshInstance3D
	if column != null:
		column.scale = Vector3(1.4, 0.05, 1.4)
		column.position.y = 0.05
		var rise := create_tween().set_parallel()
		rise.tween_property(column, "scale", Vector3.ONE, COLLAPSE_SECONDS * 0.8).set_delay(COLLAPSE_SECONDS * 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rise.tween_property(column, "position:y", 0.9, COLLAPSE_SECONDS * 0.8).set_delay(COLLAPSE_SECONDS * 0.3)


func _splash(at: Vector3) -> void:
	var drops := CPUParticles3D.new()
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.07
	drop.radial_segments = 6
	drop.rings = 3
	drops.mesh = drop
	drops.material_override = Materials3D.silt_water()
	drops.amount = 36
	drops.one_shot = true
	drops.explosiveness = 0.85
	drops.lifetime = 0.9
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	drops.emission_sphere_radius = 0.35
	drops.direction = Vector3.UP
	drops.spread = 55.0
	drops.initial_velocity_min = 1.5
	drops.initial_velocity_max = 3.2
	drops.position = at + Vector3(0, 0.9, 0)
	add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
