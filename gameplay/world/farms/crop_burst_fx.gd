extends RefCounted
class_name CropBurstFX

const LIFETIME := 0.85
const PARTICLE_COUNT := 18

const YELLOW_COLORS: Array[Color] = [
	Color(0.98, 0.88, 0.18, 0.95),
	Color(0.94, 0.78, 0.12, 0.92),
	Color(0.99, 0.92, 0.35, 0.9),
	Color(0.86, 0.66, 0.08, 0.88),
]


static func spawn(parent: Node, global_position: Vector3, direction: Vector3 = Vector3.ZERO) -> void:
	if parent == null:
		return

	var burst_dir := direction
	if burst_dir.length_squared() < 0.0001:
		burst_dir = Vector3.UP
	else:
		burst_dir = burst_dir.normalized()

	for i in PARTICLE_COUNT:
		_spawn_particle(parent, global_position, burst_dir, i)


static func _spawn_particle(
	parent: Node,
	global_position: Vector3,
	burst_dir: Vector3,
	index: int
) -> void:
	var particle := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(randf_range(0.06, 0.14), randf_range(0.06, 0.14))
	particle.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = YELLOW_COLORS[index % YELLOW_COLORS.size()]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	particle.material_override = material

	parent.add_child(particle)
	particle.global_position = global_position + Vector3(
		randf_range(-0.1, 0.1),
		randf_range(0.0, 0.2),
		randf_range(-0.1, 0.1)
	)
	particle.rotation.y = randf_range(0.0, TAU)

	var lateral := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if lateral.length_squared() < 0.0001:
		lateral = Vector3.RIGHT
	lateral = lateral.normalized()

	var launch := (
		burst_dir * randf_range(1.0, 2.6)
		+ lateral * randf_range(0.6, 1.8)
		+ Vector3.UP * randf_range(0.5, 1.6)
	)
	var end_pos := particle.global_position + launch
	end_pos.y -= randf_range(0.25, 0.75)

	var start_alpha: float = material.albedo_color.a
	var spin := randf_range(-8.0, 8.0)
	var tween := particle.create_tween().set_parallel(true)
	tween.tween_property(particle, "global_position", end_pos, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "rotation:y", particle.rotation.y + spin, LIFETIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		start_alpha,
		0.0,
		LIFETIME
	)
	tween.chain().tween_callback(particle.queue_free)
