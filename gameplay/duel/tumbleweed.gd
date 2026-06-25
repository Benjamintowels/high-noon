extends Node3D
class_name DuelTumbleweed

const BOUNCE_HEIGHT := 0.32
const BOUNCE_COUNT := 7
const RADIUS := 0.4
const DONUT_COUNT := 11

static var _donut_texture: ImageTexture

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _elapsed := 0.0
var _duration := 5.0
var _roll_sign := 1.0
var _visual: Node3D


static func opening_roll_duration(fade_in: float, intro_delay: float, countdown_seconds: int) -> float:
	return fade_in + intro_delay + float(countdown_seconds)


func begin_roll(lane: Node3D, duration: float) -> void:
	_duration = maxf(duration, 0.5)
	_resolve_path(lane)
	_roll_sign = 1.0 if _to.x >= _from.x else -1.0
	global_position = _from
	set_process(true)


func _ready() -> void:
	_build_visual()


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)

	var flat_pos := _from.lerp(_to, _ease_roll(t))
	flat_pos.y += _bounce_y(t)
	global_position = flat_pos

	var travel := (_to - _from).length()
	var roll_angle := (t * travel) / RADIUS * _roll_sign
	rotation.z = -roll_angle
	rotation.x = sin(t * 28.0) * 0.18

	if t >= 1.0:
		set_process(false)
		queue_free()


func _resolve_path(lane: Node3D) -> void:
	var start := lane.get_node_or_null("TumbleweedStart") as Node3D
	var end := lane.get_node_or_null("TumbleweedEnd") as Node3D
	if start != null and end != null:
		_from = start.global_position
		_to = end.global_position
		return

	var player_spawn := lane.get_node_or_null("PlayerSpawn") as Node3D
	var enemy_spawn := lane.get_node_or_null("EnemySpawn") as Node3D
	var mid_z := 7.0
	if player_spawn != null and enemy_spawn != null:
		mid_z = (player_spawn.global_position.z + enemy_spawn.global_position.z) * 0.5
	_from = Vector3(-5.5, 0.12, mid_z)
	_to = Vector3(5.5, 0.12, mid_z)


func _ease_roll(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _bounce_y(t: float) -> float:
	var local := t * float(BOUNCE_COUNT)
	var phase := fmod(local, 1.0)
	var idx := int(local)
	var decay := pow(0.7, float(idx))
	return 4.0 * BOUNCE_HEIGHT * decay * phase * (1.0 - phase)


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)

	var donut_texture := _get_donut_texture()
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	for i in DONUT_COUNT:
		var donut := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		var size := rng.randf_range(0.55, 0.95)
		mesh.size = Vector2(size, size)
		donut.mesh = mesh

		var material := StandardMaterial3D.new()
		material.albedo_texture = donut_texture
		material.albedo_color = Color(
			rng.randf_range(0.5, 0.64),
			rng.randf_range(0.4, 0.52),
			rng.randf_range(0.24, 0.34),
			rng.randf_range(0.55, 0.82)
		)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		donut.material_override = material

		donut.rotation = Vector3(
			rng.randf_range(-PI, PI),
			rng.randf_range(-PI, PI),
			rng.randf_range(-PI, PI)
		)
		donut.position = Vector3(
			rng.randf_range(-0.32, 0.32),
			rng.randf_range(-0.18, 0.22),
			rng.randf_range(-0.32, 0.32)
		)
		_visual.add_child(donut)


static func _get_donut_texture() -> ImageTexture:
	if _donut_texture != null:
		return _donut_texture

	const SIZE := 128
	const OUTER_R := 0.48
	const INNER_R := 0.24
	const EDGE_SOFTNESS := 0.035

	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var center := Vector2((SIZE - 1) * 0.5, (SIZE - 1) * 0.5)
	var max_radius := SIZE * 0.5

	for y in SIZE:
		for x in SIZE:
			var dist := Vector2(x, y).distance_to(center) / max_radius
			var outer_fade := 1.0 - smoothstep(OUTER_R - EDGE_SOFTNESS, OUTER_R + EDGE_SOFTNESS, dist)
			var inner_fade := smoothstep(INNER_R - EDGE_SOFTNESS, INNER_R + EDGE_SOFTNESS, dist)
			var alpha := clampf(outer_fade * inner_fade, 0.0, 1.0)
			if alpha <= 0.001:
				continue
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	_donut_texture = ImageTexture.create_from_image(image)
	return _donut_texture
