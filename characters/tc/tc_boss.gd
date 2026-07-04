extends TcActor
class_name TcBoss

const TcAnimConfigScript := preload("res://characters/tc/tc_anim_config.gd")
const TcAnimUtilsScript := preload("res://characters/tc/tc_anim_utils.gd")
const TcMeleeStrikeScript := preload("res://characters/tc/tc_melee_strike.gd")
const TcWaterWaveSpellScript := preload("res://characters/tc/tc_water_wave_spell.gd")
const TcSlamAttackScript := preload("res://characters/tc/tc_slam_attack.gd")
const TcBubbleProjectileScript := preload("res://characters/tc/tc_bubble_projectile.gd")
const TcHealingSpellScript := preload("res://characters/tc/tc_healing_spell.gd")
const TcHipHopDanceScript := preload("res://characters/tc/tc_hip_hop_dance.gd")
const TcChargeRunScript := preload("res://characters/tc/tc_charge_run.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")
const CombatKnockdownScript := preload("res://gameplay/combat/combat_knockdown.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const NpcCombatNavigationScript := preload("res://gameplay/navigation/npc_combat_navigation.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

enum AiState {
	CHASE,
	COMBAT_DECIDING,
	BLOCKING,
	ATTACK_WINDUP,
	ATTACKING,
	BACKFLIP_BUBBLES,
	SLAM_JUMP,
	SLAM_FALL,
	HEALING,
	RELOCATING,
	HIP_HOP_DANCE,
	CHARGE_RUN_WINDUP,
	CHARGE_RUN,
	CHARGE_WALL_FLIP,
	REFLECT_KNOCKDOWN,
}

enum AttackKind {
	MELEE_CHARGE,
	WATER_WAVE,
	SLAM,
}

enum ReflectKnockdownPhase {
	NONE,
	FALLING,
	STAND_UP,
}

const GRAVITY := 22.0
const FACING_SPEED := 8.0
const WALK_SPEED := 2.8
const RUN_SPEED := 5.6
const BLEND_SPEED := 8.0
const LOCOMOTION_STOP_SPEED := 0.08
const LOCOMOTION_RUN_SPEED := 3.2
const DETECT_RANGE := 48.0
const ATTACK_RANGE := TcMeleeStrikeScript.RANGE
const SPELL_MIN_RANGE := TcWaterWaveSpellScript.SPELL_MIN_RANGE
const SPELL_MAX_RANGE := TcWaterWaveSpellScript.SPELL_MAX_RANGE
const DECISION_MIN := 0.35
const DECISION_MAX := 1.0
const MELEE_ATTACK_CHANCE := 0.34
const WATER_WAVE_CHANCE := 0.28
const SLAM_CHANCE := 0.18
const BLOCK_CHANCE := 0.10
const HEAL_CHANCE := 0.08
const HIP_HOP_CHANCE := 0.14
const CHARGE_RUN_CHANCE := 0.16
const BLOCK_DURATION_MIN := 1.0
const BLOCK_DURATION_MAX := 2.2
const CHASE_BLOCK_CHANCE := 0.08
const MAX_HEALTH := 10
const BLOCK_FACING_DOT_MIN := 0.28
const RELOCATE_ARRIVE_DIST := 1.2
const AIM_THREAT_RANGE := 52.0
const GUN_AIM_BACKFLIP_DELAY_MIN := 0.15
const GUN_AIM_BACKFLIP_DELAY_MAX := 0.85
const GUN_AIM_BACKFLIP_COOLDOWN := 3.5
const BUBBLE_COUNT := 3
const BUBBLE_INTERVAL := 0.18
const STAND_UP_SPEED := 2.0
const KNOCKDOWN_CLIP_BLEND := 0.28
const KNOCKDOWN_CLIP_OVERLAP := 0.14
const KNOCKDOWN_TO_COMBAT_BLEND := 0.36
const KNOCKDOWN_KNOCKBACK_DURATION := 0.24
const KNOCKDOWN_MODEL_Y_OFFSET := -0.68
const KNOCKDOWN_FALL_OFFSET_DELAY := 0.52
const KNOCKDOWN_FALL_OFFSET_BLEND := 0.28
const KNOCKDOWN_STAND_OFFSET_BLEND := 0.38
const ONE_SHOT_FADEIN := 0.24
const ONE_SHOT_FADEOUT := 0.30
const LOCOMOTION_TWEEN_DURATION := 0.32
const COMBAT_IDLE_TWEEN_DURATION := 0.28

@export var sight_range := DETECT_RANGE
@export var show_hitbox_debug_meshes := true
@export var show_hitbox_debug_in_game := false

var _ai_state := AiState.CHASE
var _state_timer := 0.0
var _decision_timer := 0.0
var _windup_timer := 0.0
var _combat_target: Node3D
var _last_attack_target: Node3D
var _blocking_approach := false
var _combat_idle_blend := 1.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _health := MAX_HEALTH
var _defeated := false
var _blocking := false
var _attack_kind := AttackKind.MELEE_CHARGE
var _attack_elapsed := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_direction := Vector3.FORWARD
var _attack_cooldown := 0.0
var _heal_cooldown := 0.0
var _hip_hop_cooldown := 0.0
var _charge_run_cooldown := 0.0
var _charge_direction := Vector3.FORWARD
var _charge_trail_timer := 0.0
var _charge_target: Node3D
var _charge_hit_targets: Dictionary = {}
var _dance_boulder_timer := 0.0
var _relocate_target := Vector3.ZERO
var _combat_nav: NpcCombatNavigation
var _body_hit_marker: Node3D
var _body_hit_debug_mesh: MeshInstance3D
var _head_hit_marker: Node3D
var _head_hit_debug_mesh: MeshInstance3D
var _melee_hit_absorbed := false
var _block_blend_tween: Tween
var _locomotion_blend_tween: Tween
var _combat_idle_blend_tween: Tween
var _ragdoll
var _gun_aim_backflip_pending := false
var _gun_aim_backflip_committed := false
var _gun_aim_backflip_timer := 0.0
var _gun_aim_backflip_threat: Node3D
var _gun_aim_backflip_cooldown := 0.0
var _bubble_burst_remaining := 0
var _bubble_burst_timer := 0.0
var _slam_direction := Vector3.FORWARD
var _slam_jump_tween: Tween
var _reflect_knockdown_active := false
var _reflect_knockdown_direction := Vector3.FORWARD
var _reflect_knockdown_phase := ReflectKnockdownPhase.NONE
var _reflect_knockdown_base_model_y := 0.0
var _reflect_knockdown_model_tween: Tween
var _pending_hit_react := false


func _on_actor_ready() -> void:
	add_to_group("tc_boss")
	add_to_group("cave_enemy")
	add_to_group("duel_target")
	_bind_hitbox_nodes()
	_setup_animation_library()
	_setup_animation_tree()
	_setup_combat_navigation()
	_setup_combat_ragdoll()
	setup_npc_locomotion_audio()
	call_deferred("_finalize_spawn")


func _finalize_spawn() -> void:
	snap_to_floor()
	_prime_idle_pose()
	_sync_hitbox_debug_visibility()
	_set_combat_idle_blend(1.0)
	_begin_chase()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _defeated:
		return

	if _ragdoll != null and _ragdoll.is_active():
		tick_melee_stun(delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return

	tick_melee_stun(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_heal_cooldown = maxf(_heal_cooldown - delta, 0.0)
	_hip_hop_cooldown = maxf(_hip_hop_cooldown - delta, 0.0)
	_charge_run_cooldown = maxf(_charge_run_cooldown - delta, 0.0)
	_gun_aim_backflip_cooldown = maxf(_gun_aim_backflip_cooldown - delta, 0.0)

	if _ai_state not in [AiState.SLAM_JUMP, AiState.SLAM_FALL]:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = minf(velocity.y, 0.0)

	_update_combat_target()
	_update_player_gun_aim_threat(delta)
	_try_execute_committed_gun_aim_backflip()

	match _ai_state:
		AiState.CHASE:
			_process_chase(delta)
		AiState.COMBAT_DECIDING:
			_process_combat_deciding(delta)
		AiState.BLOCKING:
			_process_blocking(delta)
		AiState.ATTACK_WINDUP:
			_process_attack_windup(delta)
		AiState.ATTACKING:
			_process_attacking(delta)
		AiState.BACKFLIP_BUBBLES:
			_process_backflip_bubbles(delta)
		AiState.SLAM_JUMP:
			_process_slam_jump(delta)
		AiState.SLAM_FALL:
			_process_slam_fall(delta)
		AiState.HEALING:
			_process_healing(delta)
		AiState.RELOCATING:
			_process_relocating(delta)
		AiState.HIP_HOP_DANCE:
			_process_hip_hop_dance(delta)
		AiState.CHARGE_RUN_WINDUP:
			_process_charge_run_windup(delta)
		AiState.CHARGE_RUN:
			_process_charge_run(delta)
		AiState.CHARGE_WALL_FLIP:
			_process_charge_wall_flip(delta)
		AiState.REFLECT_KNOCKDOWN:
			_process_reflect_knockdown(delta)

	move_and_slide()

	if _ai_state == AiState.REFLECT_KNOCKDOWN:
		_snap_reflect_knockdown_to_floor()

	if _ai_state == AiState.CHARGE_RUN:
		_check_charge_wall_collision()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if _ai_state not in [
		AiState.ATTACKING,
		AiState.BLOCKING,
		AiState.ATTACK_WINDUP,
		AiState.BACKFLIP_BUBBLES,
		AiState.SLAM_JUMP,
		AiState.HEALING,
		AiState.HIP_HOP_DANCE,
		AiState.CHARGE_RUN_WINDUP,
		AiState.CHARGE_RUN,
		AiState.CHARGE_WALL_FLIP,
		AiState.REFLECT_KNOCKDOWN,
		AiState.SLAM_FALL,
	]:
		_update_locomotion_blend(delta, horizontal_speed)
	_update_combat_idle_blend(delta)
	update_npc_locomotion_audio(
		delta,
		horizontal_speed,
		horizontal_speed > LOCOMOTION_STOP_SPEED,
		horizontal_speed >= LOCOMOTION_RUN_SPEED
	)


func _process(_delta: float) -> void:
	_sync_hitbox_debug_visibility()


func get_faction_id() -> StringName:
	return FactionIdsScript.TC


func get_lasso_ragdoll():
	return _ragdoll


func get_lasso_animation_player() -> AnimationPlayer:
	return _animation_player


func apply_reflect_knockdown(hit_info: Dictionary) -> void:
	if _defeated or _reflect_knockdown_active:
		return

	var fall_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	fall_dir.y = 0.0
	if fall_dir.length_squared() < 0.0001:
		fall_dir = _get_flat_forward()
	else:
		fall_dir = fall_dir.normalized()

	var knockback_dir := fall_dir
	if not bool(hit_info.get("reflected_hit", false)):
		knockback_dir = -fall_dir

	var knockback_speed := float(
		hit_info.get("knockback_speed", CombatKnockdownScript.DRAG_PULL_SPEED)
	)

	_reflect_knockdown_active = true
	_reflect_knockdown_direction = knockback_dir
	_reflect_knockdown_phase = ReflectKnockdownPhase.FALLING
	_charge_target = null
	_charge_hit_targets.clear()
	_blocking = false
	_blocking_approach = false
	_abort_action_one_shots()
	_face_direction(knockback_dir, get_physics_process_delta_time())

	if _model != null:
		_reflect_knockdown_base_model_y = _model.position.y
		_set_reflect_knockdown_model_offset(0.0)

	velocity.x = knockback_dir.x * knockback_speed
	velocity.z = knockback_dir.z * knockback_speed
	velocity.y = 0.0
	_snap_reflect_knockdown_to_floor()

	_ai_state = AiState.REFLECT_KNOCKDOWN
	_state_timer = _begin_reflect_knockdown_fall()
	hold_knockback_velocity(KNOCKDOWN_KNOCKBACK_DURATION)
	apply_melee_stun(_state_timer + KNOCKDOWN_KNOCKBACK_DURATION)
	CombatHitFlashScript.flash_damage(self)


func suspend_for_reflect_knockdown() -> void:
	pass


func resume_from_reflect_knockdown() -> void:
	if _defeated:
		return
	_clear_reflect_knockdown_model_offset()
	_reflect_knockdown_active = false
	_reflect_knockdown_direction = Vector3.FORWARD
	_reflect_knockdown_phase = ReflectKnockdownPhase.NONE
	velocity = Vector3.ZERO
	_snap_reflect_knockdown_to_floor()
	if _animation_player != null:
		_animation_player.speed_scale = 1.0
	_stop_horizontal_velocity()
	if _animation_tree != null:
		_animation_tree.active = true
		_set_locomotion_blend(0.0)
		_set_combat_idle_blend(1.0)
	_tween_locomotion_blend(0.0, KNOCKDOWN_TO_COMBAT_BLEND)
	_tween_combat_idle_blend(1.0, KNOCKDOWN_TO_COMBAT_BLEND)
	_begin_combat_deciding()


func get_punch_facing_direction() -> Vector3:
	if _attack_direction.length_squared() > 0.0001:
		return _attack_direction
	return _get_flat_forward()


func is_defeated() -> bool:
	return _defeated


func get_combat_health() -> int:
	return _health


func get_combat_max_health() -> int:
	return MAX_HEALTH


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	_melee_hit_absorbed = false

	if _can_block_melee(hit_info):
		_melee_hit_absorbed = true
		_on_attack_blocked(hit_info)
		return

	_focus_attacker_from_hit(hit_info)
	_play_hit_react()

	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health
	CombatHitFlashScript.flash_damage(self)
	if result.knockback_applied:
		hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if result.killed:
		_die(hit_info)


func get_bullet_capsule() -> Dictionary:
	return GroyperBodyUtils.get_town_bullet_capsule(_skeleton, global_position, 1.8, 2.4)


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_town_head_hit_sphere(_skeleton, global_position, 0.9)


func get_threat_aim_point() -> Vector3:
	return GroyperBodyUtils.get_threat_aim_point(_skeleton, global_position)


func _bind_hitbox_nodes() -> void:
	_body_hit_marker = get_node_or_null("BulletHitbox") as Node3D
	_body_hit_debug_mesh = get_node_or_null("BulletHitbox/BodyDebugMesh") as MeshInstance3D
	_head_hit_debug_mesh = get_node_or_null("BulletHitbox/HeadDebugMesh") as MeshInstance3D
	_head_hit_marker = _head_hit_debug_mesh


func _sync_hitbox_debug_visibility() -> void:
	var show_debug := show_hitbox_debug_meshes and (
		Engine.is_editor_hint() or show_hitbox_debug_in_game
	)
	if _body_hit_debug_mesh != null:
		_body_hit_debug_mesh.visible = show_debug
	if _head_hit_debug_mesh != null:
		_head_hit_debug_mesh.visible = show_debug
	if show_debug:
		_sync_hitbox_debug_mesh()


func _sync_hitbox_debug_mesh() -> void:
	GroyperBodyUtils.sync_bullet_hitbox_debug_meshes(
		_body_hit_marker,
		_body_hit_debug_mesh,
		_head_hit_marker,
		_head_hit_debug_mesh,
		_skeleton,
		global_position
	)


func _setup_animation_library() -> void:
	if _animation_player == null:
		push_error("TcBoss: missing AnimationPlayer.")
		return
	var library := load(TcAnimConfigScript.LIB_PATH) as AnimationLibrary
	if library == null:
		push_error("TcBoss: failed to load animation library.")
		return
	if _animation_player.has_animation_library(TcAnimConfigScript.LIBRARY):
		_animation_player.remove_animation_library(TcAnimConfigScript.LIBRARY)
	_animation_player.add_animation_library(TcAnimConfigScript.LIBRARY, library)
	_ensure_knockdown_clips()


func _ensure_knockdown_clips() -> void:
	if _animation_player == null:
		return
	var library := _animation_player.get_animation_library(TcAnimConfigScript.LIBRARY)
	if library == null:
		return
	if not library.has_animation(TcAnimConfigScript.CLIP_FALLING_DOWN):
		var falling_down := TcAnimUtilsScript.load_knockdown_clip(
			TcAnimConfigScript.FALLING_DOWN_SCENE,
			String(TcAnimConfigScript.CLIP_FALLING_DOWN)
		)
		if falling_down != null:
			library.add_animation(TcAnimConfigScript.CLIP_FALLING_DOWN, falling_down)
	if not library.has_animation(TcAnimConfigScript.CLIP_STAND_UP):
		var stand_up := TcAnimUtilsScript.load_knockdown_clip(
			TcAnimConfigScript.STAND_UP_SCENE,
			String(TcAnimConfigScript.CLIP_STAND_UP)
		)
		if stand_up != null:
			library.add_animation(TcAnimConfigScript.CLIP_STAND_UP, stand_up)


func _begin_reflect_knockdown_fall() -> float:
	_reflect_knockdown_phase = ReflectKnockdownPhase.FALLING
	var duration := _play_reflect_knockdown_clip(
		TcAnimConfigScript.CLIP_FALLING_DOWN,
		1.0,
		1.2,
		KNOCKDOWN_CLIP_BLEND
	)
	_schedule_reflect_knockdown_fall_offset(duration)
	return duration


func _schedule_reflect_knockdown_fall_offset(fall_duration: float) -> void:
	if _model == null:
		return
	if _reflect_knockdown_model_tween != null and _reflect_knockdown_model_tween.is_valid():
		_reflect_knockdown_model_tween.kill()
	var delay := fall_duration * KNOCKDOWN_FALL_OFFSET_DELAY
	var blend := maxf(fall_duration * KNOCKDOWN_FALL_OFFSET_BLEND, 0.1)
	_reflect_knockdown_model_tween = create_tween()
	_reflect_knockdown_model_tween.tween_interval(delay)
	_reflect_knockdown_model_tween.set_trans(Tween.TRANS_CUBIC)
	_reflect_knockdown_model_tween.set_ease(Tween.EASE_IN)
	_reflect_knockdown_model_tween.tween_method(
		_set_reflect_knockdown_model_offset,
		0.0,
		KNOCKDOWN_MODEL_Y_OFFSET,
		blend
	)


func _begin_reflect_knockdown_stand_up() -> float:
	_reflect_knockdown_phase = ReflectKnockdownPhase.STAND_UP
	var duration := _play_reflect_knockdown_clip(
		TcAnimConfigScript.CLIP_STAND_UP,
		STAND_UP_SPEED,
		1.0,
		KNOCKDOWN_CLIP_BLEND
	)
	if _reflect_knockdown_model_tween != null and _reflect_knockdown_model_tween.is_valid():
		_reflect_knockdown_model_tween.kill()
	var rise_duration := maxf(duration * KNOCKDOWN_STAND_OFFSET_BLEND, 0.12)
	_tween_reflect_knockdown_model_offset(0.0, rise_duration, Tween.EASE_OUT)
	return duration


func _play_reflect_knockdown_clip(
	clip_name: StringName,
	speed: float,
	fallback: float,
	blend_time: float
) -> float:
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.active = false
	var clip_length := _get_clip_length(clip_name, fallback)
	var duration := clip_length / maxf(speed, 0.01)
	var phase_duration := maxf(duration - KNOCKDOWN_CLIP_OVERLAP, duration * 0.72)
	if _animation_player != null:
		_animation_player.speed_scale = speed
		_animation_player.play(
			TcAnimUtilsScript.clip_path(clip_name),
			blend_time,
			speed
		)
	_snap_reflect_knockdown_to_floor()
	return phase_duration


func _set_reflect_knockdown_model_offset(offset: float) -> void:
	if _model == null:
		return
	_model.position.y = _reflect_knockdown_base_model_y + offset


func _tween_reflect_knockdown_model_offset(
	target_offset: float,
	duration: float,
	ease_mode: Tween.EaseType = Tween.EASE_IN_OUT
) -> void:
	if _reflect_knockdown_model_tween != null and _reflect_knockdown_model_tween.is_valid():
		_reflect_knockdown_model_tween.kill()
	if _model == null or duration <= 0.0:
		_set_reflect_knockdown_model_offset(target_offset)
		return
	var start_offset := _model.position.y - _reflect_knockdown_base_model_y
	_reflect_knockdown_model_tween = create_tween()
	_reflect_knockdown_model_tween.set_trans(Tween.TRANS_CUBIC)
	_reflect_knockdown_model_tween.set_ease(ease_mode)
	_reflect_knockdown_model_tween.tween_method(
		_set_reflect_knockdown_model_offset,
		start_offset,
		target_offset,
		duration
	)


func _clear_reflect_knockdown_model_offset() -> void:
	if _reflect_knockdown_model_tween != null and _reflect_knockdown_model_tween.is_valid():
		_reflect_knockdown_model_tween.kill()
		_reflect_knockdown_model_tween = null
	_set_reflect_knockdown_model_offset(0.0)


func _snap_reflect_knockdown_to_floor() -> void:
	snap_to_floor()
	velocity.y = minf(velocity.y, 0.0)


func _setup_animation_tree() -> void:
	if _animation_tree == null or _animation_player == null:
		return

	var idle_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_IDLE)
	var combat_idle_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_COMBAT_IDLE)
	var walk_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_WALK)
	var run_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_RUN)
	var block1_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_BLOCK1)
	var punch_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_PUNCH_FORWARD)
	var back_jump_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_BACK_JUMP)
	var fall2_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_FALL2)
	var backflip_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_BACKFLIP_HOOKS)
	var charge_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_CHARGE)
	var hit_react_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_FACE_PUNCH_REACT)
	var block2_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_BLOCK2)
	var hip_hop_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_HIP_HOP_DANCE)
	var run_fast_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_RUN_FAST)
	var wall_flip_path := TcAnimUtilsScript.clip_path(TcAnimConfigScript.CLIP_WALL_FLIP)

	for clip_path: StringName in [
		idle_path, combat_idle_path, walk_path, run_path, block1_path,
		punch_path, back_jump_path, fall2_path, backflip_path, charge_path,
		hit_react_path, block2_path, hip_hop_path, run_fast_path, wall_flip_path
	]:
		if not _animation_player.has_animation(clip_path):
			push_error("TcBoss: missing clip %s" % clip_path)
			return

	var patrol_idle_node := AnimationNodeAnimation.new()
	patrol_idle_node.animation = idle_path
	var combat_idle_node := AnimationNodeAnimation.new()
	combat_idle_node.animation = combat_idle_path
	var combat_idle_blend := AnimationNodeBlend2.new()
	var idle_subtree := AnimationNodeBlendTree.new()
	idle_subtree.add_node(TcAnimConfigScript.COMBAT_IDLE_BLEND, combat_idle_blend)
	idle_subtree.add_node(&"PatrolIdleAnim", patrol_idle_node)
	idle_subtree.add_node(&"CombatIdleAnim", combat_idle_node)
	idle_subtree.connect_node(&"output", 0, TcAnimConfigScript.COMBAT_IDLE_BLEND)
	idle_subtree.connect_node(TcAnimConfigScript.COMBAT_IDLE_BLEND, 0, &"PatrolIdleAnim")
	idle_subtree.connect_node(TcAnimConfigScript.COMBAT_IDLE_BLEND, 1, &"CombatIdleAnim")

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path
	var locomotion_blend := AnimationNodeBlendSpace1D.new()
	locomotion_blend.add_blend_point(idle_subtree, 0.0)
	locomotion_blend.add_blend_point(walk_node, 0.5)
	locomotion_blend.add_blend_point(run_node, 1.0)
	locomotion_blend.min_space = 0.0
	locomotion_blend.max_space = 1.0

	var block1_node := AnimationNodeAnimation.new()
	block1_node.animation = block1_path
	var block_blend := AnimationNodeBlend2.new()
	TcAnimUtilsScript.configure_block_pose_blend(block_blend)

	var one_shots: Dictionary = {}
	for entry: Dictionary in [
		{"name": TcAnimConfigScript.PUNCH_ONE_SHOT, "clip": punch_path},
		{"name": TcAnimConfigScript.BACK_JUMP_ONE_SHOT, "clip": back_jump_path},
		{"name": TcAnimConfigScript.FALL2_ONE_SHOT, "clip": fall2_path},
		{"name": TcAnimConfigScript.BACKFLIP_ONE_SHOT, "clip": backflip_path},
		{"name": TcAnimConfigScript.CHARGE_ONE_SHOT, "clip": charge_path},
		{"name": TcAnimConfigScript.HIT_REACT_ONE_SHOT, "clip": hit_react_path},
		{"name": TcAnimConfigScript.BLOCK_REACT_ONE_SHOT, "clip": block2_path},
		{"name": TcAnimConfigScript.HIP_HOP_ONE_SHOT, "clip": hip_hop_path, "loop": false},
		{"name": TcAnimConfigScript.RUN_FAST_ONE_SHOT, "clip": run_fast_path, "loop": true},
		{"name": TcAnimConfigScript.WALL_FLIP_ONE_SHOT, "clip": wall_flip_path, "loop": false},
	]:
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = entry.clip
		var shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			shot,
			ONE_SHOT_FADEIN,
			ONE_SHOT_FADEOUT,
			not entry.get("loop", false)
		)
		one_shots[entry.name] = {"anim": anim_node, "shot": shot}

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(TcAnimConfigScript.LOCOMOTION_BLEND, locomotion_blend)
	blend_tree.add_node(TcAnimConfigScript.BLOCK_BLEND, block_blend)
	blend_tree.add_node(&"Block1Anim", block1_node)
	for entry_name: StringName in one_shots:
		blend_tree.add_node(entry_name, one_shots[entry_name].shot)
		blend_tree.add_node("%sAnim" % entry_name, one_shots[entry_name].anim)

	var chain := [
		TcAnimConfigScript.WALL_FLIP_ONE_SHOT,
		TcAnimConfigScript.RUN_FAST_ONE_SHOT,
		TcAnimConfigScript.HIP_HOP_ONE_SHOT,
		TcAnimConfigScript.BLOCK_REACT_ONE_SHOT,
		TcAnimConfigScript.HIT_REACT_ONE_SHOT,
		TcAnimConfigScript.BACKFLIP_ONE_SHOT,
		TcAnimConfigScript.FALL2_ONE_SHOT,
		TcAnimConfigScript.BACK_JUMP_ONE_SHOT,
		TcAnimConfigScript.CHARGE_ONE_SHOT,
		TcAnimConfigScript.PUNCH_ONE_SHOT,
		TcAnimConfigScript.BLOCK_BLEND,
	]
	blend_tree.connect_node(&"output", 0, chain[0])
	for i in range(chain.size() - 1):
		blend_tree.connect_node(chain[i], 0, chain[i + 1])
		blend_tree.connect_node(chain[i], 1, "%sAnim" % chain[i])
	blend_tree.connect_node(TcAnimConfigScript.BLOCK_BLEND, 0, TcAnimConfigScript.LOCOMOTION_BLEND)
	blend_tree.connect_node(TcAnimConfigScript.BLOCK_BLEND, 1, &"Block1Anim")

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	_animation_tree.set("parameters/BlockBlend/blend_amount", 0.0)
	_animation_tree.set("parameters/LocomotionBlend/CombatIdleBlend/blend_amount", 1.0)


