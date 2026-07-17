extends Node3D

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")
const DROPPED_HAT_SCRIPT := preload("res://characters/groyper/groyper_dropped_hat.gd")

const SPEED := 165.0
const DEFAULT_MAX_RANGE := 18.0
const HIT_RADIUS := 0.05
## Root-position prefilter radius: covers capsule center offset + half height
## + radius for the largest targets (mounted riders, horses).
const TARGET_PREFILTER_MARGIN := 5.0
const PELLET_KNOCKBACK_SPEED := 1.8
const PELLET_KNOCKBACK_UP := 0.55

var _origin := Vector3.ZERO
var _direction := Vector3.FORWARD
var _distance := 0.0
var _max_range := DEFAULT_MAX_RANGE
var _exclude: Array[RID] = []
var _shooter: Node3D
var _weapon_id: int = -1
var _chip_damage := 0.25


func setup(
	origin: Vector3,
	base_direction: Vector3,
	spread_offset: Vector3,
	spread_max_deg: float,
	_spread_distance: float,
	exclude: Array = [],
	shooter: Node3D = null,
	weapon_id: int = -1,
	max_range: float = -1.0,
	chip_damage: float = -1.0
) -> void:
	_origin = origin
	var forward := base_direction.normalized()
	# Immediate cone spread — pellets leave the muzzle already fanned out.
	_direction = (forward + spread_offset * deg_to_rad(spread_max_deg)).normalized()
	global_position = origin
	_shooter = shooter
	_weapon_id = weapon_id
	_max_range = max_range if max_range > 0.0 else DEFAULT_MAX_RANGE
	_chip_damage = chip_damage if chip_damage > 0.0 else 0.25
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


func _physics_process(delta: float) -> void:
	var dt := GameTime.physics_delta(delta)
	var from := global_position
	var step := _direction * SPEED * dt
	var to := from + step
	var step_length := step.length()

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		queue_free()
		return

	var hit := _cast_hit(space_state, from, _direction, to, step_length)
	if not hit.is_empty():
		_resolve_hit(hit, _direction)
		return

	global_position = to
	_distance += step_length
	if _distance >= _max_range:
		queue_free()


func _cast_hit(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	direction: Vector3,
	to: Vector3,
	step_length: float
) -> Dictionary:
	var world_hit := _cast_world_ray(space_state, from, to, step_length)
	var duel_hit := _cast_duel_targets(from, direction, step_length)
	var horse_hit := _cast_horse_bodies(from, direction, step_length)
	var hat_hit := _cast_hat_props(from, direction, step_length)
	var equestrian_hit := BulletHitDamage.resolve_equestrian_hit(
		from,
		direction,
		step_length,
		world_hit,
		duel_hit,
		horse_hit,
		get_tree(),
		_shooter
	)
	if not equestrian_hit.is_empty():
		return equestrian_hit
	return DuelHitTest.closest_hit(from, [world_hit, duel_hit, hat_hit])


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

	var reach := max_distance + TARGET_PREFILTER_MARGIN
	var reach_sq := reach * reach
	for target in get_tree().get_nodes_in_group("duel_target"):
		var target_3d := target as Node3D
		if target_3d != null and target_3d.global_position.distance_squared_to(from) > reach_sq:
			continue
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
	return BulletHitDamage.is_vulnerable_to_shooter(_shooter, target)


func _cast_horse_bodies(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_horse: Node = null

	var reach := max_distance + TARGET_PREFILTER_MARGIN
	var reach_sq := reach * reach
	for node in get_tree().get_nodes_in_group("stupid_horse"):
		if not is_instance_valid(node):
			continue
		var node_3d := node as Node3D
		if node_3d != null and node_3d.global_position.distance_squared_to(from) > reach_sq:
			continue
		var hit_t := BulletHitDamage.cast_horse_body_ray(from, dir, max_distance, node, HIT_RADIUS)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_horse = node

	if best_horse == null:
		return {}

	return {
		"position": from + dir * best_t,
		"normal": -dir,
		"collider": best_horse,
		"horse_target": best_horse,
	}


func _chip_for_hit(hit_position: Vector3) -> float:
	var distance := _origin.distance_to(hit_position)
	if _weapon_id >= 0:
		return GroyperWeapons.pellet_chip_at_distance(_weapon_id as GroyperWeapons.Id, distance)
	# Falloff without a weapon id (legacy callers).
	var start := 3.5
	var end := 11.0
	if distance <= start:
		return _chip_damage
	if distance >= end:
		return _chip_damage * 0.04
	var t := (distance - start) / maxf(end - start, 0.001)
	return _chip_damage * lerpf(1.0, 0.04, t * t)


func _resolve_hit(hit: Dictionary, direction: Vector3) -> void:
	global_position = hit.position

	var hit_info := {
		"position": hit.position,
		"normal": hit.normal,
		"direction": direction,
		"ray_origin": _origin,
		"collider": hit.collider,
		"speed": SPEED,
		"damage": 0,
		"chip_damage": _chip_for_hit(hit.position),
		"knockback_speed": PELLET_KNOCKBACK_SPEED,
		"knockback_up": PELLET_KNOCKBACK_UP,
		"pellet_hit": true,
	}
	if hit.has("duel_target"):
		hit_info["duel_target"] = hit.duel_target
	if hit.has("horse_target"):
		hit_info["horse_target"] = hit.horse_target

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

	if hit_info.has("horse_target"):
		var horse_target: Node = hit_info.horse_target
		if horse_target != null and horse_target.has_method("apply_bullet_hit"):
			horse_target.apply_bullet_hit(hit_info)
			return true

	var collider: Object = hit_info.get("collider")
	var horse := BulletHitDamage.find_horse_from_collider(collider)
	if horse != null and horse.has_method("apply_bullet_hit"):
		horse.apply_bullet_hit(hit_info)
		return true

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
