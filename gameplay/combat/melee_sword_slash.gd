extends RefCounted
class_name MeleeSwordSlash

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const RANGE := 3.1
const WINDUP_DURATION := 0.18
const STRIKE_TIME := 0.34
const COOLDOWN := 1.35
const DAMAGE := 1
const KNOCKBACK_SPEED := 7.5
const KNOCKBACK_UP := 1.1
const STUN_DURATION := 0.85
const ARC_DOT_MIN := 0.15
const RANGE_SLACK := 0.85


static func get_strike_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	if aim_target != null and is_instance_valid(aim_target):
		var to_target: Vector3 = aim_target.global_position - actor.global_position
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


static func find_strike_target(actor: Node3D, direction: Vector3) -> Node:
	if actor == null or direction.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var slash_dir := direction.normalized()
	var seen: Dictionary = {}

	for group_name: StringName in [&"cave_enemy", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == actor or not (node is Node3D):
				continue
			if not _is_valid_strike_target(actor, node):
				continue

			var target := node as Node3D
			var distance_sq := _flat_distance_squared_to_target(actor, target)
			if distance_sq > _max_range_squared() or distance_sq < 0.0001:
				continue

			var flat_dir := _flat_direction_to_target(actor, target)
			if flat_dir.dot(slash_dir) < ARC_DOT_MIN:
				continue

			if distance_sq < best_score:
				best_score = distance_sq
				best_target = target

	return best_target


static func apply_strike(attacker: Node, direction: Vector3, explicit_target: Node = null) -> bool:
	if attacker == null or direction.length_squared() < 0.0001:
		return false

	var target: Node = explicit_target
	if target == null or not is_instance_valid(target):
		target = find_strike_target(attacker as Node3D, direction)
	if target == null or not _is_valid_strike_target(attacker, target):
		return false

	var actor := attacker as Node3D
	var strike_dir := direction
	if actor != null:
		strike_dir = get_strike_direction(actor, target)
	if strike_dir.length_squared() < 0.0001:
		strike_dir = direction
	strike_dir = strike_dir.normalized()

	var hit_position: Vector3 = _get_target_anchor(target as Node3D)
	var hit_info := {
		"position": hit_position,
		"direction": strike_dir,
		"shooter": attacker,
		"damage": DAMAGE,
		"knockback_speed": KNOCKBACK_SPEED,
		"knockback_up": KNOCKBACK_UP,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"sword_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			return true
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		GameAudioScript.play_punch(attacker, hit_position)
		return true

	return false


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


static func _max_range_squared() -> float:
	var max_range := RANGE + RANGE_SLACK
	return max_range * max_range


static func _get_target_anchor(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.05, 0.0))
	return target.global_position + Vector3(0.0, 1.05, 0.0)


static func _flat_direction_to_target(actor: Node3D, target: Node3D) -> Vector3:
	var to_target := _get_target_anchor(target) - actor.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Vector3.FORWARD
	return to_target.normalized()


static func _flat_distance_squared_to_target(actor: Node3D, target: Node3D) -> float:
	var to_target := _get_target_anchor(target) - actor.global_position
	to_target.y = 0.0
	return to_target.length_squared()


static func _is_target_in_range(actor: Node3D, target: Node3D) -> bool:
	return _flat_distance_squared_to_target(actor, target) <= _max_range_squared()
