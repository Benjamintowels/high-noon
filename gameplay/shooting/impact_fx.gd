extends RefCounted
class_name ImpactFX

const WOOD_CHIP_SCENE := preload("res://gameplay/shooting/wood_chip.tscn")
const GLASS_SHARD_SCENE := preload("res://gameplay/shooting/glass_shard.tscn")

const MAX_BULLET_HOLES := 48

static var _hole_texture: Texture2D


static func spawn_wood_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	_spawn_bullet_hole(parent, position, normal)
	_spawn_wood_particles(parent, position, normal, direction)
	_spawn_wood_chips(parent, position, normal, direction, 5)


static func spawn_metal_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	_spawn_bullet_hole(parent, position, normal)
	_spawn_spark_particles(parent, position, normal, direction, Color(1.0, 0.85, 0.45))


static func spawn_glass_shatter(source: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	_spawn_spark_particles(parent_for(source), position, normal, direction, Color(0.75, 0.92, 1.0), 36)
	for i in range(10):
		var shard: RigidBody3D = GLASS_SHARD_SCENE.instantiate()
		var root := parent_for(source)
		root.add_child(shard)
		shard.global_position = position + Vector3(
			randf_range(-0.04, 0.04),
			randf_range(-0.02, 0.12),
			randf_range(-0.04, 0.04)
		)
		shard.global_rotation = Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU)
		)
		var burst := direction * randf_range(6.0, 14.0)
		burst += normal * randf_range(2.0, 6.0)
		burst += Vector3(randf_range(-3.0, 3.0), randf_range(1.0, 5.0), randf_range(-3.0, 3.0))
		shard.apply_central_impulse(burst)
		shard.apply_torque_impulse(Vector3(
			randf_range(-4.0, 4.0),
			randf_range(-4.0, 4.0),
			randf_range(-4.0, 4.0)
		))


static func spawn_generic_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	_spawn_bullet_hole(parent, position, normal)
	_spawn_dust_particles(parent, position, normal, direction)


static func parent_for(source: Node) -> Node:
	if source == null:
		return null
	if source.get_tree() != null and source.get_tree().current_scene != null:
		return source.get_tree().current_scene
	return source.get_parent()


static func _spawn_bullet_hole(parent: Node3D, position: Vector3, normal: Vector3) -> void:
	if parent == null:
		return

	var holes := parent.get_node_or_null("BulletHoles")
	if holes == null:
		holes = Node3D.new()
		holes.name = "BulletHoles"
		parent.add_child(holes)

	while holes.get_child_count() >= MAX_BULLET_HOLES:
		holes.get_child(0).queue_free()

	var decal := Decal.new()
	decal.size = Vector3(0.16, 0.16, 0.18)
	decal.texture_albedo = _get_hole_texture()
	decal.modulate = Color(0.35, 0.22, 0.12, 1.0)
	holes.add_child(decal)

	var up := Vector3.UP
	if absf(normal.dot(up)) > 0.92:
		up = Vector3.FORWARD
	decal.global_position = position + normal * 0.04
	decal.global_basis = Basis.looking_at(-normal, up)


static func _spawn_wood_particles(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 18
	particles.lifetime = 0.45
	particles.explosiveness = 0.95
	particles.direction = (normal + direction * 0.35).normalized()
	particles.spread = 48.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 7.0
	particles.gravity = Vector3(0.0, -12.0, 0.0)
	particles.scale_amount_min = 0.04
	particles.scale_amount_max = 0.09
	particles.color = Color(0.62, 0.42, 0.24, 1.0)
	parent.add_child(particles)
	particles.global_position = position
	particles.finished.connect(particles.queue_free)


static func _spawn_dust_particles(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.35
	particles.explosiveness = 0.9
	particles.direction = (normal + direction * 0.2).normalized()
	particles.spread = 36.0
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0.0, -8.0, 0.0)
	particles.scale_amount_min = 0.06
	particles.scale_amount_max = 0.12
	particles.color = Color(0.55, 0.45, 0.32, 0.7)
	parent.add_child(particles)
	particles.global_position = position
	particles.finished.connect(particles.queue_free)


static func _spawn_spark_particles(
	parent: Node3D,
	position: Vector3,
	normal: Vector3,
	direction: Vector3,
	tint: Color,
	count: int = 14
) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = count
	particles.lifetime = 0.28
	particles.explosiveness = 1.0
	particles.direction = (normal + direction * 0.5).normalized()
	particles.spread = 62.0
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 10.0
	particles.gravity = Vector3(0.0, -14.0, 0.0)
	particles.scale_amount_min = 0.025
	particles.scale_amount_max = 0.06
	particles.color = tint
	parent.add_child(particles)
	particles.global_position = position
	particles.finished.connect(particles.queue_free)


static func _spawn_wood_chips(
	parent: Node3D,
	position: Vector3,
	normal: Vector3,
	direction: Vector3,
	count: int
) -> void:
	for i in count:
		var chip: RigidBody3D = WOOD_CHIP_SCENE.instantiate()
		parent.add_child(chip)
		chip.global_position = position + normal * 0.02
		chip.global_rotation = Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU)
		)
		var impulse := direction * randf_range(3.0, 8.0)
		impulse += normal * randf_range(1.0, 4.0)
		impulse += Vector3(randf_range(-2.0, 2.0), randf_range(0.5, 3.0), randf_range(-2.0, 2.0))
		chip.apply_central_impulse(impulse)
		chip.apply_torque_impulse(Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-2.0, 2.0),
			randf_range(-2.0, 2.0)
		))


static func _get_hole_texture() -> Texture2D:
	if _hole_texture != null:
		return _hole_texture

	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y in range(64):
		for x in range(64):
			var dist := Vector2(x - 32, y - 32).length() / 32.0
			if dist < 0.28:
				image.set_pixel(x, y, Color(0.04, 0.025, 0.015, 1.0))
			elif dist < 1.0:
				var alpha := pow(1.0 - dist, 2.2) * 0.85
				image.set_pixel(x, y, Color(0.08, 0.05, 0.03, alpha))

	_hole_texture = ImageTexture.create_from_image(image)
	return _hole_texture