func _setup_combat_navigation() -> void:
	_combat_nav = NpcCombatNavigationScript.new()
	_combat_nav.setup(self)
	call_deferred("_finalize_combat_nav_agent")


func _finalize_combat_nav_agent() -> void:
	if _combat_nav != null:
		_combat_nav.mark_agent_ready()


func _setup_combat_ragdoll() -> void:
	if _skeleton == null:
		return
	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	if _model != null:
		_ragdoll.model_path = _ragdoll.get_path_to(_model)
	_ragdoll.bind_skeleton()


func _prime_idle_pose() -> void:
	_set_locomotion_blend(0.0)
	_set_combat_idle_blend(1.0)


func _process_chase(delta: float) -> void:
	if _combat_target == null:
		_combat_target = _find_player()
		if _combat_target == null:
			_stop_horizontal_velocity()
			return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= ATTACK_RANGE:
		if randf() < CHASE_BLOCK_CHANCE:
			_begin_blocking(true)
		else:
			_begin_combat_deciding()
		return
	if distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE:
		_begin_combat_deciding()
		return

	_move_toward(_combat_target.global_position, RUN_SPEED, delta)
	if _combat_nav != null and _combat_nav.is_available():
		_combat_nav.set_target_if_needed(_combat_target.global_position)
		var nav_dir: Vector3 = _combat_nav.get_move_direction(delta)
		if nav_dir.length_squared() > 0.0001:
			_move_in_direction(nav_dir, RUN_SPEED, delta)


