extends RefCounted
class_name UndeadMeleeStrike

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")

const RANGE := 3.1
const SPIN_RANGE := 3.6
const RANGE_SLACK := 0.85
const ARC_DOT_MIN := 0.15
## Follow-forward telegraph disc (slash / charged). Offset + radius ≈ RANGE.
const TELEGRAPH_FORWARD := 1.6
const TELEGRAPH_RADIUS := 1.4
## Spin telegraph is nearly centered on the actor.
const SPIN_TELEGRAPH_FORWARD := 0.15
const SPIN_TELEGRAPH_RADIUS := 3.6
const WINDUP_MIN := 0.35
const WINDUP_MAX := 0.95
const SPRINT_WINDUP_MIN := 0.2
const SPRINT_WINDUP_MAX := 0.45
const COOLDOWN := 0.675
const SPRINT_COOLDOWN := 0.9
const DAMAGE := 1
const SWORD_SLASH_STRIKE_FRACTION := 0.42
const CHARGED_UPWARD_STRIKE_FRACTION := 0.55
const SPRINT_SPIN_STRIKE_FRACTION := 0.48


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


static func apply_strike(
	attacker: Node,
	direction: Vector3,
	aim_target: Node = null,
	spin_attack: bool = false
) -> bool:
	if attacker == null:
		return false

	var actor := attacker as Node3D
	if actor == null:
		return false

	var strike_dir := _resolve_strike_direction(actor, direction, aim_target)
	if strike_dir.length_squared() < 0.0001:
		return false

	if spin_attack:
		return _apply_spin_strike(attacker, strike_dir)

	var target := _find_best_strike_target(actor, strike_dir, RANGE)
	if target == null:
		return false
	return _apply_strike_to_target(attacker, target, strike_dir)


static func play_strike_presentation(
	attacker: Node,
	direction: Vector3,
	aim_target: Node = null,
	attack_kind: StringName = &"sword_slash"
) -> void:
	var actor := attacker as Node3D
	if actor == null:
		return

	var strike_dir := _resolve_strike_direction(actor, direction, aim_target)
	match attack_kind:
		&"charged_upward":
			SwordCrescentFXScript.spawn_vertical_preview(actor, strike_dir, RANGE)
		&"sprint_spin":
			SwordCrescentFXScript.spawn_spin_preview(actor, strike_dir, SPIN_RANGE)
		_:
			SwordCrescentFXScript.spawn_preview(actor, strike_dir, RANGE)


static func _resolve_strike_direction(
	actor: Node3D,
	direction: Vector3,
	aim_target: Node = null
) -> Vector3:
	if direction.length_squared() > 0.0001:
		var flat_dir := direction
		flat_dir.y = 0.0
		if flat_dir.length_squared() > 0.0001:
			return flat_dir.normalized()
	return get_strike_direction(actor, aim_target)


static func _apply_spin_strike(attacker: Node, direction: Vector3) -> bool:
	var actor := attacker as Node3D
	if actor == null:
		return false

	var hit_any := false
	for target in _find_spin_targets(actor):
		if _apply_strike_to_target(attacker, target, direction):
			hit_any = true
	return hit_any


static func _find_spin_targets(actor: Node3D) -> Array[Node]:
	var results: Array[Node] = []
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
			if _flat_distance_squared_to_target(actor, node as Node3D) > _max_range_squared(SPIN_RANGE):
				continue
			results.append(node)

	return results


static func _find_best_strike_target(
	actor: Node3D,
	direction: Vector3,
	strike_range: float
) -> Node:
	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var slash_dir := direction.normalized()
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

			var target := node as Node3D
			var distance_sq := _flat_distance_squared_to_target(actor, target)
			if distance_sq > _max_range_squared(strike_range) or distance_sq < 0.0001:
				continue

			var flat_dir := _flat_direction_to_target(actor, target)
			if flat_dir.dot(slash_dir) < ARC_DOT_MIN:
				continue

			if distance_sq < best_score:
				best_score = distance_sq
				best_target = target

	return best_target


static func _apply_strike_to_target(
	attacker: Node,
	target: Node,
	direction: Vector3
) -> bool:
	if not _is_valid_strike_target(attacker, target):
		return false

	var hit_position: Vector3 = _get_target_anchor(target as Node3D)
	var hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"damage": DAMAGE,
		"knockback_speed": 0.0,
		"knockback_up": 0.0,
		"melee": true,
		"force_knockback": false,
		"melee_stun_duration": 0.0,
		"sword_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			_play_hit_fx(attacker, target, hit_position, direction.normalized())
			GameAudioScript.play_punch(attacker, hit_position)
			return true
		_play_hit_fx(attacker, target, hit_position, direction.normalized())
		GameAudioScript.play_punch(attacker, hit_position)
		return true

	return false


static func _play_hit_fx(
	attacker: Node,
	target: Node,
	hit_position: Vector3,
	direction: Vector3
) -> void:
	MeleeHitFXScript.play(attacker, target, hit_position, direction)
	var fx_parent := ImpactFXScript.parent_for(target)
	DirectionalImpactFXScript.spawn(fx_parent, hit_position, direction, 0.028)


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


static func _max_range_squared(strike_range: float) -> float:
	var max_range := strike_range + RANGE_SLACK
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
