extends "res://characters/chief_getcha/chief_getcha_actor.gd"
class_name ChiefGetchaNpc

const ChiefGetchaAnimConfigScript := preload("res://characters/chief_getcha/chief_getcha_anim_config.gd")
const MeleePunchScript := preload("res://gameplay/combat/melee_punch.gd")
const TcChargeRunScript := preload("res://characters/tc/tc_charge_run.gd")
const AlertSymbolFXScript := preload("res://gameplay/fx/alert_symbol_fx.gd")
const BossHealthBarScript := preload("res://gameplay/ui/boss_health_bar.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const LootCurrencyShowerScript := preload("res://gameplay/world/loot_currency_shower.gd")
const ChurchRecurveRewardScript := preload("res://gameplay/world/church_recurve_reward.gd")
const UnarmedBlockPoseConfig := preload("res://characters/groyper/unarmed_block_pose_config.gd")
const UnarmedBlockPoseExtractScript := preload(
	"res://characters/groyper/unarmed_block_pose_extract.gd"
)
const ChiefGetchaBowRigScript := preload("res://characters/chief_getcha/chief_getcha_bow_rig.gd")

enum Phase {
	SITTING,
	STANDING_UP,
	FIGHTING,
	DEFEATED,
	FLEEING,
}

enum AiState {
	CHASE,
	DECIDING,
	BLOCKING,
	ATTACK_WINDUP,
	ATTACKING,
	ROLLING,
	CHARGE_WINDUP,
	CHARGE_RUN,
	FLYING_KICK_SPRINT,
	FLYING_KICK,
	ARCHERY,
}

enum AttackKind {
	PUNCH,
	COMBO,
	KICK,
	SPIN_KICK,
	FLYING_KICK,
	DOUBLE_COMBO,
	SKILL_3,
}

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const WALK_SPEED := 3.8
const RUN_SPEED := 5.5
const BLEND_SPEED := 8.0
const MAX_HEALTH := 15
const ATTACK_RANGE := 2.1
const DETECT_RANGE := 28.0
const PUNCH_DAMAGE := 1.0
const KICK_DAMAGE := 1.25
const FLYING_KICK_DAMAGE := 1.5

## Aggressive boss pacing — prefer attacks over defense.
const BRAWL_DECISION_MIN := 0.12
const BRAWL_DECISION_MAX := 0.4
const BRAWL_BLOCK_CHANCE := 0.1
const BRAWL_BLOCK_MIN := 0.55
const BRAWL_BLOCK_MAX := 1.1
const BRAWL_ROLL_CHANCE := 0.12
const BRAWL_RETREAT_CHANCE := 0.08
const BRAWL_RETREAT_DURATION := 1.0
const BRAWL_RETREAT_RANGE := 4.5
const BRAWL_PURSUE_STOP_RANGE := 1.7
const BRAWL_PUNCH_COOLDOWN_MULT_MIN := 0.55
const BRAWL_PUNCH_COOLDOWN_MULT_MAX := 1.0
const PUNCH_TELEGRAPH_TIME := 0.28
const PUNCHED_BLOCK_CHANCE := 0.18
const PUNCHED_BLOCK_MIN := 0.55
const PUNCHED_BLOCK_MAX := 1.0
const CHARGE_RUN_CHANCE := 0.12
## Weights for close-range brawl picks (Weapon Combo 1 / Spin Kick / Double Combo / Skill 3).
const BRAWL_ATTACK_WEIGHT_PUNCH := 1.0
const BRAWL_ATTACK_WEIGHT_SPIN_KICK := 1.0
const BRAWL_ATTACK_WEIGHT_DOUBLE_COMBO := 1.0
const BRAWL_ATTACK_WEIGHT_SKILL_3 := 0.85
const FLYING_KICK_CHANCE := 0.34
const FLYING_KICK_COOLDOWN := 4.5
const FLYING_KICK_RANGE_MIN := 3.0
const FLYING_KICK_RANGE_MAX := 14.0
const FLYING_KICK_LAUNCH_RANGE := 2.8
const FLYING_KICK_SPRINT_MULT := 2.0
const FLYING_KICK_FORWARD_SPEED := 8.6
const FLYING_KICK_RISE_SPEED := 3.4
const FLYING_KICK_CONTACT_RANGE := 1.85
const ROLL_SPEED := 6.2
const ALERT_HEAD_OFFSET := 2.1
const ARCHERY_CHANCE := 0.28
const ARCHERY_DURATION_MIN := 5.0
const ARCHERY_DURATION_MAX := 9.0
const ARCHERY_SHOT_INTERVAL := 1.5
const ARCHERY_SHOT_TELEGRAPH := 0.45
const ARCHERY_PREFERRED_RANGE := 9.0
const ARCHERY_RANGE_MIN := 5.0
const ARCHERY_RANGE_MAX := 18.0
const ARCHERY_MOVE_SPEED := 2.6

const FIGHT_LINES: PackedStringArray = [
	"You dare disturb my prayer?",
	"Then let us settle this the old way.",
]

const DEFEAT_LINES: PackedStringArray = [
	"how",
]

const DEFEAT_FLEE_SPEED := 9.5
const DEFEAT_FLEE_DURATION := 2.6
const DEFEAT_LOOT_GRAM_MIN := 20
const DEFEAT_LOOT_GRAM_MAX := 30
const DEFEAT_LOOT_SHARDS_MIN := 25
const DEFEAT_LOOT_SHARDS_MAX := 35
const DEFEAT_LOOT_DURATION := 2.0
## Toss/kick recovery diagnostics. Leave off unless chasing a flip/sit regression.
const DEBUG_TOSS_RECOVERY := false
## Same floor sink as bonfire/knockdown sit — cross-legged clips float without it.
const SIT_MODEL_Y_OFFSET := -0.48
const SIT_MODEL_SINK_SPEED := 12.0

@export var speaker_name := "Chief Getcha"

@export_group("Bow Mounts")
@export var bow_back_position := Vector3(0.05, -0.05, 0.12)
@export var bow_back_rotation_deg := Vector3(8.0, 95.0, -12.0)
@export var bow_hand_position := Vector3(-0.08, -0.02, 0.04)
@export var bow_hand_rotation_deg := Vector3(90.0, 0.0, -15.0)

@onready var _interact_area: Area3D = $InteractArea

var _phase := Phase.SITTING
var _ai_state := AiState.CHASE
var _combat_target: Node3D
var _attack_kind := AttackKind.PUNCH
var _attack_elapsed := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_strike_index := 0
var _attack_strike_times: PackedFloat32Array = PackedFloat32Array()
var _attack_cooldown := 0.0
var _decision_timer := 0.0
var _state_timer := 0.0
var _windup_timer := 0.0
var _punch_telegraph_timer := 0.0
var _retreat_timer := 0.0
var _roll_direction := Vector3.ZERO
var _roll_timer := 0.0
var _charge_direction := Vector3.FORWARD
var _charge_target: Node3D
var _charge_hit_targets: Array[Node] = []
var _charge_trail_timer := 0.0
var _charge_cooldown := 0.0
var _flying_kick_cooldown := 0.0
var _flying_kick_direction := Vector3.FORWARD
## Last selectable brawl attack — excluded from the next pick (no back-to-back repeats).
var _last_brawl_attack := -1
var _pending_brawl_attack := AttackKind.PUNCH
var _move_blend := 0.0
var _walk_run_blend := 0.0
var _block_blend := 0.0
var _sit_hold_position := Vector3.ZERO
var _player_in_range: Node3D
var _talking := false
var _fight_started := false
var _boss_health_bar
var _voice_player: AudioStreamPlayer3D
var _flee_direction := Vector3.FORWARD
var _flee_timer := 0.0
var _defeat_sequence_started := false
var _stored_collision_layer := 1
var _stored_collision_mask := 1
var _bow_rig
var _archery_phase_timer := 0.0
var _archery_shot_timer := 0.0
var _archery_telegraph_timer := 0.0
var _archery_orbit_sign := 1.0
var _archery_locomotion_active := false
var _idle_anim_node: AnimationNodeAnimation
var _walk_anim_node: AnimationNodeAnimation
var _run_anim_node: AnimationNodeAnimation
## Direct ref required: "parameters/AttackAnim/animation" tree sets are a
## silent no-op in 4.6, which locked every attack to the build-time clip.
var _attack_anim_node: AnimationNodeAnimation
var _lasso_captured := false
var _lasso_player: Node3D = null
var _lasso_ring = null
var _lasso_rope_length := 2.4
var _lasso_standup_active := false
var _lasso_standup_timer := 0.0
var _lasso_standup_duration := 1.0
var _chip_damage_buffer := 0.0
var _sit_model_sink := 0.0
var _stand_up_total := 1.0


func _on_actor_ready() -> void:
	add_to_group("chief_getcha_boss")
	add_to_group("cave_enemy")
	add_to_group("duel_target")
	add_to_group("faction_npc")
	post_attack_recovery_seconds = 0.4
	_stored_collision_layer = collision_layer
	_stored_collision_mask = collision_mask
	_sit_hold_position = global_position
	MeshyCharacterMaterials.apply_outdoor_skin(_body)
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	setup_npc_locomotion_audio()
	call_deferred("_finalize_spawn")


func _finalize_spawn() -> void:
	snap_to_floor()
	_sit_hold_position = global_position
	_begin_sitting_pose()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _defeated and _phase != Phase.FLEEING:
		return

	if _lasso_captured:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		elif not should_preserve_knockback_velocity():
			velocity.y = minf(velocity.y, 0.0)
		move_and_slide()
		return

	tick_melee_stun(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_charge_cooldown = maxf(_charge_cooldown - delta, 0.0)
	_flying_kick_cooldown = maxf(_flying_kick_cooldown - delta, 0.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif not should_preserve_knockback_velocity():
		velocity.y = minf(velocity.y, 0.0)

	match _phase:
		Phase.SITTING:
			_process_sitting(delta)
		Phase.STANDING_UP:
			_process_standing_up(delta)
		Phase.FIGHTING:
			_process_fighting(delta)
		Phase.FLEEING:
			_process_fleeing(delta)

	move_and_slide()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var sprinting := (
		_ai_state in [AiState.CHASE, AiState.CHARGE_RUN, AiState.FLYING_KICK_SPRINT, AiState.FLYING_KICK]
		or _phase == Phase.FLEEING
	) and horizontal_speed > WALK_SPEED * 0.9
	var moving := horizontal_speed > 0.05 and _phase in [Phase.FIGHTING, Phase.FLEEING]
	update_npc_locomotion_audio(delta, horizontal_speed, moving, sprinting)


func _process(_delta: float) -> void:
	if _voice_player != null and is_instance_valid(_voice_player) and _voice_player.playing:
		_voice_player.global_position = get_voice_world_position()


func interact(player: Node3D) -> void:
	if _talking or _fight_started or _defeated or player == null:
		return

	_talking = true
	_player_in_range = player
	velocity = Vector3.ZERO
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		FIGHT_LINES,
		func() -> void:
			_end_dialog(player)
			_begin_boss_fight(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func get_interact_hint() -> String:
	if _fight_started or _defeated:
		return ""
	return "Talk"


func get_faction_id() -> StringName:
	return FactionIdsScript.BANDITS


func _get_max_health() -> int:
	return MAX_HEALTH


func get_combat_health() -> int:
	return _health


func get_combat_max_health() -> int:
	return MAX_HEALTH


## Suppress the default single-drop kill loot — defeat uses a currency shower.
func drops_kill_loot() -> bool:
	return false


func drops_weapon_on_death() -> bool:
	return false


func is_unarmed_blocking() -> bool:
	return (
		_blocking
		and _ai_state == AiState.BLOCKING
		and _block_blend > ChiefGetchaAnimConfigScript.BLOCK_BLEND_THRESHOLD
	)


func is_facing_punch_block(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	var facing := get_punch_facing_direction()
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001 and facing.length_squared() > 0.0001:
			return facing.normalized().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN
	return true


func is_lassoable() -> bool:
	return (
		_fight_started
		and not _defeated
		and not _lasso_captured
		and _phase == Phase.FIGHTING
	)


func get_lasso_attach_point() -> Vector3:
	return GroyperBodyUtils.get_lasso_head_attach_point(_skeleton, self)


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func get_lasso_max_match_speed() -> float:
	return RUN_SPEED


func get_lasso_drag_visual() -> Node3D:
	return _model


func begin_lasso_capture(player: Node3D, rope_length: float, ring = null) -> void:
	_ensure_lasso_ragdoll()
	_lasso_captured = true
	_lasso_standup_active = false
	_lasso_player = player
	_lasso_ring = ring
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	_end_blocking()
	_abort_roll_one_shot()
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set(
			"parameters/%s/request" % ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)
	_attack_strike_index = 0
	_attack_strike_times = PackedFloat32Array()
	_punch_telegraph_timer = 0.0
	_archery_locomotion_active = false
	if _bow_rig != null and _bow_rig.has_method("holster"):
		_bow_rig.holster()
	_debug_toss("begin_lasso_capture")


func end_lasso_capture() -> void:
	_lasso_captured = false
	_lasso_player = null
	_lasso_ring = null
	_lasso_standup_active = false
	velocity = Vector3.ZERO
	_snap_model_upright()
	_resume_combat_after_toss()
	_snap_model_upright()
	_debug_toss("end_lasso_capture")
	if _defeated or _phase != Phase.FIGHTING:
		return
	_ai_state = AiState.DECIDING
	_decision_timer = 0.2
	_attack_cooldown = maxf(_attack_cooldown, 0.45)


func get_lasso_ragdoll():
	_ensure_lasso_ragdoll()
	return _ragdoll


func get_lasso_animation_player() -> AnimationPlayer:
	return _animation_player


func has_lasso_standup_animation() -> bool:
	# Ragdoll handoff only — do NOT use Stand_Up3 here. That clip starts in the
	# cross-legged sit pose and was snapping him back into sitting after a toss.
	return _ragdoll != null


func is_lasso_standup_active() -> bool:
	return _lasso_standup_active


func begin_lasso_drag_standup() -> bool:
	if _ragdoll == null or not _ragdoll.is_lasso_drag_mode():
		_debug_toss("begin_standup FAIL no ragdoll/drag")
		return false
	_lasso_standup_active = true
	_lasso_standup_timer = 0.0
	_lasso_standup_duration = 0.55
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.stop()
	_debug_toss("begin_standup ragdoll-only")
	return true


func update_lasso_drag_standup(delta: float) -> void:
	if not _lasso_standup_active:
		return
	_lasso_standup_timer += delta
	var progress := clampf(_lasso_standup_timer / maxf(_lasso_standup_duration, 0.001), 0.0, 1.0)
	if _ragdoll != null and _ragdoll.has_method("set_standup_body_progress"):
		_ragdoll.set_standup_body_progress(progress)
	if progress >= 0.99:
		_debug_toss("standup complete progress=%.2f" % progress)
		_finish_lasso_standup()


func _finish_lasso_standup() -> void:
	if not _lasso_standup_active and (
		_ragdoll == null
		or not _ragdoll.has_method("is_active")
		or not _ragdoll.is_active()
	):
		return
	_lasso_standup_active = false
	_sit_model_sink = 0.0
	_snap_model_upright()
	if _ragdoll != null:
		if _ragdoll.has_method("is_lasso_animation_standup") and _ragdoll.is_lasso_animation_standup():
			_ragdoll.finish_animation_standup()
		elif _ragdoll.has_method("is_active") and _ragdoll.is_active():
			_debug_toss("finish_standup forcing ragdoll.deactivate")
			_ragdoll.deactivate()
	_snap_model_upright()
	_debug_toss("finish_standup done")


func _snap_model_upright() -> void:
	if _model == null:
		return
	var yaw := GroyperBodyUtils.MODEL_YAW_OFFSET
	if _combat_target != null and is_instance_valid(_combat_target):
		var to_target := _combat_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			yaw = get_model_facing_yaw_for_direction(to_target.normalized())
	# Full euler replace — apply_model_baseline only writes Y and preserves
	# ragdoll pitch/roll, which is what left him stuck on his back.
	_model.rotation = Vector3(0.0, yaw, 0.0)
	_model.position = Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y + _sit_model_sink, 0.0)


func _apply_sit_model_sink(target_weight: float, delta: float) -> void:
	if _model == null:
		return
	var target_sink := clampf(target_weight, 0.0, 1.0) * SIT_MODEL_Y_OFFSET
	var step := 1.0 - exp(-SIT_MODEL_SINK_SPEED * delta)
	_sit_model_sink = lerpf(_sit_model_sink, target_sink, step)
	_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + _sit_model_sink


func _clear_sit_model_sink() -> void:
	_sit_model_sink = 0.0
	if _model != null:
		_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y


func _debug_toss(label: String) -> void:
	if not DEBUG_TOSS_RECOVERY:
		return
	var pitch := 0.0
	var roll := 0.0
	if _model != null:
		pitch = rad_to_deg(_model.rotation.x)
		roll = rad_to_deg(_model.rotation.z)
	var ragdoll_active: bool = (
		_ragdoll != null and _ragdoll.has_method("is_active") and bool(_ragdoll.is_active())
	)
	var anim_standup: bool = (
		_ragdoll != null
		and _ragdoll.has_method("is_lasso_animation_standup")
		and bool(_ragdoll.is_lasso_animation_standup())
	)
	print(
		"[ChiefToss] %s | pitch=%.1f roll=%.1f captured=%s standup=%s ragdoll=%s animStand=%s phase=%s"
		% [
			label,
			pitch,
			roll,
			_lasso_captured,
			_lasso_standup_active,
			ragdoll_active,
			anim_standup,
			_phase,
		]
	)


func _resume_combat_after_toss() -> void:
	_clear_sit_model_sink()
	if _defeated or _phase != Phase.FIGHTING:
		_resume_locomotion_animations()
		_snap_model_upright()
		return
	# Standup-flavored ragdoll deactivate skips reset_bone_poses; clear the
	# leftover sprawl before the rebuilt tree takes over.
	if _skeleton != null:
		_skeleton.reset_bone_poses()
	# Ragdoll reset leaves rest/T-pose — rebuild the combat tree so idle/attack write bones again.
	_setup_combat_animation_tree()
	_move_blend = 0.0
	_walk_run_blend = 0.0
	_block_blend = 0.0
	_set_move_blend(0.0)
	_set_walk_run_blend(0.0)
	_set_block_blend(0.0)
	_snap_model_upright()
	_debug_toss("resume_combat")


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	const LassoHumanoidDragScript := preload("res://gameplay/lasso/lasso_humanoid_drag.gd")
	LassoHumanoidDragScript.apply(self, self, player, _lasso_ring, _lasso_rope_length, delta)
	LassoHumanoidDragScript.finish_settling_if_needed(self)


func enter_melee_aggro(player: Node3D) -> void:
	if _defeated or player == null:
		return
	_combat_target = player
	if _phase == Phase.FIGHTING and not _lasso_captured:
		_ai_state = AiState.DECIDING
		_decision_timer = 0.15
		_snap_model_upright()


func _ensure_lasso_ragdoll() -> void:
	if _ragdoll != null:
		return
	_setup_combat_ragdoll()


func suspend_animations_for_ragdoll() -> void:
	_suspend_locomotion_animations()


func get_punch_facing_direction() -> Vector3:
	var flat := _attack_direction
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		flat = -_model.global_transform.basis.z
	flat.y = 0.0
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated or _phase != Phase.FIGHTING:
		return
	if _lasso_captured:
		# Landing damage from toss still applies; skip block/react while airborne.
		_apply_incoming_damage(hit_info)
		return

	_melee_hit_absorbed = false
	var consider_reactive_block := (
		bool(hit_info.get("punch_hit", false))
		and not _blocking
		and not _defeated
	)

	if _can_block_hit(hit_info):
		_melee_hit_absorbed = true
		var attacker: Node = hit_info.get("shooter")
		MeleeClashScript.resolve(self, attacker, hit_info)
		_try_block_counter_kick(hit_info)
		return

	_focus_attacker_from_hit(hit_info)
	var cancelled_archery := false
	if _ai_state == AiState.ARCHERY:
		_cancel_archery_from_damage()
		cancelled_archery = true

	_play_hit_react()
	_apply_incoming_damage(hit_info)
	if _defeated:
		return

	if (
		not cancelled_archery
		and consider_reactive_block
		and not _defeated
		and randf() < PUNCHED_BLOCK_CHANCE
	):
		_begin_blocking(randf_range(PUNCHED_BLOCK_MIN, PUNCHED_BLOCK_MAX))


func _apply_incoming_damage(hit_info: Dictionary) -> void:
	var resolved := hit_info.duplicate(true)
	var direct_damage := int(resolved.get("damage", 0))
	if direct_damage <= 0:
		var chip := float(resolved.get("chip_damage", 0.0))
		if chip > 0.0:
			_chip_damage_buffer += chip
			var applied := 0
			while _chip_damage_buffer >= 1.0:
				_chip_damage_buffer -= 1.0
				applied += 1
			if applied <= 0:
				# Still show hit react/knockback for fractional punches that
				# have not filled a full HP yet.
				if bool(resolved.get("melee", false)) or bool(resolved.get("force_knockback", false)):
					BulletHitDamageScript.apply_body_knockback(self, resolved)
					hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
				CombatHitFlashScript.flash_damage(self)
				return
			resolved["damage"] = applied
		else:
			return

	var result := BulletHitDamageScript.process_hit(self, resolved, _health, MAX_HEALTH)
	_health = result.health
	CombatHitFlashScript.flash_damage(self)
	if result.knockback_applied:
		hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if result.killed:
		_die(resolved)


func on_unarmed_block_clash(hit_info: Dictionary) -> void:
	## Called from UnarmedPunchBlock.resolve after a successful clash.
	_try_block_counter_kick(hit_info)


func get_block_clash_fx_modulate() -> Color:
	return ChiefGetchaAnimConfigScript.BLOCK_CLASH_FX_MODULATE


func _try_block_counter_kick(hit_info: Dictionary) -> void:
	if _defeated or _phase != Phase.FIGHTING:
		return
	if not bool(hit_info.get("punch_hit", false)):
		return
	if _ai_state in [AiState.ATTACK_WINDUP, AiState.ATTACKING, AiState.FLYING_KICK]:
		return
	if randf() >= ChiefGetchaAnimConfigScript.BLOCK_COUNTER_KICK_CHANCE:
		return
	_focus_attacker_from_hit(hit_info)
	var kind := AttackKind.KICK
	if randf() < ChiefGetchaAnimConfigScript.BLOCK_COUNTER_SPIN_KICK_CHANCE:
		kind = AttackKind.SPIN_KICK
	_begin_block_counter_kick(kind)


func get_bullet_capsule() -> Dictionary:
	return GroyperBodyUtils.get_town_bullet_capsule(_skeleton, global_position, 1.8, 2.4)


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_town_head_hit_sphere(_skeleton, global_position, 0.9)


func reset_for_bonfire_rest() -> void:
	if ChurchSanctifyQuest.is_sanctified():
		queue_free()
		return
	if _fight_started and not _defeated:
		return
	if _defeat_sequence_started:
		return
	_reset_boss_state()


func _reset_boss_state() -> void:
	_defeated = false
	_fight_started = false
	_talking = false
	_defeat_sequence_started = false
	_flee_timer = 0.0
	_phase = Phase.SITTING
	_ai_state = AiState.CHASE
	_health = MAX_HEALTH
	_blocking = false
	_lasso_captured = false
	_lasso_player = null
	_lasso_ring = null
	_lasso_standup_active = false
	_chip_damage_buffer = 0.0
	_attack_cooldown = 0.0
	_charge_cooldown = 0.0
	_flying_kick_cooldown = 0.0
	_punch_telegraph_timer = 0.0
	_retreat_timer = 0.0
	velocity = Vector3.ZERO
	collision_layer = _stored_collision_layer
	collision_mask = _stored_collision_mask
	visible = true
	global_position = _sit_hold_position
	_interact_area.monitoring = true
	if _boss_health_bar != null and is_instance_valid(_boss_health_bar):
		_boss_health_bar.queue_free()
	_boss_health_bar = null
	if _ragdoll != null and _ragdoll.is_active():
		_ragdoll.deactivate()
	_resume_locomotion_animations()
	_begin_sitting_pose()


func _process_sitting(delta: float) -> void:
	global_position = _sit_hold_position
	velocity = Vector3.ZERO
	_apply_sit_model_sink(1.0, delta)
	var look_target: Node3D = _player_in_range
	if look_target == null or not is_instance_valid(look_target):
		look_target = _find_player()
	if look_target != null:
		_face_position(look_target.global_position, delta)


func _process_standing_up(delta: float) -> void:
	velocity = Vector3.ZERO
	var stand_progress := 1.0 - clampf(_state_timer / maxf(_stand_up_total, 0.001), 0.0, 1.0)
	_apply_sit_model_sink(1.0 - stand_progress, delta)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	_clear_sit_model_sink()
	_phase = Phase.FIGHTING
	_setup_combat_animation_tree()
	_ai_state = AiState.CHASE
	_roll_decision_timer()
	_begin_chase()


func _process_fighting(delta: float) -> void:
	if is_melee_stunned() and not should_preserve_knockback_velocity():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_update_combat_target()
	if _combat_target == null:
		return

	if _punch_telegraph_timer > 0.0:
		_update_punch_telegraph(delta)
		return

	match _ai_state:
		AiState.CHASE:
			_process_chase(delta)
		AiState.DECIDING:
			_process_deciding(delta)
		AiState.BLOCKING:
			_process_blocking(delta)
		AiState.ATTACK_WINDUP:
			_process_attack_windup(delta)
		AiState.ATTACKING:
			_process_attacking(delta)
		AiState.ROLLING:
			_process_rolling(delta)
		AiState.CHARGE_WINDUP:
			_process_charge_windup(delta)
		AiState.CHARGE_RUN:
			_process_charge_run(delta)
		AiState.FLYING_KICK_SPRINT:
			_process_flying_kick_sprint(delta)
		AiState.FLYING_KICK:
			_process_flying_kick(delta)
		AiState.ARCHERY:
			_process_archery(delta)

	# Never keep absorb-invuln when we're not actually holding a block pose.
	if _ai_state != AiState.BLOCKING and _blocking:
		_blocking = false
		_block_blend = 0.0
		_set_block_blend(0.0)


func _begin_boss_fight(player: Node3D) -> void:
	if _fight_started or _defeated or player == null:
		return

	_fight_started = true
	ChurchSanctifyQuest.begin_quest()
	_combat_target = player
	_interact_area.monitoring = false
	if player.has_method("enter_overworld_combat"):
		player.enter_overworld_combat()
	_boss_health_bar = BossHealthBarScript.attach_to(self, speaker_name)
	_ensure_lasso_ragdoll()
	_phase = Phase.STANDING_UP
	_ai_state = AiState.CHASE
	_play_stand_up()


func _begin_sitting_pose() -> void:
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player == null:
		return
	_setup_sit_clip()
	var sit_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_SIT)
	if _animation_player.has_animation(sit_path):
		_animation_player.play(sit_path)
	_sit_model_sink = SIT_MODEL_Y_OFFSET
	if _model != null:
		_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + _sit_model_sink


func _play_stand_up() -> void:
	if _animation_player == null:
		_clear_sit_model_sink()
		_phase = Phase.FIGHTING
		_setup_combat_animation_tree()
		return
	_setup_stand_up_clip()
	var stand_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_STAND_UP)
	if not _animation_player.has_animation(stand_path):
		_clear_sit_model_sink()
		_phase = Phase.FIGHTING
		_setup_combat_animation_tree()
		return
	var anim := _animation_player.get_animation(stand_path)
	_stand_up_total = maxf(anim.length * 0.5, 0.8)
	_state_timer = _stand_up_total
	_animation_player.play(stand_path)


func _process_chase(delta: float) -> void:
	if _combat_target == null:
		return

	if _retreat_timer > 0.0:
		_retreat_timer -= delta
		var away := global_position - _combat_target.global_position
		away.y = 0.0
		if away.length() >= BRAWL_RETREAT_RANGE or away.length_squared() < 0.0001:
			_retreat_timer = 0.0
		else:
			var back := away.normalized()
			velocity.x = back.x * RUN_SPEED * 0.85
			velocity.z = back.z * RUN_SPEED * 0.85
			_face_position(global_position + back, delta)
			_update_locomotion_blend(delta, Vector2(velocity.x, velocity.z).length(), true)
			return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if Engine.get_physics_frames() % 20 == 0 and _try_begin_flying_kick_sprint(distance):
		return
	if Engine.get_physics_frames() % 35 == 0 and _try_begin_archery(distance):
		return

	if distance <= ATTACK_RANGE:
		_ai_state = AiState.DECIDING
		_roll_decision_timer()
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if distance <= BRAWL_PURSUE_STOP_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_position(_combat_target.global_position, delta)
		_ai_state = AiState.DECIDING
		_roll_decision_timer()
		return

	var dir := to_target.normalized()
	velocity.x = dir.x * RUN_SPEED
	velocity.z = dir.z * RUN_SPEED
	_face_position(global_position + dir, delta)
	_update_locomotion_blend(delta, Vector2(velocity.x, velocity.z).length(), true)


func _process_deciding(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return

	_roll_decision_timer()
	if _combat_target == null:
		return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if _try_begin_archery(distance):
		return
	if distance > ATTACK_RANGE + 0.5:
		_ai_state = AiState.CHASE
		return

	_decide_brawl_action()


func _decide_brawl_action() -> void:
	var to_target := (
		_combat_target.global_position - global_position
		if _combat_target != null
		else Vector3.ZERO
	)
	to_target.y = 0.0
	var distance := to_target.length()

	if _try_begin_archery(distance):
		return

	if _try_begin_flying_kick_sprint(distance):
		return

	if (
		_charge_cooldown <= 0.0
		and TcChargeRunScript.can_cast(_charge_cooldown)
		and _combat_target != null
		and TcChargeRunScript.is_in_range(self, _combat_target)
		and randf() < CHARGE_RUN_CHANCE
	):
		_begin_charge_windup()
		return

	# Attack first — boss should feel aggressive.
	if _attack_cooldown <= 0.0:
		_begin_punch_telegraph()
		return

	if randf() < BRAWL_BLOCK_CHANCE:
		_begin_blocking(randf_range(BRAWL_BLOCK_MIN, BRAWL_BLOCK_MAX))
		return
	if randf() < BRAWL_ROLL_CHANCE:
		_begin_roll()
		return
	if randf() < BRAWL_RETREAT_CHANCE:
		_retreat_timer = BRAWL_RETREAT_DURATION
		_ai_state = AiState.CHASE
		return
	_ai_state = AiState.CHASE


func _process_blocking(delta: float) -> void:
	_blocking = true
	# Snap pose on — slow lerp was absorbing hits before arms looked blocked.
	if _block_blend < 0.99:
		_block_blend = 1.0
		_set_block_blend(_block_blend)
	velocity.x = 0.0
	velocity.z = 0.0
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_end_blocking()


func _process_attack_windup(delta: float) -> void:
	_velocity_zero()
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _flat_direction_to(_combat_target.global_position)
	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_begin_attacking()


func _process_attacking(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	_velocity_zero()
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _flat_direction_to(_combat_target.global_position)

	while (
		_attack_strike_index < _attack_strike_times.size()
		and _attack_elapsed >= _attack_strike_times[_attack_strike_index]
	):
		_apply_attack_strike()
		_attack_strike_index += 1
		_attack_struck = true

	if _attack_timer <= 0.0:
		_end_attacking()


func _process_rolling(delta: float) -> void:
	_roll_timer -= delta
	_move_in_direction(_roll_direction, ROLL_SPEED, delta)
	_update_locomotion_blend(delta, ROLL_SPEED, true)
	if _roll_timer <= 0.0:
		_end_rolling()


func _process_charge_windup(delta: float) -> void:
	_velocity_zero()
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_begin_charge_run()


func _process_charge_run(delta: float) -> void:
	_state_timer -= delta
	_charge_trail_timer -= delta
	_charge_direction = TcChargeRunScript.update_charge_direction(
		_charge_direction,
		self,
		_charge_target,
		delta
	)
	velocity.x = _charge_direction.x * TcChargeRunScript.CHARGE_SPEED
	velocity.z = _charge_direction.z * TcChargeRunScript.CHARGE_SPEED
	_face_position(global_position + _charge_direction, delta)
	_update_locomotion_blend(delta, TcChargeRunScript.CHARGE_SPEED, true)

	if _charge_trail_timer <= 0.0:
		_charge_trail_timer = TcChargeRunScript.TRAIL_INTERVAL
		TcChargeRunScript.spawn_fire_trail(self, _charge_direction)

	if _charge_target != null and TcChargeRunScript.check_player_hit(self, _charge_target):
		if not _charge_hit_targets.has(_charge_target):
			_charge_hit_targets.append(_charge_target)
			TcChargeRunScript.apply_player_hit(self, _charge_target, _charge_direction)

	if _state_timer <= 0.0:
		_finish_charge_run()


func _begin_chase() -> void:
	_ai_state = AiState.CHASE


func _begin_punch_telegraph() -> void:
	if _attack_cooldown > 0.0:
		_ai_state = AiState.CHASE
		return
	_pending_brawl_attack = _pick_brawl_attack()
	_velocity_zero()
	if _combat_target != null:
		_face_position(_combat_target.global_position, get_physics_process_delta_time())
	_show_alert_fx()
	_punch_telegraph_timer = PUNCH_TELEGRAPH_TIME


func _update_punch_telegraph(delta: float) -> void:
	_velocity_zero()
	_update_locomotion_blend(delta, 0.0, false)
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
	_punch_telegraph_timer = maxf(_punch_telegraph_timer - delta, 0.0)
	if _punch_telegraph_timer > 0.0:
		return
	_begin_attack_windup(_pending_brawl_attack)


func _pick_brawl_attack() -> AttackKind:
	## Close-range kit: Weapon Combo 1, Lunge Spin Kick, Double Combo, Skill 3.
	## Never pick the same attack twice in a row.
	var options: Array[Dictionary] = [
		{"kind": AttackKind.PUNCH, "weight": BRAWL_ATTACK_WEIGHT_PUNCH},
		{"kind": AttackKind.SPIN_KICK, "weight": BRAWL_ATTACK_WEIGHT_SPIN_KICK},
		{"kind": AttackKind.DOUBLE_COMBO, "weight": BRAWL_ATTACK_WEIGHT_DOUBLE_COMBO},
		{"kind": AttackKind.SKILL_3, "weight": BRAWL_ATTACK_WEIGHT_SKILL_3},
	]
	var total_weight := 0.0
	var eligible: Array[Dictionary] = []
	for option in options:
		var kind: int = option["kind"]
		if kind == _last_brawl_attack:
			continue
		eligible.append(option)
		total_weight += float(option["weight"])
	if eligible.is_empty():
		return AttackKind.PUNCH
	var roll := randf() * total_weight
	var cursor := 0.0
	for option in eligible:
		cursor += float(option["weight"])
		if roll <= cursor:
			return option["kind"] as AttackKind
	return eligible[eligible.size() - 1]["kind"] as AttackKind


func _begin_attack_windup(kind: AttackKind) -> void:
	_attack_kind = kind
	_ai_state = AiState.ATTACK_WINDUP
	_windup_timer = 0.18
	_attack_direction = _flat_direction_to(
		_combat_target.global_position if _combat_target != null else global_position + Vector3.FORWARD
	)


func _begin_attacking() -> void:
	_ai_state = AiState.ATTACKING
	_attack_elapsed = 0.0
	_attack_struck = false
	_attack_strike_index = 0
	_attack_direction = _flat_direction_to(
		_combat_target.global_position if _combat_target != null else global_position + Vector3.FORWARD
	)
	var anim_name := _attack_anim_name(_attack_kind)
	var anim_path := _clip_path(anim_name)
	var length := 1.0
	if _animation_player != null and _animation_player.has_animation(anim_path):
		length = _animation_player.get_animation(anim_path).length
	_attack_strike_times = _get_attack_strike_times(length)
	var last_strike := length * _get_attack_strike_fraction()
	if not _attack_strike_times.is_empty():
		last_strike = _attack_strike_times[_attack_strike_times.size() - 1]
	# Multi-hit clips must run through the late second strike, not cut at ~72% length.
	_attack_timer = maxf(last_strike + 0.28, length * 0.98)
	_fire_attack_one_shot(anim_path)


func _end_attacking() -> void:
	if _is_selectable_brawl_attack(_attack_kind):
		_last_brawl_attack = _attack_kind as int
	_attack_struck = false
	_attack_strike_index = 0
	_attack_strike_times = PackedFloat32Array()
	_attack_cooldown = MeleePunchScript.COOLDOWN * randf_range(
		BRAWL_PUNCH_COOLDOWN_MULT_MIN,
		BRAWL_PUNCH_COOLDOWN_MULT_MAX
	)
	_ai_state = AiState.DECIDING
	_decision_timer = get_post_attack_recovery_seconds()


func _is_selectable_brawl_attack(kind: AttackKind) -> bool:
	return kind in [
		AttackKind.PUNCH,
		AttackKind.SPIN_KICK,
		AttackKind.DOUBLE_COMBO,
		AttackKind.SKILL_3,
	]


func _apply_attack_strike() -> void:
	var damage := PUNCH_DAMAGE
	if _attack_kind == AttackKind.KICK:
		damage = KICK_DAMAGE
	elif _attack_kind == AttackKind.SPIN_KICK:
		damage = KICK_DAMAGE * 1.25
	elif _attack_kind == AttackKind.FLYING_KICK:
		damage = FLYING_KICK_DAMAGE
	elif _attack_kind == AttackKind.COMBO:
		damage = PUNCH_DAMAGE * 1.15
	elif _attack_kind == AttackKind.DOUBLE_COMBO:
		damage = PUNCH_DAMAGE * 1.1
	elif _attack_kind == AttackKind.SKILL_3:
		damage = PUNCH_DAMAGE * 1.2
	MeleePunchScript.apply_strike(
		self,
		_attack_direction,
		_combat_target,
		{
			"damage": damage,
			"knockdown": _attack_kind in [
				AttackKind.KICK,
				AttackKind.SPIN_KICK,
				AttackKind.FLYING_KICK,
			],
			"face_punch_reaction": _attack_kind in [
				AttackKind.PUNCH,
				AttackKind.DOUBLE_COMBO,
				AttackKind.SKILL_3,
			],
		}
	)
	# Only lunge on the first hit of a multi-hit string so range stays honest.
	if _attack_strike_index == 0:
		velocity.x += _attack_direction.x * MeleePunchScript.LUNGE_SPEED * 0.65
		velocity.z += _attack_direction.z * MeleePunchScript.LUNGE_SPEED * 0.65


func _begin_blocking(duration: float = -1.0) -> void:
	_ai_state = AiState.BLOCKING
	_blocking = true
	_block_blend = 1.0
	_set_block_blend(1.0)
	_punch_telegraph_timer = 0.0
	if duration < 0.0:
		_state_timer = randf_range(BRAWL_BLOCK_MIN, BRAWL_BLOCK_MAX)
	else:
		_state_timer = duration


func _end_blocking() -> void:
	_blocking = false
	_block_blend = 0.0
	_set_block_blend(0.0)
	_ai_state = AiState.DECIDING
	_roll_decision_timer()


func _begin_block_counter_kick(kind: AttackKind = AttackKind.KICK) -> void:
	_blocking = false
	_block_blend = 0.0
	_set_block_blend(0.0)
	_punch_telegraph_timer = 0.0
	_attack_strike_index = 0
	_attack_strike_times = PackedFloat32Array()
	_abort_roll_one_shot()
	_begin_attack_windup(kind)


func _try_begin_flying_kick_sprint(distance: float) -> bool:
	if _flying_kick_cooldown > 0.0 or _combat_target == null:
		return false
	if distance < FLYING_KICK_RANGE_MIN or distance > FLYING_KICK_RANGE_MAX:
		return false
	if randf() >= FLYING_KICK_CHANCE:
		return false
	_begin_flying_kick_sprint()
	return true


func _begin_flying_kick_sprint() -> void:
	_ai_state = AiState.FLYING_KICK_SPRINT
	_punch_telegraph_timer = 0.0
	_blocking = false
	_block_blend = 0.0
	_set_block_blend(0.0)
	_show_alert_fx()


func _process_flying_kick_sprint(delta: float) -> void:
	if _combat_target == null:
		_ai_state = AiState.CHASE
		return
	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= FLYING_KICK_LAUNCH_RANGE or distance < 0.35:
		_begin_flying_kick()
		return
	if distance > FLYING_KICK_RANGE_MAX + 2.0:
		_flying_kick_cooldown = FLYING_KICK_COOLDOWN * 0.35
		_ai_state = AiState.CHASE
		return
	var dir := to_target.normalized()
	var sprint_speed := RUN_SPEED * FLYING_KICK_SPRINT_MULT
	velocity.x = dir.x * sprint_speed
	velocity.z = dir.z * sprint_speed
	_face_position(global_position + dir, delta)
	_update_locomotion_blend(delta, sprint_speed, true)


func _begin_flying_kick() -> void:
	_ai_state = AiState.FLYING_KICK
	_attack_kind = AttackKind.FLYING_KICK
	_attack_elapsed = 0.0
	_attack_struck = false
	_flying_kick_direction = _flat_direction_to(
		_combat_target.global_position if _combat_target != null else global_position + Vector3.FORWARD
	)
	var anim_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_FLYING_KICK)
	var length := 1.0
	if _animation_player != null and _animation_player.has_animation(anim_path):
		length = _animation_player.get_animation(anim_path).length
	_attack_timer = maxf(length * 0.55, 0.55)
	velocity.x = _flying_kick_direction.x * FLYING_KICK_FORWARD_SPEED
	velocity.z = _flying_kick_direction.z * FLYING_KICK_FORWARD_SPEED
	velocity.y = FLYING_KICK_RISE_SPEED
	_fire_attack_one_shot(anim_path)


func _process_flying_kick(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	velocity.x = _flying_kick_direction.x * FLYING_KICK_FORWARD_SPEED
	velocity.z = _flying_kick_direction.z * FLYING_KICK_FORWARD_SPEED
	_face_position(global_position + _flying_kick_direction, delta)
	_update_locomotion_blend(delta, FLYING_KICK_FORWARD_SPEED, true)

	var strike_time := _get_attack_length() * ChiefGetchaAnimConfigScript.FLYING_KICK_STRIKE_FRACTION
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		_apply_flying_kick_strike()

	if _attack_timer <= 0.0 or (_attack_elapsed > 0.18 and is_on_floor() and _attack_struck):
		_end_flying_kick()


func _apply_flying_kick_strike() -> void:
	if _combat_target == null or not is_instance_valid(_combat_target):
		return
	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > FLYING_KICK_CONTACT_RANGE:
		return
	MeleePunchScript.apply_strike(
		self,
		_flying_kick_direction,
		_combat_target,
		{
			"damage": FLYING_KICK_DAMAGE,
			"knockdown": true,
			"face_punch_reaction": false,
		}
	)


func _end_flying_kick() -> void:
	_flying_kick_cooldown = FLYING_KICK_COOLDOWN
	_attack_struck = false
	_velocity_zero()
	_ai_state = AiState.DECIDING
	_decision_timer = get_post_attack_recovery_seconds() * 0.55


func _try_begin_archery(distance: float) -> bool:
	if _combat_target == null:
		return false
	if distance < ARCHERY_RANGE_MIN or distance > ARCHERY_RANGE_MAX:
		return false
	if randf() >= ARCHERY_CHANCE:
		return false
	_begin_archery()
	return true


func _begin_archery() -> void:
	_ensure_bow_rig()
	_ai_state = AiState.ARCHERY
	_punch_telegraph_timer = 0.0
	_blocking = false
	_block_blend = 0.0
	_set_block_blend(0.0)
	_archery_phase_timer = randf_range(ARCHERY_DURATION_MIN, ARCHERY_DURATION_MAX)
	_archery_shot_timer = ARCHERY_SHOT_TELEGRAPH
	_archery_telegraph_timer = ARCHERY_SHOT_TELEGRAPH
	_archery_orbit_sign = -1.0 if randf() < 0.5 else 1.0
	if _bow_rig != null:
		_bow_rig.apply_offsets(
			bow_back_position,
			bow_back_rotation_deg,
			bow_hand_position,
			bow_hand_rotation_deg
		)
		_bow_rig.set_equipped(true)
	_set_archery_locomotion(true)
	_show_alert_fx()
	_fire_attack_one_shot(_clip_path(ChiefGetchaAnimConfigScript.CLIP_BOW_AIM))


func _process_archery(delta: float) -> void:
	if _combat_target == null or not is_instance_valid(_combat_target):
		_end_archery()
		return

	if _bow_rig != null:
		_bow_rig.apply_offsets(
			bow_back_position,
			bow_back_rotation_deg,
			bow_hand_position,
			bow_hand_rotation_deg
		)

	_archery_phase_timer -= delta
	_face_position(_combat_target.global_position, delta)
	_update_archery_movement(delta)

	if _archery_telegraph_timer > 0.0:
		_archery_telegraph_timer -= delta
		_archery_shot_timer -= delta
		if _archery_telegraph_timer <= 0.0:
			_fire_archery_shot()
			_archery_shot_timer = ARCHERY_SHOT_INTERVAL
		return

	_archery_shot_timer -= delta
	if _archery_shot_timer <= 0.0:
		_archery_telegraph_timer = ARCHERY_SHOT_TELEGRAPH
		_archery_shot_timer = ARCHERY_SHOT_TELEGRAPH
		_show_alert_fx()
		_fire_attack_one_shot(_clip_path(ChiefGetchaAnimConfigScript.CLIP_BOW_AIM))

	if _archery_phase_timer <= 0.0:
		_end_archery()


func _update_archery_movement(delta: float) -> void:
	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var move_dir := Vector3.ZERO
	if distance > 0.001:
		var forward := to_target.normalized()
		var side := Vector3(-forward.z, 0.0, forward.x) * _archery_orbit_sign
		if distance < ARCHERY_PREFERRED_RANGE - 1.2:
			move_dir = (-forward * 0.65 + side * 0.55).normalized()
		elif distance > ARCHERY_PREFERRED_RANGE + 1.6:
			move_dir = (forward * 0.7 + side * 0.45).normalized()
		else:
			move_dir = side
	velocity.x = move_dir.x * ARCHERY_MOVE_SPEED
	velocity.z = move_dir.z * ARCHERY_MOVE_SPEED
	_update_locomotion_blend(delta, ARCHERY_MOVE_SPEED, false)


func _fire_archery_shot() -> void:
	if _bow_rig == null or _combat_target == null:
		return
	var aim := _combat_target.global_position + Vector3(0.0, 1.05, 0.0)
	var root := get_tree().current_scene if get_tree() != null else get_parent()
	_bow_rig.fire_at(aim, self, root)


func _cancel_archery_from_damage() -> void:
	_end_archery(false)
	_ai_state = AiState.DECIDING
	_decision_timer = get_post_attack_recovery_seconds() * 0.35


func _end_archery(return_to_deciding: bool = true) -> void:
	_archery_phase_timer = 0.0
	_archery_shot_timer = 0.0
	_archery_telegraph_timer = 0.0
	if _bow_rig != null:
		_bow_rig.set_equipped(false)
	_set_archery_locomotion(false)
	_velocity_zero()
	if return_to_deciding:
		_ai_state = AiState.DECIDING
		_roll_decision_timer()


func _ensure_bow_rig() -> void:
	if _bow_rig != null:
		return
	if _skeleton == null:
		_bind_rig()
	_bow_rig = ChiefGetchaBowRigScript.new()
	_bow_rig.ensure_mounted(_skeleton)
	_bow_rig.apply_offsets(
		bow_back_position,
		bow_back_rotation_deg,
		bow_hand_position,
		bow_hand_rotation_deg
	)


func _set_archery_locomotion(active: bool) -> void:
	_archery_locomotion_active = active
	if _idle_anim_node == null or _walk_anim_node == null or _run_anim_node == null:
		return
	if active:
		_idle_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_BOW_AIM)
		_walk_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_BOW_WALK)
		_run_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_BOW_WALK)
	else:
		_idle_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_IDLE)
		_walk_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_WALK)
		_run_anim_node.animation = _clip_path(ChiefGetchaAnimConfigScript.CLIP_RUN)