func _process_combat_deciding(delta: float) -> void:
	_stop_horizontal_velocity()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return

	if _combat_target == null:
		_begin_chase()
		return

	if TcHealingSpellScript.can_cast(self, _health, MAX_HEALTH, _heal_cooldown):
		if randf() < HEAL_CHANCE:
			_begin_healing()
			return

	if TcHipHopDanceScript.can_cast(_hip_hop_cooldown) and randf() < HIP_HOP_CHANCE:
		_begin_hip_hop_dance()
		return

	_charge_target = TcChargeRunScript.find_nearest_player(self)
	if (
		_charge_target != null
		and TcChargeRunScript.can_cast(_charge_run_cooldown)
		and TcChargeRunScript.is_in_range(self, _charge_target)
		and randf() < CHARGE_RUN_CHANCE
	):
		_begin_charge_run_windup()
		return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var in_melee := distance <= ATTACK_RANGE + 0.5
	var in_spell := distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE
	if not in_melee and not in_spell:
		_begin_chase()
		return

	var roll := randf()
	if _attack_cooldown <= 0.0:
		if in_spell and roll < WATER_WAVE_CHANCE:
			_begin_attack_windup(AttackKind.WATER_WAVE)
			return
		if roll < SLAM_CHANCE:
			_begin_slam_jump()
			return
		if in_melee and roll < SLAM_CHANCE + MELEE_ATTACK_CHANCE:
			_begin_attack_windup(AttackKind.MELEE_CHARGE)
			return
		if in_spell and roll < SLAM_CHANCE + MELEE_ATTACK_CHANCE + WATER_WAVE_CHANCE:
			_begin_attack_windup(AttackKind.WATER_WAVE)
			return

	if roll < BLOCK_CHANCE:
		_begin_blocking()
	elif randf() < 0.55:
		_begin_relocate()
	else:
		_begin_chase()


