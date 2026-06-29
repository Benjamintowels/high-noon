extends RefCounted
class_name BirdFeatherBurstFX

const LIFETIME := 0.95
const FEATHER_COUNT := 16

const FEATHER_COLORS: Array[Color] = [
	Color(0.92, 0.14, 0.12, 0.95),
	Color(0.82, 0.1, 0.08, 0.9),
	Color(0.96, 0.24, 0.18, 0.92),
	Color(0.68, 0.08, 0.06, 0.88),
]


static func spawn(parent: Node, global_position: Vector3, direction: Vector3 = Vector3.ZERO) -> void:
	if parent == null:
		return

	var burst_dir := direction
	if burst_dir.length_squared() < 0.0001:
		burst_dir = Vector3.UP
	else:
		burst_dir = burst_dir.normalized()

	for i in FEATHER_COUNT:
		_spawn_feather(parent, global_position, burst_dir, i)


static func _spawn_feather(
	parent: Node,
	global_position: Vector3,
	burst_dir: Vector3,
	index: int
) -> void:
	var feather := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(randf_range(0.08, 0.16), randf_range(0.04, 0.09))
	feather.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = FEATHER_COLORS[index % FEATHER_COLORS.size()]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	feather.material_override = material

	parent.add_child(feather)
	feather.global_position = global_position + Vector3(
		randf_range(-0.08, 0.08),
		randf_range(-0.02, 0.12),
		randf_range(-0.08, 0.08)
	)
	feather.rotation.y = randf_range(0.0, TAU)

	var lateral := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if lateral.length_squared() < 0.0001:
		lateral = Vector3.RIGHT
	lateral = lateral.normalized()

	var launch := (
		burst_dir * randf_range(1.2, 2.8)
		+ lateral * randf_range(0.8, 2.2)
		+ Vector3.UP * randf_range(0.35, 1.4)
	)
	var end_pos := feather.global_position + launch
	end_pos.y -= randf_range(0.35, 0.9)

	var start_alpha: float = material.albedo_color.a
	var spin := randf_range(-6.0, 6.0)
	var tween := feather.create_tween().set_parallel(true)
	tween.tween_property(feather, "global_position", end_pos, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(feather, "rotation:y", feather.rotation.y + spin, LIFETIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		start_alpha,
		0.0,
		LIFETIME
	)
	tween.chain().tween_callback(feather.queue_free)
