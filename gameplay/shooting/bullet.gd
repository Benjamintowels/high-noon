extends Node3D

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const DROPPED_HAT_SCRIPT := preload("res://characters/groyper/groyper_dropped_hat.gd")

## Very fast travel — ~25 m in ~0.13 s at default speed. Still visible, dodgeable last-second.
const SPEED := 185.0
const MAX_RANGE := 140.0
const HIT_RADIUS := 0.05

var _origin := Vector3.ZERO
var _direction := Vector3.FORWARD
var _distance := 0.0
var _speed := SPEED
var _exclude: Array[RID] = []
var _shooter: Node3D


func setup(
	origin: Vector3,
	direction: Vector3,
	exclude: Array = [],
	shooter: Node3D = null,
	speed_override: float = -1.0,
	scale_override: float = 1.0
) -> void:
	_origin = origin
	_direction = direction.normalized()
	global_position = origin
	_shooter = shooter
	_speed = speed_override if speed_override > 0.0 else SPEED
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)

	if scale_override != 1.0:
		scale = Vector3.ONE * scale_override


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())


func _physics_process(delta: float) -> void:
	var dt := GameTime.physics_delta(delta)
	var from := global_position
	var step := _direction * _speed * dt
	var to := from + step
	var step_length := step.length()

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		queue_free()
		return

	var hit := _cast_hit(space_state, from, to, step_length)
	if not hit.is_empty():
		_resolve_hit(hit)
		return

	global_position = to
	_distance += step_length
	if _distance >= MAX_RANGE:
		queue_free()


func _cast_hit(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	step_length: float
) -> Dictionary:
	var duel_hit := _cast_duel_targets(from, _direction, step_length)
	if not duel_hit.is_empty():
		return duel_hit

	var hat_hit := _cast_hat_props(from, _direction, step_length)
	if not hat_hit.is_empty():
		return hat_hit

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	if not _exclude.is_empty():
		query.exclude = _exclude

	return space_state.intersect_ray(query)


func _cast_duel_targets(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_target: Node = null

	for target in get_tree().get_nodes_in_group("duel_target"):
		if target == _shooter or not _is_vulnerable_duel_target(target):
			continue
		if not target.has_method("get_bullet_capsule"):
			continue

		var capsule: Dictionary = target.get_bullet_capsule()
		var center: Vector3 = capsule.get("center", Vector3.ZERO)
		var half_height: float = capsule.get("half_height", 0.75)
		var radius: float = capsule.get("radius", 0.5) + HIT_RADIUS
		var axis: Vector3 = capsule.get("axis", Vector3.UP)

		var hit_t := DuelHitTest.raycast_capsule(
			from, dir, max_distance, center, half_height, radius, axis
		)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_target = target

	if best_target == null:
		return {}

	return {
		"position": from + dir * best_t,
		"normal": -dir,
		"collider": best_target,
		"duel_target": best_target,
	}


func _cast_hat_props(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {}

	var hat_hit := DuelHitTest.closest_group_sphere_hit(
		from,
		dir,
		max_distance,
		DROPPED_HAT_SCRIPT.HAT_PROP_GROUP,
		0.18,
		tree
	)
	if hat_hit.is_empty():
		return {}

	return {
		"position": hat_hit.position,
		"normal": hat_hit.normal,
		"collider": hat_hit.collider,
	}


func _is_vulnerable_duel_target(target: Node) -> bool:
	if target == null:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if target.has_method("is_duel_defeated") and target.is_duel_defeated():
		return false
	return target.has_method("receive_bullet_hit")


func _resolve_hit(hit: Dictionary) -> void:
	global_position = hit.position

	var hit_info := {
		"position": hit.position,
		"normal": hit.normal,
		"direction": _direction,
		"collider": hit.collider,
		"speed": _speed,
	}
	if hit.has("duel_target"):
		hit_info["duel_target"] = hit.duel_target

	var handled := _dispatch_hit(hit_info)
	if not handled:
		var parent := ImpactFXScript.parent_for(self)
		if parent is Node3D:
			ImpactFXScript.spawn_generic_impact(parent, hit.position, hit.normal, _direction)

	var scene_root := get_tree().current_scene
	if scene_root != null:
		SHOT_BEAM.spawn(scene_root, _origin, hit.position)

	queue_free()


func _dispatch_hit(hit_info: Dictionary) -> bool:
	hit_info["shooter"] = _shooter
	if hit_info.has("duel_target"):
		var duel_target: Node = hit_info.duel_target
		if duel_target != null and duel_target.has_method("receive_bullet_hit"):
			duel_target.receive_bullet_hit(hit_info)
			return true

	var collider: Object = hit_info.get("collider")
	if collider == null:
		return false

	var node := collider as Node
	while node != null:
		if node.has_method("apply_bullet_hit"):
			node.apply_bullet_hit(hit_info)
			return true
		if node.has_method("receive_bullet_hit"):
			node.receive_bullet_hit(hit_info)
			return true
		node = node.get_parent()

	return false