func _process_blocking(delta: float) -> void:
	_blocking = true
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		if _blocking_approach:
			var to_target := _combat_target.global_position - global_position
			to_target.y = 0.0
			if to_target.length() > ATTACK_RANGE * 0.85:
				_move_in_direction(to_target.normalized(), WALK_SPEED, delta)
			else:
				_stop_horizontal_velocity()
		else:
			_stop_horizontal_velocity()
	else:
		_stop_horizontal_velocity()

	_state_timer -= delta
	if _state_timer <= 0.0:
		_end_blocking()
		_begin_combat_deciding()


func _process_attack_windup(delta: float) -> void:
	_stop_horizontal_velocity()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _get_attack_direction()
	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_begin_attacking()


func _process_attacking(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	_stop_horizontal_velocity()

	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, delta)
		_attack_direction = _get_attack_direction()

	var strike_fraction := _get_attack_strike_fraction()
	var strike_time := _get_attack_length() * strike_fraction
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		if _combat_target != null:
			_last_attack_target = _combat_target
		_execute_attack_strike()

	if _attack_timer <= 0.0:
		_end_attacking()


func _process_backflip_bubbles(delta: float) -> void:
	_stop_horizontal_velocity()
	_attack_elapsed += delta
	_attack_timer -= delta
	_bubble_burst_timer -= delta

	var backflip_length := _get_clip_length(TcAnimConfigScript.CLIP_BACKFLIP_HOOKS, 1.4)
	var strike_time := backflip_length * 0.72
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		_bubble_burst_remaining = BUBBLE_COUNT
		_bubble_burst_timer = 0.0

	if _attack_struck and _bubble_burst_remaining > 0 and _bubble_burst_timer <= 0.0:
		_launch_bubble()
		_bubble_burst_remaining -= 1
		_bubble_burst_timer = BUBBLE_INTERVAL

	if _attack_timer <= 0.0:
		_finish_backflip_bubbles()


