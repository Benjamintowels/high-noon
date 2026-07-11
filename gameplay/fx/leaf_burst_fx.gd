extends RefCounted
class_name LeafBurstFX

const LIFETIME := 0.9

const LEAF_TEXTURES: Array[Texture2D] = [
	preload("res://Assets/Particles/Leaf1.png"),
	preload("res://Assets/Particles/Leaf2.png"),
]


static func spawn(
	parent: Node,
	global_position: Vector3,
	direction: Vector3 = Vector3.ZERO,
	count: int = -1
) -> void:
	if parent == null:
		return

	var burst_count := count
	if burst_count < 1:
		burst_count = randi_range(3, 7)

	var burst_dir := direction
	if burst_dir.length_squared() < 0.0001:
		burst_dir = Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		).normalized()

	for i in burst_count:
		_spawn_leaf(parent, global_position, burst_dir, i)


static func _spawn_leaf(
	parent: Node,
	global_position: Vector3,
	burst_dir: Vector3,
	index: int
) -> void:
	var leaf := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(randf_range(0.12, 0.22), randf_range(0.12, 0.22))
	leaf.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_texture = LEAF_TEXTURES[index % LEAF_TEXTURES.size()]
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.08
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	leaf.material_override = material

	parent.add_child(leaf)
	leaf.global_position = global_position + Vector3(
		randf_range(-0.35, 0.35),
		randf_range(0.15, 0.75),
		randf_range(-0.35, 0.35)
	)
	leaf.rotation.y = randf_range(0.0, TAU)

	var lateral := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if lateral.length_squared() < 0.0001:
		lateral = Vector3.RIGHT
	lateral = lateral.normalized()

	var launch := (
		burst_dir * randf_range(0.6, 1.6)
		+ lateral * randf_range(0.5, 1.4)
		+ Vector3.UP * randf_range(0.45, 1.2)
	)
	var end_pos := leaf.global_position + launch
	end_pos.y -= randf_range(0.2, 0.65)

	var spin := randf_range(-7.0, 7.0)
	var tween := leaf.create_tween().set_parallel(true)
	tween.tween_property(leaf, "global_position", end_pos, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(leaf, "rotation:y", leaf.rotation.y + spin, LIFETIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(leaf.queue_free)
