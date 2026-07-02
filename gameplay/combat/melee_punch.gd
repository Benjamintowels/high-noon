extends RefCounted
class_name MeleePunch

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")

const RANGE := 1.95
const KNIFE_RANGE := 2.35
const WINDUP_DURATION := 0.22
const LUNGE_SPEED := 3.2
const KNIFE_LUNGE_SPEED := 3.8
const COOLDOWN := 1.15
const EXIT_BLEND_DURATION := 0.52
const ANIM_FADEOUT := 0.52
const STUN_DURATION := 0.55
const DAMAGE := 1
const KNIFE_DAMAGE := 2
const KNOCKBACK_SPEED := 4.0
const KNIFE_KNOCKBACK_SPEED := 5.2
const KNOCKBACK_UP := 0.9
const PLAYER_HIT_BOUNCE_SPEED := 2.4
const PLAYER_HIT_LUNGE_SPEED := 1.6
const ARC_DOT_MIN := 0.35


static func get_strike_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	if aim_target != null and is_instance_valid(aim_target):
		var to_target: Vector3 = aim_target.global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			return to_target.normalized()

	if actor.has_method("get_punch_facing_direction"):
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


static func attacker_uses_knife(attacker: Node) -> bool:
	return attacker != null \
		and attacker.has_method("uses_knife_melee") \
		and attacker.uses_knife_melee()


static func get_range_for_attacker(attacker: Node) -> float:
	return KNIFE_RANGE if attacker_uses_knife(attacker) else RANGE


static func get_damage_for_attacker(attacker: Node) -> int:
	return KNIFE_DAMAGE if attacker_uses_knife(attacker) else DAMAGE


static func get_knockback_speed_for_attacker(attacker: Node) -> float:
	return KNIFE_KNOCKBACK_SPEED if attacker_uses_knife(attacker) else KNOCKBACK_SPEED


static func get_lunge_speed_for_attacker(attacker: Node) -> float:
	return KNIFE_LUNGE_SPEED if attacker_uses_knife(attacker) else LUNGE_SPEED


static func find_nearest_strike_target(actor: Node3D) -> Node:
	if actor == null:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var seen: Dictionary = {}
	var strike_range := get_range_for_attacker(actor)

	for group_name: StringName in [&"duel_target", &"overworld_player"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == actor or not (node is Node3D):
				continue
			if not _is_valid_strike_target(actor, node):
				continue

			var target := node as Node3D
			var to_target := target.global_position - actor.global_position
			to_target.y = 0.0
			var distance_sq := to_target.length_squared()
			if distance_sq > strike_range * strike_range or distance_sq < 0.0001:
				continue

			if distance_sq < best_score:
				best_score = distance_sq
				best_target = target

	return best_target


static func get_player_strike_direction(actor: Node3D) -> Vector3:
	var nearest := find_nearest_strike_target(actor)
	if nearest != null:
		return get_strike_direction(actor, nearest)
	return get_strike_direction(actor)


static func is_in_range_for_actor(actor: Node3D, target: Node3D) -> bool:
	if actor == null or target == null or not is_instance_valid(target):
		return false
	var to_target := target.global_position - actor.global_position
	to_target.y = 0.0
	var strike_range := get_range_for_attacker(actor)
	return to_target.length_squared() <= strike_range * strike_range


static func find_strike_target(actor: Node3D, direction: Vector3) -> Node:
	if actor == null or direction.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var punch_dir := direction.normalized()
	var seen: Dictionary = {}
	var strike_range := get_range_for_attacker(actor)

	for group_name: StringName in [&"duel_target", &"overworld_player"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == actor or not (node is Node3D):
				continue
			if not _is_valid_strike_target(actor, node):
				continue

			var target := node as Node3D
			var to_target := target.global_position - actor.global_position
			to_target.y = 0.0
			var distance_sq := to_target.length_squared()
			if distance_sq > strike_range * strike_range or distance_sq < 0.0001:
				continue

			var flat_dir := to_target.normalized()
			if flat_dir.dot(punch_dir) < ARC_DOT_MIN:
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

	var hit_position: Vector3 = target.global_position + Vector3(0.0, 1.05, 0.0)
	var use_knife := attacker_uses_knife(attacker)
	var hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"damage": get_damage_for_attacker(attacker),
		"knockback_speed": get_knockback_speed_for_attacker(attacker),
		"knockback_up": KNOCKBACK_UP,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
	}
	if use_knife:
		hit_info["knife_hit"] = true

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		if use_knife:
			BloodSplatterFXScript.spawn_for_hit(target, hit_info)
			GameAudioScript.play_knife_slice(attacker, hit_position)
		else:
			MeleeHitFXScript.play(attacker, target, hit_position, direction)
			GameAudioScript.play_punch(attacker, hit_position)
		return true

	return false


static func apply_knockback(body: CharacterBody3D, direction: Vector3) -> void:
	if body == null:
		return
	var hit_info := {
		"direction": direction,
		"knockback_speed": KNOCKBACK_SPEED,
		"knockback_up": KNOCKBACK_UP,
	}
	BulletHitDamageScript.apply_body_knockback(body, hit_info)


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
