extends RefCounted
class_name BlastDamage

const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const BlastRadiusFXScript := preload("res://gameplay/fx/blast_radius_fx.gd")

const DEFAULT_RADIUS := 5.5
const DEFAULT_BLAST_FORCE := 26.0


static func explode_visual(parent: Node, center: Vector3, radius: float = DEFAULT_RADIUS) -> void:
	if parent == null:
		return
	_spawn_explosion_vfx(parent, center, radius)


static func explode(
	center: Vector3,
	shooter: Node3D,
	radius: float = DEFAULT_RADIUS,
	blast_force: float = DEFAULT_BLAST_FORCE
) -> void:
	var tree := shooter.get_tree() if shooter != null else null
	if tree == null:
		return

	var parent := tree.current_scene
	if parent == null:
		parent = tree.root

	_spawn_explosion_vfx(parent, center, radius)

	for group_name: StringName in [&"duel_target", &"target_scorable"]:
		for node in tree.get_nodes_in_group(group_name):
			_try_blast_target(node, center, radius, blast_force, shooter)

	_apply_physics_blast(parent, center, radius, blast_force, shooter)


static func _spawn_explosion_vfx(parent: Node, center: Vector3, radius: float) -> void:
	BlastRadiusFXScript.spawn(parent, center, radius)
	MuzzleFlashFXScript.spawn(parent, center, &"epic_explosion", 0.09)
	MuzzleFlashFXScript.spawn(parent, center + Vector3(0.0, 0.35, 0.0), &"epic_explosion", 0.065)
	MuzzleFlashFXScript.spawn(parent, center, &"symmetrical", 0.04)

	for i in 4:
		var offset := Vector3(
			cos(TAU * float(i) / 4.0) * radius * 0.28,
			randf_range(0.1, 0.45),
			sin(TAU * float(i) / 4.0) * radius * 0.28
		)
		MuzzleFlashFXScript.spawn(parent, center + offset, &"epic_explosion", 0.038)

	SmokePuffFXScript.spawn_burst(parent, center, 10)


static func _try_blast_target(
	target: Node,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("is_defeated") and target.is_defeated():
		return
	if target.has_method("is_duel_defeated") and target.is_duel_defeated():
		return

	var target_point := _get_target_point(target)
	var distance := target_point.distance_to(center)
	if distance > radius:
		return

	var falloff := 1.0 - pow(distance / radius, 1.35)
	var impulse_scale := clampf(falloff * 1.35, 0.15, 1.5)
	var blast_dir := (target_point - center).normalized()
	if blast_dir.length_squared() < 0.0001:
		blast_dir = Vector3.UP

	var hit_info := {
		"position": target_point,
		"normal": -blast_dir,
		"direction": blast_dir,
		"impulse_scale": impulse_scale,
		"explosion": true,
		"blast_force": blast_force * falloff,
		"shooter": shooter,
	}

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
	elif target.has_method("apply_bullet_hit"):
		target.apply_bullet_hit(hit_info)


static func _get_target_point(target: Node) -> Vector3:
	if target is Node3D:
		var node3d := target as Node3D
		if target.has_method("get_bullet_capsule"):
			var capsule: Dictionary = target.get_bullet_capsule()
			return capsule.get("center", node3d.global_position)
		return node3d.global_position
	return Vector3.ZERO


static func _apply_physics_blast(
	parent: Node,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	for child in parent.get_children():
		_push_physics_node(child, center, radius, blast_force, shooter)


static func _push_physics_node(
	node: Node,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	if node is RigidBody3D and node != shooter:
		var body := node as RigidBody3D
		var distance := body.global_position.distance_to(center)
		if distance <= radius:
			var falloff := 1.0 - distance / radius
			var push_dir := (body.global_position - center).normalized()
			if push_dir.length_squared() < 0.0001:
				push_dir = Vector3.UP
			var offset := body.global_position - center
			body.apply_impulse(
				push_dir * blast_force * falloff + Vector3.UP * blast_force * 0.2 * falloff,
				offset
			)

	for child in node.get_children():
		_push_physics_node(child, center, radius, blast_force, shooter)
