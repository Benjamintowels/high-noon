extends RefCounted
class_name MeleePunch

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const GroyperHitReactionConfig := preload("res://characters/groyper/groyper_hit_reaction_config.gd")
const UnarmedPunchBlockScript := preload("res://gameplay/combat/unarmed_punch_block.gd")

const RANGE := 1.95
const KNIFE_RANGE := 2.35
const ANIM_FPS := 60.0
const PLAYBACK_SPEED := 2.0
const ANIM_FADEIN := 0.14
const LUNGE_SPEED := 4.2
const KNIFE_LUNGE_SPEED := 4.8
const COOLDOWN := 1.15
## Player-only punch pacing: shorter cooldown between punches and a faster
## attack playback so the swing comes out almost immediately.
const PLAYER_COOLDOWN := 0.6
const PLAYER_ATTACK_SPEED_MULT := 1.45
const EXIT_BLEND_DURATION := 0.52
const ANIM_FADEOUT := 0.52
const STUN_DURATION := 0.55
const DAMAGE := 1
const BANDIT_PUNCH_DAMAGE := 0.5
const KNIFE_DAMAGE := 2
const KNOCKBACK_SPEED := 4.0
const KNIFE_KNOCKBACK_SPEED := 5.2
const KNOCKBACK_UP := 0.9
const PLAYER_HIT_BOUNCE_SPEED := 2.4
const PLAYER_HIT_LUNGE_SPEED := 2.2
const ARC_DOT_MIN := 0.35
const COMBO_INPUT_BUFFER := 0.22

enum ComboStep { HOOK, ELBOW_FIRST, ELBOW_SECOND }

## Right-upper-hook strike time on the punch animation timeline.
const HOOK_STRIKE_ANIM_TIME := 0.5
## Combo input window on the hook (frames at 60fps on the hook clip).
const HOOK_COMBO_FRAME_START := 30
const HOOK_COMBO_FRAME_END := 105
## First elbow strike in the shared elbow clip (seconds on clip timeline).
const ELBOW_HIT1_STRIKE_ANIM_TIME := 0.6
const ELBOW_HIT1_END_ANIM_TIME := 1.0
const ELBOW_HIT1_COMBO_START := 0.6
const ELBOW_HIT1_COMBO_END := 0.99
## Second elbow strike resumes at 1.0s on the same clip.
const ELBOW_HIT2_START_ANIM_TIME := 1.0
const ELBOW_HIT2_STRIKE_ANIM_TIME := 1.15


static func frame_to_time(frame: float, fps: float = ANIM_FPS) -> float:
	return frame / maxf(fps, 0.001)


static func get_attack_duration(anim_length: float) -> float:
	return get_attack_duration_for_step(ComboStep.HOOK, anim_length)


static func get_attack_duration_for_step(step: ComboStep, anim_length: float) -> float:
	var start_time := get_step_seek_base(step)
	var end_time := get_step_end_anim_time(step, anim_length)
	var segment_length := maxf(end_time - start_time, 0.001)
	var scaled_length := segment_length / PLAYBACK_SPEED
	var minimum := (get_strike_anim_time(step) + 0.12 - start_time) / PLAYBACK_SPEED
	return maxf(scaled_length, minimum)


static func get_windup_duration() -> float:
	return get_strike_real_duration(ComboStep.HOOK)


static func get_strike_anim_time(step: ComboStep) -> float:
	match step:
		ComboStep.HOOK:
			return HOOK_STRIKE_ANIM_TIME
		ComboStep.ELBOW_FIRST:
			return ELBOW_HIT1_STRIKE_ANIM_TIME
		ComboStep.ELBOW_SECOND:
			return ELBOW_HIT2_STRIKE_ANIM_TIME
	return HOOK_STRIKE_ANIM_TIME


static func get_strike_real_duration(step: ComboStep) -> float:
	var start_time := get_step_seek_base(step)
	return maxf(get_strike_anim_time(step) - start_time, 0.0) / PLAYBACK_SPEED


static func get_step_seek_base(step: ComboStep) -> float:
	match step:
		ComboStep.ELBOW_SECOND:
			return ELBOW_HIT2_START_ANIM_TIME
		_:
			return 0.0


static func get_step_end_anim_time(step: ComboStep, anim_length: float) -> float:
	match step:
		ComboStep.ELBOW_FIRST:
			return minf(ELBOW_HIT1_END_ANIM_TIME, anim_length)
		_:
			return anim_length


static func get_next_combo_step(step: ComboStep) -> ComboStep:
	match step:
		ComboStep.HOOK:
			return ComboStep.ELBOW_FIRST
		ComboStep.ELBOW_FIRST:
			return ComboStep.ELBOW_SECOND
		_:
			return ComboStep.ELBOW_SECOND


static func can_chain_combo(step: ComboStep) -> bool:
	return step == ComboStep.HOOK or step == ComboStep.ELBOW_FIRST


static func get_combo_window_start(step: ComboStep) -> float:
	match step:
		ComboStep.HOOK:
			return frame_to_time(HOOK_COMBO_FRAME_START)
		ComboStep.ELBOW_FIRST:
			return ELBOW_HIT1_COMBO_START
		_:
			return INF