func _begin_roll() -> void:
	if _combat_target == null:
		return
	_ai_state = AiState.ROLLING
	var away := global_position - _combat_target.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -global_transform.basis.z
	_roll_direction = away.normalized()
	var roll_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_ROLL)
	var roll_length := 0.7
	if _animation_player != null and _animation_player.has_animation(roll_path):
		roll_length = _animation_player.get_animation(roll_path).length * 0.5
	_roll_timer = roll_length
	_fire_roll_one_shot(roll_path)


func _end_rolling() -> void:
	_ai_state = AiState.DECIDING
	_roll_decision_timer()


func _begin_charge_windup() -> void:
	_charge_target = _combat_target
	_ai_state = AiState.CHARGE_WINDUP
	_state_timer = TcChargeRunScript.WINDUP_DURATION
	_charge_hit_targets.clear()
	if _charge_target != null:
		TcChargeRunScript.spawn_target_alert(self, _charge_target)


func _begin_charge_run() -> void:
	_ai_state = AiState.CHARGE_RUN
	var to_target := _charge_target.global_position - global_position if _charge_target != null else Vector3.FORWARD
	to_target.y = 0.0
	_charge_direction = to_target.normalized() if to_target.length_squared() > 0.0001 else _get_flat_forward()
	_state_timer = TcChargeRunScript.MAX_DURATION
	_charge_trail_timer = 0.0
	var charge_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_CHARGE)
	_fire_attack_one_shot(charge_path)


