class_name LassoTautDrag

const TAUT_RATIO := 0.98
const LIVESTOCK_MATCH_SPEED := 24.0
const DEFAULT_NPC_RUN_SPEED := 5.5
const DRAG_SPEED_EPSILON := 0.18
const STOP_SPEED := 0.22
const APPROACH_SPEED_EPSILON := 0.12

const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")


static func store_capture_position(target: Node3D) -> void:
	if target == null:
		return
	target.set_meta(&"lasso_capture_position", target.global_position)


static func get_capture_position(target: Node3D) -> Vector3:
	if target != null and target.has_meta(&"lasso_capture_position"):
		return target.get_meta(&"lasso_capture_position") as Vector3
	if target != null:
		return target.global_position
	return Vector3.ZERO


static func apply(
	body: CharacterBody3D,
	target: Node3D,
	player: Node3D,
	rope_length: float,
	delta: float,
	ragdoll_drag_active: bool = false
) -> Dictionary:
	var leader_vel := get_leader_velocity(player)
	var leader_speed := Vector2(leader_vel.x, leader_vel.z).length()
	var leader_anchor := get_leader_anchor(player)
	var attach := LassoTargetUtils.get_attach_point(target)
	var offset := leader_anchor - attach
	offset.y = 0.0
	var dist := offset.length()

	var to_leader := _flat_dir(offset)
	var away_speed := _away_speed(leader_vel, to_leader)
	var approaching := away_speed < -APPROACH_SPEED_EPSILON

	var max_match := get_max_match_speed(target)
	var livestock := is_livestock(target)
	var slack := dist < rope_length * TAUT_RATIO
	var taut := not slack
	var overstretched := dist > rope_length

	var ragdoll_drag := false
	if taut and not livestock and not approaching:
		if away_speed > max_match + DRAG_SPEED_EPSILON:
			ragdoll_drag = true
		elif ragdoll_drag_active and away_speed > STOP_SPEED:
			ragdoll_drag = true

	var pull_direction := to_leader if away_speed > 0.05 else _flat_dir(leader_vel)
	var pull_velocity := Vector3.ZERO
	var desired := Vector3.ZERO

	if slack or approaching:
		desired = Vector3.ZERO
	elif ragdoll_drag:
		pull_velocity = to_leader * away_speed
	elif away_speed > STOP_SPEED:
		desired = to_leader * away_speed
	elif overstretched:
		var pull := clampf((dist - rope_length) * 4.0, 0.0, max_match)
		desired = to_leader * pull

	if not ragdoll_drag:
		body.velocity.x = desired.x
		body.velocity.z = desired.z

	var actual_speed := away_speed if away_speed > 0.0 else 0.0
	if ragdoll_drag:
		actual_speed = away_speed

	var sprinting := taut and not ragdoll_drag and actual_speed > max_match * 0.55
	if livestock and actual_speed > 1.0:
		sprinting = away_speed > max_match * 0.45
	elif taut and not ragdoll_drag and not livestock and away_speed > STOP_SPEED:
		sprinting = away_speed > max_match * 0.45

	if taut and not ragdoll_drag and not approaching:
		LassoTargetUtils.face_travel_direction(body, leader_vel, player.global_position, delta)

	return {
		"slack": slack,
		"taut": taut,
		"approaching": approaching,
		"dragged": ragdoll_drag,
		"ragdoll_drag": ragdoll_drag,
		"speed": actual_speed,
		"sprinting": sprinting,
		"livestock": livestock,
		"pull_direction": pull_direction,
		"pull_velocity": pull_velocity,
		"rope_distance": dist,
		"away_speed": away_speed,
	}


static func get_leader_velocity(player: Node3D) -> Vector3:
	if player != null and player.has_method("get_lasso_leader_velocity"):
		return player.call("get_lasso_leader_velocity") as Vector3
	if player == null:
		return Vector3.ZERO
	return Vector3(player.velocity.x, 0.0, player.velocity.z)


static func get_leader_anchor(player: Node3D) -> Vector3:
	if player != null and player.has_method("get_lasso_throw_anchor"):
		return player.call("get_lasso_throw_anchor") as Vector3
	if player == null:
		return Vector3.ZERO
	return player.global_position + Vector3(0.0, 1.2, 0.0)


static func get_max_match_speed(target: Node3D) -> float:
	if target != null and target.has_method("get_lasso_max_match_speed"):
		return float(target.call("get_lasso_max_match_speed"))
	if is_livestock(target):
		return LIVESTOCK_MATCH_SPEED
	return DEFAULT_NPC_RUN_SPEED


static func is_livestock(target: Node3D) -> bool:
	return target.is_in_group("stupid_horse") or target.is_in_group("cow")


static func reset_drag_visual(target: Node3D) -> void:
	if target == null:
		return
	if target.has_meta(&"lasso_capture_position"):
		target.remove_meta(&"lasso_capture_position")
	if target.has_meta(&"lasso_taut_length"):
		target.remove_meta(&"lasso_taut_length")
	if target.has_meta(&"lasso_ragdoll_active"):
		target.remove_meta(&"lasso_ragdoll_active")
	if target.has_meta(&"lasso_pull_stopped_timer"):
		target.remove_meta(&"lasso_pull_stopped_timer")


static func _away_speed(leader_vel: Vector3, to_leader: Vector3) -> float:
	return leader_vel.x * to_leader.x + leader_vel.z * to_leader.z


static func _flat_dir(velocity: Vector3) -> Vector3:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length_squared() < 0.0001:
		return Vector3.FORWARD
	return flat.normalized()