static func get_combo_window_end(step: ComboStep) -> float:
	match step:
		ComboStep.HOOK:
			return frame_to_time(HOOK_COMBO_FRAME_END)
		ComboStep.ELBOW_FIRST:
			return ELBOW_HIT1_COMBO_END
		_:
			return -INF


static func is_in_combo_input_window(step: ComboStep, anim_time: float) -> bool:
	if not can_chain_combo(step):
		return false
	return anim_time >= get_combo_window_start(step) and anim_time <= get_combo_window_end(step)


static func can_accept_combo_buffer(step: ComboStep, anim_time: float) -> bool:
	if not can_chain_combo(step):
		return false
	var window_start := get_combo_window_start(step)
	var window_end := get_combo_window_end(step)
	var buffer_lead_anim := COMBO_INPUT_BUFFER * PLAYBACK_SPEED
	var earliest := maxf(0.0, window_start - buffer_lead_anim)
	return anim_time >= earliest and anim_time <= window_end


static func get_exit_blend_duration() -> float:
	return EXIT_BLEND_DURATION / PLAYBACK_SPEED


static func get_anim_fadein() -> float:
	return ANIM_FADEIN / PLAYBACK_SPEED


static func get_anim_time(elapsed: float) -> float:
	return elapsed * PLAYBACK_SPEED


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


static func apply_strike(
	attacker: Node,
	direction: Vector3,
	explicit_target: Node = null,
	options: Dictionary = {}
) -> bool:
	if attacker == null or direction.length_squared() < 0.0001:
		return false

	_strike_nearby_props(attacker, direction)

	var target: Node = explicit_target
	if target == null or not is_instance_valid(target):
		target = find_strike_target(attacker as Node3D, direction)
	if target == null or not _is_valid_strike_target(attacker, target):
		return false

	var use_knife := attacker_uses_knife(attacker)
	var hit_position: Vector3 = target.global_position + Vector3(0.0, 1.05, 0.0)
	var preview_hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"melee": true,
		"punch_hit": true,
		"chip_damage": float(options.get("damage", get_damage_for_attacker(attacker))),
	}
	if use_knife:
		preview_hit_info["knife_hit"] = true
	if UnarmedPunchBlockScript.can_block_punch(target, preview_hit_info):
		return UnarmedPunchBlockScript.resolve(attacker, target, preview_hit_info)

	var damage := float(options.get("damage", get_damage_for_attacker(attacker)))
	var knockdown := bool(options.get("knockdown", false))
	var face_punch := bool(options.get("face_punch_reaction", not knockdown))
	var hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"damage": 0,
		"chip_damage": damage,
		"punch_hit": true,
		"knockback_speed": get_knockback_speed_for_attacker(attacker),
		"knockback_up": KNOCKBACK_UP,
		"melee": true,
		"force_knockback": knockdown,
		"melee_stun_duration": STUN_DURATION,
		"face_punch_reaction": face_punch,
	}
	if knockdown:
		hit_info["knockback_speed"] = maxf(
			float(hit_info["knockback_speed"]),
			GroyperHitReactionConfig.KNOCKDOWN_KNOCKBACK_THRESHOLD
		)
	if use_knife:
		hit_info["knife_hit"] = true
	var kill_launch: Vector3 = options.get("kill_launch_velocity", Vector3.ZERO)
	if kill_launch.length_squared() > 0.0001:
		# Only read by the defeat ragdoll when the strike kills: the corpse
		# launches on this ballistic arc instead of dropping at the spot.
		hit_info["mounted_dismount"] = true
		hit_info["mounted_launch_velocity"] = kill_launch

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if knockdown and target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		if use_knife:
			BloodSplatterFXScript.spawn_for_hit(target, hit_info)
			GameAudioScript.play_knife_slice(attacker, hit_position)
		else:
			MeleeHitFXScript.play(attacker, target, hit_position, direction)
			CombatHitFlashScript.flash_punch_hit(target)
			GameAudioScript.play_punch(attacker, hit_position)
		return true

	return false


## Punches also shove physics props (group "punchable_prop") caught in the
## swing arc, whether or not a character was hit.
static func _strike_nearby_props(attacker: Node, direction: Vector3) -> void:
	var actor := attacker as Node3D
	if actor == null or not actor.is_inside_tree():
		return
	var punch_dir := direction.normalized()
	var strike_range := get_range_for_attacker(attacker) + 0.35
	for node in actor.get_tree().get_nodes_in_group(&"punchable_prop"):
		if node == attacker or not (node is Node3D) or not node.has_method("receive_punch"):
			continue
		var prop := node as Node3D
		var to_prop := prop.global_position - actor.global_position
		to_prop.y = 0.0
		var distance_sq := to_prop.length_squared()
		if distance_sq > strike_range * strike_range:
			continue
		if distance_sq > 0.0001 and to_prop.normalized().dot(punch_dir) < ARC_DOT_MIN:
			continue
		prop.receive_punch({
			"position": actor.global_position,
			"direction": punch_dir,
			"shooter": attacker,
			"melee": true,
			"punch_hit": true,
		})


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
