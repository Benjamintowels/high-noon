extends RefCounted
class_name ImpactFX

const WOOD_CHIP_SCENE := preload("res://gameplay/shooting/wood_chip.tscn")
const GLASS_SHARD_SCENE := preload("res://gameplay/shooting/glass_shard.tscn")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const MAX_BULLET_HOLES := 64

enum SurfaceKind {
	WOOD,
	PLASTER,
	METAL,
	GENERIC,
}

static var _hole_textures: Dictionary = {}


static func spawn_surface_impact(
	mark_root: Node3D,
	position: Vector3,
	normal: Vector3,
	direction: Vector3,
	kind: SurfaceKind = SurfaceKind.GENERIC
) -> void:
	if mark_root == null:
		return

	_spawn_bullet_hole(mark_root, position, normal, kind)

	match kind:
		SurfaceKind.WOOD:
			_spawn_wood_particles(mark_root, position, normal, direction)
			_spawn_wood_chips(mark_root, position, normal, direction, 4)
		SurfaceKind.PLASTER:
			_spawn_dust_particles(mark_root, position, normal, direction, Color(0.68, 0.6, 0.48, 0.75), 14)
			_spawn_plaster_chips(mark_root, position, normal, direction)
		SurfaceKind.METAL:
			_spawn_spark_particles(mark_root, position, normal, direction, Color(1.0, 0.85, 0.45))
		_:
			_spawn_dust_particles(mark_root, position, normal, direction)

	_play_bullet_hit_sound(mark_root, position)


static func spawn_wood_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	spawn_surface_impact(parent, position, normal, direction, SurfaceKind.WOOD)


static func spawn_plaster_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	spawn_surface_impact(parent, position, normal, direction, SurfaceKind.PLASTER)


static func spawn_metal_impact(parent: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	spawn_surface_impact(parent, position, normal, direction, SurfaceKind.METAL)


static func spawn_glass_shatter(source: Node3D, position: Vector3, normal: Vector3, direction: Vector3) -> void:
	var root := parent_for(source)
	_play_bullet_hit_sound(root, position)
	_spawn_spark_particles(root, position, normal, direction, Color(0.75, 0.92, 1.0), 36)
	for i in range(10):
		var shard: RigidBody3D = GLASS_SHARD_SCENE.instantiate()
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
	spawn_surface_impact(parent, position, normal, direction, SurfaceKind.GENERIC)


static func mark_root_for(collider: Node) -> Node3D:
	var node: Node = collider
	while node != null:
		if node is Node3D:
			var node_name := (node as Node3D).name
			if (
				node_name.begins_with("Build_")
				or node_name.begins_with("Signs")
				or node_name == "PracticeFence"
			):
				return node as Node3D
		node = node.get_parent()

	if collider is Node3D:
		return collider as Node3D
	return null


static func parent_for(source: Node) -> Node:
	if source == null:
		return null
	if source.get_tree() != null and source.get_tree().current_scene != null:
		return source.get_tree().current_scene
	return source.get_parent()


static func _play_bullet_hit_sound(source: Node, position: Vector3) -> void:
	var audio_parent := parent_for(source)
	if audio_parent != null:
		GameAudio.play_bullet_hit(audio_parent, position)


static func _spawn_bullet_hole(parent: Node3D, position: Vector3, normal: Vector3, kind: SurfaceKind) -> void:
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
	var mark_scale := randf_range(0.88, 1.14)
	var mark_size := 0.15 * mark_scale
	decal.size = Vector3(mark_size, 0.24, mark_size)
	decal.texture_albedo = _get_hole_texture(kind)
	decal.modulate = _get_hole_modulate(kind)
	decal.albedo_mix = 1.0
	decal.normal_fade = 0.35
	decal.upper_fade = 0.12
	decal.lower_fade = 0.12
	holes.add_child(decal)
	decal.global_transform = _decal_transform(position, normal)


static func _decal_transform(position: Vector3, normal: Vector3) -> Transform3D:
	var n := normal.normalized()
	var tangent := n.cross(Vector3.UP)
	if tangent.length_squared() < 0.001:
		tangent = n.cross(Vector3.FORWARD)
	tangent = tangent.normalized()
	var bitangent := tangent.cross(n).normalized()
	var basis := Basis(tangent, n, bitangent)
	basis = basis.rotated(n, randf() * TAU)
	return Transform3D(basis, position + n * 0.03)


static func _get_hole_modulate(kind: SurfaceKind) -> Color:
	match kind:
		SurfaceKind.WOOD:
			return Color(0.42, 0.26, 0.14, 1.0)
		SurfaceKind.PLASTER:
			return Color(0.58, 0.52, 0.42, 1.0)
		SurfaceKind.METAL:
			return Color(0.22, 0.22, 0.24, 1.0)
		_:
			return Color(0.45, 0.38, 0.3, 1.0)


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


static func _spawn_plaster_chips(
	parent: Node3D,
	position: Vector3,
	normal: Vector3,
	direction: Vector3
) -> void:
	_spawn_dust_particles(
		parent,
		position,
		normal,
		direction,
		Color(0.74, 0.66, 0.52, 0.9),
		8
	)


static func _spawn_dust_particles(
	parent: Node3D,
	position: Vector3,
	normal: Vector3,
	direction: Vector3,
	tint: Color = Color(0.55, 0.45, 0.32, 0.7),
	count: int = 10
) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = count
	particles.lifetime = 0.35
	particles.explosiveness = 0.9
	particles.direction = (normal + direction * 0.2).normalized()
	particles.spread = 36.0
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0.0, -8.0, 0.0)
	particles.scale_amount_min = 0.06
	particles.scale_amount_max = 0.12
	particles.color = tint
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