func _process_hip_hop_dance(delta: float) -> void:
	_stop_horizontal_velocity()
	_attack_timer -= delta
	_dance_boulder_timer -= delta

	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, delta)

	TcHipHopDanceScript.apply_camera_shake_pulse(self)

	if _dance_boulder_timer <= 0.0:
		_dance_boulder_timer = TcHipHopDanceScript.BOULDER_INTERVAL
		TcHipHopDanceScript.spawn_boulder_volley(self, _combat_target)

	if _attack_timer <= 0.0:
		if randf() < TcHipHopDanceScript.LOOP_CHANCE:
			_restart_hip_hop_dance()
		else:
			_finish_hip_hop_dance()


func _process_charge_run_windup(delta: float) -> void:
	_stop_horizontal_velocity()
	_state_timer -= delta

	if _charge_target == null or not is_instance_valid(_charge_target):
		_charge_target = TcChargeRunScript.find_nearest_player(self)
	if _charge_target != null:
		_face_position(_charge_target.global_position, delta)

	if _state_timer <= 0.0:
		_begin_charge_run()


func _process_charge_run(delta: float) -> void:
	_state_timer -= delta
	_charge_trail_timer -= delta

	if _charge_target == null or not is_instance_valid(_charge_target):
		_charge_target = TcChargeRunScript.find_nearest_player(self)

	_charge_direction = TcChargeRunScript.update_charge_direction(
		_charge_direction,
		self,
		_charge_target,
		delta
	)
	velocity.x = _charge_direction.x * TcChargeRunScript.CHARGE_SPEED
	velocity.z = _charge_direction.z * TcChargeRunScript.CHARGE_SPEED
	_face_direction(_charge_direction, delta)

	TcChargeRunScript.apply_camera_shake_pulse(self)

	if _charge_trail_timer <= 0.0:
		_charge_trail_timer = TcChargeRunScript.TRAIL_INTERVAL
		TcChargeRunScript.spawn_fire_trail(self, _charge_direction)

	if (
		_charge_target != null
		and is_instance_valid(_charge_target)
		and not _charge_hit_targets.has(_charge_target.get_instance_id())
		and TcChargeRunScript.check_player_hit(self, _charge_target)
	):
		var charge_target := _charge_target
		var charge_target_id := charge_target.get_instance_id()
		TcChargeRunScript.apply_player_hit(self, charge_target, _charge_direction)
		_charge_hit_targets[charge_target_id] = true

	if _state_timer <= 0.0:
		_finish_charge_run()


func _process_charge_wall_flip(delta: float) -> void:
	_stop_horizontal_velocity()
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_finish_charge_run()


func _process_reflect_knockdown(delta: float) -> void:
	tick_melee_stun(delta)
	_state_timer -= delta

	if should_preserve_knockback_velocity():
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
			_snap_reflect_knockdown_to_floor()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y = 0.0
		_snap_reflect_knockdown_to_floor()

	if _state_timer > 0.0:
		return

	match _reflect_knockdown_phase:
		ReflectKnockdownPhase.FALLING:
			velocity = Vector3.ZERO
			_snap_reflect_knockdown_to_floor()
			_state_timer = _begin_reflect_knockdown_stand_up()
			apply_melee_stun(_state_timer + KNOCKDOWN_CLIP_OVERLAP)
		ReflectKnockdownPhase.STAND_UP:
			velocity = Vector3.ZERO
			_snap_reflect_knockdown_to_floor()
			resume_from_reflect_knockdown()


func _process_slam_jump(delta: float) -> void:
	_stop_horizontal_velocity()
	_attack_timer -= delta
	if _is_slam_jump_arc_complete():
		_begin_slam_fall()


func _is_slam_jump_arc_complete() -> bool:
	if _slam_jump_tween == null:
		return true
	if not _slam_jump_tween.is_valid():
		_slam_jump_tween = null
		return true
	return not _slam_jump_tween.is_running()


func _process_slam_fall(delta: float) -> void:
	velocity.x = _slam_direction.x * TcSlamAttackScript.FALL_FORWARD_SPEED
	velocity.z = _slam_direction.z * TcSlamAttackScript.FALL_FORWARD_SPEED
	velocity.y -= GRAVITY * delta
	_attack_timer -= delta

	if is_on_floor() and velocity.y <= 0.0:
		velocity = Vector3.ZERO
		TcSlamAttackScript.apply_slam_landing(self, _slam_direction)
		_attack_cooldown = TcMeleeStrikeScript.COOLDOWN
		_abort_action_one_shots()
		_snap_locomotion_idle()
		_begin_combat_deciding()


