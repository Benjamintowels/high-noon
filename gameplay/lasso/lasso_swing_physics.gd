class_name LassoSwingPhysics

const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")
const LassoTautDragScript := preload("res://gameplay/lasso/lasso_taut_drag.gd")

const MIN_ROPE_LENGTH := 2.2
const CLIMB_SPEED := 4.8
const TIGHTEN_PULL_SPEED := 18.0
const ROPE_CENTER_RADIUS := 0.42
const SWING_ATTACH_OFFSET := Vector3(0.0, 1.15, 0.0)
const RELEASE_JUMP_UP := 5.0
const RELEASE_JUMP_HORIZ_MAX := 3.2
const RELEASE_JUMP_CARRY := 0.22
const SWING_GRAVITY := 22.0


static func measure_rope_span(body: Node3D, anchor: Node3D) -> Dictionary:
	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var attach := get_swing_attach(body)
	var offset := attach - anchor_point
	var dist := offset.length()
	var rope_dir := Vector3.ZERO if dist < 0.001 else offset / dist
	return {
		"anchor": anchor_point,
		"attach": attach,
		"dist": dist,
		"rope_dir": rope_dir,
		"angle_deg": rad_to_deg(get_rope_angle_from_vertical(rope_dir)),
	}


static func compute_rope_length(player: Node3D, anchor: Node3D) -> float:
	var leader := get_swing_attach(player)
	var attach := LassoTargetUtils.get_attach_point(anchor)
	return maxf(leader.distance_to(attach), MIN_ROPE_LENGTH)


static func get_player_attach(player: Node3D) -> Vector3:
	return LassoTautDragScript.get_leader_anchor(player)


static func get_swing_attach(player: Node3D) -> Vector3:
	if player != null and player.has_method("get_lasso_swing_attach"):
		return player.call("get_lasso_swing_attach") as Vector3
	return get_player_attach(player)


static func get_rope_angle_from_vertical(rope_dir: Vector3) -> float:
	return acos(clampf(-rope_dir.dot(Vector3.DOWN), -1.0, 1.0))


static func get_rope_body_pitch(rope_dir: Vector3) -> float:
	if rope_dir.length_squared() < 0.0001:
		return 0.0
	return Vector3.DOWN.signed_angle_to(rope_dir.normalized(), Vector3.RIGHT)


static func get_rope_center_distance_h(body: Node3D, anchor: Node3D) -> float:
	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	return Vector2(
		body.global_position.x - anchor_point.x,
		body.global_position.z - anchor_point.z
	).length()


static func is_at_rope_center(body: Node3D, anchor: Node3D) -> bool:
	return get_rope_center_distance_h(body, anchor) <= ROPE_CENTER_RADIUS


static func get_rope_walk_direction(body: Node3D, anchor: Node3D, walk_input: float) -> Vector3:
	if absf(walk_input) < 0.01:
		return Vector3.ZERO

	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var to_center := Vector3(
		anchor_point.x - body.global_position.x,
		0.0,
		anchor_point.z - body.global_position.z
	)
	if to_center.length_squared() < 0.0001:
		return Vector3.ZERO

	to_center = to_center.normalized()
	if walk_input > 0.0:
		return to_center
	return -to_center


static func is_body_near_floor(body: CharacterBody3D) -> bool:
	if body.is_on_floor():
		return true
	var space_state := body.get_world_3d().direct_space_state
	if space_state == null:
		return false
	var from := body.global_position + Vector3(0.0, 0.2, 0.0)
	var to := body.global_position + Vector3(0.0, -1.25, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [body.get_rid()]
	var hit := space_state.intersect_ray(query)
	return not hit.is_empty()


static func clear_swing_state(_body: CharacterBody3D) -> void:
	pass


static func apply_tighten_pull(body: CharacterBody3D, anchor: Node3D, delta: float) -> void:
	if body == null or anchor == null:
		return
	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var attach := get_swing_attach(body)
	var to_anchor := anchor_point - attach
	if to_anchor.length_squared() < 0.01:
		body.velocity = Vector3.ZERO
		return
	body.velocity += to_anchor.normalized() * (TIGHTEN_PULL_SPEED * delta)


static func snap_to_rope_center(body: CharacterBody3D, anchor: Node3D) -> float:
	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	body.global_position.x = anchor_point.x - SWING_ATTACH_OFFSET.x
	body.global_position.z = anchor_point.z - SWING_ATTACH_OFFSET.z
	var attach := get_swing_attach(body)
	return maxf(attach.distance_to(anchor_point), MIN_ROPE_LENGTH)


static func apply_vertical_climb_step(
	body: CharacterBody3D,
	anchor: Node3D,
	rope_length: float,
	max_rope_length: float,
	delta: float,
	climb_input: float
) -> float:
	if body == null or anchor == null or delta <= 0.0001:
		return rope_length

	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var new_length := rope_length - climb_input * CLIMB_SPEED * delta
	new_length = clampf(new_length, MIN_ROPE_LENGTH, maxf(max_rope_length, MIN_ROPE_LENGTH))
	var desired_attach := anchor_point + Vector3(0.0, -new_length, 0.0)
	body.global_position = desired_attach - SWING_ATTACH_OFFSET
	body.velocity = Vector3.ZERO
	return new_length


static func enforce_rope_constraint(
	body: CharacterBody3D,
	anchor: Node3D,
	rope_length: float
) -> void:
	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var attach := get_swing_attach(body)
	var snapped_attach := _snap_attach_to_rope(anchor_point, attach, rope_length)
	body.global_position = snapped_attach - SWING_ATTACH_OFFSET


static func enforce_ground_rope_tether(
	body: CharacterBody3D,
	anchor: Node3D,
	rope_length: float
) -> void:
	if body == null or anchor == null:
		return

	var anchor_point := LassoTargetUtils.get_attach_point(anchor)
	var attach := get_swing_attach(body)
	var offset := attach - anchor_point
	var dist := offset.length()
	if dist <= rope_length + 0.02:
		return

	var rope_dir := offset / dist
	var corrected_attach := anchor_point + rope_dir * rope_length
	body.global_position = corrected_attach - SWING_ATTACH_OFFSET

	var radial_out := body.velocity.dot(rope_dir)
	if radial_out > 0.0:
		body.velocity -= rope_dir * radial_out


static func compute_release_jump_velocity(
	body: CharacterBody3D,
	move_dir: Vector3,
	run_speed: float
) -> Vector3:
	var horizontal := Vector3(body.velocity.x, 0.0, body.velocity.z) * RELEASE_JUMP_CARRY
	if move_dir.length_squared() > 0.0001:
		horizontal += move_dir.normalized() * run_speed * 0.18

	if horizontal.length_squared() > 0.0001:
		horizontal = horizontal.normalized() * minf(horizontal.length(), RELEASE_JUMP_HORIZ_MAX)
	return Vector3(horizontal.x, RELEASE_JUMP_UP, horizontal.z)


static func _snap_attach_to_rope(anchor_point: Vector3, attach: Vector3, rope_length: float) -> Vector3:
	var offset := attach - anchor_point
	if offset.length_squared() < 0.0001:
		return anchor_point + Vector3(0.0, -rope_length, 0.0)
	return anchor_point + offset.normalized() * rope_length
