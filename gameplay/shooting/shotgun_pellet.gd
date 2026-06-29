extends Node3D

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const DROPPED_HAT_SCRIPT := preload("res://characters/groyper/groyper_dropped_hat.gd")

const SPEED := 185.0
const MAX_RANGE := 140.0
const HIT_RADIUS := 0.05

var _origin := Vector3.ZERO
var _base_direction := Vector3.FORWARD
var _spread_offset := Vector3.ZERO
var _spread_max_rad := 0.0
var _spread_distance := 20.0
var _distance := 0.0
var _exclude: Array[RID] = []
var _shooter: Node3D


func setup(
	origin: Vector3,
	base_direction: Vector3,
	spread_offset: Vector3,
	spread_max_deg: float,
	spread_distance: float,
	exclude: Array = [],
	shooter: Node3D = null
) -> void:
	_origin = origin
	_base_direction = base_direction.normalized()
	_spread_offset = spread_offset
	_spread_max_rad = deg_to_rad(spread_max_deg)
	_spread_distance = maxf(spread_distance, 0.1)
	global_position = origin
	_shooter = shooter
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())


func _get_direction() -> Vector3:
	var spread_t := clampf(_distance / _spread_distance, 0.0, 1.0)
	spread_t = spread_t * spread_t
	return (_base_direction + _spread_offset * _spread_max_rad * spread_t).normalized()


func _physics_process(delta: float) -> void:
	var dt := GameTime.physics_delta(delta)
	var direction := _get_direction()
	var from := global_position
	var step := direction * SPEED * dt
	var to := from + step
	var step_length := step.length()

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		queue_free()
		return

	var hit := _cast_hit(space_state, from, direction, to, step_length)
	if not hit.is_empty():
		_resolve_hit(hit, direction)
		return

	global_position = to
	_distance += step_length
	if _distance >= MAX_RANGE:
		queue_free()


func _cast_hit(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	direction: Vector3,
	to: Vector3,
	step_length: float
) -> Dictionary:
	return DuelHitTest.closest_hit(from, [
		_cast_world_ray(space_state, from, to, step_length),
		_cast_duel_targets(from, direction, step_length),
		_cast_hat_props(from, direction, step_length),
	])


func _cast_world_ray(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	max_distance: float
) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	if not _exclude.is_empty():
		query.exclude = _exclude

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	var hit_distance := from.distance_to(hit.position)
	if hit_distance > max_distance + 0.001:
		return {}

	return hit


func _cast_duel_targets(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_target: Node = null

	for target in get_tree().get_nodes_in_group("duel_target"):
		if target == _shooter or not _is_vulnerable_duel_target(target):
			continue
		if not target.has_method("get_bullet_capsule"):
			continue

		var hit_t := BulletHitDamage.cast_duel_target_ray(from, dir, max_distance, target, HIT_RADIUS)
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


func _resolve_hit(hit: Dictionary, direction: Vector3) -> void:
	global_position = hit.position

	var hit_info := {
		"position": hit.position,
		"normal": hit.normal,
		"direction": direction,
		"ray_origin": _origin,
		"collider": hit.collider,
		"speed": SPEED,
	}
	if hit.has("duel_target"):
		hit_info["duel_target"] = hit.duel_target

	var handled := _dispatch_hit(hit_info)
	if not handled:
		var mark_parent: Node3D = null
		var collider: Object = hit_info.get("collider")
		if collider is Node:
			mark_parent = ImpactFXScript.mark_root_for(collider as Node)
		if mark_parent == null:
			var fallback := ImpactFXScript.parent_for(self)
			if fallback is Node3D:
				mark_parent = fallback
		if mark_parent != null:
			ImpactFXScript.spawn_generic_impact(mark_parent, hit.position, hit.normal, direction)

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