func _finish_charge_run() -> void:
	_charge_cooldown = TcChargeRunScript.COOLDOWN
	_velocity_zero()
	_ai_state = AiState.DECIDING
	_roll_decision_timer()


func _can_block_hit(hit_info: Dictionary) -> bool:
	# Must match is_unarmed_blocking — no invisible absorb before the pose is up.
	if not is_unarmed_blocking():
		return false
	if not bool(hit_info.get("punch_hit", false)) and not bool(hit_info.get("melee", false)):
		return false
	return is_facing_punch_block(hit_info)


func _focus_attacker_from_hit(hit_info: Dictionary) -> void:
	var shooter: Node3D = hit_info.get("shooter")
	if shooter == null or not is_instance_valid(shooter):
		return
	_combat_target = shooter


func _die(hit_info: Dictionary) -> void:
	if _defeated or _defeat_sequence_started:
		return
	if _ai_state == AiState.ARCHERY:
		_end_archery(false)
	_defeated = true
	_defeat_sequence_started = true
	_phase = Phase.DEFEATED
	_velocity_zero()
	_blocking = false
	_interact_area.monitoring = false
	if _boss_health_bar != null and is_instance_valid(_boss_health_bar):
		_boss_health_bar.queue_free()
	_boss_health_bar = null
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudioScript.play_death_sound(self, hit_position)
	ChurchSanctifyQuest.mark_chief_defeated()
	_persist_church_sanctify_progress()
	_clear_church_skeleton_ambush()
	_start_defeat_loot_shower(hit_info)
	_spawn_church_recurve_reward()
	call_deferred("_play_defeat_cinematic", hit_info)


