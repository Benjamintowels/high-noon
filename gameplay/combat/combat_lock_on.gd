extends RefCounted
class_name CombatLockOn

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")

const TARGET_GROUPS: Array[StringName] = [&"cave_enemy", &"duel_target"]

const MAX_RANGE := 22.0
const MAX_RANGE_SQ := MAX_RANGE * MAX_RANGE
const BREAK_RANGE := 26.0
const BREAK_RANGE_SQ := BREAK_RANGE * BREAK_RANGE
const AIM_HALF_ANGLE_DEG := 52.0
const AIM_HALF_ANGLE_RAD := deg_to_rad(AIM_HALF_ANGLE_DEG)
const AIM_MIN_DOT := cos(AIM_HALF_ANGLE_RAD)
const ANGLE_WEIGHT := 1.45
const DISTANCE_WEIGHT := 0.5
const ACQUIRE_BLEND_SPEED := 8.5
const TRACK_BLEND_SPEED := 15.0
const AIM_HEIGHT := 1.15
const MAX_ORBIT_YAW := deg_to_rad(78.0)
const LOCK_PITCH_MIN := deg_to_rad(-30.0)
const LOCK_PITCH_MAX := deg_to_rad(40.0)


static func find_best_target(
	actor: Node3D,
	look_forward: Vector3,
	max_range_sq: float = MAX_RANGE_SQ
) -> Node3D:
	if actor == null or look_forward.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var view_dir := look_forward.normalized()
	var best_target: Node3D = null
	var best_score := INF
	var seen: Dictionary = {}

	for group_name: StringName in TARGET_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == actor or not (node is Node3D):
				continue
			if not is_valid_target(actor, node, max_range_sq):
				continue

			var target := node as Node3D
			var to_target := get_aim_point(target) - actor.global_position
			to_target.y = 0.0
			var distance_sq := to_target.length_squared()
			if distance_sq < 0.0001:
				continue

			var flat_dir := to_target / sqrt(distance_sq)
			var dot := view_dir.dot(flat_dir)
			if dot < AIM_MIN_DOT:
				continue

			var angle_score := 1.0 - dot
			var dist_score := sqrt(distance_sq) / MAX_RANGE
			var score := angle_score * ANGLE_WEIGHT + dist_score * DISTANCE_WEIGHT
			if score < best_score:
				best_score = score
				best_target = target

	return best_target


static func is_valid_target(
	actor: Node,
	target: Node,
	max_range_sq: float = BREAK_RANGE_SQ
) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == actor:
		return false
	if not (target is Node3D):
		return false
	if not BulletHitDamageScript.is_vulnerable_to_shooter(actor, target):
		return false
	if actor.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(actor, target):
			return false
	if not target.has_method("receive_bullet_hit"):
		return false

	var actor_3d := actor as Node3D
	var target_3d := target as Node3D
	var to_target := get_aim_point(target_3d) - actor_3d.global_position
	to_target.y = 0.0
	return to_target.length_squared() <= max_range_sq


static func get_aim_point(target: Node3D) -> Vector3:
	if target == null:
		return Vector3.ZERO
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, AIM_HEIGHT, 0.0))
	return target.global_position + Vector3(0.0, AIM_HEIGHT, 0.0)


static func get_flat_facing(actor: Node3D, target: Node3D) -> Vector3:
	if actor == null or target == null:
		return Vector3.ZERO
	var to_target := get_aim_point(target) - actor.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Vector3.ZERO
	return to_target.normalized()


static func compute_focus_angles(
	pivot_pos: Vector3,
	aim_point: Vector3,
	orbit_yaw_offset: float
) -> Vector2:
	var to_target := aim_point - pivot_pos
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	if flat.length_squared() < 0.0001:
		return Vector2(0.0, 0.0)

	# Overworld camera pivot already owns yaw convention — raw atan2 only (no +PI).
	var yaw := atan2(flat.x, flat.z) + orbit_yaw_offset
	var horiz := flat.length()
	var pitch := clampf(-atan2(to_target.y, horiz), LOCK_PITCH_MIN, LOCK_PITCH_MAX)
	return Vector2(yaw, pitch)


static func advance_blend(current: float, active: bool, delta: float) -> float:
	var target := 1.0 if active else 0.0
	var step := 1.0 - exp(-ACQUIRE_BLEND_SPEED * delta)
	return lerpf(current, target, step)


static func track_camera_angles(
	current_yaw: float,
	current_pitch: float,
	target_yaw: float,
	target_pitch: float,
	delta: float
) -> Vector2:
	var step := 1.0 - exp(-TRACK_BLEND_SPEED * delta)
	return Vector2(
		lerp_angle(current_yaw, target_yaw, step),
		lerpf(current_pitch, target_pitch, step)
	)
