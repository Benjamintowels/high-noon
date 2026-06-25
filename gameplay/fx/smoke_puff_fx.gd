extends RefCounted
class_name SmokePuffFX

const LIFETIME := 1.35
const RISE_DISTANCE := 1.1


static func spawn_trail(parent: Node, global_position: Vector3, puff_scale: float = 0.22) -> void:
	_spawn_puff(parent, global_position, puff_scale, 0.42)


static func spawn_burst(parent: Node, global_position: Vector3, count: int = 6) -> void:
	for i in count:
		var offset := Vector3(
			randf_range(-0.65, 0.65),
			randf_range(0.0, 0.35),
			randf_range(-0.65, 0.65)
		)
		_spawn_puff(parent, global_position + offset, randf_range(0.28, 0.5), randf_range(0.55, 0.85))


static func _spawn_puff(
	parent: Node,
	global_position: Vector3,
	puff_scale: float,
	start_alpha: float
) -> void:
	if parent == null:
		return

	var puff := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = puff_scale
	mesh.height = puff_scale * 2.2
	puff.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 0.97, 0.99, start_alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	puff.material_override = material

	parent.add_child(puff)
	puff.global_position = global_position + Vector3(
		randf_range(-0.08, 0.08),
		randf_range(-0.04, 0.06),
		randf_range(-0.08, 0.08)
	)

	var end_scale := puff_scale * randf_range(2.0, 2.8)
	var rise := Vector3(
		randf_range(-0.12, 0.12),
		RISE_DISTANCE + randf_range(0.0, 0.45),
		randf_range(-0.12, 0.12)
	)

	var tween := puff.create_tween().set_parallel(true)
	tween.tween_property(puff, "global_position", puff.global_position + rise, LIFETIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(puff, "scale", Vector3.ONE * end_scale, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		start_alpha,
		0.0,
		LIFETIME
	)
	tween.chain().tween_callback(puff.queue_free)