static func _get_hole_texture(kind: SurfaceKind) -> Texture2D:
	if _hole_textures.has(kind):
		return _hole_textures[kind]

	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var inner := Color(0.03, 0.02, 0.015, 1.0)
	var ring := Color(0.1, 0.065, 0.04, 0.95)
	var chip := Color(0.16, 0.11, 0.07, 0.55)
	match kind:
		SurfaceKind.PLASTER:
			inner = Color(0.08, 0.07, 0.06, 1.0)
			ring = Color(0.24, 0.2, 0.16, 0.92)
			chip = Color(0.34, 0.28, 0.22, 0.5)
		SurfaceKind.METAL:
			inner = Color(0.02, 0.02, 0.025, 1.0)
			ring = Color(0.12, 0.12, 0.14, 0.9)
			chip = Color(0.22, 0.2, 0.18, 0.45)
		SurfaceKind.GENERIC:
			inner = Color(0.05, 0.04, 0.03, 1.0)
			ring = Color(0.14, 0.11, 0.08, 0.88)
			chip = Color(0.2, 0.16, 0.12, 0.5)

	var center := Vector2(64.0, 64.0)
	for y in range(128):
		for x in range(128):
			var offset := Vector2(x, y) - center
			var angle := atan2(offset.y, offset.x)
			var wobble := 1.0 + sin(angle * 6.0) * 0.07 + cos(angle * 11.0) * 0.05
			var dist := offset.length() / 64.0 * wobble
			var pixel: Color
			if dist < 0.18:
				pixel = inner
			elif dist < 0.34:
				var t := inverse_lerp(0.18, 0.34, dist)
				pixel = inner.lerp(ring, t)
			elif dist < 0.72:
				var t := inverse_lerp(0.34, 0.72, dist)
				pixel = ring.lerp(chip, t)
				pixel.a = lerpf(0.95, 0.0, t)
			elif dist < 1.0:
				var t := inverse_lerp(0.72, 1.0, dist)
				pixel = chip
				pixel.a = lerpf(chip.a, 0.0, t)
			else:
				continue
			image.set_pixel(x, y, pixel)

	var texture := ImageTexture.create_from_image(image)
	_hole_textures[kind] = texture
	return texture
