extends RefCounted
class_name WoodBreakFX
## Wooden prop destruction burst: a shower of particle wood chips plus a few
## real physics planks that clatter out, linger, then shrink away. Same visual
## language as the PhysicsTable explosion, parameterized for smaller props.

const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")

const PUSHABLE_COLLISION_LAYER := 2
const CHUNK_LIFETIME := 1.2
const DEBRIS_LIFETIME := 7.0
const DEBRIS_IMPULSE := 4.5
const WOOD_COLOR := Color(0.42, 0.28, 0.16)


static func spawn(
	parent: Node,
	center: Vector3,
	chunk_count := 12,
	plank_count := 4,
	burst_direction := Vector3.ZERO
) -> void:
	if parent == null:
		return
	_spawn_chunk_burst(parent, center, chunk_count, burst_direction)
	_spawn_physics_planks(parent, center, plank_count)


static func _spawn_chunk_burst(
	parent: Node,
	center: Vector3,
	chunk_count: int,
	burst_direction: Vector3
) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.amount = chunk_count
	particles.lifetime = CHUNK_LIFETIME
	particles.explosiveness = 1.0
	var direction := Vector3.UP
	if burst_direction.length_squared() > 0.0001:
		direction = (burst_direction.normalized() + Vector3.UP).normalized()
	particles.direction = direction
	particles.spread = 70.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 6.5
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.gravity = Vector3(0.0, -14.0, 0.0)
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.18, 0.05, 0.09)
	chunk.material = _wood_material()
	particles.mesh = chunk
	parent.add_child(particles)
	particles.global_position = center
	particles.emitting = true
	var tree := parent.get_tree()
	if tree != null:
		tree.create_timer(CHUNK_LIFETIME + 0.6).timeout.connect(particles.queue_free)


static func _spawn_physics_planks(parent: Node, center: Vector3, plank_count: int) -> void:
	var material := _wood_material()
	for i in plank_count:
		var piece := RigidBody3D.new()
		piece.collision_layer = PUSHABLE_COLLISION_LAYER
		piece.collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
		piece.mass = 1.0
		piece.linear_damp = 0.4
		piece.angular_damp = 0.6

		var size := Vector3(
			randf_range(0.22, 0.42),
			randf_range(0.035, 0.07),
			randf_range(0.08, 0.16)
		)
		var mesh_instance := MeshInstance3D.new()
		var plank := BoxMesh.new()
		plank.size = size
		plank.material = material
		mesh_instance.mesh = plank
		piece.add_child(mesh_instance)

		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		piece.add_child(shape)

		parent.add_child(piece)
		var angle := TAU * float(i) / float(plank_count) + randf_range(-0.3, 0.3)
		var out := Vector3(cos(angle), 0.0, sin(angle))
		piece.global_position = (
			center
			+ out * randf_range(0.1, 0.35)
			+ Vector3(0.0, randf_range(0.05, 0.3), 0.0)
		)
		piece.rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
		piece.apply_impulse((out + Vector3.UP * randf_range(0.6, 1.2)).normalized() * DEBRIS_IMPULSE * piece.mass)
		piece.apply_torque_impulse(Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * 1.2)

		var tween := piece.create_tween()
		tween.tween_interval(DEBRIS_LIFETIME)
		tween.tween_property(mesh_instance, "scale", Vector3(0.01, 0.01, 0.01), 0.6)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(piece.queue_free)


static func _wood_material() -> StandardMaterial3D:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = WOOD_COLOR
	wood.roughness = 0.9
	return wood
