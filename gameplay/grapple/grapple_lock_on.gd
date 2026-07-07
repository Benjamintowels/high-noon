extends RefCounted
class_name GrappleLockOn

const GrappleTargetUtils := preload("res://gameplay/grapple/grapple_target_utils.gd")
const CombatLockOnScript := preload("res://gameplay/combat/combat_lock_on.gd")

const MAX_RANGE := 28.0
const AIM_HALF_ANGLE_DEG := 52.0
const AIM_HALF_ANGLE_RAD := deg_to_rad(AIM_HALF_ANGLE_DEG)
const AIM_MIN_DOT := cos(AIM_HALF_ANGLE_RAD)
const ANGLE_WEIGHT := 1.45
const DISTANCE_WEIGHT := 0.5
const ACQUIRE_BLEND_SPEED := 8.5
const TRACK_BLEND_SPEED := 15.0


static func find_best_target(
	actor: Node3D,
	look_forward: Vector3,
	max_range: float = MAX_RANGE
) -> Node3D:
	if actor == null or look_forward.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var view_dir := look_forward.normalized()
	var best_target: Node3D = null
	var best_score := INF

	for node in tree.get_nodes_in_group(GrappleTargetUtils.GRAPPLE_GROUP):
		if not node is Node3D:
			continue

		var anchor := node as Node3D
		if not is_valid_target(actor, anchor, max_range):
			continue

		var to_target := get_aim_point(anchor) - actor.global_position
		var distance := to_target.length()
		if distance < 0.0001:
			continue

		var aim_dir := to_target / distance
		var dot := view_dir.dot(aim_dir)
		if dot < AIM_MIN_DOT:
			continue

		var angle_score := 1.0 - dot
		var dist_score := distance / max_range
		var score := angle_score * ANGLE_WEIGHT + dist_score * DISTANCE_WEIGHT
		if score < best_score:
			best_score = score
			best_target = anchor

	return best_target


static func is_valid_target(
	actor: Node3D,
	target: Node3D,
	max_range: float = MAX_RANGE
) -> bool:
	if actor == null or target == null or not is_instance_valid(target):
		return false
	if target == actor:
		return false
	return actor.global_position.distance_to(get_aim_point(target)) <= max_range


static func get_aim_point(target: Node3D) -> Vector3:
	return GrappleTargetUtils.get_attach_point(target)


static func compute_focus_angles(
	pivot_pos: Vector3,
	aim_point: Vector3,
	orbit_yaw_offset: float,
	pitch_min: float,
	pitch_max: float
) -> Vector2:
	var to_target := aim_point - pivot_pos
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	if flat.length_squared() < 0.0001:
		return Vector2(0.0, 0.0)

	var yaw := atan2(flat.x, flat.z) + orbit_yaw_offset
	var horiz := flat.length()
	var pitch := clampf(-atan2(to_target.y, horiz), pitch_min, pitch_max)
	return Vector2(yaw, pitch)


static func advance_blend(current: float, active: bool, delta: float) -> float:
	return CombatLockOnScript.advance_blend(current, active, delta)


static func track_camera_angles(
	current_yaw: float,
	current_pitch: float,
	target_yaw: float,
	target_pitch: float,
	delta: float
) -> Vector2:
	return CombatLockOnScript.track_camera_angles(
		current_yaw,
		current_pitch,
		target_yaw,
		target_pitch,
		delta
	)