func _persist_church_sanctify_progress() -> void:
	var player := _combat_target
	if player == null or not is_instance_valid(player):
		player = _find_player()
	var stage := get_tree().current_scene if get_tree() != null else null
	AdventureSave.sync_runtime_state(player, stage)


func _play_defeat_cinematic(_hit_info: Dictionary) -> void:
	var player := _combat_target
	if player == null or not is_instance_valid(player):
		player = _find_player()

	_setup_combat_animation_tree()
	_move_blend = 0.0
	_walk_run_blend = 0.0
	_block_blend = 0.0
	_set_move_blend(0.0)
	_set_walk_run_blend(0.0)
	_set_block_blend(0.0)

	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(true)
	if player != null and player.has_method("begin_comet_cinematic_camera"):
		player.begin_comet_cinematic_camera(self)

	var hud = _get_raid_hud(player)
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	_talking = true
	DialogManager.show_dialog_sequence(
		DEFEAT_LINES,
		func() -> void:
			_talking = false
			_stop_voice()
			_begin_defeat_flee(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_talk_voice()
	)


func _begin_defeat_flee(player: Node3D) -> void:
	var away := Vector3.FORWARD
	if player != null and is_instance_valid(player):
		away = global_position - player.global_position
		away.y = 0.0
	if away.length_squared() < 0.0001:
		away = -_model.global_transform.basis.z
		away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3.FORWARD
	_flee_direction = away.normalized()
	_flee_timer = DEFEAT_FLEE_DURATION
	_phase = Phase.FLEEING
	_ai_state = AiState.CHASE
	collision_layer = 0
	collision_mask = _stored_collision_mask
	_setup_combat_animation_tree()
	_move_blend = 1.0
	_walk_run_blend = 1.0
	_set_move_blend(1.0)
	_set_walk_run_blend(1.0)

	if player != null and player.has_method("begin_comet_cinematic_camera_exit"):
		player.begin_comet_cinematic_camera_exit()
	var flee_hud = _get_raid_hud(player)
	if flee_hud != null and flee_hud.has_method("hide_drama_letterbox"):
		flee_hud.hide_drama_letterbox()


func _process_fleeing(delta: float) -> void:
	_flee_timer -= delta
	velocity.x = _flee_direction.x * DEFEAT_FLEE_SPEED
	velocity.z = _flee_direction.z * DEFEAT_FLEE_SPEED
	_face_position(global_position + _flee_direction, delta)
	_update_locomotion_blend(delta, Vector2(velocity.x, velocity.z).length(), true)

	if _flee_timer > 0.0:
		return

	_finish_defeat_flee()


func _finish_defeat_flee() -> void:
	_phase = Phase.DEFEATED
	_velocity_zero()
	visible = false
	collision_layer = 0
	collision_mask = 0

	var player := _combat_target
	if player == null or not is_instance_valid(player):
		player = _find_player()
	if player != null and player.has_method("end_comet_cinematic"):
		player.end_comet_cinematic()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if player != null and player.has_method("exit_overworld_combat"):
		player.exit_overworld_combat()

	queue_free()


func _start_defeat_loot_shower(hit_info: Dictionary) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var drop_pos: Vector3 = hit_info.get("position", global_position + Vector3(0.0, 0.9, 0.0))
	if drop_pos.is_equal_approx(Vector3.ZERO):
		drop_pos = global_position + Vector3(0.0, 0.9, 0.0)
	LootCurrencyShowerScript.start(
		parent,
		drop_pos,
		randi_range(DEFEAT_LOOT_GRAM_MIN, DEFEAT_LOOT_GRAM_MAX),
		randi_range(DEFEAT_LOOT_SHARDS_MIN, DEFEAT_LOOT_SHARDS_MAX),
		DEFEAT_LOOT_DURATION
	)


func _spawn_church_recurve_reward() -> void:
	ChurchRecurveRewardScript.spawn_if_needed(get_parent() as Node3D)


func _clear_church_skeleton_ambush() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("church_skeleton_ambush"):
		if node.has_method("disarm_permanently"):
			node.disarm_permanently()


func _get_raid_hud(player: Node3D):
	if player != null and player.has_method("get_raid_hud"):
		return player.get_raid_hud()
	return null


func _activate_defeat_ragdoll(hit_info: Dictionary) -> void:
	_bind_rig()
	if _ragdoll == null:
		_ragdoll = RAGDOLL_SCRIPT.new()
		_ragdoll.name = "Ragdoll"
		add_child(_ragdoll)
	if _skeleton != null:
		_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
		if _model != null:
			_ragdoll.model_path = _ragdoll.get_path_to(_model)
		_ragdoll.bind_skeleton()
	if _ragdoll != null and not _ragdoll.is_active():
		# Capture live poses first; activate() stops anim sources after capture.
		_ragdoll.activate(hit_info, _animation_player)


func _setup_sit_clip() -> void:
	_ensure_clip_library()
	_add_runtime_clip(
		ChiefGetchaAnimConfigScript.CLIP_SIT,
		ChiefGetchaAnimConfigScript.MESHY_SIT,
		true
	)


func _setup_stand_up_clip() -> void:
	_ensure_clip_library()
	_add_runtime_clip(
		ChiefGetchaAnimConfigScript.CLIP_STAND_UP,
		ChiefGetchaAnimConfigScript.MESHY_STAND_UP,
		false
	)


func _setup_combat_animation_tree() -> void:
	if _animation_player == null or _animation_tree == null:
		return

	# Must release the stand-up clip before mutating libraries / tree_root.
	# Adding libs or stopping mid-playback after mutations has SIGSEGV'd here.
	_animation_tree.active = false
	_animation_player.stop()

	# After a ragdoll toss the ragdoll left both nodes with process_mode
	# DISABLED and speed_scale 0 — undo that or the rebuilt tree never runs.
	_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
	_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
	_animation_player.speed_scale = 1.0
	_animation_player.active = true

	_ensure_clip_library()
	_setup_unarmed_block_pose_library()
	for clip_name: StringName in [
		ChiefGetchaAnimConfigScript.CLIP_IDLE,
		ChiefGetchaAnimConfigScript.CLIP_WALK,
		ChiefGetchaAnimConfigScript.CLIP_RUN,
		ChiefGetchaAnimConfigScript.CLIP_PUNCH,
		ChiefGetchaAnimConfigScript.CLIP_COMBO,
		ChiefGetchaAnimConfigScript.CLIP_DOUBLE_COMBO,
		ChiefGetchaAnimConfigScript.CLIP_SKILL_3,
		ChiefGetchaAnimConfigScript.CLIP_KICK,
		ChiefGetchaAnimConfigScript.CLIP_SPIN_KICK,
		ChiefGetchaAnimConfigScript.CLIP_FLYING_KICK,
		ChiefGetchaAnimConfigScript.CLIP_CHARGE,
		ChiefGetchaAnimConfigScript.CLIP_ROLL,
		ChiefGetchaAnimConfigScript.CLIP_HIT,
		ChiefGetchaAnimConfigScript.CLIP_BOW_WALK,
		ChiefGetchaAnimConfigScript.CLIP_BOW_AIM,
	]:
		_add_runtime_clip(clip_name, _meshy_for_clip(clip_name), _clip_should_loop(clip_name))

	var idle_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_IDLE)
	var walk_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_WALK)
	var run_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_RUN)
	var block_path := UnarmedBlockPoseConfig.get_animation_path()
	var punch_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_PUNCH)
	var roll_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_ROLL)
	var hit_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_HIT)

	_idle_anim_node = AnimationNodeAnimation.new()
	_idle_anim_node.animation = idle_path
	_walk_anim_node = AnimationNodeAnimation.new()
	_walk_anim_node.animation = walk_path
	_run_anim_node = AnimationNodeAnimation.new()
	_run_anim_node.animation = run_path
	var block_pose_node := AnimationNodeAnimation.new()
	block_pose_node.animation = block_path
	_attack_anim_node = AnimationNodeAnimation.new()
	_attack_anim_node.animation = punch_path
	var roll_node := AnimationNodeAnimation.new()
	roll_node.animation = roll_path
	var hit_node := AnimationNodeAnimation.new()
	hit_node.animation = hit_path

	var walk_run_space := AnimationNodeBlendSpace1D.new()
	walk_run_space.add_blend_point(_walk_anim_node, 0.0)
	walk_run_space.add_blend_point(_run_anim_node, 1.0)
	walk_run_space.min_space = 0.0
	walk_run_space.max_space = 1.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true
	var block_blend := AnimationNodeBlend2.new()
	# Filtered upper-body hold must not sync with locomotion (matches Groyper).
	block_blend.sync = false
	_configure_chief_block_blend_filter(block_blend)

	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)
	var roll_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		roll_shot,
		CombatAnimTransitionsScript.ROLL_FADEIN,
		CombatAnimTransitionsScript.ROLL_FADEOUT
	)
	var hit_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		hit_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT,
		true
	)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(ChiefGetchaAnimConfigScript.MOVE_BLEND_NODE, move_blend)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.LOCOMOTION_BLEND_NODE, walk_run_space)
	blend_tree.add_node(&"IdleAnim", _idle_anim_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE, block_blend)
	blend_tree.add_node(&"BlockPoseAnim", block_pose_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(&"AttackAnim", _attack_anim_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT, roll_shot)
	blend_tree.add_node(&"RollAnim", roll_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.HIT_ONE_SHOT, hit_shot)
	blend_tree.add_node(&"HitAnim", hit_node)

	blend_tree.connect_node(ChiefGetchaAnimConfigScript.MOVE_BLEND_NODE, 0, &"IdleAnim")
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.MOVE_BLEND_NODE, 1, ChiefGetchaAnimConfigScript.LOCOMOTION_BLEND_NODE)
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE, 0, ChiefGetchaAnimConfigScript.MOVE_BLEND_NODE)
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE, 1, &"BlockPoseAnim")
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT, 0, ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE)
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT, 1, &"AttackAnim")
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT, 0, ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT)
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT, 1, &"RollAnim")
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.HIT_ONE_SHOT, 0, ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT)
	blend_tree.connect_node(ChiefGetchaAnimConfigScript.HIT_ONE_SHOT, 1, &"HitAnim")
	blend_tree.connect_node(&"output", 0, ChiefGetchaAnimConfigScript.HIT_ONE_SHOT)

	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.tree_root = blend_tree
	_animation_tree.active = true
	_set_move_blend(0.0)
	_set_walk_run_blend(0.0)
	_set_block_blend(0.0)
	_ensure_bow_rig()
	if _bow_rig != null:
		_bow_rig.set_equipped(false)


