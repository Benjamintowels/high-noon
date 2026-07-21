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
const LightningGemCombatScript := preload("res://gameplay/combat/lightning_gem_combat.gd")
const FireGemCombatScript := preload("res://gameplay/combat/fire_gem_combat.gd")
const IceGemCombatScript := preload("res://gameplay/combat/ice_gem_combat.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const PunchPoseConfigScript := preload("res://characters/groyper/punch_pose_config.gd")

const RANGE := 1.95
const KNIFE_RANGE := 2.35
## Wider than strike range so combo follow-ups still turn toward a shoved enemy.
const FACE_RANGE := 7.0
## Melee is XZ-gated; reject absurd vertical offsets (floaters / cliffs).
const MAX_VERTICAL_REACH := 2.0
const ANIM_FPS := 60.0
## Whole punch combo (hook → elbow → double) plays slightly faster than authored.
const PLAYBACK_SPEED := 1.4
const ANIM_FADEIN := 0.14
const LUNGE_SPEED := 4.2
const KNIFE_LUNGE_SPEED := 4.8
const COOLDOWN := 1.15
## Player-only punch pacing: no post-swing cooldown; recovery is interruptible
## so a new jab can start as soon as the previous strike finishes exiting.
## Combo clip speed is solely PLAYBACK_SPEED (no extra player mult).
const PLAYER_COOLDOWN := 0.0
const PLAYER_ATTACK_SPEED_MULT := 1.0
const EXIT_BLEND_DURATION := 0.52
const ANIM_FADEOUT := 0.52
## Base NPC stagger / stunlock from a punch. Elbow (combo hit 2) uses 2x.
const STUN_DURATION := 1.0
const ELBOW_STUN_MULT := 2.0
## Unarmed fist chip damage (half of the old 1.0). Knife melee keeps KNIFE_DAMAGE.
const DAMAGE := 0.5
const BANDIT_PUNCH_DAMAGE := 0.5
const KNIFE_DAMAGE := 2
const KNOCKBACK_SPEED := 4.0
const KNIFE_KNOCKBACK_SPEED := 5.2
const KNOCKBACK_UP := 0.9
const PLAYER_HIT_BOUNCE_SPEED := 2.4
const PLAYER_HIT_LUNGE_SPEED := 2.2
const ARC_DOT_MIN := 0.35
const COMBO_INPUT_BUFFER := 0.22

enum ComboStep { HOOK, ELBOW_FIRST, ELBOW_SECOND, DOUBLE_FIRST, DOUBLE_SECOND }


static func frame_to_time(frame: float, fps: float = ANIM_FPS) -> float:
	return frame / maxf(fps, 0.001)


static func get_playback_speed(_step: ComboStep) -> float:
	return PLAYBACK_SPEED


## No extra player speed mult — PLAYBACK_SPEED alone paces the whole combo.
static func uses_snappy_player_speed(_step: ComboStep) -> bool:
	return false


static func get_attack_duration(anim_length: float) -> float:
	return get_attack_duration_for_step(ComboStep.HOOK, anim_length)


static func get_attack_duration_for_step(step: ComboStep, anim_length: float) -> float:
	var start_time := get_step_seek_base(step)
	var end_time := get_step_end_anim_time(step, anim_length)
	var segment_length := maxf(end_time - start_time, 0.001)
	var playback := get_playback_speed(step)
	var scaled_length := segment_length / playback
	var minimum := (get_strike_anim_time(step) + 0.08 - start_time) / playback
	return maxf(scaled_length, minimum)


static func get_windup_duration() -> float:
	return get_strike_real_duration(ComboStep.HOOK)


## Strike times come from Animation markers on each punch clip (see PunchPoseConfig).
static func get_strike_anim_time(step: ComboStep) -> float:
	match step:
		ComboStep.HOOK:
			return PunchPoseConfigScript.get_hook_strike()
		ComboStep.ELBOW_FIRST:
			return PunchPoseConfigScript.get_elbow_strike_1()
		ComboStep.ELBOW_SECOND:
			return PunchPoseConfigScript.get_elbow_strike_2()
		ComboStep.DOUBLE_FIRST:
			return PunchPoseConfigScript.get_double_strike_1()
		ComboStep.DOUBLE_SECOND:
			return PunchPoseConfigScript.get_double_strike_2()
	return PunchPoseConfigScript.get_hook_strike()


static func get_strike_real_duration(step: ComboStep) -> float:
	var start_time := get_step_seek_base(step)
	return maxf(get_strike_anim_time(step) - start_time, 0.0) / get_playback_speed(step)


static func get_step_seek_base(step: ComboStep) -> float:
	match step:
		ComboStep.ELBOW_SECOND:
			return _same_clip_segment_split(
				get_strike_anim_time(ComboStep.ELBOW_FIRST),
				get_strike_anim_time(ComboStep.ELBOW_SECOND)
			)
		ComboStep.DOUBLE_SECOND:
			return _same_clip_segment_split(
				get_strike_anim_time(ComboStep.DOUBLE_FIRST),
				get_strike_anim_time(ComboStep.DOUBLE_SECOND)
			)
		_:
			return 0.0


## Split a multi-hit clip shortly after the prior strike so the next press
## can start without waiting out the whole recovery.
static func _same_clip_segment_split(prior_strike: float, next_strike: float) -> float:
	var hold := PunchPoseConfigScript.POST_STRIKE_HOLD
	var earliest := prior_strike + hold
	var latest := maxf(next_strike - 0.05, prior_strike + 0.05)
	return clampf(earliest, prior_strike + 0.05, latest)


static func get_step_end_anim_time(step: ComboStep, anim_length: float) -> float:
	match step:
		ComboStep.HOOK, ComboStep.ELBOW_SECOND:
			# Chainable single-clip steps: cut shortly after the strike lands.
			return minf(
				get_strike_anim_time(step) + PunchPoseConfigScript.POST_STRIKE_HOLD,
				anim_length
			)
		ComboStep.ELBOW_FIRST:
			return minf(get_step_seek_base(ComboStep.ELBOW_SECOND), anim_length)
		ComboStep.DOUBLE_FIRST:
			return minf(get_step_seek_base(ComboStep.DOUBLE_SECOND), anim_length)
		_:
			return anim_length


static func get_next_combo_step(step: ComboStep) -> ComboStep:
	match step:
		ComboStep.HOOK:
			return ComboStep.ELBOW_FIRST
		ComboStep.ELBOW_FIRST:
			return ComboStep.ELBOW_SECOND
		ComboStep.ELBOW_SECOND:
			return ComboStep.DOUBLE_FIRST
		ComboStep.DOUBLE_FIRST:
			return ComboStep.DOUBLE_SECOND
		_:
			return ComboStep.DOUBLE_SECOND


static func can_chain_combo(step: ComboStep) -> bool:
	return (
		step == ComboStep.HOOK
		or step == ComboStep.ELBOW_FIRST
		or step == ComboStep.ELBOW_SECOND
		or step == ComboStep.DOUBLE_FIRST
	)


static func get_combo_window_start(step: ComboStep) -> float:
	if not can_chain_combo(step):
		return INF
	return get_strike_anim_time(step)


static func get_combo_window_end(step: ComboStep) -> float:
	if not can_chain_combo(step):
		return -INF
	return get_strike_anim_time(step) + PunchPoseConfigScript.POST_STRIKE_HOLD


static func is_combo_finisher_step(step: ComboStep) -> bool:
	return step == ComboStep.DOUBLE_SECOND


static func get_stun_duration_for_step(step: ComboStep) -> float:
	## Combo hit 2 (first elbow) keeps the heavier stunlock.
	if step == ComboStep.ELBOW_FIRST:
		return STUN_DURATION * ELBOW_STUN_MULT
	return STUN_DURATION


static func is_in_combo_input_window(step: ComboStep, anim_time: float) -> bool:
	if not can_chain_combo(step):
		return false
	return anim_time >= get_combo_window_start(step) and anim_time <= get_combo_window_end(step)


## Buffer presses from just before the strike through the end of the step.
## Follow-up never starts early — player consumes this only when the step finishes.
static func can_accept_combo_buffer(
	step: ComboStep,
	anim_time: float,
	anim_length: float = INF
) -> bool:
	if not can_chain_combo(step):
		return false
	var window_start := get_combo_window_start(step)
	var buffer_lead_anim := COMBO_INPUT_BUFFER * get_playback_speed(step)
	var earliest := maxf(0.0, window_start - buffer_lead_anim)
	var latest := get_step_end_anim_time(step, anim_length)
	return anim_time >= earliest and anim_time <= latest


static func get_exit_blend_duration() -> float:
	return EXIT_BLEND_DURATION / PLAYBACK_SPEED


static func get_anim_fadein() -> float:
	return ANIM_FADEIN / PLAYBACK_SPEED


static func get_anim_time(elapsed: float, step: ComboStep = ComboStep.HOOK) -> float:
	return elapsed * get_playback_speed(step)


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


static func get_damage_for_attacker(attacker: Node) -> float:
	return float(KNIFE_DAMAGE) if attacker_uses_knife(attacker) else DAMAGE


static func get_knockback_speed_for_attacker(attacker: Node) -> float:
	return KNIFE_KNOCKBACK_SPEED if attacker_uses_knife(attacker) else KNOCKBACK_SPEED


static func get_lunge_speed_for_attacker(attacker: Node) -> float:
	return KNIFE_LUNGE_SPEED if attacker_uses_knife(attacker) else LUNGE_SPEED


static func find_nearest_strike_target(actor: Node3D, max_range: float = -1.0) -> Node:
	if actor == null:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var seen: Dictionary = {}
	var strike_range := max_range if max_range > 0.0 else get_range_for_attacker(actor)

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
			if not _is_within_vertical_reach(actor, target):
				continue
			var to_target := target.global_position - actor.global_position
			to_target.y = 0.0
			var distance_sq := to_target.length_squared()
			if distance_sq > strike_range * strike_range or distance_sq < 0.0001:
				continue

			if distance_sq < best_score:
				best_score = distance_sq
				best_target = target

	return best_target


## Prefer a nearby strike target; fall back to a wider facing search for combo turns.
static func find_nearest_face_target(actor: Node3D) -> Node:
	var nearest := find_nearest_strike_target(actor)
	if nearest != null:
		return nearest
	return find_nearest_strike_target(actor, FACE_RANGE)


static func get_player_strike_direction(actor: Node3D) -> Vector3:
	var nearest := find_nearest_face_target(actor)
	if nearest != null:
		return get_strike_direction(actor, nearest)
	return get_strike_direction(actor)


static func is_in_range_for_actor(
	actor: Node3D,
	target: Node3D,
	strike_range: float = -1.0
) -> bool:
	if actor == null or target == null or not is_instance_valid(target):
		return false
	if not _is_within_vertical_reach(actor, target):
		return false
	var to_target := target.global_position - actor.global_position
	to_target.y = 0.0
	var reach := strike_range if strike_range > 0.0 else get_range_for_attacker(actor)
	return to_target.length_squared() <= reach * reach


static func _is_within_vertical_reach(actor: Node3D, target: Node3D) -> bool:
	return absf(target.global_position.y - actor.global_position.y) <= MAX_VERTICAL_REACH


static func find_strike_target(
	actor: Node3D,
	direction: Vector3,
	strike_range: float = -1.0,
	arc_dot_min: float = NAN
) -> Node:
	if actor == null or direction.length_squared() < 0.0001:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best_target: Node = null
	var best_score := INF
	var punch_dir := direction.normalized()
	var seen: Dictionary = {}
	var reach := strike_range if strike_range > 0.0 else get_range_for_attacker(actor)
	var arc_min := arc_dot_min if not is_nan(arc_dot_min) else ARC_DOT_MIN

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
			if not _is_within_vertical_reach(actor, target):
				continue
			var to_target := target.global_position - actor.global_position
			to_target.y = 0.0
			var distance_sq := to_target.length_squared()
			if distance_sq > reach * reach or distance_sq < 0.0001:
				continue

			var flat_dir := to_target.normalized()
			if flat_dir.dot(punch_dir) < arc_min:
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

	var strike_range := float(options.get("strike_range", -1.0))
	var arc_dot_min := float(options.get("arc_dot_min", NAN))
	_strike_nearby_props(attacker, direction, strike_range)

	var target: Node = explicit_target
	if target == null or not is_instance_valid(target):
		target = find_strike_target(attacker as Node3D, direction, strike_range, arc_dot_min)
	if target == null or not _is_valid_strike_target(attacker, target):
		return false
	# Explicit targets still need reach — bosses were hitting from across the arena.
	var actor := attacker as Node3D
	var reach := strike_range if strike_range > 0.0 else get_range_for_attacker(attacker)
	if actor != null and target is Node3D and not is_in_range_for_actor(actor, target as Node3D, reach):
		return false
	if actor != null and target is Node3D and not is_nan(arc_dot_min):
		var to_target := (target as Node3D).global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			var flat_dir := to_target.normalized()
			if flat_dir.dot(direction.normalized()) < arc_dot_min:
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
	# Player Q-grab counter: spin-throw the puncher instead of taking the hit.
	if target.has_method("try_unarmed_parry") and target.try_unarmed_parry(attacker, preview_hit_info):
		return true
	if UnarmedPunchBlockScript.can_block_punch(target, preview_hit_info):
		return UnarmedPunchBlockScript.resolve(attacker, target, preview_hit_info)

	var damage := float(options.get("damage", get_damage_for_attacker(attacker)))
	var knockdown := bool(options.get("knockdown", false))
	var face_punch := bool(options.get("face_punch_reaction", not knockdown))
	var knockback_speed := float(
		options.get("knockback_speed", get_knockback_speed_for_attacker(attacker))
	)
	var knockback_up := float(options.get("knockback_up", KNOCKBACK_UP))
	var stun_duration := float(options.get("melee_stun_duration", STUN_DURATION))
	var hit_info := {
		"position": hit_position,
		"direction": direction.normalized(),
		"shooter": attacker,
		"damage": 0,
		"chip_damage": damage,
		"punch_hit": true,
		"knockback_speed": knockback_speed,
		"knockback_up": knockback_up,
		"melee": true,
		"force_knockback": knockdown or bool(options.get("force_knockback", false)),
		"melee_stun_duration": stun_duration,
		"face_punch_reaction": face_punch,
		"skip_stun": bool(options.get("skip_stun", false)),
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
		# Explicit 0 disables stun (e.g. knockdown-only boss hits).
		if stun_duration > 0.0 and target.has_method("apply_melee_stun"):
			target.apply_melee_stun(stun_duration)
		if use_knife:
			BloodSplatterFXScript.spawn_for_hit(target, hit_info)
			GameAudioScript.play_knife_slice(attacker, hit_position)
			MeleeHitFXScript.play(attacker, target, hit_position, direction, {
				"skip_impact_sprite": true,
				"skip_flash_light": true,
				"skip_dust": true,
			})
		else:
			# Fists: no smoke — white→red body flash, big splatter only on kill.
			MeleeHitFXScript.play(attacker, target, hit_position, direction, {
				"skip_dust": true,
			})
			CombatHitFlashScript.flash_punch_hit(target)
			GameAudioScript.play_punch(attacker, hit_position)
			if target.has_method("is_defeated") and target.is_defeated():
				BloodSplatterFXScript.spawn_big_for_hit(target, hit_info)
		LightningGemCombatScript.try_proc_on_hit(
			attacker,
			target,
			GroyperWeaponsScript.Id.UNARMED
		)
		FireGemCombatScript.try_proc_on_hit(
			attacker,
			target,
			GroyperWeaponsScript.Id.UNARMED
		)
		IceGemCombatScript.try_proc_on_hit(
			attacker,
			target,
			GroyperWeaponsScript.Id.UNARMED
		)
		return true

	return false


## Punches also shove physics props (group "punchable_prop") caught in the
## swing arc, whether or not a character was hit.
static func _strike_nearby_props(
	attacker: Node,
	direction: Vector3,
	strike_range_override: float = -1.0
) -> void:
	var actor := attacker as Node3D
	if actor == null or not actor.is_inside_tree():
		return
	var punch_dir := direction.normalized()
	var base_reach := (
		strike_range_override if strike_range_override > 0.0 else get_range_for_attacker(attacker)
	)
	var strike_range := base_reach + 0.35
	for node in actor.get_tree().get_nodes_in_group(&"punchable_prop"):
		if node == attacker or not (node is Node3D) or not node.has_method("receive_punch"):
			continue
		var prop := node as Node3D
		var prop_pos := prop.global_position
		if prop.has_method("get_prop_center"):
			prop_pos = prop.get_prop_center()
		var to_prop := prop_pos - actor.global_position
		to_prop.y = 0.0
		var distance_sq := to_prop.length_squared()
		var reach := strike_range
		if prop.has_method("get_prop_contact_radius"):
			reach += float(prop.get_prop_contact_radius())
		if distance_sq > reach * reach:
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
