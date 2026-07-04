extends RefCounted
class_name TcMeleeStrike

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const HammerAoeFXScript := preload("res://gameplay/fx/hammer_aoe_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const STRIKE_RADIUS := 4.5
const STRIKE_CENTER_FORWARD := 3.5
const STRIKE_RANGE_SLACK := 1.2
const STRIKE_HEIGHT := 1.4
const GROUND_FX_OFFSET := 0.08
const RANGE := STRIKE_CENTER_FORWARD + STRIKE_RADIUS
const WINDUP_MIN := 0.4
const WINDUP_MAX := 0.9
const STRIKE_FRACTION := 0.55
const COOLDOWN := 2.0
const DAMAGE := 2
const KNOCKBACK_SPEED := 8.0
const KNOCKBACK_UP := 1.2
const PLAYER_KNOCKBACK_SPEED := 5.5
const PLAYER_KNOCKBACK_UP := 0.9
const STUN_DURATION := 1.0
const VICTIM_CAMERA_SHAKE := 1.1
const ATTACKER_CAMERA_SHAKE := 0.55
const NEARBY_SHAKE_RADIUS := 12.0
const NEARBY_SHAKE_STRENGTH := 0.75
const PILLAR_TOPPLE_POWER := 7000


static func get_strike_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	if aim_target != null and is_instance_valid(aim_target) and actor != null:
		var to_target: Vector3 = (aim_target as Node3D).global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			return to_target.normalized()

	if actor != null and actor.has_method("get_punch_facing_direction"):
		var facing: Vector3 = actor.get_punch_facing_direction()
		if facing.length_squared() > 0.0001:
			return facing.normalized()

	var basis := actor.global_transform.basis
	var forward := -basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = basis.x
		forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


static func get_strike_circle_center(actor: Node3D, direction: Vector3) -> Vector3:
	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	else:
		flat_dir = flat_dir.normalized()
	var anchor := actor.global_position + Vector3(0.0, STRIKE_HEIGHT, 0.0)
	return anchor + flat_dir * STRIKE_CENTER_FORWARD


static func is_target_in_strike_circle(
	actor: Node3D,
	target: Node3D,
	direction: Vector3
) -> bool:
	if actor == null or target == null:
		return false
	var center := get_strike_circle_center(actor, direction)
	var target_point := _get_target_strike_point(target)
	var offset := target_point - center
	offset.y = 0.0
	return offset.length_squared() <= _effective_strike_radius_squared()


static func _effective_strike_radius_squared() -> float:
	var radius := STRIKE_RADIUS + STRIKE_RANGE_SLACK
	return radius * radius


static func find_strike_targets(actor: Node3D, direction: Vector3) -> Array[Node]:
	var results: Array[Node] = []
	if actor == null or direction.length_squared() < 0.0001:
		return results

	var tree := actor.get_tree()
	if tree == null:
		return results

	var seen: Dictionary = {}
	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == actor or not (node is Node3D):
				continue
			if not _is_valid_strike_target(actor, node):
				continue
			if not is_target_in_strike_circle(actor, node as Node3D, direction):
				continue
			results.append(node)

	return results


static func apply_strike(attacker: Node, direction: Vector3, aim_target: Node = null) -> bool:
	if attacker == null:
		return false

	var actor := attacker as Node3D
	if actor == null:
		return false

	var strike_dir := _resolve_strike_direction(actor, direction, aim_target)
	if strike_dir.length_squared() < 0.0001:
		return false

	var targets := find_strike_targets(actor, strike_dir)
	var hit_any := false
	for target in targets:
		if _apply_strike_to_target(attacker, target, strike_dir):
			hit_any = true
	return hit_any


static func play_strike_presentation(
	attacker: Node,
	direction: Vector3,
	aim_target: Node = null
) -> void:
	var actor := attacker as Node3D
	if actor == null:
		return

	var strike_dir := _resolve_strike_direction(actor, direction, aim_target)
	var center := get_strike_circle_center(actor, strike_dir)
	var ground_center := Vector3(
		center.x,
		actor.global_position.y + GROUND_FX_OFFSET,
		center.z
	)
	var fx_parent := ImpactFXScript.parent_for(actor)
	HammerAoeFXScript.spawn(fx_parent, ground_center, STRIKE_RADIUS)
	GameAudioScript.play_punch(actor, ground_center)
	_shake_nearby_viewers(actor, NEARBY_SHAKE_RADIUS, NEARBY_SHAKE_STRENGTH)
	_topple_nearby_pillars(actor, ground_center, STRIKE_RADIUS)


static func _topple_nearby_pillars(origin: Node3D, center: Vector3, radius: float) -> void:
	var tree := origin.get_tree()
	if tree == null:
		return
	var radius_sq := (radius + 2.0) * (radius + 2.0)
	for node in tree.get_nodes_in_group(&"PillarFall"):
		if not (node is Node3D):
			continue
		if node.has_method("get") and node.get("fallen") and node.get("fallen"):
			continue
		var offset := (node as Node3D).global_position - center
		offset.y = 0.0
		if offset.length_squared() <= radius_sq and node.has_method("pillar_fall"):
			node.pillar_fall(PILLAR_TOPPLE_POWER)


static func _shake_nearby_viewers(
	origin: Node3D,
	radius: float,
	strength: float
) -> void:
	var tree := origin.get_tree()
	if tree == null:
		return

	var radius_sq := radius * radius
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if not (node is Node3D):
			continue
		var offset := (node as Node3D).global_position - origin.global_position
		offset.y = 0.0
		var dist_sq := offset.length_squared()
		if dist_sq > radius_sq:
			continue
		if not node.has_method("apply_camera_shake"):
			continue
		var falloff := 1.0 - sqrt(dist_sq) / radius * 0.45
		node.apply_camera_shake(strength * falloff)


static func _apply_strike_to_target(
	attacker: Node,
	target: Node,
	direction: Vector3
) -> bool:
	if not _is_valid_strike_target(attacker, target):
		return false

	var hit_position: Vector3 = _get_target_strike_point(target as Node3D)
	var knockback_speed := KNOCKBACK_SPEED
	var knockback_up := KNOCKBACK_UP
	if target.is_in_group(&"overworld_player"):
		knockback_speed = PLAYER_KNOCKBACK_SPEED
		knockback_up = PLAYER_KNOCKBACK_UP
	var hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"damage": DAMAGE,
		"knockback_speed": knockback_speed,
		"knockback_up": knockback_up,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"hammer_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			MeleeHitFXScript.play(attacker, target, hit_position, direction.normalized())
			GameAudioScript.play_punch(attacker, hit_position)
			return true
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		MeleeHitFXScript.play(attacker, target, hit_position, direction.normalized())
		GameAudioScript.play_punch(attacker, hit_position)
		return true
	return false


static func _resolve_strike_direction(
	actor: Node3D,
	direction: Vector3,
	aim_target: Node
) -> Vector3:
	if direction.length_squared() > 0.0001:
		var flat := direction
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			return flat.normalized()
	return get_strike_direction(actor, aim_target)


static func _is_valid_strike_target(attacker: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == attacker:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if attacker.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(attacker, target):
			return false
	if not target.has_method("receive_bullet_hit"):
		return false
	return true


static func _get_target_strike_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.0, 0.0))
	return target.global_position + Vector3(0.0, 1.0, 0.0)
