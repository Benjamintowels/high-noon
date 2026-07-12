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
# Heavy (two-handed) strikes launch targets harder and stun longer to sell weight.
const HEAVY_KNOCKBACK_SPEED := 13.0
const HEAVY_KNOCKBACK_UP := 2.0
const HEAVY_STUN_DURATION := 1.1
const ARC_DOT_MIN := 0.15
const RANGE_SLACK := 0.85
const SWORD_SLASH_FPS := 60.0
const COMBO_INPUT_FRAME_START := 30
const COMBO_INPUT_FRAME_END := 70
const SPIN_COMBO_INPUT_FRAME_START := 55
const SPIN_COMBO_INPUT_FRAME_END := 105
const SPIN_RANGE := 3.4
const SPIN_STRIKE_FRACTION := 0.5
const SPIN_VISUAL_FRACTION := 0.5
const SPIN_COOLDOWN := 1.5


static func frame_to_time(frame: float, fps: float = SWORD_SLASH_FPS) -> float:
	return frame / maxf(fps, 0.001)


static func time_to_frame(time: float, fps: float = SWORD_SLASH_FPS) -> float:
	return time * fps


static func anim_time_step(delta: float, playback_speed: float = 1.0) -> float:
	return delta * maxf(playback_speed, 0.001)


static func get_playback_speed(
	animation_tree: AnimationTree,
	time_scale_node: StringName = &""
) -> float:
	if animation_tree == null or not animation_tree.active or time_scale_node.is_empty():
		return 1.0
	var scale = animation_tree.get("parameters/%s/scale" % time_scale_node)
	if scale is float:
		return maxf(absf(scale), 0.001)
	return 1.0


static func read_one_shot_time(
	animation_tree: AnimationTree,
	one_shot_node: StringName
) -> float:
	if animation_tree == null or not animation_tree.active or one_shot_node.is_empty():
		return -1.0
	var time = animation_tree.get("parameters/%s/time" % one_shot_node)
	if time is float:
		return maxf(time, 0.0)
	return -1.0


static func is_in_combo_input_window(anim_time: float, fps: float = SWORD_SLASH_FPS) -> bool:
	var frame := time_to_frame(anim_time, fps)
	return frame >= COMBO_INPUT_FRAME_START and frame <= COMBO_INPUT_FRAME_END


static func is_in_spin_combo_input_window(anim_time: float, fps: float = SWORD_SLASH_FPS) -> bool:
	var frame := time_to_frame(anim_time, fps)
	return frame >= SPIN_COMBO_INPUT_FRAME_START and frame <= SPIN_COMBO_INPUT_FRAME_END


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


static func find_strike_target(
	actor: Node3D,
	direction: Vector3,
	strike_range: float = RANGE,
	arc_dot_min: float = ARC_DOT_MIN
) -> Node:
	return _find_best_strike_target(actor, direction, strike_range, arc_dot_min)


static func is_target_in_strike_range(
	actor: Node3D,
	target: Node,
	strike_range: float = RANGE
) -> bool:
	if actor == null or target == null or not (target is Node3D):
		return false
	return _is_target_in_range(actor, target as Node3D, strike_range)


static func find_spin_strike_targets(actor: Node3D) -> Array[Node]:
	var targets: Array[Node] = []
	if actor == null:
		return targets

	var tree := actor.get_tree()
	if tree == null:
		return targets

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
			if _flat_distance_squared_to_target(actor, target) > _max_spin_range_squared():
				continue
			targets.append(target)

	targets.sort_custom(
		func(a: Node, b: Node) -> bool:
			return (
				_flat_distance_squared_to_target(actor, a as Node3D)
				< _flat_distance_squared_to_target(actor, b as Node3D)
			)
	)
	return targets


static func apply_spin_strike(attacker: Node, direction: Vector3, damage: int = DAMAGE) -> int:
	var hit_count := 0
	for target in find_spin_strike_targets(attacker as Node3D):
		if apply_strike(attacker, direction, target, RANGE, damage):
			hit_count += 1
	return hit_count


static func _find_best_strike_target(
	actor: Node3D,
	direction: Vector3,
	strike_range: float,
	arc_dot_min: float
) -> Node:
	if actor == null or direction.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var slash_dir := direction.normalized()
	var seen: Dictionary = {}
	var max_range_sq := _max_range_squared(strike_range)

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
			if distance_sq > max_range_sq or distance_sq < 0.0001:
				continue

			var flat_dir := _flat_direction_to_target(actor, target)
			if flat_dir.dot(slash_dir) < arc_dot_min:
				continue

			if distance_sq < best_score:
				best_score = distance_sq
				best_target = target

	return best_target


static func apply_strike(
	attacker: Node,
	direction: Vector3,
	explicit_target: Node = null,
	strike_range: float = RANGE,
	damage: int = DAMAGE,
	heavy: bool = false
) -> bool:
	if attacker == null or direction.length_squared() < 0.0001:
		return false

	var target: Node = explicit_target
	if target == null or not is_instance_valid(target):
		target = find_strike_target(attacker as Node3D, direction, strike_range)
	if target == null or not _is_valid_strike_target(attacker, target):
		return false

	var actor := attacker as Node3D
	if actor != null and not _is_target_in_range(actor, target as Node3D, strike_range):
		return false
	var strike_dir := direction
	if actor != null:
		strike_dir = get_strike_direction(actor, target)
	if strike_dir.length_squared() < 0.0001:
		strike_dir = direction
	strike_dir = strike_dir.normalized()

	var hit_position: Vector3 = _get_target_anchor(target as Node3D)
	var stun_duration := HEAVY_STUN_DURATION if heavy else STUN_DURATION
	var hit_info := {
		"position": hit_position,
		"direction": strike_dir,
		"shooter": attacker,
		"damage": damage,
		"knockback_speed": HEAVY_KNOCKBACK_SPEED if heavy else KNOCKBACK_SPEED,
		"knockback_up": HEAVY_KNOCKBACK_UP if heavy else KNOCKBACK_UP,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": stun_duration,
		"sword_hit": true,
		"heavy_hit": heavy,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			return true
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(stun_duration)
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


static func _max_range_squared(strike_range: float = RANGE) -> float:
	var max_range := strike_range + RANGE_SLACK
	return max_range * max_range


static func _max_spin_range_squared() -> float:
	return _max_range_squared(SPIN_RANGE)


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


static func _is_target_in_range(
	actor: Node3D,
	target: Node3D,
	strike_range: float = RANGE
) -> bool:
	return _flat_distance_squared_to_target(actor, target) <= _max_range_squared(strike_range)