func _process_healing(delta: float) -> void:
	_stop_horizontal_velocity()
	_state_timer -= delta
	if _state_timer <= 0.0:
		_health = TcHealingSpellScript.apply_heal(_health, MAX_HEALTH)
		_heal_cooldown = TcHealingSpellScript.COOLDOWN
		_begin_combat_deciding()


func _process_relocating(delta: float) -> void:
	if _combat_target == null:
		_begin_chase()
		return

	var to_point := _relocate_target - global_position
	to_point.y = 0.0
	if to_point.length() <= RELOCATE_ARRIVE_DIST:
		_begin_combat_deciding()
		return

	_move_in_direction(to_point.normalized(), RUN_SPEED, delta)


func _begin_chase() -> void:
	_ai_state = AiState.CHASE
	_tween_combat_idle_blend(1.0, COMBAT_IDLE_TWEEN_DURATION)


func _begin_combat_deciding() -> void:
	_ai_state = AiState.COMBAT_DECIDING
	_decision_timer = randf_range(DECISION_MIN, DECISION_MAX)
	_snap_locomotion_idle()
	_tween_combat_idle_blend(1.0, COMBAT_IDLE_TWEEN_DURATION)


func _prepare_for_action_anim() -> void:
	_stop_horizontal_velocity()
	_tween_locomotion_blend(0.0, LOCOMOTION_TWEEN_DURATION)


func _snap_locomotion_idle() -> void:
	_stop_horizontal_velocity()
	_tween_locomotion_blend(0.0, LOCOMOTION_TWEEN_DURATION)


func _abort_action_one_shots() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	for one_shot_name: StringName in [
		TcAnimConfigScript.PUNCH_ONE_SHOT,
		TcAnimConfigScript.BACK_JUMP_ONE_SHOT,
		TcAnimConfigScript.FALL2_ONE_SHOT,
		TcAnimConfigScript.BACKFLIP_ONE_SHOT,
		TcAnimConfigScript.CHARGE_ONE_SHOT,
		TcAnimConfigScript.RUN_FAST_ONE_SHOT,
		TcAnimConfigScript.WALL_FLIP_ONE_SHOT,
		TcAnimConfigScript.BLOCK_REACT_ONE_SHOT,
		TcAnimConfigScript.HIT_REACT_ONE_SHOT,
		TcAnimConfigScript.HIP_HOP_ONE_SHOT,
	]:
		_animation_tree.set(
			"parameters/%s/request" % one_shot_name,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		)


func _finish_backflip_bubbles() -> void:
	_gun_aim_backflip_cooldown = GUN_AIM_BACKFLIP_COOLDOWN
	_abort_action_one_shots()
	_snap_locomotion_idle()
	_begin_combat_deciding()


func _begin_blocking(approach := false, hold_override := -1.0) -> void:
	_ai_state = AiState.BLOCKING
	_blocking = true
	_blocking_approach = approach
	_prepare_for_action_anim()
	_state_timer = (
		hold_override
		if hold_override > 0.0
		else randf_range(BLOCK_DURATION_MIN, BLOCK_DURATION_MAX)
	)
	_tween_block_blend(1.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_IN)


func _end_blocking() -> void:
	_blocking = false
	_blocking_approach = false
	_tween_block_blend(0.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT)


func _begin_attack_windup(kind: AttackKind = AttackKind.MELEE_CHARGE) -> void:
	_ai_state = AiState.ATTACK_WINDUP
	_attack_kind = kind
	_prepare_for_action_anim()
	match kind:
		AttackKind.WATER_WAVE:
			_windup_timer = randf_range(
				TcWaterWaveSpellScript.WINDUP_MIN,
				TcWaterWaveSpellScript.WINDUP_MAX
			)
		_:
			_windup_timer = randf_range(
				TcMeleeStrikeScript.WINDUP_MIN,
				TcMeleeStrikeScript.WINDUP_MAX
			)


func _begin_attacking() -> void:
	_ai_state = AiState.ATTACKING
	_attack_elapsed = 0.0
	_attack_struck = false
	_attack_timer = _get_attack_length()
	_fire_attack_one_shot(_get_attack_one_shot_name())


func _end_attacking() -> void:
	match _attack_kind:
		AttackKind.WATER_WAVE:
			_attack_cooldown = TcWaterWaveSpellScript.COOLDOWN
		_:
			_attack_cooldown = TcMeleeStrikeScript.COOLDOWN
	_abort_action_one_shots()
	_snap_locomotion_idle()
	_begin_combat_deciding()


func _begin_slam_jump() -> void:
	if _combat_target != null:
		_slam_direction = _get_attack_direction()
		_face_position(_combat_target.global_position, get_physics_process_delta_time())
	_prepare_for_action_anim()
	_ai_state = AiState.SLAM_JUMP
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_BACK_JUMP, 0.9)
	_attack_struck = false
	_fire_attack_one_shot(TcAnimConfigScript.BACK_JUMP_ONE_SHOT)

	var start_y := global_position.y
	var peak_y := start_y + TcSlamAttackScript.JUMP_HEIGHT
	if _slam_jump_tween != null and _slam_jump_tween.is_valid():
		_slam_jump_tween.kill()
	_slam_jump_tween = create_tween()
	_slam_jump_tween.tween_property(self, "global_position:y", peak_y, TcSlamAttackScript.JUMP_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _begin_slam_fall() -> void:
	if _ai_state != AiState.SLAM_JUMP:
		return
	if _slam_jump_tween != null and _slam_jump_tween.is_valid():
		_slam_jump_tween.kill()
	_slam_jump_tween = null
	_ai_state = AiState.SLAM_FALL
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_FALL2, 1.1)
	_fire_attack_one_shot(TcAnimConfigScript.FALL2_ONE_SHOT)
	velocity.y = -1.0


func _begin_healing() -> void:
	_ai_state = AiState.HEALING
	_prepare_for_action_anim()
	_state_timer = TcHealingSpellScript.AURA_DURATION * 0.65
	TcHealingSpellScript.spawn_aura(self)


func _begin_relocate() -> void:
	_ai_state = AiState.RELOCATING
	_relocate_target = _pick_relocate_point()


func _begin_backflip_bubbles() -> void:
	_ai_state = AiState.BACKFLIP_BUBBLES
	_prepare_for_action_anim()
	_attack_elapsed = 0.0
	_attack_struck = false
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_BACKFLIP_HOOKS, 1.4)
	_bubble_burst_remaining = 0
	_bubble_burst_timer = 0.0
	_fire_attack_one_shot(TcAnimConfigScript.BACKFLIP_ONE_SHOT)


func _begin_hip_hop_dance() -> void:
	_ai_state = AiState.HIP_HOP_DANCE
	_prepare_for_action_anim()
	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, get_physics_process_delta_time())
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_HIP_HOP_DANCE, 3.0)
	_dance_boulder_timer = 0.35
	_fire_attack_one_shot(TcAnimConfigScript.HIP_HOP_ONE_SHOT)


func _restart_hip_hop_dance() -> void:
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_HIP_HOP_DANCE, 3.0)
	_dance_boulder_timer = 0.2
	_fire_attack_one_shot(TcAnimConfigScript.HIP_HOP_ONE_SHOT)


func _finish_hip_hop_dance() -> void:
	_hip_hop_cooldown = TcHipHopDanceScript.COOLDOWN
	_abort_action_one_shots()
	_snap_locomotion_idle()
	_begin_combat_deciding()


