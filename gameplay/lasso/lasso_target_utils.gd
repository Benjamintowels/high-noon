class_name LassoTargetUtils

const LASSOABLE_GROUPS: Array[StringName] = [
	&"town_npc",
	&"town_groyper",
	&"town_sheriff",
	&"stupid_horse",
	&"cow",
]

const CAPTURE_QUERY_RADIUS := 1.15
const DEFAULT_DRAG_SPEED := 2.8
const DEFAULT_ROPE_LENGTH := 8.5

const LassoTautDragScript := preload("res://gameplay/lasso/lasso_taut_drag.gd")


static func is_lassoable(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.is_in_group("overworld_player") or node.is_in_group("player"):
		return false
	if node.has_method("is_lassoable"):
		return bool(node.call("is_lassoable"))
	for group_name: StringName in LASSOABLE_GROUPS:
		if node.is_in_group(group_name):
			return true
	return false


static func get_attach_point(target: Node3D) -> Vector3:
	if target.has_method("get_lasso_attach_point"):
		return target.call("get_lasso_attach_point") as Vector3
	return target.global_position + Vector3(0.0, 1.0, 0.0)


static func get_loose_attach_point(target: Node3D) -> Vector3:
	if target.has_method("get_lasso_loose_attach_point"):
		return target.call("get_lasso_loose_attach_point") as Vector3
	return target.global_position + Vector3(0.0, 0.1, 0.0)


static func get_drag_speed(target: Node3D) -> float:
	if target.is_in_group("cow"):
		return 1.6
	if target.is_in_group("stupid_horse"):
		return 2.2
	return DEFAULT_DRAG_SPEED


static func find_lasso_target_at(world: World3D, position: Vector3) -> Node3D:
	if world == null:
		return null

	var space_state := world.direct_space_state
	if space_state == null:
		return null

	var shape := SphereShape3D.new()
	shape.radius = CAPTURE_QUERY_RADIUS
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, position + Vector3(0.0, 0.5, 0.0))
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = 1

	var best: Node3D = null
	var best_dist_sq := INF
	for hit: Dictionary in space_state.intersect_shape(params, 24):
		var collider: Object = hit.get("collider")
		if collider is Node3D:
			var node := collider as Node3D
			if not is_lassoable(node):
				continue
			var dist_sq := node.global_position.distance_squared_to(position)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = node

	return best


const MIN_TAUT_ROPE_LENGTH := 1.2
const MAX_TAUT_ROPE_LENGTH := 15.0


static func compute_taut_rope_length(player: Node3D, target: Node3D) -> float:
	var leader_anchor := LassoTautDragScript.get_leader_anchor(player)
	var attach := get_attach_point(target)
	var offset := Vector2(leader_anchor.x - attach.x, leader_anchor.z - attach.z)
	return clampf(offset.length(), MIN_TAUT_ROPE_LENGTH, MAX_TAUT_ROPE_LENGTH)


static func begin_capture(target: Node3D, player: Node3D, rope_length: float = DEFAULT_ROPE_LENGTH, ring: LassoRing = null) -> void:
	LassoTautDragScript.store_capture_position(target)
	if target.has_method("begin_lasso_capture"):
		target.call("begin_lasso_capture", player, rope_length, ring)


static func end_capture(target: Node3D) -> void:
	if target != null and is_instance_valid(target):
		const LassoHumanoidDragScript := preload("res://gameplay/lasso/lasso_humanoid_drag.gd")
		if target.is_in_group("town_npc") or target.is_in_group("town_groyper") or target.is_in_group("town_sheriff"):
			var ring: LassoRing = target.get("_lasso_ring")
			LassoHumanoidDragScript.cleanup(target, ring)
		LassoTautDragScript.reset_drag_visual(target)
		if target.has_method("end_lasso_capture"):
			target.call("end_lasso_capture")


static func apply_drag(target: Node3D, player: Node3D, delta: float) -> void:
	if target == null or player == null:
		return
	if not target is CharacterBody3D:
		return
	if target.has_method("apply_lasso_drag"):
		target.call("apply_lasso_drag", player, delta)
		return
	apply_taut_drag(target as CharacterBody3D, target, player, DEFAULT_ROPE_LENGTH, delta)


static func apply_taut_drag(
	body: CharacterBody3D,
	target: Node3D,
	player: Node3D,
	rope_length: float,
	delta: float
) -> Dictionary:
	return LassoTautDragScript.apply(body, target, player, rope_length, delta)


static func face_horizontally(body: CharacterBody3D, look_pos: Vector3, delta: float) -> void:
	_face_horizontally(body, look_pos, delta)


static func face_travel_direction(
	body: CharacterBody3D,
	leader_vel: Vector3,
	player_pos: Vector3,
	delta: float
) -> void:
	var flat_vel := Vector3(leader_vel.x, 0.0, leader_vel.z)
	if flat_vel.length_squared() > 0.04:
		face_movement_direction(body, flat_vel, delta)
	else:
		_face_horizontally(body, player_pos, delta)


static func face_movement_direction(body: CharacterBody3D, direction: Vector3, delta: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	if body.has_method("_face_position"):
		body.call("_face_position", body.global_position + flat.normalized(), delta)
		return
	var facing := body.get_node_or_null("Facing") as Node3D
	var target_yaw := atan2(flat.x, flat.z)
	if facing != null:
		facing.rotation.y = lerp_angle(facing.rotation.y, target_yaw, 8.0 * delta)
	elif body.has_method("_face_position"):
		body.call("_face_position", body.global_position + flat.normalized(), delta)


static func _face_horizontally(body: CharacterBody3D, look_pos: Vector3, delta: float) -> void:
	var facing := body.get_node_or_null("Facing") as Node3D
	var to_target := look_pos - body.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := atan2(to_target.x, to_target.z)
	if facing != null:
		facing.rotation.y = lerp_angle(facing.rotation.y, target_yaw, 8.0 * delta)
	elif body.has_method("_face_position"):
		body.call("_face_position", look_pos, delta)