func _setup_unarmed_block_pose_library() -> void:
	if _animation_player == null:
		return
	var source := UnarmedBlockPoseExtractScript.load_authored_library()
	if source == null:
		push_warning(
			"ChiefGetchaNpc: missing unarmed_block_pose.tres — author in groyper_body.tscn."
		)
		return
	var block_hold := source.get_animation(UnarmedBlockPoseConfig.BLOCK_HOLD)
	if block_hold == null:
		push_warning("ChiefGetchaNpc: UnarmedBlock library missing block_hold.")
		return
	# Groyper absolute arm positions don't transfer across Meshy rigs — rotations only.
	var rotation_only := _strip_position_tracks(block_hold.duplicate(true))
	rotation_only.loop_mode = Animation.LOOP_LINEAR
	var library := AnimationLibrary.new()
	library.add_animation(UnarmedBlockPoseConfig.BLOCK_HOLD, rotation_only)
	if _animation_player.has_animation_library(UnarmedBlockPoseConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(UnarmedBlockPoseConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(UnarmedBlockPoseConfig.LIBRARY_NAME, library)


func _configure_chief_block_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	# Only bones present in the authored Groyper block_hold clip. Filtering
	# spine/neck with no keys has crashed AnimationTree activation on this rig.
	const BLOCK_ARM_BONES: Array[String] = [
		"LeftShoulder",
		"LeftArm",
		"LeftForeArm",
		"LeftHand",
		"RightShoulder",
		"RightArm",
		"RightForeArm",
		"RightHand",
	]
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_ARM_BONES:
		blend_node.set_filter_path(UnarmedBlockPoseConfig.get_skeleton_track_path(bone_name), true)


func _strip_position_tracks(animation: Animation) -> Animation:
	if animation == null:
		return null
	for track_idx in range(animation.get_track_count() - 1, -1, -1):
		if animation.track_get_type(track_idx) == Animation.TYPE_POSITION_3D:
			animation.remove_track(track_idx)
	return animation


func _ensure_clip_library() -> void:
	if _animation_player == null:
		return
	if _animation_player.has_animation_library(ChiefGetchaAnimConfigScript.LIBRARY):
		return
	_animation_player.add_animation_library(ChiefGetchaAnimConfigScript.LIBRARY, AnimationLibrary.new())


func _add_runtime_clip(clip_name: StringName, meshy_clip: StringName, loop: bool) -> void:
	if _animation_player == null:
		return
	var library: AnimationLibrary = _animation_player.get_animation_library(
		ChiefGetchaAnimConfigScript.LIBRARY
	)
	if library == null:
		return
	if library.has_animation(String(clip_name)):
		return
	var raw := RigAnimUtils.load_skeleton_animation(
		ChiefGetchaAnimConfigScript.MERGED_SCENE,
		meshy_clip
	)
	if raw == null:
		push_error("ChiefGetchaNpc: failed to load clip '%s'." % meshy_clip)
		return
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	library.add_animation(String(clip_name), animation)


func _meshy_for_clip(clip_name: StringName) -> StringName:
	match clip_name:
		ChiefGetchaAnimConfigScript.CLIP_IDLE:
			return ChiefGetchaAnimConfigScript.MESHY_IDLE
		ChiefGetchaAnimConfigScript.CLIP_WALK:
			return ChiefGetchaAnimConfigScript.MESHY_WALK
		ChiefGetchaAnimConfigScript.CLIP_RUN:
			return ChiefGetchaAnimConfigScript.MESHY_RUN
		ChiefGetchaAnimConfigScript.CLIP_PUNCH:
			return ChiefGetchaAnimConfigScript.MESHY_PUNCH
		ChiefGetchaAnimConfigScript.CLIP_COMBO:
			return ChiefGetchaAnimConfigScript.MESHY_COMBO
		ChiefGetchaAnimConfigScript.CLIP_DOUBLE_COMBO:
			return ChiefGetchaAnimConfigScript.MESHY_DOUBLE_COMBO
		ChiefGetchaAnimConfigScript.CLIP_SKILL_3:
			return ChiefGetchaAnimConfigScript.MESHY_SKILL_3
		ChiefGetchaAnimConfigScript.CLIP_KICK:
			return ChiefGetchaAnimConfigScript.MESHY_KICK
		ChiefGetchaAnimConfigScript.CLIP_SPIN_KICK:
			return ChiefGetchaAnimConfigScript.MESHY_SPIN_KICK
		ChiefGetchaAnimConfigScript.CLIP_FLYING_KICK:
			return ChiefGetchaAnimConfigScript.MESHY_FLYING_KICK
		ChiefGetchaAnimConfigScript.CLIP_CHARGE:
			return ChiefGetchaAnimConfigScript.MESHY_CHARGE
		ChiefGetchaAnimConfigScript.CLIP_ROLL:
			return ChiefGetchaAnimConfigScript.MESHY_ROLL
		ChiefGetchaAnimConfigScript.CLIP_HIT:
			return ChiefGetchaAnimConfigScript.MESHY_HIT
		ChiefGetchaAnimConfigScript.CLIP_BOW_WALK:
			return ChiefGetchaAnimConfigScript.MESHY_BOW_WALK
		ChiefGetchaAnimConfigScript.CLIP_BOW_AIM:
			return ChiefGetchaAnimConfigScript.MESHY_BOW_AIM
		_:
			return ChiefGetchaAnimConfigScript.MESHY_IDLE


func _clip_should_loop(clip_name: StringName) -> bool:
	return clip_name in [
		ChiefGetchaAnimConfigScript.CLIP_IDLE,
		ChiefGetchaAnimConfigScript.CLIP_WALK,
		ChiefGetchaAnimConfigScript.CLIP_RUN,
		ChiefGetchaAnimConfigScript.CLIP_SIT,
		ChiefGetchaAnimConfigScript.CLIP_BOW_WALK,
		ChiefGetchaAnimConfigScript.CLIP_BOW_AIM,
	]


func _attack_anim_name(kind: AttackKind) -> StringName:
	match kind:
		AttackKind.COMBO:
			return ChiefGetchaAnimConfigScript.CLIP_COMBO
		AttackKind.DOUBLE_COMBO:
			return ChiefGetchaAnimConfigScript.CLIP_DOUBLE_COMBO
		AttackKind.SKILL_3:
			return ChiefGetchaAnimConfigScript.CLIP_SKILL_3
		AttackKind.KICK:
			return ChiefGetchaAnimConfigScript.CLIP_KICK
		AttackKind.SPIN_KICK:
			return ChiefGetchaAnimConfigScript.CLIP_SPIN_KICK
		AttackKind.FLYING_KICK:
			return ChiefGetchaAnimConfigScript.CLIP_FLYING_KICK
		_:
			return ChiefGetchaAnimConfigScript.CLIP_PUNCH


func _get_attack_strike_fraction() -> float:
	match _attack_kind:
		AttackKind.COMBO:
			return ChiefGetchaAnimConfigScript.COMBO_STRIKE_FRACTION
		AttackKind.KICK:
			return ChiefGetchaAnimConfigScript.KICK_STRIKE_FRACTION
		AttackKind.SPIN_KICK:
			return ChiefGetchaAnimConfigScript.SPIN_KICK_STRIKE_FRACTION
		AttackKind.FLYING_KICK:
			return ChiefGetchaAnimConfigScript.FLYING_KICK_STRIKE_FRACTION
		_:
			return ChiefGetchaAnimConfigScript.PUNCH_STRIKE_FRACTION


func _get_attack_strike_times(anim_length: float) -> PackedFloat32Array:
	match _attack_kind:
		AttackKind.PUNCH:
			return ChiefGetchaAnimConfigScript.punch_strike_times(anim_length)
		AttackKind.DOUBLE_COMBO:
			return ChiefGetchaAnimConfigScript.double_combo_strike_times(anim_length)
		AttackKind.SKILL_3:
			return ChiefGetchaAnimConfigScript.skill_3_strike_times(anim_length)
		_:
			return PackedFloat32Array([anim_length * _get_attack_strike_fraction()])


func _get_attack_length() -> float:
	var anim_path := _clip_path(_attack_anim_name(_attack_kind))
	if _animation_player != null and _animation_player.has_animation(anim_path):
		return _animation_player.get_animation(anim_path).length
	return 1.0


func _clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [ChiefGetchaAnimConfigScript.LIBRARY, clip_name])


func _fire_attack_one_shot(anim_path: StringName) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_abort_roll_one_shot()
	# Swap the clip on the node ref — tree.set("parameters/AttackAnim/animation")
	# silently does nothing, which kept every attack on Weapon Combo 1.
	if _attack_anim_node != null:
		_attack_anim_node.animation = anim_path
	_animation_tree.set(
		"parameters/%s/request" % ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _fire_roll_one_shot(anim_path: StringName) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(&"parameters/RollAnim/animation", anim_path)
	_animation_tree.set(
		"parameters/%s/request" % ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _abort_roll_one_shot() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/request" % ChiefGetchaAnimConfigScript.ROLL_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
	)


func _play_hit_react() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var hit_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_HIT)
	_animation_tree.set(&"parameters/HitAnim/animation", hit_path)
	_animation_tree.set(
		"parameters/%s/request" % ChiefGetchaAnimConfigScript.HIT_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	var moving := speed > 0.05
	if moving:
		_move_blend = lerpf(_move_blend, 1.0, BLEND_SPEED * delta)
		var walk_run_target := 1.0 if sprinting else 0.0
		_walk_run_blend = lerpf(_walk_run_blend, walk_run_target, BLEND_SPEED * delta)
	else:
		_move_blend = lerpf(_move_blend, 0.0, BLEND_SPEED * delta)
		_walk_run_blend = lerpf(_walk_run_blend, 0.0, BLEND_SPEED * delta)
	_set_move_blend(_move_blend)
	_set_walk_run_blend(_walk_run_blend)


func _set_move_blend(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % ChiefGetchaAnimConfigScript.MOVE_BLEND_NODE,
		clampf(value, 0.0, 1.0)
	)


func _set_walk_run_blend(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_position" % ChiefGetchaAnimConfigScript.LOCOMOTION_BLEND_NODE,
		clampf(value, 0.0, 1.0)
	)


func _set_block_blend(value: float) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE,
		clampf(value, 0.0, 1.0)
	)


func _update_combat_target() -> void:
	if _combat_target != null and is_instance_valid(_combat_target):
		if _combat_target.has_method("is_defeated") and _combat_target.is_defeated():
			_combat_target = null
			return
		return
	_combat_target = _find_player()


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group(&"overworld_player"):
		if node is Node3D:
			return node as Node3D
	return null


func _roll_decision_timer() -> void:
	_decision_timer = randf_range(BRAWL_DECISION_MIN, BRAWL_DECISION_MAX)


func _flat_direction_to(target_pos: Vector3) -> Vector3:
	var flat := target_pos - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return _get_flat_forward()
	return flat.normalized()


func _get_flat_forward() -> Vector3:
	var flat := -_model.global_transform.basis.z
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return Vector3.FORWARD
	return flat.normalized()


func _move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	var flat := direction
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	flat = flat.normalized()
	velocity.x = flat.x * speed
	velocity.z = flat.z * speed
	_face_position(global_position + flat, delta)


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _velocity_zero() -> void:
	if should_preserve_knockback_velocity():
		return
	velocity.x = 0.0
	velocity.z = 0.0


func _show_alert_fx() -> void:
	AlertSymbolFXScript.spawn_above(self, global_position + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0))


func _suspend_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = false


func _resume_locomotion_animations() -> void:
	# The ragdoll hard-disables both nodes (process_mode DISABLED, speed_scale 0)
	# in _stop_animation_sources — restoring only .active leaves them frozen.
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.speed_scale = 1.0
		_animation_player.active = true


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.55, 0.0)


func _end_dialog(player: Node3D) -> void:
	_talking = false
	_stop_voice()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _play_talk_voice() -> void:
	_stop_voice()
	var stream := GameAudioScript.pick_gropyptalk_voice()
	if stream == null:
		return
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.stream = stream
	_voice_player.max_distance = 48.0
	add_child(_voice_player)
	_voice_player.global_position = get_voice_world_position()
	_voice_player.finished.connect(func() -> void:
		_voice_player = null
	)
	_voice_player.play()


func _stop_voice() -> void:
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.queue_free()
	_voice_player = null


func _on_interact_body_entered(body: Node3D) -> void:
	if _fight_started or _defeated:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