func _begin_charge_run_windup() -> void:
	_charge_target = TcChargeRunScript.find_nearest_player(self)
	if _charge_target == null:
		_begin_combat_deciding()
		return

	_combat_target = _charge_target
	_ai_state = AiState.CHARGE_RUN_WINDUP
	_charge_hit_targets.clear()
	_prepare_for_action_anim()
	_tween_combat_idle_blend(1.0, COMBAT_IDLE_TWEEN_DURATION)
	_state_timer = TcChargeRunScript.WINDUP_DURATION
	_face_position(_charge_target.global_position, get_physics_process_delta_time())
	TcChargeRunScript.spawn_target_alert(self, _charge_target)


func _begin_charge_run() -> void:
	if _charge_target == null or not is_instance_valid(_charge_target):
		_finish_charge_run()
		return

	_ai_state = AiState.CHARGE_RUN
	var to_target := _charge_target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		_charge_direction = _get_flat_forward()
	else:
		_charge_direction = to_target.normalized()

	_state_timer = TcChargeRunScript.MAX_DURATION
	_charge_trail_timer = 0.0
	_fire_attack_one_shot(TcAnimConfigScript.RUN_FAST_ONE_SHOT)


func _begin_charge_wall_flip(impact_point: Vector3, wall_normal: Vector3) -> void:
	_ai_state = AiState.CHARGE_WALL_FLIP
	_stop_horizontal_velocity()
	_abort_action_one_shots()
	TcChargeRunScript.spawn_wall_impact(self, impact_point, wall_normal)
	_attack_timer = _get_clip_length(TcAnimConfigScript.CLIP_WALL_FLIP, 1.1)
	_fire_attack_one_shot(TcAnimConfigScript.WALL_FLIP_ONE_SHOT)


func _finish_charge_run() -> void:
	_charge_run_cooldown = TcChargeRunScript.COOLDOWN
	_charge_target = null
	_charge_hit_targets.clear()
	_stop_horizontal_velocity()
	_abort_action_one_shots()
	_snap_locomotion_idle()
	_tween_combat_idle_blend(1.0, COMBAT_IDLE_TWEEN_DURATION)
	_begin_combat_deciding()


func _check_charge_wall_collision() -> void:
	if not TcChargeRunScript.is_boss_room(self):
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if not TcChargeRunScript.is_wall_collision(normal):
			continue
		var impact_point := collision.get_position()
		_begin_charge_wall_flip(impact_point, normal)
		return


func _execute_attack_strike() -> void:
	var strike_dir := _get_attack_direction()
	match _attack_kind:
		AttackKind.WATER_WAVE:
			TcWaterWaveSpellScript.launch_wave(self, strike_dir, _combat_target)
		AttackKind.MELEE_CHARGE:
			TcMeleeStrikeScript.play_strike_presentation(self, strike_dir, _combat_target)
			TcMeleeStrikeScript.apply_strike(self, strike_dir, _combat_target)


func _launch_bubble() -> void:
	if _combat_target == null or not is_instance_valid(_combat_target):
		return
	var bubble := TcBubbleProjectileScript.new()
	bubble.name = "TcBubble"
	var fx_parent := ImpactFXScript.parent_for(self)
	fx_parent.add_child(bubble)
	bubble.global_position = global_position + Vector3(0.0, 2.2, 0.0)
	var lifetime := randf_range(2.0, 4.0)
	bubble.setup(self, _combat_target, lifetime)


func _on_attack_blocked(hit_info: Dictionary) -> void:
	_focus_attacker_from_hit(hit_info)
	_play_block_react()
	var attacker: Node = hit_info.get("shooter")
	MeleeClashScript.resolve(self, attacker, hit_info)


func _play_block_react() -> void:
	var react_clips: Array[StringName] = [
		TcAnimConfigScript.CLIP_BLOCK2,
		TcAnimConfigScript.CLIP_BLOCK3,
		TcAnimConfigScript.CLIP_BLOCK4,
		TcAnimConfigScript.CLIP_BLOCK5,
	]
	var clip_name := react_clips[randi() % react_clips.size()]
	if _animation_player != null:
		var library := _animation_player.get_animation_library(TcAnimConfigScript.LIBRARY)
		if library != null and library.has_animation(clip_name):
			library.add_animation(TcAnimConfigScript.CLIP_BLOCK2, library.get_animation(clip_name))
	_fire_attack_one_shot(TcAnimConfigScript.BLOCK_REACT_ONE_SHOT)


func _play_hit_react() -> void:
	if _ai_state in [
		AiState.SLAM_JUMP,
		AiState.SLAM_FALL,
		AiState.BACKFLIP_BUBBLES,
		AiState.HIP_HOP_DANCE,
		AiState.CHARGE_RUN,
		AiState.CHARGE_WALL_FLIP,
	]:
		return
	_fire_attack_one_shot(TcAnimConfigScript.HIT_REACT_ONE_SHOT)


func _can_block_melee(hit_info: Dictionary) -> bool:
	if not _blocking:
		return false
	if not hit_info.get("melee", false):
		return false
	return _is_facing_attack(hit_info)


