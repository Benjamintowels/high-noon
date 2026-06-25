extends RefCounted
class_name GroyperRagdollImpulse

## Impulse helpers for duel defeat falls and the future melt weapon ragdoll.


static func compute_fall_impulse(skeleton: Skeleton3D, hit_info: Dictionary) -> Dictionary:
	var hit_position: Vector3 = hit_info.get("position", skeleton.global_position)
	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var impulse_scale := float(hit_info.get("impulse_scale", 1.0))
	var explosion_boost := 2.6 if hit_info.get("explosion", false) else 1.0
	var power := impulse_scale * explosion_boost
	var backward := -skeleton.global_transform.basis.z.normalized()
	var knockback_dir := (backward * 0.85 + shot_direction * 0.45).normalized()

	var torso := _get_torso_center(skeleton)
	var local_hit := skeleton.global_transform.basis.inverse() * (hit_position - torso)
	var hit_offset := hit_position - torso

	var roll_velocity := clampf(local_hit.x * 3.4, -2.6, 2.6)
	var yaw_velocity := clampf(local_hit.z * 2.2, -1.8, 1.8)
	var pitch_velocity := 5.4 + clampf(local_hit.y * 1.8, -0.6, 1.4)

	var roll_torque := hit_offset.cross(shot_direction).dot(skeleton.global_transform.basis.z)
	var yaw_torque := hit_offset.cross(shot_direction).dot(skeleton.global_transform.basis.y)
	roll_velocity += clampf(roll_torque * 2.4, -1.8, 1.8)
	yaw_velocity += clampf(yaw_torque * 1.6, -1.2, 1.2)

	return {
		"pitch_velocity": pitch_velocity * power,
		"roll_velocity": roll_velocity * power,
		"yaw_velocity": yaw_velocity * power,
		"knockback_velocity": (knockback_dir * 1.45 + Vector3(0.0, 0.18, 0.0)) * power,
	}


static func compute_gun_arm_kick(skeleton: Skeleton3D, hit_info: Dictionary) -> Vector3:
	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var side_sign := 1.0 if shot_direction.dot(skeleton.global_transform.basis.x) >= 0.0 else -1.0
	return (
		shot_direction * 0.62
		+ Vector3(-0.28, 0.18 * side_sign, 0.38)
		+ Vector3.UP * 0.12
	)


static func compute_spine_bend(skeleton: Skeleton3D, hit_info: Dictionary) -> Dictionary:
	var hit_position: Vector3 = hit_info.get("position", skeleton.global_position)
	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var torso := _get_torso_center(skeleton)
	var local_hit := skeleton.global_transform.basis.inverse() * (hit_position - torso)
	var side_sign := 1.0 if shot_direction.dot(skeleton.global_transform.basis.x) >= 0.0 else -1.0

	var nx := clampf(local_hit.x / 0.32, -1.0, 1.0)
	var ny := clampf(local_hit.y / 0.42, -1.0, 1.0)
	var nz := clampf(local_hit.z / 0.24, -1.0, 1.0)
	var shot_pitch := clampf(-shot_direction.dot(skeleton.global_transform.basis.y), -0.35, 0.85)

	return {
		"Hips": Vector3(nz * 0.1 + shot_pitch * 0.08, nx * 0.1, nx * 0.06 * side_sign),
		"Spine": Vector3(ny * -0.22 + nz * 0.16 + shot_pitch * 0.12, nx * 0.14, nx * 0.1 * side_sign),
		"Spine01": Vector3(ny * -0.34 + nz * 0.24 + shot_pitch * 0.18, nx * 0.18, nx * 0.12 * side_sign),
		"Spine02": Vector3(ny * -0.44 + nz * 0.3 + shot_pitch * 0.22, nx * 0.22, nx * 0.14 * side_sign),
	}


static func apply_hit_impulse(
	simulator: PhysicalBoneSimulator3D,
	skeleton: Skeleton3D,
	hit_info: Dictionary,
	impulse_scale := 1.0
) -> void:
	if simulator == null or skeleton == null:
		return

	var hit_position: Vector3 = hit_info.get("position", skeleton.global_position)
	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var backward := -skeleton.global_transform.basis.z.normalized()
	var knockback := (backward * 0.75 + shot_direction * 0.55).normalized()
	var fall_impulse := (knockback + Vector3.DOWN * 0.18).normalized()

	var hips := simulator.get_node_or_null("Hips") as PhysicalBone3D
	if hips != null:
		hips.apply_central_impulse(fall_impulse * 4.8 * impulse_scale)
		hips.apply_impulse(
			shot_direction * 1.8 * impulse_scale,
			hit_position - hips.global_position
		)
		return

	var nearest_bone := _find_nearest_physical_bone(simulator, hit_position)
	if nearest_bone != null:
		var offset := hit_position - nearest_bone.global_position
		nearest_bone.apply_impulse(fall_impulse * 3.8 * impulse_scale, offset)


static func _get_torso_center(skeleton: Skeleton3D) -> Vector3:
	var hips_id := skeleton.find_bone("Hips")
	if hips_id >= 0:
		return skeleton.global_transform * skeleton.get_bone_global_pose(hips_id).origin
	return skeleton.global_position + Vector3(0.0, 1.05, 0.0)


static func _find_nearest_physical_bone(
	simulator: PhysicalBoneSimulator3D,
	world_position: Vector3
) -> PhysicalBone3D:
	var nearest: PhysicalBone3D = null
	var nearest_distance := INF

	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var bone := child as PhysicalBone3D
			var distance := bone.global_position.distance_squared_to(world_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = bone

	return nearest
