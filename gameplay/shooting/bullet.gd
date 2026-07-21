extends Node3D

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const DROPPED_HAT_SCRIPT := preload("res://characters/groyper/groyper_dropped_hat.gd")
const ElementalAttackFX := preload("res://gameplay/fx/elemental_attack_fx.gd")
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const LightningGemCombat := preload("res://gameplay/combat/lightning_gem_combat.gd")
const FireGemCombat := preload("res://gameplay/combat/fire_gem_combat.gd")
const IceGemCombat := preload("res://gameplay/combat/ice_gem_combat.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const TerrainGrassFireScript := preload("res://gameplay/world/terrain_grass_fire.gd")

## Very fast travel — ~25 m in ~0.13 s at default speed. Still visible, dodgeable last-second.
const SPEED := 185.0
const MAX_RANGE := 140.0
const HIT_RADIUS := 0.05
## Nudge past a pierced target so the next cast does not re-hit the same capsule.
const PIERCE_ADVANCE := 0.08
## Root-position prefilter radius: covers capsule center offset + half height
## + radius for the largest targets (mounted riders, horses).
const TARGET_PREFILTER_MARGIN := 5.0

var _origin := Vector3.ZERO
var _direction := Vector3.FORWARD
var _distance := 0.0
var _speed := SPEED
var _exclude: Array[RID] = []
var _shooter: Node3D
var _boss_reflected := false
var _body_damage := BulletHitDamage.BODY_DAMAGE
var _head_damage := BulletHitDamage.HEAD_DAMAGE
var _chip_damage := 0.0
var _pierce_enabled := false
var _pierce_damage_falloff := 1
## Instance IDs already pierced this shot (duel/horse casts ignore RID excludes).
var _pierced_ids: Dictionary = {}
## Set at spawn when the firing weapon has an elemental trail gem (e.g. Lightning).
var elemental_trail := false
var weapon_id: int = -1


func setup(
	origin: Vector3,
	direction: Vector3,
	exclude: Array = [],
	shooter: Node3D = null,
	speed_override: float = -1.0,
	scale_override: float = 1.0,
	body_damage: int = -1,
	head_damage: int = -1,
	chip_damage: float = -1.0,
	pierce: bool = false,
	pierce_damage_falloff: int = 1
) -> void:
	_origin = origin
	_direction = direction.normalized()
	global_position = origin
	_shooter = shooter
	_speed = speed_override if speed_override > 0.0 else SPEED
	if body_damage >= 0:
		_body_damage = body_damage
	if head_damage >= 0:
		_head_damage = head_damage
	if chip_damage >= 0.0:
		_chip_damage = chip_damage
	_pierce_enabled = pierce
	_pierce_damage_falloff = maxi(0, pierce_damage_falloff)
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


## Apply remaining pierce / chip stats from the firing weapon after weapon_id is set.
func configure_from_weapon(wid: int) -> void:
	weapon_id = wid
	if wid < 0:
		return
	var id: Variant = wid as GroyperWeaponsScript.Id
	_chip_damage = GroyperWeaponsScript.get_chip_damage(id)
	_pierce_enabled = GroyperWeaponsScript.can_pierce(id)
	_pierce_damage_falloff = GroyperWeaponsScript.get_pierce_damage_falloff(id)
	if _chip_damage > 0.0:
		_body_damage = 0
		_head_damage = 0
	else:
		_body_damage = GroyperWeaponsScript.get_body_damage(id)
		_head_damage = GroyperWeaponsScript.get_head_damage(id)


func mark_as_boss_reflected() -> void:
	_boss_reflected = true


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
	var world_hit := _cast_world_ray(space_state, from, to, step_length)
	var duel_hit := _cast_duel_targets(from, _direction, step_length)
	var horse_hit := _cast_horse_bodies(from, _direction, step_length)
	var hat_hit := _cast_hat_props(from, _direction, step_length)
	var equestrian_hit := BulletHitDamage.resolve_equestrian_hit(
		from,
		_direction,
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
		if _pierced_ids.has(target.get_instance_id()):
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


func _resolve_hit(hit: Dictionary) -> void:
	global_position = hit.position

	var hit_info := {
		"position": hit.position,
		"normal": hit.normal,
		"direction": _direction,
		"ray_origin": _origin,
		"collider": hit.collider,
		"speed": _speed,
		"projectile_kind": &"bullet",
		"projectile_speed": _speed,
		"weapon_id": weapon_id,
	}
	if _chip_damage > 0.0:
		hit_info["damage"] = 0
		hit_info["chip_damage"] = _chip_damage
	else:
		hit_info["body_damage"] = _body_damage
		hit_info["head_damage"] = _head_damage
	if _boss_reflected:
		hit_info["reflected_hit"] = true
		hit_info["boss_reflected"] = true
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
			ImpactFXScript.spawn_generic_impact(mark_parent, hit.position, hit.normal, _direction)

	var scene_root := get_tree().current_scene
	if scene_root != null:
		SHOT_BEAM.spawn(scene_root, _origin, hit.position)
		if elemental_trail:
			ElementalAttackFX.spawn_trail_dust(
				scene_root,
				_origin,
				hit.position,
				ElementalAttackFX.get_trail_color(weapon_id, _shooter)
			)
			if ElementalAttackFX.get_active_trail_gem(weapon_id, _shooter) == ElementalGems.FIRE:
				TerrainGrassFireScript.try_ignite_fire_trail(
					get_tree(),
					_origin,
					hit.position,
					_shooter
				)

	if _try_continue_pierce(hit, handled):
		return

	queue_free()


func _try_continue_pierce(hit: Dictionary, handled: bool) -> bool:
	if not _pierce_enabled or not handled or _chip_damage > 0.0:
		return false
	if maxi(_body_damage, _head_damage) <= _pierce_damage_falloff:
		return false

	_body_damage = maxi(0, _body_damage - _pierce_damage_falloff)
	_head_damage = maxi(0, _head_damage - _pierce_damage_falloff)
	if maxi(_body_damage, _head_damage) <= 0:
		return false

	_exclude_pierce_target(hit)
	var advance := _direction * PIERCE_ADVANCE
	global_position = hit.position + advance
	_origin = global_position
	_distance += hit.position.distance_to(_origin)
	return true


func _exclude_pierce_target(hit: Dictionary) -> void:
	var target: Node = null
	if hit.has("duel_target"):
		target = hit.duel_target as Node
	elif hit.has("horse_target"):
		target = hit.horse_target as Node
	else:
		target = hit.get("collider") as Node
	if target == null:
		return
	_pierced_ids[target.get_instance_id()] = true
	if target is Node3D:
		_add_exclude_node(target as Node3D)


func _cast_horse_bodies(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_horse: Node = null

	var reach := max_distance + TARGET_PREFILTER_MARGIN
	var reach_sq := reach * reach
	for node in get_tree().get_nodes_in_group("stupid_horse"):
		if not is_instance_valid(node):
			continue
		if _pierced_ids.has(node.get_instance_id()):
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


func _dispatch_hit(hit_info: Dictionary) -> bool:
	hit_info["shooter"] = _shooter
	if hit_info.has("duel_target"):
		var duel_target: Node = hit_info.duel_target
		if duel_target != null and duel_target.has_method("receive_bullet_hit"):
			duel_target.receive_bullet_hit(hit_info)
			_try_elemental_procs(duel_target)
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
			# Hitboxes (StaticBody3D) own apply_bullet_hit and forward to the
			# actor — elemental procs must resolve the actor, not stop at the hitbox.
			_try_elemental_procs(_resolve_elemental_combatant(node))
			return true
		if node.has_method("receive_bullet_hit"):
			node.receive_bullet_hit(hit_info)
			_try_elemental_procs(node)
			return true
		node = node.get_parent()

	return false


func _resolve_elemental_combatant(from_node: Node) -> Node:
	var node := from_node
	while node != null:
		if node.has_method("apply_fire_damage"):
			return node
		if node is CharacterBody3D and node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	node = from_node
	while node != null:
		if node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	return from_node


func _try_elemental_procs(target: Node) -> void:
	if _shooter == null or target == null:
		return
	LightningGemCombat.try_proc_on_hit(_shooter, target, weapon_id)
	FireGemCombat.try_proc_on_hit(_shooter, target, weapon_id)
	IceGemCombat.try_proc_on_hit(_shooter, target, weapon_id)