func _is_facing_attack(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return _get_flat_forward().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN
	var attack_dir := _get_flat_attack_direction(hit_info)
	return _get_flat_forward().dot(attack_dir) <= -BLOCK_FACING_DOT_MIN


func _get_flat_attack_direction(hit_info: Dictionary) -> Vector3:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = _get_flat_forward()
	return direction.normalized()


func _update_player_gun_aim_threat(delta: float) -> void:
	if _gun_aim_backflip_committed:
		return

	var player := _find_player()
	var aimed := player != null and _is_player_pointing_gun_at_me(player)
	if aimed:
		_focus_hostile(player)
		if _gun_aim_backflip_cooldown > 0.0:
			return
		if not _gun_aim_backflip_pending:
			_gun_aim_backflip_pending = true
			_gun_aim_backflip_timer = randf_range(
				GUN_AIM_BACKFLIP_DELAY_MIN,
				GUN_AIM_BACKFLIP_DELAY_MAX
			)
			_gun_aim_backflip_threat = player
			return

		_gun_aim_backflip_timer -= delta
		if _gun_aim_backflip_timer <= 0.0:
			_gun_aim_backflip_pending = false
			_gun_aim_backflip_committed = true
		return

	if _gun_aim_backflip_pending:
		_gun_aim_backflip_pending = false
		_gun_aim_backflip_timer = 0.0
		_gun_aim_backflip_threat = null


func _try_execute_committed_gun_aim_backflip() -> void:
	if not _gun_aim_backflip_committed:
		return
	if _defeated or _gun_aim_backflip_cooldown > 0.0:
		_gun_aim_backflip_committed = false
		return
	if _ai_state in [
		AiState.ATTACK_WINDUP,
		AiState.ATTACKING,
		AiState.BACKFLIP_BUBBLES,
		AiState.SLAM_JUMP,
		AiState.SLAM_FALL,
		AiState.HEALING,
		AiState.HIP_HOP_DANCE,
	]:
		_gun_aim_backflip_committed = false
		return

	_gun_aim_backflip_committed = false
	if _blocking:
		_end_blocking()
	_begin_backflip_bubbles()
	_gun_aim_backflip_threat = null


func _is_player_pointing_gun_at_me(player: Node3D) -> bool:
	if player == null or not _is_valid_hostile(player):
		return false
	var weapon_rig := player.get_node_or_null("WeaponRig")
	if weapon_rig == null or not weapon_rig.has_method("is_aiming") or not weapon_rig.is_aiming():
		return false
	if weapon_rig.has_method("get_equipped_weapon_id"):
		var weapon_id = weapon_rig.get_equipped_weapon_id()
		if (
			GroyperWeaponsScript.is_bow(weapon_id)
			or GroyperWeaponsScript.is_lasso(weapon_id)
		):
			return false
	if player.has_method("is_weapon_aimed_at"):
		return player.is_weapon_aimed_at(self, AIM_THREAT_RANGE)
	return false


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("overworld_player"):
		if node is Node3D and _is_valid_hostile(node):
			return node as Node3D
	return null


func _update_combat_target() -> void:
	if _combat_target != null and is_instance_valid(_combat_target):
		if not _is_valid_combat_target(_combat_target):
			_combat_target = null
	else:
		_combat_target = null
	if _combat_target == null:
		_combat_target = _find_player()


func _focus_hostile(target: Node3D) -> void:
	if target == null or not _is_valid_hostile(target):
		return
	_combat_target = target


func _focus_attacker_from_hit(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		_focus_hostile(attacker as Node3D)


func _is_valid_combat_target(node: Node) -> bool:
	if not _is_valid_hostile(node):
		return false
	var offset := (node as Node3D).global_position - global_position
	offset.y = 0.0
	return offset.length_squared() <= sight_range * sight_range


func _is_valid_hostile(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_defeated") and node.is_defeated():
		return false
	return FactionAffinityScript.are_hostile(self, node)


func _pick_relocate_point() -> Vector3:
	var center := global_position
	if _combat_target != null:
		center = _combat_target.global_position
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(4.0, 9.0)
	return center + Vector3(sin(angle), 0.0, cos(angle)) * distance


func _get_attack_length() -> float:
	match _attack_kind:
		AttackKind.WATER_WAVE:
			return _get_clip_length(TcAnimConfigScript.CLIP_PUNCH_FORWARD, 1.2)
		AttackKind.MELEE_CHARGE:
			return _get_clip_length(TcAnimConfigScript.CLIP_CHARGE, 1.5)
		_:
			return _get_clip_length(TcAnimConfigScript.CLIP_CHARGE, 1.5)


func _get_attack_strike_fraction() -> float:
	match _attack_kind:
		AttackKind.WATER_WAVE:
			return TcWaterWaveSpellScript.CAST_FRACTION
		_:
			return TcMeleeStrikeScript.STRIKE_FRACTION


func _get_attack_one_shot_name() -> StringName:
	match _attack_kind:
		AttackKind.WATER_WAVE:
			return TcAnimConfigScript.PUNCH_ONE_SHOT
		_:
			return TcAnimConfigScript.CHARGE_ONE_SHOT


func _get_attack_direction() -> Vector3:
	return TcMeleeStrikeScript.get_strike_direction(self, _combat_target)


func _fire_attack_one_shot(one_shot_name: StringName) -> void:
	if _animation_tree == null:
		return
	_animation_tree.set(
		"parameters/%s/request" % one_shot_name,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _get_clip_length(clip_name: StringName, fallback: float) -> float:
	if _animation_player == null:
		return fallback
	var clip_path := String(TcAnimUtilsScript.clip_path(clip_name))
	if _animation_player.has_animation(clip_path):
		return _animation_player.get_animation(clip_path).length
	return fallback


func _update_combat_idle_blend(delta: float) -> void:
	if _ai_state in [
		AiState.CHARGE_RUN_WINDUP,
		AiState.CHARGE_RUN,
		AiState.CHARGE_WALL_FLIP,
	]:
		return
	var target := 1.0
	_combat_idle_blend = lerpf(_combat_idle_blend, target, BLEND_SPEED * delta)
	_set_combat_idle_blend(_combat_idle_blend)


func _tween_locomotion_blend(target: float, duration: float) -> void:
	if _locomotion_blend_tween != null and _locomotion_blend_tween.is_valid():
		_locomotion_blend_tween.kill()
	_locomotion_blend = target
	var tween := CombatAnimTransitionsScript.tween_tree_float(
		self,
		_animation_tree,
		"LocomotionBlend/blend_position",
		target,
		duration
	)
	if tween != null:
		_locomotion_blend_tween = tween


func _tween_combat_idle_blend(target: float, duration: float) -> void:
	if _combat_idle_blend_tween != null and _combat_idle_blend_tween.is_valid():
		_combat_idle_blend_tween.kill()
	_combat_idle_blend = target
	var tween := CombatAnimTransitionsScript.tween_tree_float(
		self,
		_animation_tree,
		"LocomotionBlend/CombatIdleBlend/blend_amount",
		target,
		duration
	)
	if tween != null:
		_combat_idle_blend_tween = tween


func _set_combat_idle_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/LocomotionBlend/CombatIdleBlend/blend_amount",
		clampf(value, 0.0, 1.0)
	)


func _update_locomotion_blend(delta: float, horizontal_speed: float) -> void:
	var target := 0.0
	if horizontal_speed > LOCOMOTION_RUN_SPEED:
		target = 1.0
	elif horizontal_speed > LOCOMOTION_STOP_SPEED:
		target = 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_set_locomotion_blend(_locomotion_blend)


func _set_locomotion_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set("parameters/LocomotionBlend/blend_position", clampf(value, 0.0, 1.0))


func _set_block_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set("parameters/BlockBlend/blend_amount", clampf(value, 0.0, 1.0))


func _tween_block_blend(target: float, duration: float) -> void:
	if _block_blend_tween != null and _block_blend_tween.is_valid():
		_block_blend_tween.kill()
	var start := 0.0
	if _animation_tree != null:
		start = CombatAnimTransitionsScript.coerce_float(
			_animation_tree.get("parameters/BlockBlend/blend_amount")
		)
	_block_blend_tween = create_tween()
	_block_blend_tween.tween_method(_set_block_blend, start, target, duration)


func _move_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	var offset := target_pos - global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		_stop_horizontal_velocity()
		return
	_move_in_direction(offset.normalized(), speed, delta)


func _move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	if should_preserve_knockback_velocity():
		return
	if is_melee_stunned():
		_stop_horizontal_velocity()
		return
	var flat := direction
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		_stop_horizontal_velocity()
		return
	flat = flat.normalized()
	velocity.x = flat.x * speed
	velocity.z = flat.z * speed
	_face_direction(flat, delta)


func _face_position(target_pos: Vector3, delta: float) -> void:
	var offset := target_pos - global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		return
	_face_direction(offset.normalized(), delta)


func _face_direction(direction: Vector3, delta: float) -> void:
	if _model == null:
		return
	var target_yaw := get_model_facing_yaw_for_direction(direction)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _stop_horizontal_velocity() -> void:
	if should_preserve_knockback_velocity():
		return
	velocity.x = 0.0
	velocity.z = 0.0


func _get_flat_forward() -> Vector3:
	if _model == null:
		return Vector3.FORWARD
	var forward := _model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _die(hit_info: Dictionary) -> void:
	if _defeated:
		return
	var hit_position: Vector3 = hit_info.get("position", global_position + Vector3(0.0, 2.0, 0.0))
	GameAudioScript.play_death_sound(self, hit_position)
	BloodSplatterFXScript.spawn_big_for_hit(self, hit_info)
	_defeated = true
	velocity = Vector3.ZERO
	_bind_rig()
	if _ragdoll != null and _skeleton != null:
		_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
		if _model != null:
			_ragdoll.model_path = _ragdoll.get_path_to(_model)
		_ragdoll.bind_skeleton()
	if _ragdoll != null and not _ragdoll.is_active():
		if _animation_tree != null:
			_animation_tree.active = false
		if _animation_player != null:
			_animation_player.active = false
		_ragdoll.activate(hit_info, _animation_player)
