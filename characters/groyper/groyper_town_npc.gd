extends GroyperActor
class_name GroyperTownNpc

const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")
const DUEL_HAT_SCRIPT := preload("res://characters/groyper/groyper_duel_hat.gd")
const HAT_BASE_MATERIAL := preload("res://characters/groyper/cowboy_hat_material.tres")
const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const AlertSymbolFX := preload("res://gameplay/fx/alert_symbol_fx.gd")
const TownShootout := preload("res://gameplay/world/town_shootout.gd")
const TownAggroVoiceScript := preload("res://gameplay/audio/town_aggro_voice.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const FactionAffinity := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const FactionRally := preload("res://gameplay/faction/faction_rally.gd")
const FactionShowdown := preload("res://gameplay/faction/faction_showdown.gd")
const TownNpcShove := preload("res://gameplay/world/town_npc_shove.gd")
const RollDodgeExtract := preload("res://characters/groyper/roll_dodge_extract.gd")
const SaddlePoseConfig := preload("res://characters/groyper/saddle_pose_config.gd")
const NpcCombatNavigationScript := preload("res://gameplay/navigation/npc_combat_navigation.gd")
const PunchPoseExtractScript := preload("res://characters/groyper/punch_pose_extract.gd")
const PunchPoseConfig := preload("res://characters/groyper/punch_pose_config.gd")
const MeleePunchScript := preload("res://gameplay/combat/melee_punch.gd")
const GroyperLassoStandupScript := preload("res://characters/groyper/groyper_lasso_standup.gd")

const LOCOMOTION_BLEND := &"LocomotionBlend"
const ROLL_ANIM_NODE := &"RollAnim"
const ROLL_ONE_SHOT := &"RollOneShot"
const PUNCH_ANIM_NODE := &"PunchAnim"
const SADDLE_BLEND := &"SaddleBlend"
const SADDLE_ANIM_NODE := &"SaddleAnim"

const WALK_SPEED := 2.2
const RUN_SPEED := 5.5
const GRAVITY := 22.0
const FACING_SPEED := 10.0
const BLEND_SPEED := 8.0
const THREATEN_RANGE := 18.0
const CHEST_AIM_HEIGHT := 1.25
const COMBAT_FIRE_DELAY_MIN := 1.5
const COMBAT_FIRE_DELAY_MAX := 3.0
const AGGRO_COMBAT_FIRE_DELAY_MIN := 1.2
const AGGRO_COMBAT_FIRE_DELAY_MAX := 2.4
const COMBAT_RELOCATE_MIN := 4.0
const COMBAT_RELOCATE_MAX := 9.0
const COMBAT_ARRIVE_DISTANCE := 0.65
const COMBAT_MISS_DISTANCE_NEAR := 3.0
const COMBAT_MISS_DISTANCE_FAR := 30.0
const COMBAT_AIM_MISS_CHANCE_NEAR := 0.02
const COMBAT_AIM_MISS_CHANCE_FAR := 0.90
const CENTERED_AIM_SPREAD := 0.06
const OFF_BODY_AIM_SPREAD := 1.1
const ALERT_HEAD_OFFSET := 2.45
const ALERT_HEAD_BONE_OFFSET := 0.55
const FACTION_ESCALATE_MIN := 5.0
const FACTION_ESCALATE_MAX := 10.0
const FACTION_ESCALATE_CHANCE := 0.30
const FACTION_ALLY_DRAW_RANGE := 14.0
const FACTION_INTERVENE_RANGE := 22.0
const AIM_THREAT_RANGE := 48.0
const FACTION_STARE_BEFORE_DRAW_DELAY := 1.0
const FACTION_THREAT_LOST_GRACE := 0.5
const PLAYER_HOLSTER_DEESCALATE_DELAY := 3.0
const AIM_THREAT_CONE_DEG := 60.0
const FACTION_AGGRO_RALLY_RANGE := 60.0
const SHOVE_STUMBLE_SPEED := 2.6
const SHOVE_STUMBLE_COOLDOWN := 1.25
const SHOVE_STEP_WALK_BLEND := 0.5
const ROLL_SPEED_MULTIPLIER := 1.5
const RUN_ROLL_SPEED_MULTIPLIER := 1.05
const ROLL_ANIM_FADEIN := 0.06
const ROLL_ANIM_FADEOUT := 0.12
const ROLL_HITBOX_HALF_HEIGHT := 0.22
const ROLL_HITBOX_RADIUS := 0.12
const COMBAT_ROLL_CHANCE := 0.38
const COMBAT_ROLL_ON_HIT_CHANCE := 0.22
const COMBAT_ROLL_COOLDOWN := 3.5
const COMBAT_PUNCH_CHANCE := 0.42
const PUNCH_BLEND_IN_SPEED := 5.5
const SADDLE_BLEND_SPEED := 8.0
const HORSE_MOUNT_RANGE := 2.35
const HORSE_SEARCH_RANGE := 30.0
const HORSE_PATROL_CHECK_MIN := 16.0
const HORSE_PATROL_CHECK_MAX := 32.0
const HORSE_PATROL_RIDE_MIN := 8.0
const HORSE_PATROL_RIDE_MAX := 18.0
const HORSE_PATROL_MOUNT_CHANCE := 0.4
const HORSE_COMBAT_CHASE_RANGE := 30.0
const HORSE_MOUNT_COOLDOWN := 14.0
const HORSE_PATROL_WANDER_MIN := 6.0
const HORSE_PATROL_WANDER_MAX := 16.0
const MOUNT_DEFEAT_LAUNCH_SPEED := 8.0
const MOUNT_DEFEAT_LAUNCH_UP := 5.5
const HORSE_DEATH_DISMOUNT_DURATION := 0.38
const HORSE_DEATH_DISMOUNT_ARC := 0.45
const DISMOUNT_HOP_DURATION := 0.46
const DISMOUNT_HOP_HEIGHT := 0.8
const MOUNT_AIM_SPINE_DEAD_ZONE := deg_to_rad(32.0)
const MOUNT_AIM_SPINE_SMOOTH := 14.0
const MOUNTED_FIRE_HORSE_CHANCE := 0.5

const HORSE_RIDE_NONE := 0
const HORSE_RIDE_PATROL := 1
const HORSE_RIDE_COMBAT_CHASE := 2

enum AiState {
	IDLE,
	WALKING,
	STARING,
	APPROACHING_HORSE,
	COMBAT_DRAWING,
	COMBAT_AIMING,
	COMBAT_MOVING,
	DEFEATED,
}

const HAT_COLOR_PALETTE: Array[Color] = [
	Color(0.72, 0.18, 0.14),
	Color(0.15, 0.35, 0.75),
	Color(0.2, 0.6, 0.25),
	Color(0.94, 0.82, 0.2),
	Color(0.94, 0.94, 0.92),
	Color(0.55, 0.28, 0.62),
	Color(0.35, 0.22, 0.14),
	Color(0.08, 0.08, 0.1),
]

@export var random_hat_color := true
@export var wear_hat := true
@export var hat_color := Color(0.72, 0.18, 0.14)
@export var equipped_weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.REVOLVER
@export var faction_on_sight_aggro_range := 18.0
@export var faction_max_engage_range := 24.0
@export var idle_duration_min := 5.0
@export var idle_duration_max := 10.0
@export var walk_duration_min := 2.0
@export var walk_duration_max := 5.0

const HITBOX_HALF_HEIGHT := 0.48
const HITBOX_RADIUS := 0.28
const MOUNTED_HITBOX_HALF_HEIGHT := 0.54
const MOUNTED_HITBOX_RADIUS := 0.36
const MOUNTED_CHEST_OFFSET := Vector3(0.0, 0.62, 0.0)
const MOUNTED_HEAD_OFFSET := Vector3(0.0, 1.02, 0.0)
const MOUNTED_HEAD_RADIUS := 0.38
const MOUNTED_HITBOX_MIN_Y_ABOVE_MOUNT := 0.28

var _weapon_rig
var _ragdoll
var _duel_hat
var _aggro_voice: Node
var _combat_nav

var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _aim_target: Node3D
var _combat_active := false
var _defeated := false
var _health := BulletHitDamage.DEFAULT_MAX_HEALTH
var _fire_timer := 0.0
var _fire_timer_duration := 0.0
var _committed_aim_zone := ""
var _aim_spread_offset := Vector3.ZERO
var _smoothed_aim_point := Vector3.ZERO
var _has_locked_aim := false
var _combat_move_target := Vector3.ZERO
var _combat_move_pursue := false
var _saved_ai_state := AiState.IDLE
var _roam_center := Vector3.ZERO
var _roam_half_extents := Vector2(4.5, 42.0)
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_ring: LassoRing
var _lasso_rope_length := 8.5
var _lasso_standup_active := false
var _lasso_standup_time := 0.0
var _lasso_standup_blend := 0.0
var _lasso_standup_nodes_ready := false
var _lasso_standup_model_sink := 0.0
var _faction_id: StringName = &""
var _faction_standoff_active := false
var _faction_aggro_level := 0
var _faction_provoker: Node3D
var _faction_escalation_timer := 0.0
var _faction_aggro_entered_timer := 0.0
var _faction_threat_lost_timer := 0.0
var _player_holstered_deescalate_timer := 0.0
var _faction_standing_down := false
var _shove_stumbling := false
var _shove_direction := Vector3.ZERO
var _shove_stumble_cooldown := 0.0
var _gentle_shove_stepping := false
var _gentle_shove_step_time := 0.0
var _gentle_shove_step_dir := Vector3.ZERO
var _gentle_shove_step_from := Vector3.ZERO
var _gentle_shove_step_distance := 0.0
var _gentle_shove_step_cooldown := 0.0
var _shove_settling := false
var _shove_settle_time := 0.0
var _shove_settle_from_blend := 0.0
var _shove_saved_ai_state := AiState.IDLE
var _shove_was_in_combat := false
var _stumble_exit_blending := false
var _shove_settle_duration := TownNpcShove.SHOVE_SETTLE_DURATION
var _roll_active := false
var _roll_timer := 0.0
var _roll_duration := 0.0
var _roll_direction := Vector3.ZERO
var _roll_speed := 0.0
var _roll_speed_multiplier := ROLL_SPEED_MULTIPLIER
var _roll_is_run := false
var _roll_cooldown := 0.0
var _roll_anim_node: AnimationNodeAnimation
var _punch_active := false
var _punch_timer := 0.0
var _punch_duration := 0.0
var _punch_direction := Vector3.ZERO
var _punch_strike_applied := false
var _punch_cooldown := 0.0
var _punch_exit_active := false
var _punch_exit_timer := 0.0
var _punch_blend := 0.0
var _punch_blend_node: AnimationNodeBlend2
var _punch_anim_node: AnimationNodeAnimation
var _collision_shape: CollisionShape3D
var _saddle_blend_node: AnimationNodeBlend2
var _saddle_blend := 0.0
var _mounted_horse: StupidHorse
var _mounted_model_mount_offset := Transform3D.IDENTITY
var _horse_mount_target: StupidHorse
var _horse_ride_purpose := HORSE_RIDE_NONE
var _horse_ride_target := Vector3.ZERO
var _horse_ride_timer := 0.0
var _horse_mount_cooldown := 0.0
var _horse_patrol_check_timer := 0.0
var _mount_spine_yaw := 0.0
var _mounted_fire_horse: StupidHorse
var _mounted_aim_alert_active := false
var _player_weapon_threat_active := false
var _horse_dismount_tween: Tween
var _horse_dismount_active := false
var _horse_death_dismount_callback: Callable
var _horse_dismount_launch_velocity := Vector3.ZERO


func _on_actor_ready() -> void:
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	_horse_patrol_check_timer = randf_range(HORSE_PATROL_CHECK_MIN, HORSE_PATROL_CHECK_MAX)
	add_to_group("town_npc")
	add_to_group("becker_boys")
	add_to_group(get_town_character_group())
	add_to_group("duel_target")
	add_to_group("lassoable")
	if FactionIds.rallies_town_on_injury(get_faction_id()):
		add_to_group("faction_npc")
	TownNpcShove.configure_npc_collision(self)
	_setup_locomotion()
	setup_npc_locomotion_audio()
	_setup_combat()
	_setup_combat_navigation()
	_begin_idle()
	call_deferred("_finalize_spawn")


func get_town_character_group() -> StringName:
	return &"town_groyper"


func _finalize_spawn() -> void:
	if _mounted_horse == null:
		snap_to_floor()
	_roam_center = global_position


func _physics_process(delta: float) -> void:
	if _defeated:
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if not _defeated:
		_update_player_weapon_reaction(delta)

	_shove_stumble_cooldown = maxf(_shove_stumble_cooldown - delta, 0.0)
	_gentle_shove_step_cooldown = maxf(_gentle_shove_step_cooldown - delta, 0.0)
	_roll_cooldown = maxf(_roll_cooldown - delta, 0.0)
	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
	_horse_mount_cooldown = maxf(_horse_mount_cooldown - delta, 0.0)

	if _punch_active:
		_update_punch_overlay(delta)

	tick_melee_stun(delta)
	if is_melee_stunned() and not _defeated:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = minf(velocity.y, 0.0)
		move_and_slide()
		var stunned_speed := Vector2(velocity.x, velocity.z).length()
		_update_locomotion_blend(delta, stunned_speed, false)
		update_npc_locomotion_audio(delta, stunned_speed, stunned_speed > 0.05, false)
		_state_timer -= delta
		return

	if _roll_active:
		_update_roll_dodge(delta)
		return

	if _horse_dismount_active:
		velocity = Vector3.ZERO
		move_and_slide()
		update_npc_locomotion_audio(delta, 0.0, false, false)
		return

	if _mounted_horse != null:
		_update_mounted_physics(delta)
		return

	if _shove_stumbling:
		_process_shove_stumble(delta)
		return

	if _gentle_shove_stepping:
		_process_gentle_shove_step(delta)
		return

	if _shove_settling:
		_process_shove_settle(delta)
		return

	if is_npc_shoveable():
		var shove_contact := TownNpcShove.find_strongest_contact(self)
		var shove_level: int = int(shove_contact.get("level", TownNpcShove.Level.NONE))
		if shove_level == TownNpcShove.Level.LETHAL:
			receive_bullet_hit(
				TownNpcShove.build_lethal_hit_info(
					self,
					shove_contact.get("mover") as CharacterBody3D,
					shove_contact.get("push_dir", Vector3.ZERO)
				)
			)
			move_and_slide()
			update_npc_locomotion_audio(delta, 0.0, false, false)
			return
		if shove_level == TownNpcShove.Level.STUMBLE and _shove_stumble_cooldown <= 0.0:
			_begin_shove_stumble(shove_contact.get("push_dir", Vector3.FORWARD))
			_process_shove_stumble(delta)
			return
		if (
			shove_level == TownNpcShove.Level.GENTLE
			and _gentle_shove_step_cooldown <= 0.0
		):
			_begin_gentle_shove_step(
				shove_contact.get("push_dir", Vector3.FORWARD),
				float(shove_contact.get("speed", 0.0))
			)
			_process_gentle_shove_step(delta)
			return

	if _uses_faction_aggro() or _faction_aggro_level > 0:
		_update_faction_aggro(delta)

	if not _combat_active and not _faction_aggro_locks_peaceful_roam() and _horse_mount_target == null:
		_update_peaceful_horse_patrol(delta)

	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if not _combat_active and not _faction_aggro_locks_peaceful_roam() and _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			velocity.x = _walk_direction.x * WALK_SPEED
			velocity.z = _walk_direction.z * WALK_SPEED
			_face_position(global_position + _walk_direction, delta)
			if not _combat_active and not _faction_aggro_locks_peaceful_roam() and _state_timer <= 0.0:
				_begin_idle()
		AiState.STARING:
			velocity.x = 0.0
			velocity.z = 0.0
			if _aim_target != null:
				_face_position(_aim_target.global_position, delta)
		AiState.APPROACHING_HORSE:
			_process_approach_horse(delta)
		AiState.COMBAT_MOVING:
			if _combat_move_pursue:
				_apply_combat_pursue_movement(delta)
			else:
				_apply_combat_relocate_movement(delta)
		_:
			velocity.x = 0.0
			velocity.z = 0.0
			if _aim_target != null:
				_face_position(_aim_target.global_position, delta)

	_apply_punch_strike_if_ready()
	move_with_ground_snap()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var sprinting := _ai_state == AiState.COMBAT_MOVING
	var moving := (
		_ai_state == AiState.WALKING
		or _ai_state == AiState.COMBAT_MOVING
		or _ai_state == AiState.APPROACHING_HORSE
	)
	if not _shove_stumbling and not _gentle_shove_stepping and not _shove_settling:
		_update_locomotion_blend(delta, horizontal_speed, sprinting)
	update_npc_locomotion_audio(delta, horizontal_speed, moving, sprinting)

	_state_timer -= delta


func _process(delta: float) -> void:
	if _defeated or _weapon_rig == null or _lasso_captured:
		return

	if _has_locked_aim and _aim_target != null and not _faction_standing_down:
		_update_aim_tracking(delta)
	if _faction_standing_down and _weapon_rig.is_holstered():
		_finish_faction_stand_down()
	if _mounted_horse != null:
		_update_mounted_aim_spine(delta)
		_update_mounted_saddle_gun_arm()
	_weapon_rig.update(delta, _smoothed_aim_point)
	_update_combat_ai(delta)


func set_hat_color(color: Color) -> void:
	hat_color = color
	if _duel_hat != null and _skeleton != null:
		_duel_hat.bind_skeleton(_skeleton, _create_hat_material(color))
		_duel_hat.prepare_for_round(false)


func get_faction_id() -> StringName:
	if _faction_id != &"":
		return _faction_id
	return FactionIds.BECKER_BOYS


func get_faction_aggro_level() -> int:
	return _faction_aggro_level


func get_faction_aggro_target() -> Node3D:
	return _aim_target


func _uses_faction_aggro() -> bool:
	return (
		FactionIds.rallies_town_on_injury(get_faction_id())
		or _faction_standoff_active
		or FactionAffinity.faction_wars_with_outsiders(get_faction_id())
	)


func _faction_aggro_locks_peaceful_roam() -> bool:
	return _faction_standoff_active or _faction_aggro_level > 0 or _player_weapon_threat_active


func _is_provoked_player(target: Node3D) -> bool:
	if target == null or not target.is_in_group("overworld_player"):
		return false
	if _faction_provoker != target:
		return false
	return _faction_aggro_level >= 2


func _player_is_aiming_at_me(player: Node3D) -> bool:
	return _is_player_weapon_threatening_target(player, self)


func _is_valid_combat_target(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if _is_standoff_ranch_ally(target):
		return false
	if FactionAffinity.are_hostile(self, target):
		return true
	return _is_provoked_player(target)


func _is_player_townsperson_assault(shooter: Node3D) -> bool:
	return (
		shooter != null
		and shooter.is_in_group("overworld_player")
		and FactionIds.rallies_town_on_injury(get_faction_id())
	)


func _faction_wars_with_outsiders() -> bool:
	return FactionAffinity.faction_wars_with_outsiders(get_faction_id())


func _check_outsider_player_threat() -> void:
	if not _faction_wars_with_outsiders() or _defeated:
		return

	var player := _find_player()
	if player == null:
		return
	if not _is_player_weapon_threatening_target(player, self):
		return

	var level := 2 if _faction_aggro_level <= 1 else 3
	set_faction_aggro_level(level, player)


func _react_to_hostile_shooter(
	shooter: Node3D,
	killed: bool,
	_hit_info: Dictionary = {}
) -> void:
	if shooter == null or not is_instance_valid(shooter):
		return
	if not _is_valid_combat_target(shooter) and not _is_player_townsperson_assault(shooter):
		return

	if _uses_faction_aggro() or _faction_standoff_active:
		if FactionIds.rallies_town_on_injury(get_faction_id()):
			_trigger_town_shootout(shooter)
		else:
			FactionRally.rally_faction_on_injury(self, shooter, get_tree(), 3)
		_ensure_overworld_combat_for_target(shooter)
		if not killed:
			set_faction_aggro_level(maxi(_faction_aggro_level, 3), shooter)
	elif not killed:
		if FactionIds.rallies_town_on_injury(get_faction_id()):
			_trigger_town_shootout(shooter)
		if not _combat_active:
			enter_combat(shooter)


func notify_mounted_horse_shot(hit_info: Dictionary) -> void:
	if _defeated:
		return
	_react_to_hostile_shooter(hit_info.get("shooter"), false)


func notify_mounted_horse_killed(hit_info: Dictionary) -> void:
	if _defeated or _horse_dismount_active:
		return
	if _mounted_horse == null and not _is_model_parented_to_horse():
		return
	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	var exit_pos := global_position
	if horse != null and horse.has_method("get_death_dismount_position_for_rider"):
		exit_pos = horse.get_death_dismount_position_for_rider(hit_info)
	dismount_from_dead_horse(exit_pos, hit_info)


func is_faction_standoff_active() -> bool:
	return _faction_standoff_active


func celebrate_faction_showdown_victory() -> void:
	if _defeated:
		return
	exit_faction_standoff_peaceful()
	if _aggro_voice != null:
		_aggro_voice.play_cheer()


func exit_faction_standoff_peaceful() -> void:
	if _defeated:
		return

	_faction_standoff_active = false
	exit_town_faction_combat_peaceful()


func exit_town_faction_combat_peaceful() -> void:
	if _defeated:
		return
	if _faction_standoff_active:
		return

	_player_weapon_threat_active = false
	_faction_threat_lost_timer = 0.0
	_player_holstered_deescalate_timer = 0.0
	_faction_standing_down = false
	_faction_escalation_timer = 0.0
	_faction_aggro_entered_timer = 0.0
	_faction_aggro_level = 0
	_faction_provoker = null
	_cancel_horse_approach()
	if _mounted_horse != null and _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE:
		_request_horse_dismount()
	if _combat_nav != null:
		_combat_nav.clear_target()
	_combat_active = false
	_combat_move_pursue = false
	_aim_target = null
	_has_locked_aim = false
	_reset_bow_draw()
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()
	_velocity_zero()
	_begin_idle()


func configure_faction_standoff(faction_id: StringName, stare_target: Node3D = null) -> void:
	_faction_id = faction_id
	_faction_standoff_active = true
	add_to_group("faction_npc")
	set_faction_aggro_level(1, stare_target)


func set_faction_aggro_level(level: int, target: Node3D = null) -> void:
	if _defeated:
		return

	var previous_level := _faction_aggro_level
	_faction_aggro_level = clampi(level, 0, 3)
	if _faction_aggro_level == 0:
		_faction_provoker = null
		_faction_aggro_entered_timer = 0.0
	elif target != null:
		_faction_provoker = target
	if _faction_aggro_level != previous_level:
		_faction_aggro_entered_timer = 0.0

	match _faction_aggro_level:
		1:
			_combat_active = false
			_combat_move_pursue = false
			_has_locked_aim = false
			if _mounted_horse != null and _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE:
				_horse_ride_purpose = HORSE_RIDE_NONE
			if _horse_mount_target != null:
				_cancel_horse_approach()
			if _weapon_rig != null and _weapon_rig.is_aiming():
				_weapon_rig.begin_holster()
			_aim_target = target if target != null else _pick_nearest_hostile_in_range()
			_saved_ai_state = AiState.STARING
			_ai_state = AiState.STARING
			_velocity_zero()
			_snap_face_toward_target()
			_schedule_faction_escalation()
			if previous_level == 0 and not _faction_standoff_active:
				_faction_threat_lost_timer = 0.0
				_show_alert_fx()
				if _aggro_voice != null:
					if _aggro_voice.has_method("play_woah_now"):
						_aggro_voice.play_woah_now()
					else:
						_aggro_voice.play_woah_on_alert()
		2, 3:
			var combat_target := target
			if combat_target == null:
				combat_target = _aim_target
			if combat_target == null:
				combat_target = _pick_nearest_hostile_in_range()
			if combat_target == null:
				return
			_ensure_overworld_combat_for_target(combat_target)
			if not _combat_active:
				enter_combat(combat_target)
			else:
				var target_changed := combat_target != _aim_target
				_aim_target = combat_target
				if target_changed or not _has_locked_aim:
					_roll_mounted_fire_target()
					_committed_aim_zone = _pick_body_aim_zone()
					_refresh_aim_spread()
					_has_locked_aim = true
					_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset
			if _faction_aggro_level >= 2:
				_schedule_faction_escalation()
			if _faction_aggro_level == 2:
				FactionRally.propagate_draw_to_allies(
					self,
					get_tree(),
					FACTION_ALLY_DRAW_RANGE
				)
			if _faction_aggro_level == 3 and previous_level < 3 and not _faction_standoff_active:
				FactionRally.propagate_faction_aggro(
					self,
					combat_target,
					get_tree(),
					3,
					FACTION_AGGRO_RALLY_RANGE
				)
				if FactionIds.rallies_town_on_injury(get_faction_id()):
					_trigger_town_shootout(combat_target)


func is_weapon_aimed_at(target: Node3D, max_range: float = THREATEN_RANGE) -> bool:
	if _weapon_rig == null or not _weapon_rig.is_aiming():
		return false
	if target == null or not target.has_method("get_bullet_capsule"):
		return false

	var origin: Vector3 = _weapon_rig.get_muzzle_global_position()
	var to_target: Vector3 = _smoothed_aim_point - origin
	if to_target.length_squared() < 0.0001:
		return false

	var direction: Vector3 = to_target.normalized()
	var capsule: Dictionary = target.get_bullet_capsule()
	var hit_t := DuelHitTest.raycast_capsule(
		origin,
		direction,
		max_range,
		capsule.get("center", Vector3.ZERO),
		capsule.get("half_height", 0.75),
		capsule.get("radius", 0.5) + 0.05,
		capsule.get("axis", Vector3.UP)
	)
	return hit_t >= 0.0


func enter_combat(player: Node3D) -> void:
	if _defeated or _combat_active:
		return
	if _is_friendly_combatant(player):
		return

	_ensure_overworld_combat_for_target(player)

	_combat_active = true
	_aim_target = player
	_combat_move_pursue = false
	_saved_ai_state = _ai_state
	_ai_state = AiState.COMBAT_DRAWING
	_velocity_zero()
	if _mounted_horse != null or _horse_mount_target != null:
		_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE
	_committed_aim_zone = _pick_body_aim_zone()
	_roll_mounted_fire_target()
	_refresh_aim_spread()
	_has_locked_aim = true
	_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset
	_show_alert_fx()
	_weapon_rig.set_prep_aim(false)
	_weapon_rig.begin_draw()
	if _aggro_voice != null:
		_aggro_voice.schedule_on_aggro()


func get_voice_world_position() -> Vector3:
	return _get_alert_world_position()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	var shooter: Node3D = hit_info.get("shooter")

	var result := BulletHitDamage.process_hit(self, hit_info, _health)
	_health = result.health

	if (
		not result.killed
		and is_mounted_on_horse()
		and bool(result.get("knockback_applied", false))
	):
		_knock_off_horse_from_hit(hit_info)

	_react_to_hostile_shooter(shooter, result.killed, hit_info)

	if (
		not result.killed
		and _combat_active
		and shooter != null
		and is_instance_valid(shooter)
		and not bool(hit_info.get("melee", false))
	):
		_try_combat_roll_away_from(shooter.global_position, COMBAT_ROLL_ON_HIT_CHANCE)

	if result.killed:
		_activate_defeat_ragdoll(hit_info)
		if _faction_standoff_active:
			FactionShowdown.check_after_death(self, get_tree())
		else:
			FactionRally.notify_faction_member_eliminated(self, get_tree())


func is_defeated() -> bool:
	return _defeated


func is_lassoable() -> bool:
	return not _defeated and not _lasso_captured


func get_lasso_attach_point() -> Vector3:
	return GroyperBodyUtils.get_lasso_head_attach_point(_skeleton, self)


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func get_lasso_max_match_speed() -> float:
	return RUN_SPEED


func get_lasso_drag_visual() -> Node3D:
	return _model


func begin_lasso_capture(player: Node3D, rope_length: float, ring: LassoRing = null) -> void:
	if _mounted_horse != null:
		_request_horse_dismount()
	_lasso_captured = true
	_lasso_player = player
	_lasso_ring = ring
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	_combat_active = false
	_aim_target = null
	_ai_state = AiState.IDLE
	_play_lasso_capture_voice()


func _play_lasso_capture_voice() -> void:
	if _aggro_voice != null and _aggro_voice.has_method("play_lasso_capture_voice"):
		_aggro_voice.play_lasso_capture_voice()


func play_lasso_drag_voice() -> void:
	if _aggro_voice != null and _aggro_voice.has_method("play_lasso_drag_voice"):
		_aggro_voice.play_lasso_drag_voice()


func end_lasso_capture() -> void:
	_lasso_captured = false
	_lasso_player = null
	_lasso_ring = null
	velocity = Vector3.ZERO
	_begin_idle()


func get_lasso_ragdoll():
	return _ragdoll


func get_lasso_animation_player() -> AnimationPlayer:
	return _animation_player


func is_lasso_standup_active() -> bool:
	return _lasso_standup_active


func has_lasso_standup_animation() -> bool:
	return _lasso_standup_nodes_ready


func begin_lasso_drag_standup() -> bool:
	if not has_lasso_standup_animation() or _ragdoll == null:
		return false
	if not _ragdoll.is_lasso_drag_mode():
		return false
	_lasso_standup_active = true
	_lasso_standup_time = 0.0
	_lasso_standup_blend = 1.0
	_lasso_standup_model_sink = 0.0
	GroyperLassoStandupScript.set_stand_seek(_animation_tree, 0.0)
	GroyperLassoStandupScript.set_stand_playback_speed(
		_animation_tree,
		GroyperLassoStandupScript.PLAYBACK_SPEED
	)
	GroyperLassoStandupScript.set_blend(_animation_tree, 1.0)
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.speed_scale = 1.0
		_animation_player.active = true
	_locomotion_blend = 0.0
	if _animation_tree != null and _animation_tree.get("parameters/LocomotionBlend/blend_position") != null:
		_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	return true


func update_lasso_drag_standup(delta: float) -> void:
	if not _lasso_standup_active or not has_lasso_standup_animation():
		return
	_lasso_standup_time += delta
	var duration := GroyperLassoStandupScript.get_stand_duration(_animation_player)
	var progress := clampf(_lasso_standup_time / duration, 0.0, 1.0)
	_lasso_standup_blend = GroyperLassoStandupScript.update_smoothed_blend(
		_lasso_standup_blend,
		progress,
		delta
	)
	GroyperLassoStandupScript.set_blend(_animation_tree, _lasso_standup_blend)
	if _ragdoll != null and _ragdoll.is_lasso_animation_standup():
		_ragdoll.set_standup_body_progress(progress)
	_lasso_standup_model_sink = GroyperLassoStandupScript.apply_model_ground_sink(
		_model,
		progress,
		_lasso_standup_model_sink,
		delta
	)
	if GroyperLassoStandupScript.should_finish(progress, _lasso_standup_blend):
		_finish_lasso_standup()


func _finish_lasso_standup() -> void:
	if not _lasso_standup_active:
		return
	_lasso_standup_active = false
	_lasso_standup_model_sink = 0.0
	if _model != null:
		GroyperBodyUtils.apply_model_baseline(_model)
	if _ragdoll != null:
		_ragdoll.finish_animation_standup()


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	const LassoHumanoidDragScript := preload("res://gameplay/lasso/lasso_humanoid_drag.gd")
	LassoHumanoidDragScript.apply(self, self, player, _lasso_ring, _lasso_rope_length, delta)
	LassoHumanoidDragScript.finish_settling_if_needed(self)


func get_hat_collectible_id() -> StringName:
	return GroyperHatCatalog.id_for_color(hat_color)


func get_lasso_hat_drop_anchor() -> Vector3:
	var pos := global_position
	pos.y = GroyperBodyUtils.snap_position_to_floor(
		get_world_3d(),
		pos,
		GroyperBodyUtils.ACTOR_MODEL_Y
	).y
	return pos


func get_lasso_hat_skeleton() -> Skeleton3D:
	return _skeleton


func get_duel_hat() -> GroyperDuelHat:
	return _duel_hat


func contains_bullet_hit(world_point: Vector3, margin: float) -> bool:
	if _defeated:
		return false
	var capsule := get_bullet_capsule()
	return DuelHitTest.point_in_capsule(
		world_point,
		capsule["center"],
		capsule["half_height"],
		capsule["radius"],
		capsule.get("axis", Vector3.UP),
		margin
	)


func get_threat_aim_point() -> Vector3:
	var chest := global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	if _skeleton == null:
		return chest
	var torso := _get_torso_transform()
	var center := torso.origin
	if center.y < global_position.y + 0.35:
		return chest
	if center.distance_squared_to(global_position) > 400.0:
		return chest
	return center


func get_bullet_capsule() -> Dictionary:
	_sync_mounted_actor_position()
	_force_mounted_hitbox_transforms()
	if is_mounted_on_horse() or _is_model_parented_to_horse():
		return _get_mounted_bullet_capsule()
	var torso := _get_torso_transform()
	var half_height := (
		ROLL_HITBOX_HALF_HEIGHT if _roll_active else HITBOX_HALF_HEIGHT
	)
	var radius := ROLL_HITBOX_RADIUS if _roll_active else HITBOX_RADIUS
	return {
		"center": get_threat_aim_point(),
		"half_height": half_height,
		"radius": radius,
		"axis": torso.basis.y,
	}


func get_head_hit_sphere() -> Dictionary:
	_sync_mounted_actor_position()
	_force_mounted_hitbox_transforms()
	if is_mounted_on_horse() or _is_model_parented_to_horse():
		return _get_mounted_head_hit_sphere()
	return GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	)


func _trigger_town_shootout(shooter: Node3D) -> void:
	TownShootout.rally_becker_boys_on_injury(
		self,
		shooter,
		get_tree(),
		FACTION_AGGRO_RALLY_RANGE
	)


func _is_friendly_combatant(other: Node3D) -> bool:
	return FactionAffinity.are_allies(self, other)


func _update_faction_aggro(delta: float) -> void:
	if _defeated:
		return

	if get_faction_id() == FactionIds.ENGINES and _combat_active:
		return

	if FactionIds.rallies_town_on_injury(get_faction_id()):
		_try_deescalate_town_faction_combat()
	_update_player_holster_deescalation(delta)

	if _faction_standoff_active:
		_update_standoff_faction_aggro(delta)
		return

	_update_town_player_threat_aggro(delta)


func _try_deescalate_town_faction_combat() -> void:
	if _defeated or _faction_standoff_active:
		return
	if _faction_aggro_level < 2 and not _combat_active:
		return

	if _aim_target != null and is_instance_valid(_aim_target):
		if _aim_target.has_method("is_defeated") and _aim_target.is_defeated():
			exit_town_faction_combat_peaceful()
			return
		if _is_valid_combat_target(_aim_target) and not _is_combat_target_out_of_engagement_range():
			return

	if _pick_nearest_hostile_faction_member(faction_max_engage_range) != null:
		return

	exit_town_faction_combat_peaceful()


func _is_in_player_gun_standoff() -> bool:
	if _defeated or _faction_standoff_active or not _uses_faction_aggro():
		return false
	if _faction_aggro_level < 2 and not _combat_active:
		return false
	var player := _find_player()
	if player == null:
		return false
	return _aim_target == player


func _update_player_holster_deescalation(delta: float) -> void:
	if _faction_standing_down:
		return
	if not _is_in_player_gun_standoff():
		_player_holstered_deescalate_timer = 0.0
		return

	var player := _aim_target
	if player.has_method("is_weapon_raised") and player.is_weapon_raised():
		_player_holstered_deescalate_timer = 0.0
		return

	_player_holstered_deescalate_timer += delta
	if _player_holstered_deescalate_timer >= PLAYER_HOLSTER_DEESCALATE_DELAY:
		_player_holstered_deescalate_timer = 0.0
		_begin_faction_stand_down()


func _begin_faction_stand_down() -> void:
	if _faction_standing_down or _weapon_rig == null:
		return

	_faction_standing_down = true
	_combat_move_pursue = false
	_has_locked_aim = false
	_reset_bow_draw()
	_velocity_zero()
	if _weapon_rig.is_holstered():
		_finish_faction_stand_down()
	else:
		_weapon_rig.begin_holster()


func _finish_faction_stand_down() -> void:
	if not _faction_standing_down:
		return
	exit_town_faction_combat_peaceful()


func _update_town_player_threat_aggro(delta: float) -> void:
	if _combat_active or _faction_aggro_level >= 2:
		return

	if _faction_aggro_level == 1 and _player_weapon_threat_active:
		_faction_aggro_entered_timer += delta
		_check_faction_aimed_at_response()
		return

	if _faction_aggro_level == 1 and not _player_weapon_threat_active:
		_maintain_town_threat_stare(delta)
		return

	if _faction_aggro_level == 0 and not _player_weapon_threat_active:
		_try_aggro_hostile_on_sight()


func _should_react_to_player_gun_threat() -> bool:
	if _is_standoff_ranch_ally_npc():
		return false
	return FactionIds.rallies_town_on_injury(get_faction_id())


func _is_standoff_ranch_ally_npc() -> bool:
	return _faction_standoff_active and get_faction_id() == FactionIds.BECKER_BOYS


func _is_standoff_ranch_ally(target: Node) -> bool:
	if not _is_standoff_ranch_ally_npc() or target == null:
		return false
	var target_faction := FactionAffinity.resolve_faction_id(target)
	return target_faction == FactionIds.PLAYER or target_faction == FactionIds.BECKER_BOYS


func _update_player_weapon_reaction(delta: float) -> void:
	if not _should_react_to_player_gun_threat():
		return
	if _defeated or _lasso_captured or _combat_active or _faction_aggro_level >= 2:
		return

	var player := _find_player()
	if player == null:
		return

	var horizontal_dist := _get_horizontal_distance_to(player)
	if horizontal_dist > AIM_THREAT_RANGE:
		return

	var threatening := _player_is_threatening_becker_boy(player, true)
	if threatening:
		_faction_threat_lost_timer = 0.0
		var play_alert := not _player_weapon_threat_active
		_begin_player_weapon_stare(player, play_alert)
		return

	if not _player_weapon_threat_active:
		return

	_faction_threat_lost_timer += delta
	if _faction_threat_lost_timer < FACTION_THREAT_LOST_GRACE:
		return

	_end_player_weapon_stare()


func _begin_player_weapon_stare(player: Node3D, play_alert: bool) -> void:
	_player_weapon_threat_active = true
	if _horse_mount_target != null:
		_cancel_horse_approach()

	var entering := _ai_state != AiState.STARING or _aim_target != player
	_aim_target = player
	if _ai_state != AiState.STARING:
		_saved_ai_state = _ai_state
		_ai_state = AiState.STARING
		_velocity_zero()

	if play_alert and entering:
		_show_alert_fx()
		if _aggro_voice != null:
			if _aggro_voice.has_method("play_woah_now"):
				_aggro_voice.play_woah_now()
			else:
				_aggro_voice.play_woah_on_alert()
	if _uses_faction_aggro():
		if _faction_aggro_level < 1:
			set_faction_aggro_level(1, player)
		else:
			_faction_provoker = player
			_faction_threat_lost_timer = 0.0


func _end_player_weapon_stare() -> void:
	_player_weapon_threat_active = false
	_faction_threat_lost_timer = 0.0
	if _uses_faction_aggro() and not _faction_standoff_active:
		_deescalate_faction_aggro()
	elif _ai_state == AiState.STARING and not _combat_active:
		_resume_peaceful_ai()
		_aim_target = null


func _update_standoff_faction_aggro(delta: float) -> void:
	if _faction_wars_with_outsiders():
		_check_outsider_player_threat()

	if _faction_aggro_level == 0 and not _combat_active and not _player_weapon_threat_active:
		if _try_aggro_hostile_on_sight():
			return
		return

	if _faction_aggro_level == 1 and not _combat_active:
		_faction_aggro_entered_timer += delta
		if _aim_target == null or not is_instance_valid(_aim_target):
			_aim_target = _pick_nearest_hostile_in_range()
		_check_faction_aimed_at_response()
		_check_faction_ally_draw_support()
		_tick_faction_escalation(delta, 2)
	elif _faction_aggro_level == 2:
		_tick_faction_escalation(delta, 3)


func _maintain_town_threat_stare(delta: float) -> void:
	var player := _find_player()
	var threatening := player != null and _player_is_threatening_becker_boy(player, true)

	if threatening:
		_faction_threat_lost_timer = 0.0
		_faction_aggro_entered_timer += delta
		if _aim_target == null or not is_instance_valid(_aim_target):
			_aim_target = player
		if _ai_state != AiState.STARING:
			_saved_ai_state = _ai_state
			_ai_state = AiState.STARING
			_velocity_zero()
		_check_faction_aimed_at_response()
		return

	_faction_threat_lost_timer += delta
	if _faction_threat_lost_timer >= FACTION_THREAT_LOST_GRACE:
		_deescalate_faction_aggro()


func _deescalate_faction_aggro() -> void:
	if _faction_standoff_active:
		return
	_faction_aggro_level = 0
	_faction_provoker = null
	_faction_escalation_timer = 0.0
	_faction_aggro_entered_timer = 0.0
	_faction_threat_lost_timer = 0.0
	_aim_target = null
	if _ai_state == AiState.STARING:
		_resume_peaceful_ai()


func _check_faction_aimed_at_response() -> void:
	if _faction_aggro_level != 1:
		return

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.is_hostile(get_faction_id(), FactionAffinity.resolve_faction_id(npc)):
			continue
		if npc.has_method("get_faction_aggro_level") and npc.get_faction_aggro_level() < 2:
			continue
		if npc.has_method("is_weapon_aimed_at") and npc.is_weapon_aimed_at(self):
			set_faction_aggro_level(2, npc as Node3D)
			return

	var player := _find_player()
	if player == null:
		return
	if _is_standoff_ranch_ally(player):
		return
	if not _faction_standoff_active and _faction_aggro_entered_timer < FACTION_STARE_BEFORE_DRAW_DELAY:
		return
	if player.has_method("is_weapon_aimed_at") and player.is_weapon_aimed_at(self, AIM_THREAT_RANGE):
		set_faction_aggro_level(2, player)


func _check_faction_ally_draw_support() -> void:
	if _faction_aggro_level != 1:
		return

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if not npc.has_method("get_faction_id") or npc.get_faction_id() != get_faction_id():
			continue
		if not npc.has_method("get_faction_aggro_level") or npc.get_faction_aggro_level() < 2:
			continue
		if global_position.distance_to(npc.global_position) > FACTION_ALLY_DRAW_RANGE:
			continue
		var draw_target: Node3D = null
		if npc.has_method("get_faction_aggro_target"):
			draw_target = npc.get_faction_aggro_target()
		if draw_target == null:
			draw_target = _pick_nearest_hostile_in_range()
		if draw_target != null:
			set_faction_aggro_level(2, draw_target)
			return


func _tick_faction_escalation(delta: float, next_level: int) -> void:
	_faction_escalation_timer -= delta
	if _faction_escalation_timer > 0.0:
		return

	_schedule_faction_escalation()
	if randf() >= FACTION_ESCALATE_CHANCE:
		return

	var target := _aim_target
	if _faction_wars_with_outsiders():
		var nearest := _pick_nearest_hostile_in_range()
		if nearest != null:
			target = nearest
	elif target == null or not is_instance_valid(target):
		target = _pick_nearest_hostile_in_range()
	elif _faction_standoff_active and next_level == 3:
		var nearest := _pick_nearest_hostile_in_range()
		if nearest != null:
			target = nearest
	if target == null:
		return

	set_faction_aggro_level(next_level, target)


func _schedule_faction_escalation() -> void:
	_faction_escalation_timer = randf_range(FACTION_ESCALATE_MIN, FACTION_ESCALATE_MAX)


func _pick_nearest_hostile_faction_member(max_range: float = -1.0) -> Node3D:
	if max_range < 0.0:
		max_range = faction_max_engage_range
	var max_range_sq := max_range * max_range
	var my_faction := get_faction_id()
	var nearest: Node3D
	var nearest_dist_sq := INF

	for npc in get_tree().get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == self:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.is_enemy_faction(my_faction, FactionAffinity.resolve_faction_id(npc)):
			continue
		var dist_sq := global_position.distance_squared_to(npc.global_position)
		if dist_sq > max_range_sq or dist_sq >= nearest_dist_sq:
			continue
		nearest_dist_sq = dist_sq
		nearest = npc as Node3D

	for group_name: StringName in [&"engines_npc", &"bandit"]:
		for npc in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(npc) or npc == self:
				continue
			if npc.has_method("is_defeated") and npc.is_defeated():
				continue
			if not FactionAffinity.is_enemy_faction(my_faction, FactionAffinity.resolve_faction_id(npc)):
				continue
			var dist_sq := global_position.distance_squared_to(npc.global_position)
			if dist_sq > max_range_sq or dist_sq >= nearest_dist_sq:
				continue
			nearest_dist_sq = dist_sq
			nearest = npc as Node3D

	var player := _find_player()
	if player != null and not (player.has_method("is_defeated") and player.is_defeated()):
		if FactionAffinity.is_enemy_faction(my_faction, FactionIds.PLAYER):
			var dist_sq := global_position.distance_squared_to(player.global_position)
			if dist_sq <= max_range_sq and dist_sq < nearest_dist_sq:
				nearest = player

	return nearest


func _pick_nearest_hostile_in_range(max_range: float = -1.0) -> Node3D:
	return _pick_nearest_hostile_faction_member(max_range)


func _get_horizontal_distance_to(target: Node3D) -> float:
	if target == null or not is_instance_valid(target):
		return INF
	var offset := target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _is_combat_target_out_of_engagement_range() -> bool:
	if _aim_target == null or not is_instance_valid(_aim_target):
		return true
	return _get_horizontal_distance_to(_aim_target) > faction_max_engage_range


func _exit_combat_peaceful() -> void:
	if not _combat_active and _faction_aggro_level < 2:
		return
	if not _faction_standoff_active:
		exit_town_faction_combat_peaceful()
		return

	if not _combat_active:
		return
	_cancel_horse_approach()
	if _mounted_horse != null and _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE:
		_horse_ride_purpose = HORSE_RIDE_NONE
	_combat_active = false
	_combat_move_pursue = false
	_aim_target = null
	_has_locked_aim = false
	_reset_bow_draw()
	if _weapon_rig != null:
		_weapon_rig.reset_to_holster()
	_velocity_zero()
	_begin_idle()


func _update_threat_stare() -> void:
	if _uses_faction_aggro() or _faction_aggro_level > 0 or _combat_active or _defeated:
		return

	if _try_aggro_hostile_on_sight():
		return

	var player := _find_player()
	if player == null:
		if _ai_state == AiState.STARING:
			_resume_peaceful_ai()
		return

	if _player_is_threatening(player):
		if _ai_state != AiState.STARING:
			_saved_ai_state = _ai_state
			_ai_state = AiState.STARING
			_velocity_zero()
			_show_alert_fx()
			if _aggro_voice != null:
				_aggro_voice.play_woah_on_alert()
		_aim_target = player
	elif _ai_state == AiState.STARING:
		_resume_peaceful_ai()


func _try_aggro_hostile_on_sight() -> bool:
	var target := _pick_nearest_hostile_faction_member(faction_on_sight_aggro_range)
	if target == null:
		return false
	if _uses_faction_aggro():
		set_faction_aggro_level(3, target)
	else:
		enter_combat(target)
	return true


func _refresh_combat_target_if_needed() -> void:
	if not _combat_active:
		return

	if (
		_aim_target != null
		and is_instance_valid(_aim_target)
		and not (_aim_target.has_method("is_defeated") and _aim_target.is_defeated())
		and _is_valid_combat_target(_aim_target)
		and not _is_combat_target_out_of_engagement_range()
	):
		return

	var hostile := _pick_nearest_hostile_in_range()
	if hostile == null:
		_exit_combat_peaceful()
		return

	_aim_target = hostile
	_committed_aim_zone = _pick_body_aim_zone()
	_roll_mounted_fire_target()
	_refresh_aim_spread()
	_has_locked_aim = true
	_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset


func _resume_peaceful_ai() -> void:
	_aim_target = null
	match _saved_ai_state:
		AiState.WALKING:
			_begin_walk()
		_:
			_begin_idle()


func _player_is_threatening(player: Node3D) -> bool:
	return _player_is_threatening_becker_boy(player, true)


func _player_is_threatening_becker_boy(player: Node3D, include_self: bool = false) -> bool:
	if player == null:
		return false

	if include_self and _is_player_weapon_threatening_target(player, self):
		return true

	# Mounted NPCs only react to direct aim — not nearby allies being aimed at.
	if is_mounted_on_horse():
		return false

	for npc in get_tree().get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc) or npc == self or not npc is Node3D:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinity.are_allies(self, npc):
			continue
		var to_ally: Vector3 = (npc as Node3D).global_position - global_position
		to_ally.y = 0.0
		if to_ally.length() > FACTION_INTERVENE_RANGE:
			continue
		if _is_player_weapon_threatening_target(player, npc as Node3D):
			return true

	return false


func _is_player_weapon_threatening_target(player: Node3D, target: Node3D) -> bool:
	if player == null or target == null:
		return false

	var horizontal := target.global_position - player.global_position
	horizontal.y = 0.0
	if horizontal.length() > AIM_THREAT_RANGE:
		return false

	if not player.has_method("is_weapon_aimed_at"):
		return false
	return player.is_weapon_aimed_at(target, AIM_THREAT_RANGE)


func _ensure_overworld_combat_for_target(target: Node3D) -> void:
	if target == null or not target.is_in_group("overworld_player"):
		return
	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	var player := players[0] as Node3D
	if player == null:
		return null
	return player


func _update_combat_ai(delta: float) -> void:
	if (
		not _combat_active
		or _defeated
		or _roll_active
		or _punch_active
		or is_melee_stunned()
		or _faction_standing_down
	):
		return

	_refresh_combat_target_if_needed()

	if _mounted_horse == null and _horse_mount_target == null and _horse_mount_cooldown <= 0.0:
		_try_begin_combat_horse_chase()

	match _ai_state:
		AiState.COMBAT_DRAWING:
			if _weapon_rig.is_aiming():
				if _can_begin_combat_aiming():
					_begin_combat_aiming()
				else:
					_begin_combat_approach()
		AiState.COMBAT_AIMING:
			if not _is_target_in_weapon_range():
				_reset_bow_draw()
				_begin_combat_approach()
				return
			if not _has_combat_line_of_sight_to(_aim_target):
				_reset_bow_draw()
				_begin_combat_approach()
				return
			_update_bow_draw_for_fire_timer()
			_fire_timer = maxf(_fire_timer - delta, 0.0)
			if _fire_timer <= 0.0:
				_fire_at_target()
		AiState.COMBAT_MOVING:
			if _weapon_rig != null and not _weapon_rig.is_aiming():
				if _weapon_rig.is_holstered():
					_weapon_rig.set_prep_aim(false)
					_weapon_rig.begin_draw()
			elif _can_begin_combat_aiming():
				_begin_combat_aiming()
			elif _should_try_combat_punch():
				_try_start_combat_punch()


func _can_begin_combat_aiming() -> bool:
	return _is_target_in_weapon_range() and _has_combat_line_of_sight_to(_aim_target)


func _uses_aggro_fire_rate() -> bool:
	if _faction_aggro_level >= 2:
		return true
	if not _combat_active:
		return false
	var target := _aim_target if _aim_target != null else _faction_provoker
	return target != null and target.is_in_group("overworld_player")


func _roll_combat_fire_delay() -> float:
	if _uses_aggro_fire_rate():
		return randf_range(AGGRO_COMBAT_FIRE_DELAY_MIN, AGGRO_COMBAT_FIRE_DELAY_MAX)
	return randf_range(COMBAT_FIRE_DELAY_MIN, COMBAT_FIRE_DELAY_MAX)


func _begin_combat_aiming() -> void:
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return
	if not _has_combat_line_of_sight_to(_aim_target):
		_begin_combat_approach()
		return

	_roll_mounted_fire_target()
	_refresh_aim_spread()
	_ai_state = AiState.COMBAT_AIMING
	_fire_timer_duration = _roll_combat_fire_delay()
	_fire_timer = _fire_timer_duration
	_reset_bow_draw()


func _reset_bow_draw() -> void:
	if _weapon_rig != null and GroyperWeapons.is_bow(_weapon_rig.get_equipped_weapon_id()):
		_weapon_rig.set_bow_draw(0.0)


func _update_bow_draw_for_fire_timer() -> void:
	if _weapon_rig == null or not GroyperWeapons.is_bow(_weapon_rig.get_equipped_weapon_id()):
		return
	if _fire_timer_duration <= 0.001:
		return
	var charge := 1.0 - clampf(_fire_timer / _fire_timer_duration, 0.0, 1.0)
	_weapon_rig.set_bow_draw(charge)


func _begin_combat_approach() -> void:
	if _aim_target == null:
		return
	if _can_begin_combat_aiming():
		_begin_combat_aiming()
		return

	if _mounted_horse != null:
		_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE
		_ai_state = AiState.COMBAT_MOVING
		_combat_move_pursue = true
		return

	_combat_move_pursue = true
	_ai_state = AiState.COMBAT_MOVING
	if _aim_target != null:
		_sync_combat_nav_target_to(_aim_target)
		if _has_combat_line_of_sight_to(_aim_target):
			_try_combat_roll_toward(
				_get_combat_nav_roll_point_toward(_aim_target),
				COMBAT_ROLL_CHANCE * 0.35
			)


func _fire_at_target() -> void:
	if _weapon_rig == null or not _weapon_rig.is_aiming():
		return
	if not _is_target_in_weapon_range():
		_begin_combat_approach()
		return
	if (_uses_faction_aggro() or _faction_standoff_active) and _faction_aggro_level < 3:
		_begin_combat_aiming()
		return

	_weapon_rig.fire_at(_smoothed_aim_point)

	if randf() < 0.5:
		_begin_combat_aiming()
	else:
		_begin_combat_relocate()


func _begin_combat_relocate() -> void:
	if _mounted_horse != null:
		_ai_state = AiState.COMBAT_MOVING
		_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE
		_combat_move_pursue = false
		_pick_horse_patrol_target()
		return

	_combat_move_pursue = false
	_ai_state = AiState.COMBAT_MOVING
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(COMBAT_RELOCATE_MIN, COMBAT_RELOCATE_MAX)
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * distance
	_combat_move_target = global_position + offset
	_combat_move_target.y = global_position.y
	if _combat_nav != null:
		_combat_move_target = _combat_nav.snap_position(_combat_move_target)
		_combat_nav.set_target(_combat_move_target)
	_try_combat_roll_toward(_combat_move_target, COMBAT_ROLL_CHANCE * 0.5)


func _pick_body_aim_zone() -> String:
	var roll := randf()
	if roll < 0.58:
		return "chest"
	if roll < 0.82:
		return "head"
	if roll < 0.93:
		return "gut"
	if roll < 0.97:
		return "left_shoulder"
	return "right_shoulder"


func _sample_body_aim_point(zone_id: String) -> Vector3:
	if _mounted_fire_horse != null and is_instance_valid(_mounted_fire_horse):
		if _mounted_fire_horse.has_method("get_bullet_capsule"):
			var horse_capsule: Dictionary = _mounted_fire_horse.get_bullet_capsule()
			return horse_capsule.get("center", _mounted_fire_horse.global_position)
		return _mounted_fire_horse.global_position + Vector3(0.0, 0.55, 0.0)
	if _aim_target != null and _aim_target.has_method("get_duel_body_aim_point"):
		return _aim_target.get_duel_body_aim_point(zone_id)
	if _aim_target != null:
		return _aim_target.global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	return global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)


func _get_weapon_effective_range() -> float:
	if _weapon_rig == null:
		return GroyperWeapons.get_effective_range(GroyperWeapons.get_enemy_weapon())
	return GroyperWeapons.get_effective_range(_weapon_rig.get_equipped_weapon_id())


func _get_horizontal_distance_to_target() -> float:
	if _aim_target == null:
		return INF
	var to_target := _aim_target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _is_target_in_weapon_range() -> bool:
	return _get_horizontal_distance_to_target() <= _get_weapon_effective_range()


func _is_target_in_melee_range() -> bool:
	if _aim_target == null or not is_instance_valid(_aim_target):
		return false
	return MeleePunchScript.is_in_range_for_actor(self, _aim_target)


func _should_try_combat_punch() -> bool:
	if (
		not _combat_active
		or _punch_active
		or is_melee_stunned()
		or _punch_cooldown > 0.0
		or _roll_active
		or _mounted_horse != null
		or _aim_target == null
	):
		return false
	return _is_target_in_melee_range()


func get_punch_facing_direction() -> Vector3:
	if _aim_target != null and is_instance_valid(_aim_target):
		return MeleePunchScript.get_strike_direction(self, _aim_target)
	return MeleePunchScript.get_strike_direction(self)


func _try_start_combat_punch() -> bool:
	if not _should_try_combat_punch():
		return false
	if randf() >= COMBAT_PUNCH_CHANCE:
		return false
	return _start_combat_punch()


func _start_combat_punch() -> bool:
	var direction := get_punch_facing_direction()
	if direction.length_squared() < 0.0001:
		return false

	var anim_path := PunchPoseConfig.get_animation_path()
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return false

	var animation := _animation_player.get_animation(anim_path)
	_punch_duration = MeleePunchScript.get_attack_duration(animation.length)
	_punch_timer = 0.0
	_punch_active = true
	_punch_strike_applied = false
	_punch_direction = direction
	_punch_cooldown = MeleePunchScript.COOLDOWN
	_punch_blend = 0.0

	if _punch_anim_node != null:
		_punch_anim_node.animation = anim_path
	_init_punch_animation_tree_state()
	return true


func _init_punch_animation_tree_state() -> void:
	_punch_blend = 0.0
	PunchPoseConfig.set_tree_blend(_animation_tree, 0.0)
	PunchPoseConfig.set_tree_seek(_animation_tree, 0.0)


func _set_punch_tree_blend(amount: float) -> void:
	_punch_blend = amount
	PunchPoseConfig.set_tree_blend(_animation_tree, amount)


func _sync_punch_anim_time(time: float) -> void:
	PunchPoseConfig.set_tree_seek(_animation_tree, MeleePunchScript.get_anim_time(time))


func _update_punch_overlay(delta: float) -> void:
	if _punch_exit_active:
		_punch_exit_timer += delta
		var progress := clampf(
			_punch_exit_timer / maxf(MeleePunchScript.get_exit_blend_duration(), 0.001),
			0.0,
			1.0
		)
		var eased := 1.0 - pow(1.0 - progress, 2.6)
		_set_punch_tree_blend(lerpf(1.0, 0.0, eased))
		_sync_punch_anim_time(_punch_timer)
		if progress >= 1.0:
			_finish_punch()
		return

	_punch_timer += delta
	var fade_progress := clampf(
		_punch_timer / maxf(MeleePunchScript.get_anim_fadein(), 0.001),
		0.0,
		1.0
	)
	var blend_target := fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
	var blend_step := 1.0 - exp(-PUNCH_BLEND_IN_SPEED * delta)
	_set_punch_tree_blend(lerpf(_punch_blend, blend_target, blend_step))
	_sync_punch_anim_time(_punch_timer)

	if _punch_timer >= _punch_duration:
		_begin_punch_exit()


func _apply_punch_strike_if_ready() -> void:
	if not _punch_active or _punch_exit_active or _punch_strike_applied:
		return
	if _punch_timer < MeleePunchScript.get_windup_duration():
		return

	_punch_strike_applied = true
	MeleePunchScript.apply_strike(self, _punch_direction, _aim_target)
	velocity.x += _punch_direction.x * MeleePunchScript.LUNGE_SPEED
	velocity.z += _punch_direction.z * MeleePunchScript.LUNGE_SPEED


func _begin_punch_exit() -> void:
	if _punch_exit_active:
		return

	_punch_exit_active = true
	_punch_exit_timer = 0.0


func _finish_punch() -> void:
	_punch_active = false
	_punch_exit_active = false
	_punch_timer = 0.0
	_punch_exit_timer = 0.0
	_punch_duration = 0.0
	_punch_direction = Vector3.ZERO
	_punch_strike_applied = false
	_init_punch_animation_tree_state()

	if not _combat_active or _aim_target == null:
		return
	if _can_begin_combat_aiming():
		_begin_combat_aiming()
	elif _combat_move_pursue:
		_ai_state = AiState.COMBAT_MOVING
	else:
		_begin_combat_approach()


func _get_combat_aim_miss_chance() -> float:
	if _aim_target == null:
		return COMBAT_AIM_MISS_CHANCE_FAR

	var to_target := _aim_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= COMBAT_MISS_DISTANCE_NEAR:
		return COMBAT_AIM_MISS_CHANCE_NEAR
	if distance >= COMBAT_MISS_DISTANCE_FAR:
		return COMBAT_AIM_MISS_CHANCE_FAR

	var t := (distance - COMBAT_MISS_DISTANCE_NEAR) / (COMBAT_MISS_DISTANCE_FAR - COMBAT_MISS_DISTANCE_NEAR)
	t = t * t
	return lerpf(COMBAT_AIM_MISS_CHANCE_NEAR, COMBAT_AIM_MISS_CHANCE_FAR, t)


func _refresh_aim_spread() -> void:
	var body_point := _sample_body_aim_point(_committed_aim_zone)
	_aim_spread_offset = _resolve_aim_point(body_point, _get_combat_aim_miss_chance()) - body_point


func _resolve_aim_point(body_point: Vector3, miss_chance: float) -> Vector3:
	var spread := OFF_BODY_AIM_SPREAD if randf() < miss_chance else CENTERED_AIM_SPREAD
	return body_point + Vector3(
		randf_range(-spread, spread),
		randf_range(-spread * 0.45, spread * 0.45),
		randf_range(-spread, spread)
	)


func _update_aim_tracking(delta: float) -> void:
	var zone_point := _sample_body_aim_point(_committed_aim_zone)
	var target := zone_point + _aim_spread_offset
	var track_step := 1.0 - exp(-8.0 * delta)
	_smoothed_aim_point = _smoothed_aim_point.lerp(target, track_step)


func _activate_defeat_ragdoll(hit_info: Dictionary) -> void:
	if _aggro_voice != null:
		_aggro_voice.stop_for_death()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_death_sound(self, hit_position)
	_defeated = true
	_combat_active = false
	_combat_move_pursue = false
	_ai_state = AiState.DEFEATED
	_roll_active = false

	var was_mounted := is_mounted_on_horse() or _is_model_parented_to_horse()
	if was_mounted:
		hit_info["mounted_dismount"] = true
		_dismount_for_defeat(hit_info)

	_bind_rig()
	if _ragdoll != null and _skeleton != null:
		_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
		if _model != null:
			_ragdoll.model_path = _ragdoll.get_path_to(_model)
		_ragdoll.bind_skeleton()

	_velocity_zero()
	if _ragdoll != null and not _ragdoll.is_active():
		_suspend_locomotion_animations()
		_ragdoll.activate(hit_info, _animation_player)


func _suspend_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = false
		if _animation_player.is_playing():
			_animation_player.pause()


func _resume_locomotion_animations() -> void:
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.speed_scale = 1.0
		_animation_player.active = true
		if not _animation_player.is_playing():
			_animation_player.play()
	if not has_meta(&"lasso_soft_loco_resume"):
		_locomotion_blend = 0.0
		if _animation_tree != null and _animation_tree.get("parameters/LocomotionBlend/blend_position") != null:
			_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	else:
		remove_meta(&"lasso_soft_loco_resume")


func _setup_combat() -> void:
	if _skeleton == null:
		push_error("GroyperTownNpc: missing skeleton.")
		return

	GroyperBodyUtils.ensure_weapon_mounts(_skeleton)

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, equipped_weapon_id)

	_ragdoll = RAGDOLL_SCRIPT.new()
	_ragdoll.name = "Ragdoll"
	add_child(_ragdoll)
	_ragdoll.skeleton_path = _ragdoll.get_path_to(_skeleton)
	_ragdoll.bind_skeleton()

	if random_hat_color:
		hat_color = _pick_random_hat_color()

	if wear_hat:
		_duel_hat = DUEL_HAT_SCRIPT.new()
		_duel_hat.name = "DuelHat"
		add_child(_duel_hat)
		_duel_hat.bind_skeleton(_skeleton, _create_hat_material(hat_color))
		_duel_hat.prepare_for_round(false)

	_aggro_voice = _create_aggro_voice()


func _create_aggro_voice() -> Node:
	var voice := TownAggroVoiceScript.new()
	voice.name = "AggroVoice"
	add_child(voice)
	voice.setup(self)
	return voice


func _velocity_zero() -> void:
	velocity = Vector3.ZERO


func _setup_combat_navigation() -> void:
	_combat_nav = NpcCombatNavigationScript.new()
	_combat_nav.setup(self)


func _finalize_combat_nav_agent() -> void:
	if _combat_nav != null:
		_combat_nav.mark_agent_ready()


func _get_combat_nav_aim_point(target: Node3D) -> Vector3:
	if target == null:
		return global_position
	if target.has_method("get_threat_aim_point"):
		return target.get_threat_aim_point()
	return target.global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)


func _sync_combat_nav_target_to(target: Node3D) -> void:
	if _combat_nav == null or target == null:
		return
	if _combat_nav.is_recovery_active():
		return
	_combat_nav.set_target_if_needed(_get_combat_nav_aim_point(target))


func _get_combat_nav_direction(delta: float) -> Vector3:
	if _aim_target == null:
		return Vector3.ZERO
	return _get_combat_nav_direction_toward(delta, _get_combat_nav_aim_point(_aim_target))


func _get_combat_nav_direction_toward(delta: float, world_pos: Vector3) -> Vector3:
	if _combat_nav != null and _combat_nav.is_available():
		var dir: Vector3 = _combat_nav.get_move_direction(delta)
		if dir.length_squared() > 0.0001:
			return dir
	var to_target := world_pos - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Vector3.ZERO
	return to_target.normalized()


func _get_combat_nav_roll_point_toward(target: Node3D) -> Vector3:
	if _combat_nav != null and _combat_nav.is_available():
		var move_dir: Vector3 = _combat_nav.get_move_direction(0.0)
		if move_dir.length_squared() > 0.0001:
			return _combat_nav.get_roll_target_ahead(move_dir)
	return _get_combat_nav_aim_point(target)


func _handle_combat_stuck(move_dir: Vector3, final_target: Vector3) -> bool:
	if _combat_nav == null:
		return false
	if _combat_nav.consume_pending_relocate():
		if _mounted_horse != null:
			_combat_nav.force_wide_flank_recovery(final_target)
			return false
		_begin_combat_nav_relocate(final_target)
		return true
	if not _combat_nav.consume_stuck_roll_request():
		return false

	var roll_dir: Vector3 = _combat_nav.get_safe_roll_direction(move_dir)
	if roll_dir.length_squared() < 0.0001:
		return false
	_try_combat_roll_toward(_combat_nav.get_roll_target_ahead(roll_dir), 1.0)
	return true


func _begin_combat_nav_relocate(final_target: Vector3) -> void:
	_combat_move_pursue = false
	_ai_state = AiState.COMBAT_MOVING
	var to_target := final_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		_begin_combat_relocate()
		return

	var lateral := to_target.normalized().cross(Vector3.UP)
	if randf() < 0.5:
		lateral = -lateral
	var distance := randf_range(COMBAT_RELOCATE_MIN, COMBAT_RELOCATE_MAX)
	_combat_move_target = global_position + lateral * distance
	_combat_move_target.y = global_position.y
	if _combat_nav != null:
		_combat_move_target = _combat_nav.snap_position(_combat_move_target)
		_combat_nav.set_target(_combat_move_target)


func _get_mounted_combat_chase_input(fallback_dest: Vector3) -> Vector3:
	if _aim_target != null and is_instance_valid(_aim_target):
		if _is_target_in_weapon_range():
			return Vector3.ZERO
		var aim_point := _get_combat_nav_aim_point(_aim_target)
		if _combat_nav != null:
			if not _combat_nav.is_recovery_active():
				_combat_nav.set_target_if_needed(aim_point)
			var nav_dir: Vector3 = _combat_nav.get_move_direction(0.0)
			if (
				nav_dir.length_squared() > 0.0001
				and (
					not _has_combat_line_of_sight_to(_aim_target)
					or _combat_nav.is_recovery_active()
				)
			):
				return nav_dir

		var to_target := aim_point - global_position
		to_target.y = 0.0
		if to_target.length_squared() < 0.0001:
			return Vector3.ZERO
		return to_target.normalized()

	var to_dest := fallback_dest - global_position
	to_dest.y = 0.0
	if to_dest.length_squared() < 0.0001:
		return Vector3.ZERO
	return to_dest.normalized()


func _has_combat_line_of_sight_to(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	var aim_point := _get_combat_nav_aim_point(target)
	var origin := global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return true

	var query := PhysicsRayQueryParameters3D.create(origin, aim_point)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collision_mask = 1
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	if hit.collider == target:
		return true
	return hit.position.distance_to(aim_point) <= 0.55


func _apply_combat_pursue_movement(delta: float) -> void:
	if _aim_target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if _is_combat_target_out_of_engagement_range():
		_exit_combat_peaceful()
		return
	if _can_begin_combat_aiming():
		velocity.x = 0.0
		velocity.z = 0.0
		_combat_move_pursue = false
		_begin_combat_aiming()
		return
	if _should_try_combat_punch() and _try_start_combat_punch():
		return

	_sync_combat_nav_target_to(_aim_target)
	var move_dir := _get_combat_nav_direction(delta)

	var h_speed := Vector2(velocity.x, velocity.z).length()
	if _combat_nav != null:
		_combat_nav.update_stuck(delta, h_speed)
		if _handle_combat_stuck(move_dir, _get_combat_nav_aim_point(_aim_target)):
			return

	if move_dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	velocity.x = move_dir.x * RUN_SPEED
	velocity.z = move_dir.z * RUN_SPEED
	_face_position(global_position + move_dir, delta)


func _apply_combat_relocate_movement(delta: float) -> void:
	var to_target := _combat_move_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() <= COMBAT_ARRIVE_DISTANCE * COMBAT_ARRIVE_DISTANCE:
		velocity.x = 0.0
		velocity.z = 0.0
		_begin_combat_approach()
		return

	if _combat_nav != null and not _combat_nav.is_recovery_active():
		_combat_nav.set_target_if_needed(_combat_move_target)
	var move_dir := _get_combat_nav_direction_toward(delta, _combat_move_target)
	if move_dir.length_squared() < 0.0001 and to_target.length_squared() > 0.0001:
		move_dir = to_target.normalized()

	var h_speed := Vector2(velocity.x, velocity.z).length()
	if _combat_nav != null:
		_combat_nav.update_stuck(delta, h_speed)
		if _handle_combat_stuck(move_dir, _combat_move_target):
			return

	if move_dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	velocity.x = move_dir.x * RUN_SPEED
	velocity.z = move_dir.z * RUN_SPEED
	_face_position(global_position + move_dir, delta)


func _pick_random_hat_color() -> Color:
	return HAT_COLOR_PALETTE[randi() % HAT_COLOR_PALETTE.size()]


func _create_hat_material(color: Color) -> StandardMaterial3D:
	var mat := HAT_BASE_MATERIAL.duplicate() as StandardMaterial3D
	# Drop the shared hat texture so albedo_color reads as a solid hat tint.
	mat.albedo_texture = null
	mat.albedo_color = color
	return mat


func _setup_locomotion() -> void:
	if _animation_player == null:
		push_error("GroyperTownNpc: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)
	_register_stumble_clip(library)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)
	_setup_roll_dodge_library()
	_setup_punch_pose_library()

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
	):
		push_error("GroyperTownNpc: locomotion clips missing on AnimationPlayer.")
		return

	var walk_roll_path := StringName(
		"%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]
	)
	if not _animation_player.has_animation(walk_roll_path):
		push_error("GroyperTownNpc: roll dodge clips missing on AnimationPlayer.")
		return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 0.5)
	blend_space.add_blend_point(run_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0

	_roll_anim_node = AnimationNodeAnimation.new()
	_roll_anim_node.animation = walk_roll_path

	var roll_one_shot := AnimationNodeOneShot.new()
	roll_one_shot.fadein_time = ROLL_ANIM_FADEIN
	roll_one_shot.fadeout_time = ROLL_ANIM_FADEOUT
	roll_one_shot.sync = true

	var punch_path := PunchPoseConfig.get_animation_path()
	var punch_has_clip := false
	if _animation_player.has_animation(punch_path):
		_punch_anim_node = AnimationNodeAnimation.new()
		_punch_anim_node.animation = punch_path
		punch_has_clip = true

	var punch_time_seek := AnimationNodeTimeSeek.new()
	_punch_blend_node = AnimationNodeBlend2.new()
	_punch_blend_node.sync = false
	if punch_has_clip:
		PunchPoseConfig.configure_punch_blend_filter(_punch_blend_node)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.add_node(ROLL_ANIM_NODE, _roll_anim_node)
	blend_tree.add_node(ROLL_ONE_SHOT, roll_one_shot)
	if punch_has_clip:
		blend_tree.add_node(PUNCH_ANIM_NODE, _punch_anim_node)
		blend_tree.add_node(PunchPoseConfig.TIME_SEEK_NODE, punch_time_seek)
		blend_tree.add_node(PunchPoseConfig.BLEND_NODE, _punch_blend_node)
	blend_tree.connect_node(ROLL_ONE_SHOT, 0, LOCOMOTION_BLEND)
	blend_tree.connect_node(ROLL_ONE_SHOT, 1, ROLL_ANIM_NODE)
	if punch_has_clip:
		blend_tree.connect_node(PunchPoseConfig.TIME_SEEK_NODE, 0, PUNCH_ANIM_NODE)
		blend_tree.connect_node(PunchPoseConfig.BLEND_NODE, 0, ROLL_ONE_SHOT)
		blend_tree.connect_node(PunchPoseConfig.BLEND_NODE, 1, PunchPoseConfig.TIME_SEEK_NODE)

	var saddle_path := SaddlePoseConfig.get_animation_path()
	var output_source: StringName
	if _animation_player.has_animation(saddle_path):
		var saddle_anim := AnimationNodeAnimation.new()
		saddle_anim.animation = saddle_path
		_saddle_blend_node = AnimationNodeBlend2.new()
		_saddle_blend_node.sync = false
		SaddlePoseConfig.configure_saddle_blend_filter(_saddle_blend_node)
		blend_tree.add_node(SADDLE_ANIM_NODE, saddle_anim)
		blend_tree.add_node(SADDLE_BLEND, _saddle_blend_node)
		if punch_has_clip:
			blend_tree.connect_node(SADDLE_BLEND, 0, PunchPoseConfig.BLEND_NODE)
		else:
			blend_tree.connect_node(SADDLE_BLEND, 0, ROLL_ONE_SHOT)
		blend_tree.connect_node(SADDLE_BLEND, 1, SADDLE_ANIM_NODE)
		output_source = SADDLE_BLEND
	else:
		push_warning("GroyperTownNpc: missing saddle pose — horseback riding disabled.")
		if punch_has_clip:
			output_source = PunchPoseConfig.BLEND_NODE
		else:
			output_source = ROLL_ONE_SHOT

	_lasso_standup_nodes_ready = GroyperLassoStandupScript.attach_standup_branch(
		blend_tree,
		output_source,
		_animation_player
	)
	if _lasso_standup_nodes_ready:
		blend_tree.connect_node(&"output", 0, GroyperLassoStandupScript.BLEND_NODE)
		GroyperLassoStandupScript.init_tree_state(_animation_tree)
	else:
		blend_tree.connect_node(&"output", 0, output_source)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_init_punch_animation_tree_state()


func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperTownNpc: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


func _register_stumble_clip(library: AnimationLibrary) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(RigAnimConfig.STUMBLE_SCENE)
	if raw == null:
		push_error(
			"GroyperTownNpc: failed to load stumble clip from %s."
			% RigAnimConfig.STUMBLE_SCENE
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	library.add_animation(RigAnimConfig.LOCOMOTION_STUMBLE, animation)


func _get_stumble_anim_path() -> StringName:
	return StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_STUMBLE]
	)


func is_npc_shoveable() -> bool:
	return not _defeated and not _lasso_captured


func _capture_shove_resume_state() -> void:
	_shove_saved_ai_state = _ai_state
	_shove_was_in_combat = _combat_active


func _resume_after_shove() -> void:
	if _defeated:
		return
	if _combat_active or _shove_was_in_combat:
		_ai_state = _shove_saved_ai_state
		return
	if _faction_aggro_locks_peaceful_roam():
		_ai_state = _shove_saved_ai_state
		return
	_begin_idle()


func _get_shove_settle_target_blend() -> float:
	if _ai_state == AiState.WALKING:
		return SHOVE_STEP_WALK_BLEND
	if _ai_state == AiState.COMBAT_MOVING:
		return 1.0
	return 0.0


func _begin_shove_settle(
	from_blend: float,
	duration: float = TownNpcShove.SHOVE_SETTLE_DURATION
) -> void:
	_shove_settling = true
	_shove_settle_time = 0.0
	_shove_settle_from_blend = from_blend
	_shove_settle_duration = duration
	_set_shove_step_locomotion(from_blend)


func _process_shove_settle(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = 0.0
	velocity.z = 0.0

	if _combat_active and _aim_target != null:
		_face_position(_aim_target.global_position, delta)
	elif _faction_aggro_locks_peaceful_roam() and _aim_target != null:
		_face_position(_aim_target.global_position, delta)

	_shove_settle_time += delta
	var t := clampf(_shove_settle_time / _shove_settle_duration, 0.0, 1.0)
	var eased := TownNpcShove.settle_ease(t)
	var target := _get_shove_settle_target_blend()
	var blend := lerpf(_shove_settle_from_blend, target, eased)
	_set_shove_step_locomotion(blend)

	move_and_slide()
	update_npc_locomotion_audio(delta, 0.0, false, false)

	if t >= 1.0:
		_shove_settling = false
		_locomotion_blend = target


func _set_shove_step_locomotion(blend: float) -> void:
	_locomotion_blend = blend
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set("parameters/LocomotionBlend/blend_position", blend)


func _begin_gentle_shove_step(push_dir: Vector3, speed: float) -> void:
	_capture_shove_resume_state()
	_gentle_shove_stepping = true
	_gentle_shove_step_time = 0.0
	_gentle_shove_step_dir = push_dir
	if _gentle_shove_step_dir.length_squared() < 0.0001:
		_gentle_shove_step_dir = -global_transform.basis.z
	_gentle_shove_step_dir.y = 0.0
	_gentle_shove_step_dir = _gentle_shove_step_dir.normalized()
	_gentle_shove_step_from = global_position
	var speed_ratio := clampf(speed / TownNpcShove.GENTLE_MAX_SPEED, 0.65, 1.15)
	_gentle_shove_step_distance = TownNpcShove.SHOVE_STEP_DISTANCE * speed_ratio
	_velocity_zero()
	_face_position(global_position + _gentle_shove_step_dir, 0.016)


func _process_gentle_shove_step(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_gentle_shove_step_time += delta
	var t := clampf(_gentle_shove_step_time / TownNpcShove.SHOVE_STEP_DURATION, 0.0, 1.0)
	var move_t := TownNpcShove.gentle_step_ease(t)
	var blend := TownNpcShove.gentle_step_walk_blend(t, SHOVE_STEP_WALK_BLEND)
	_set_shove_step_locomotion(blend)

	var target_pos := (
		_gentle_shove_step_from
		+ _gentle_shove_step_dir * (_gentle_shove_step_distance * move_t)
	)
	global_position = TownNpcShove.clip_step_position(
		self,
		_gentle_shove_step_from,
		target_pos
	)
	_face_position(global_position + _gentle_shove_step_dir, delta)

	move_and_slide()
	update_npc_locomotion_audio(
		delta,
		_gentle_shove_step_distance / TownNpcShove.SHOVE_STEP_DURATION,
		true,
		false
	)

	if t >= 1.0:
		_end_gentle_shove_step()


func _end_gentle_shove_step() -> void:
	_gentle_shove_stepping = false
	_gentle_shove_step_time = 0.0
	_gentle_shove_step_cooldown = TownNpcShove.SHOVE_STEP_COOLDOWN
	_begin_shove_settle(_locomotion_blend)
	_resume_after_shove()


func _begin_shove_stumble(push_dir: Vector3) -> void:
	_capture_shove_resume_state()
	_stumble_exit_blending = false
	_shove_stumbling = true
	_shove_direction = push_dir
	if _shove_direction.length_squared() < 0.0001:
		_shove_direction = -global_transform.basis.z
	_shove_direction.y = 0.0
	_shove_direction = _shove_direction.normalized()
	_shove_stumble_cooldown = SHOVE_STUMBLE_COOLDOWN
	_velocity_zero()

	if _animation_tree != null:
		_animation_tree.active = false
	if _animation_player != null:
		_animation_player.active = true
		_animation_player.speed_scale = 1.0
		var stumble_path := _get_stumble_anim_path()
		if _animation_player.has_animation(stumble_path):
			if not _animation_player.animation_finished.is_connected(_on_shove_stumble_anim_finished):
				_animation_player.animation_finished.connect(_on_shove_stumble_anim_finished)
			_animation_player.play(stumble_path)

	if _aggro_voice != null and _aggro_voice.has_method("play_woah_now"):
		_aggro_voice.play_woah_now()


func _get_stumble_exit_blend() -> float:
	return SHOVE_STEP_WALK_BLEND


func _get_stumble_exit_speed_scale() -> float:
	if _animation_player == null:
		return 0.0

	var stumble_path := _get_stumble_anim_path()
	var anim := _animation_player.get_animation(stumble_path)
	if anim == null or anim.length <= 0.001:
		return 0.0

	var remaining := anim.length - _animation_player.current_animation_position
	var t := 1.0 - clampf(remaining / TownNpcShove.STUMBLE_EXIT_BLEND_DURATION, 0.0, 1.0)
	return 1.0 - TownNpcShove.settle_ease(t)


func _activate_locomotion_for_stumble_exit() -> void:
	var exit_blend := _get_stumble_exit_blend()
	_locomotion_blend = exit_blend
	if _animation_tree != null:
		_animation_tree.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_tree.set("parameters/LocomotionBlend/blend_position", exit_blend)
		_animation_tree.active = true
	if _animation_player != null:
		_animation_player.process_mode = Node.PROCESS_MODE_INHERIT
		_animation_player.active = true
		_animation_player.speed_scale = 1.0


func _try_begin_stumble_exit_blend() -> void:
	if _stumble_exit_blending or _animation_player == null:
		return

	var stumble_path := _get_stumble_anim_path()
	if _animation_player.current_animation != stumble_path:
		return

	var anim := _animation_player.get_animation(stumble_path)
	if anim == null:
		return

	var remaining := anim.length - _animation_player.current_animation_position
	if remaining > TownNpcShove.STUMBLE_EXIT_BLEND_DURATION:
		return

	_stumble_exit_blending = true
	_activate_locomotion_for_stumble_exit()


func _process_shove_stumble(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	_try_begin_stumble_exit_blend()

	var speed_scale := _get_stumble_exit_speed_scale() if _stumble_exit_blending else 1.0
	velocity.x = _shove_direction.x * SHOVE_STUMBLE_SPEED * speed_scale
	velocity.z = _shove_direction.z * SHOVE_STUMBLE_SPEED * speed_scale
	_face_position(global_position + _shove_direction, delta)
	move_and_slide()
	update_npc_locomotion_audio(
		delta,
		Vector2(velocity.x, velocity.z).length(),
		true,
		false
	)


func _on_shove_stumble_anim_finished(anim_name: StringName) -> void:
	if anim_name != _get_stumble_anim_path():
		return
	if _animation_player != null and _animation_player.animation_finished.is_connected(
		_on_shove_stumble_anim_finished
	):
		_animation_player.animation_finished.disconnect(_on_shove_stumble_anim_finished)
	_end_shove_stumble()


func _end_shove_stumble() -> void:
	_shove_stumbling = false
	_shove_direction = Vector3.ZERO
	_stumble_exit_blending = false
	_velocity_zero()
	if _animation_player != null:
		if _animation_player.animation_finished.is_connected(_on_shove_stumble_anim_finished):
			_animation_player.animation_finished.disconnect(_on_shove_stumble_anim_finished)
		if _animation_player.is_playing():
			_animation_player.stop()
	_activate_locomotion_for_stumble_exit()
	_begin_shove_settle(_get_stumble_exit_blend(), TownNpcShove.STUMBLE_SETTLE_DURATION)
	_resume_after_shove()


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO


func _begin_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	_clamp_walk_direction_to_roam()


func _clamp_walk_direction_to_roam() -> void:
	var offset := global_position - _roam_center
	offset.y = 0.0
	var next_pos := global_position + _walk_direction * WALK_SPEED * walk_duration_max
	var next_offset := next_pos - _roam_center
	next_offset.y = 0.0

	if absf(next_offset.x) > _roam_half_extents.x:
		_walk_direction.x *= -1.0
	if absf(next_offset.z) > _roam_half_extents.y:
		_walk_direction.z *= -1.0

	if _walk_direction.length_squared() < 0.0001:
		_walk_direction = Vector3(-offset.x, 0.0, -offset.z).normalized()


func _setup_roll_dodge_library() -> void:
	if _animation_player == null:
		return

	var source := RollDodgeExtract.load_authored_library()
	if source == null:
		push_error("GroyperTownNpc: missing roll_dodge.tres — run RollDodgeExtract.")
		return

	if _animation_player.has_animation_library(RollDodgeConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(RollDodgeConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(RollDodgeConfig.LIBRARY_NAME, source.duplicate(true))


func _setup_punch_pose_library() -> void:
	if _animation_player == null:
		return

	var source := PunchPoseExtractScript.load_authored_library()
	if source == null:
		push_warning("GroyperTownNpc: missing punch_pose.tres — author in groyper_body.tscn.")
		return

	if _animation_player.has_animation_library(PunchPoseConfig.LIBRARY_NAME):
		_animation_player.remove_animation_library(PunchPoseConfig.LIBRARY_NAME)
	_animation_player.add_animation_library(PunchPoseConfig.LIBRARY_NAME, source.duplicate(true))


func _try_combat_roll_toward(target_pos: Vector3, chance: float) -> bool:
	if (
		not _combat_active
		or _roll_active
		or _punch_active
		or _roll_cooldown > 0.0
		or _mounted_horse != null
		or _horse_mount_target != null
	):
		return false
	if randf() >= chance:
		return false

	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return false

	var direction := to_target.normalized()
	if _combat_nav != null:
		var safe_dir: Vector3 = _combat_nav.get_safe_roll_direction(direction)
		if safe_dir.length_squared() < 0.0001:
			return false
		direction = safe_dir

	return _start_roll_dodge(direction, RUN_SPEED, true)


func _try_combat_roll_away_from(threat_pos: Vector3, chance: float) -> bool:
	if not _combat_active or _roll_active or _roll_cooldown > 0.0:
		return false
	if randf() >= chance:
		return false

	var away := global_position - threat_pos
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	away = away.normalized()

	_ai_state = AiState.COMBAT_MOVING
	_combat_move_pursue = false
	_combat_move_target = global_position
	return _start_roll_dodge(away, RUN_SPEED, true)


func _start_roll_dodge(direction: Vector3, base_speed: float, sprinting: bool) -> bool:
	var anim_path := StringName(
		"%s/%s" % [RollDodgeConfig.LIBRARY_NAME, RollDodgeConfig.WALK_ROLL]
	)
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		push_error("GroyperTownNpc: missing roll clip '%s'." % RollDodgeConfig.WALK_ROLL)
		return false

	var animation := _animation_player.get_animation(anim_path)
	_roll_duration = animation.length
	_roll_timer = 0.0
	_roll_active = true
	_roll_direction = direction.normalized()
	_roll_speed = base_speed
	_roll_is_run = sprinting
	_roll_speed_multiplier = (
		RUN_ROLL_SPEED_MULTIPLIER if _roll_is_run else ROLL_SPEED_MULTIPLIER
	)
	_roll_cooldown = COMBAT_ROLL_COOLDOWN
	_velocity_zero()

	var boosted := Vector3(velocity.x, 0.0, velocity.z)
	if boosted.length_squared() < 0.0001:
		boosted = _roll_direction * base_speed
	else:
		boosted = boosted.normalized() * maxf(boosted.length(), base_speed)
	boosted *= _roll_speed_multiplier
	velocity.x = boosted.x
	velocity.z = boosted.z

	if _roll_anim_node != null:
		_roll_anim_node.animation = anim_path
	if _animation_tree != null:
		_animation_tree.set(
			"parameters/%s/request" % ROLL_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)
	return true


func _update_roll_dodge(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	velocity.x = _roll_direction.x * _roll_speed * _roll_speed_multiplier
	velocity.z = _roll_direction.z * _roll_speed * _roll_speed_multiplier
	move_and_slide()

	_roll_timer += delta
	_face_position(global_position + _roll_direction, delta)
	_update_locomotion_blend(delta, _roll_speed * _roll_speed_multiplier, true)
	update_npc_locomotion_audio(delta, _roll_speed * _roll_speed_multiplier, true, true)

	if _roll_timer >= _roll_duration:
		_finish_roll_dodge()


func _finish_roll_dodge() -> void:
	_roll_active = false
	_roll_timer = 0.0
	_roll_duration = 0.0
	_roll_direction = Vector3.ZERO
	_roll_speed = 0.0
	_roll_speed_multiplier = ROLL_SPEED_MULTIPLIER
	_roll_is_run = false

	if not _combat_active or _aim_target == null:
		return
	if _can_begin_combat_aiming():
		_begin_combat_aiming()
		return
	if _combat_move_pursue:
		return
	var to_relocate := _combat_move_target - global_position
	to_relocate.y = 0.0
	if to_relocate.length_squared() > COMBAT_ARRIVE_DISTANCE * COMBAT_ARRIVE_DISTANCE:
		return
	_begin_combat_approach()


func mount_on_horse(horse: StupidHorse) -> void:
	if horse == null or _mounted_horse != null or _defeated:
		return
	if _saddle_blend_node == null:
		_mount_on_horse_minimal(horse)
		return

	_mount_on_horse_internal(horse, true)


func _mount_on_horse_minimal(horse: StupidHorse) -> void:
	if horse == null or _mounted_horse != null or _defeated:
		return
	_mount_on_horse_internal(horse, false)


func _mount_on_horse_internal(horse: StupidHorse, use_saddle_pose: bool) -> void:
	_mounted_horse = horse
	_horse_mount_target = null
	velocity = Vector3.ZERO

	if _collision_shape != null:
		_collision_shape.disabled = true

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(true)
		if not _combat_active and _weapon_rig.is_aiming():
			_weapon_rig.reset_to_holster()
	if use_saddle_pose:
		_update_mounted_saddle_gun_arm()

	var mount := horse.get_rider_mount_node()
	if mount != null and _model != null:
		GroyperBodyUtils.prepare_npc_model_for_horse_mount(
			self,
			_model,
			mount,
			horse.get_facing_direction()
		)
		_mounted_model_mount_offset = GroyperBodyUtils.attach_model_to_rider_mount(
			_model,
			mount
		)
		_rebind_animation_tree()

	follow_mounted_horse(mount)
	if use_saddle_pose:
		_saddle_blend = 1.0
		if _animation_tree != null:
			_animation_tree.set("parameters/SaddleBlend/blend_amount", 1.0)

	if _horse_ride_purpose == HORSE_RIDE_PATROL:
		_horse_ride_timer = randf_range(HORSE_PATROL_RIDE_MIN, HORSE_PATROL_RIDE_MAX)
		_pick_horse_patrol_target()
	elif _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE:
		_horse_ride_timer = 0.0


func dismount_from_horse(spawn_pos: Vector3, for_defeat: bool = false, for_horse_death: bool = false) -> void:
	if _mounted_horse == null and not _is_model_parented_to_horse():
		return
	if _horse_dismount_active and not for_horse_death:
		return
	if _mounted_horse == null:
		_mounted_horse = _find_horse_from_model_parent() as StupidHorse

	if for_horse_death:
		dismount_from_dead_horse(spawn_pos, {})
		return

	if for_defeat:
		_force_detach_model_to_player()
		GroyperBodyUtils.apply_model_baseline(_model)
		_rebind_animation_tree()
		_apply_dismount_cleanup(spawn_pos, true)
		return

	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	var mount_pos := global_position
	if horse != null:
		var mount := horse.get_rider_mount_node()
		if mount != null:
			mount_pos = mount.global_position

	_kill_horse_dismount_tween()
	_horse_dismount_active = true
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	_rebind_animation_tree()

	var landing := spawn_pos
	landing.y = mount_pos.y

	_mounted_horse = null
	_mounted_model_mount_offset = Transform3D.IDENTITY
	_mount_spine_yaw = 0.0

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(false)
		_weapon_rig.set_mount_aim_spine_yaw(0.0)

	global_position = mount_pos
	velocity = Vector3.ZERO

	var model_yaw_from := GroyperBodyUtils.MODEL_YAW_OFFSET
	if _model != null:
		model_yaw_from = _model.rotation.y
	var model_yaw_to := GroyperBodyUtils.MODEL_YAW_OFFSET

	_horse_dismount_tween = create_tween()
	_horse_dismount_tween.tween_method(
		func(t: float) -> void:
			global_position = GroyperBodyUtils.hop_world_position(
				mount_pos,
				landing,
				t,
				DISMOUNT_HOP_HEIGHT
			)
			_ensure_model_detached_for_horse_dismount()
			if _model != null and _model.get_parent() == self:
				var arc := 4.0 * t * (1.0 - t) * DISMOUNT_HOP_HEIGHT
				_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + arc * 0.35
				_model.rotation.y = lerp_angle(model_yaw_from, model_yaw_to, t)
			_saddle_blend = lerpf(1.0, 0.0, t)
			if _animation_tree != null:
				_animation_tree.set("parameters/SaddleBlend/blend_amount", _saddle_blend),
		0.0,
		1.0,
		DISMOUNT_HOP_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_horse_dismount_tween.tween_callback(func() -> void:
		_finish_horse_knockoff_dismount(landing)
	)


func dismount_from_dead_horse(
	exit_xz: Vector3,
	_hit_info: Dictionary,
	on_complete: Callable = Callable()
) -> void:
	if _horse_dismount_active:
		return

	if _mounted_horse == null and not _is_model_parented_to_horse():
		if on_complete.is_valid():
			on_complete.call()
		return

	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	var mount_pos := global_position
	if horse != null:
		var mount := horse.get_rider_mount_node()
		if mount != null:
			mount_pos = mount.global_position

	_kill_horse_dismount_tween()
	_horse_dismount_active = true
	_horse_death_dismount_callback = on_complete
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	_rebind_animation_tree()

	var ground_hint := mount_pos.y - 1.2
	if horse != null:
		ground_hint = horse.global_position.y

	var landing := GroyperBodyUtils.resolve_horse_death_landing(
		self,
		Vector3(exit_xz.x, ground_hint, exit_xz.z),
		ground_hint
	)

	_mounted_horse = null
	_mounted_model_mount_offset = Transform3D.IDENTITY
	_mount_spine_yaw = 0.0

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(false)
		_weapon_rig.set_mount_aim_spine_yaw(0.0)

	global_position = mount_pos
	velocity = Vector3.ZERO

	var model_yaw_from := GroyperBodyUtils.MODEL_YAW_OFFSET
	if _model != null:
		model_yaw_from = _model.rotation.y
	var model_yaw_to := GroyperBodyUtils.MODEL_YAW_OFFSET

	_horse_dismount_tween = create_tween()
	_horse_dismount_tween.tween_method(
		func(t: float) -> void:
			global_position = GroyperBodyUtils.hop_world_position(
				mount_pos,
				landing,
				t,
				HORSE_DEATH_DISMOUNT_ARC
			)
			_ensure_model_detached_for_horse_dismount()
			if _model != null and _model.get_parent() == self:
				var arc := 4.0 * t * (1.0 - t) * HORSE_DEATH_DISMOUNT_ARC
				_model.position.y = GroyperBodyUtils.ACTOR_MODEL_Y + arc * 0.35
				_model.rotation.y = lerp_angle(model_yaw_from, model_yaw_to, t)
			elif _model != null:
				_model.global_position = global_position + Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y, 0.0)
			_saddle_blend = lerpf(1.0, 0.0, t)
			if _animation_tree != null:
				_animation_tree.set("parameters/SaddleBlend/blend_amount", _saddle_blend),
		0.0,
		1.0,
		HORSE_DEATH_DISMOUNT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_horse_dismount_tween.tween_callback(func() -> void:
		_finish_horse_death_dismount(landing)
	)


func _fall_off_dead_horse(hit_info: Dictionary) -> void:
	if _horse_dismount_active or _defeated:
		return
	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	var exit_pos := global_position
	if horse != null and horse.has_method("get_death_dismount_position_for_rider"):
		exit_pos = horse.get_death_dismount_position_for_rider(hit_info)
	dismount_from_dead_horse(exit_pos, hit_info)


func _finish_horse_death_dismount(landing: Vector3) -> void:
	_horse_dismount_tween = null
	_horse_dismount_active = false
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	GroyperBodyUtils.apply_model_baseline(_model)
	_apply_dismount_cleanup(landing, false)
	var callback := _horse_death_dismount_callback
	_horse_death_dismount_callback = Callable()
	if callback.is_valid():
		callback.call()


func _finish_horse_knockoff_dismount(landing: Vector3) -> void:
	_horse_dismount_tween = null
	_horse_dismount_active = false
	_force_detach_model_to_player()
	_ensure_model_detached_for_horse_dismount()
	GroyperBodyUtils.apply_model_baseline(_model)
	_apply_dismount_cleanup(landing, false)
	var launch := _horse_dismount_launch_velocity
	_horse_dismount_launch_velocity = Vector3.ZERO
	if launch.length_squared() > 0.0001:
		velocity = launch
func _compute_horse_death_launch(hit_info: Dictionary, horse: StupidHorse) -> Vector3:
	var shot_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001 and horse != null:
		shot_dir = -horse.get_facing_direction()
	shot_dir = shot_dir.normalized() if shot_dir.length_squared() > 0.0001 else Vector3.FORWARD
	return shot_dir * 3.5 + Vector3.UP * 2.5


func _kill_horse_dismount_tween() -> void:
	if _horse_dismount_tween != null and _horse_dismount_tween.is_valid():
		_horse_dismount_tween.kill()
	_horse_dismount_tween = null
	_horse_dismount_active = false


func _apply_dismount_cleanup(spawn_pos: Vector3, for_defeat: bool) -> void:
	_mounted_horse = null
	global_position = spawn_pos
	velocity = Vector3.ZERO
	_mounted_model_mount_offset = Transform3D.IDENTITY
	_mount_spine_yaw = 0.0

	if _weapon_rig != null:
		_weapon_rig.set_saddle_aim_mode(false)
		_weapon_rig.set_mount_aim_spine_yaw(0.0)
		if _saddle_blend_node != null:
			SaddlePoseConfig.set_gun_arm_blend_filtered(_saddle_blend_node, true)
		if not for_defeat:
			if _combat_active:
				_weapon_rig.set_prep_aim(false)
			elif _weapon_rig.is_holstered():
				_weapon_rig.release_arms_for_locomotion()
			else:
				_weapon_rig.reset_to_holster()

	if _collision_shape != null and not for_defeat:
		_collision_shape.disabled = false

	GroyperBodyUtils.apply_model_baseline(_model)
	_saddle_blend = 0.0
	if _animation_tree != null:
		_animation_tree.set("parameters/SaddleBlend/blend_amount", 0.0)

	var previous_purpose := _horse_ride_purpose
	_horse_ride_purpose = HORSE_RIDE_NONE
	_horse_ride_timer = 0.0
	_horse_mount_cooldown = HORSE_MOUNT_COOLDOWN

	if for_defeat:
		return

	if _combat_active:
		_resume_foot_combat_after_dismount()
	elif previous_purpose == HORSE_RIDE_PATROL:
		_begin_idle()


func follow_mounted_horse(mount: Node3D = null) -> void:
	if _horse_dismount_active:
		return
	if _mounted_horse == null:
		return
	if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
		return
	if mount == null:
		mount = _mounted_horse.get_rider_mount_node()
	if mount == null:
		return

	global_position = mount.global_position
	velocity = Vector3.ZERO
	if _horse_dismount_active:
		return
	GroyperBodyUtils.sync_model_to_rider_mount(_model, mount, _mounted_model_mount_offset)


func get_ride_move_input() -> Vector3:
	if _ai_state == AiState.STARING or _faction_aggro_level == 1:
		return Vector3.ZERO

	if _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE:
		if _aim_target == null or not is_instance_valid(_aim_target):
			return Vector3.ZERO
		return _get_mounted_combat_chase_input(_aim_target.global_position)

	if (
		_combat_active
		and (
			_ai_state == AiState.COMBAT_AIMING
			or _ai_state == AiState.COMBAT_DRAWING
		)
	):
		return Vector3.ZERO

	if _horse_ride_purpose == HORSE_RIDE_PATROL:
		var to_patrol := _horse_ride_target - global_position
		to_patrol.y = 0.0
		if to_patrol.length_squared() < 1.2:
			_pick_horse_patrol_target()
			to_patrol = _horse_ride_target - global_position
			to_patrol.y = 0.0
		if to_patrol.length_squared() < 0.0001:
			return Vector3.ZERO
		return to_patrol.normalized()

	return Vector3.ZERO


func is_ride_sprinting() -> bool:
	return _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE


func _roll_mounted_fire_target() -> void:
	_mounted_fire_horse = null
	if _aim_target == null or not is_instance_valid(_aim_target):
		return
	if not _aim_target.has_method("is_mounted_on_horse") or not _aim_target.is_mounted_on_horse():
		return
	if randf() >= MOUNTED_FIRE_HORSE_CHANCE:
		return
	_mounted_fire_horse = get_mounted_horse_for_actor(_aim_target)


static func get_mounted_horse_for_actor(actor: Node) -> StupidHorse:
	if actor == null:
		return null
	if actor.has_method("get_mounted_horse"):
		return actor.get_mounted_horse() as StupidHorse
	return null


func get_mounted_horse() -> StupidHorse:
	return _mounted_horse


func is_mounted_on_horse() -> bool:
	if _horse_dismount_active:
		return false
	if _mounted_horse != null:
		if _mounted_horse.has_method("is_horse_defeated") and _mounted_horse.is_horse_defeated():
			return false
		return true
	return _is_model_parented_to_horse()


func is_model_on_horse_mount(horse: Node) -> bool:
	if _model == null or horse == null or not horse.has_method("get_rider_mount_node"):
		return false
	var mount: Node3D = horse.get_rider_mount_node()
	return mount != null and _model.get_parent() == mount


func _update_mounted_physics(delta: float) -> void:
	if _mounted_horse != null and _mounted_horse.has_method("is_horse_defeated"):
		if _mounted_horse.is_horse_defeated():
			if not _horse_dismount_active and not _defeated:
				_fall_off_dead_horse({})
			return
	_sync_mounted_actor_position()
	follow_mounted_horse()
	_update_mounted_aim_threat(delta)
	_update_horse_ride_ai(delta)
	_update_saddle_pose_blend(delta)

	var horse_speed := 0.0
	if _mounted_horse != null:
		horse_speed = Vector2(_mounted_horse.velocity.x, _mounted_horse.velocity.z).length()

	if (
		_horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE
		and _combat_active
		and _aim_target != null
		and is_instance_valid(_aim_target)
		and not _is_target_in_weapon_range()
		and _combat_nav != null
	):
		var chase_input := _get_mounted_combat_chase_input(_aim_target.global_position)
		_combat_nav.update_stuck(delta, horse_speed)
		_handle_combat_stuck(chase_input, _get_combat_nav_aim_point(_aim_target))

	_update_locomotion_blend(delta, horse_speed, is_ride_sprinting())
	var horse_moving := horse_speed > 0.08
	update_npc_locomotion_audio(
		delta,
		horse_speed,
		horse_moving,
		horse_moving and is_ride_sprinting()
	)


func _update_saddle_pose_blend(delta: float) -> void:
	if _animation_tree == null or _saddle_blend_node == null:
		return

	var target := 1.0 if _mounted_horse != null else 0.0
	_saddle_blend = lerpf(_saddle_blend, target, SADDLE_BLEND_SPEED * delta)
	_animation_tree.set("parameters/SaddleBlend/blend_amount", _saddle_blend)


func _update_horse_ride_ai(delta: float) -> void:
	if _mounted_horse == null:
		return

	match _horse_ride_purpose:
		HORSE_RIDE_PATROL:
			if _ai_state == AiState.STARING or _faction_aggro_level == 1:
				return
			_horse_ride_timer = maxf(_horse_ride_timer - delta, 0.0)
			if _horse_ride_timer <= 0.0:
				_request_horse_dismount()
		HORSE_RIDE_COMBAT_CHASE:
			if _aim_target == null or not is_instance_valid(_aim_target):
				if _should_stay_mounted_during_threat():
					_horse_ride_purpose = HORSE_RIDE_NONE
				else:
					_request_horse_dismount()
				return
			if not _combat_active:
				_horse_ride_purpose = HORSE_RIDE_NONE
				return
			if _is_target_in_weapon_range():
				if _weapon_rig != null and _weapon_rig.is_aiming():
					if _ai_state != AiState.COMBAT_AIMING and _has_combat_line_of_sight_to(_aim_target):
						_begin_combat_aiming()
				elif _ai_state != AiState.COMBAT_DRAWING:
					_ai_state = AiState.COMBAT_DRAWING
					if _weapon_rig != null:
						_weapon_rig.begin_draw()


func _update_mounted_aim_threat(delta: float) -> void:
	if _defeated:
		return

	if _uses_faction_aggro() or _faction_standoff_active:
		_update_faction_aggro(delta)

	if _combat_active:
		if _faction_wars_with_outsiders():
			_check_outsider_player_threat()
		if _aim_target != null:
			_face_position(_aim_target.global_position, delta)
		return

	if _player_weapon_threat_active and _aim_target != null:
		_mounted_aim_alert_active = true
		_face_position(_aim_target.global_position, delta)
		return

	_mounted_aim_alert_active = false
	if _uses_faction_aggro() or _faction_standoff_active:
		if _aim_target != null and (_ai_state == AiState.STARING or _faction_aggro_level == 1):
			_face_position(_aim_target.global_position, delta)
		return

	var player := _find_player()
	if player == null:
		_clear_mounted_aim_threat()
		return

	if _player_is_threatening_becker_boy(player, true):
		_begin_player_weapon_stare(player, not _mounted_aim_alert_active)
		_mounted_aim_alert_active = true
		_face_position(_aim_target.global_position, delta)
	else:
		_clear_mounted_aim_threat()


func _clear_mounted_aim_threat() -> void:
	_mounted_aim_alert_active = false
	if _player_weapon_threat_active:
		return
	if _faction_aggro_level == 1 and not _faction_standoff_active:
		_deescalate_faction_aggro()
	elif _ai_state == AiState.STARING and not _combat_active and _faction_aggro_level <= 0:
		_resume_peaceful_ai()


func _update_peaceful_horse_patrol(delta: float) -> void:
	if (
		_combat_active
		or _faction_aggro_locks_peaceful_roam()
		or _mounted_horse != null
		or _horse_mount_target != null
		or _lasso_captured
		or _saddle_blend_node == null
	):
		return

	_horse_patrol_check_timer = maxf(_horse_patrol_check_timer - delta, 0.0)
	if _horse_patrol_check_timer > 0.0:
		return

	_horse_patrol_check_timer = randf_range(HORSE_PATROL_CHECK_MIN, HORSE_PATROL_CHECK_MAX)
	if randf() >= HORSE_PATROL_MOUNT_CHANCE:
		return

	var horse := _find_nearest_available_horse(HORSE_SEARCH_RANGE)
	if horse == null:
		return

	_begin_approach_horse(horse, HORSE_RIDE_PATROL)


func _try_begin_combat_horse_chase() -> void:
	if not _allows_combat_horse_remount():
		return
	if (
		_aim_target == null
		or not is_instance_valid(_aim_target)
		or _horse_mount_target != null
		or _saddle_blend_node == null
	):
		return

	if _get_horizontal_distance_to(_aim_target) < HORSE_COMBAT_CHASE_RANGE:
		return

	var horse := _find_nearest_available_horse(HORSE_SEARCH_RANGE)
	if horse == null:
		return

	_begin_approach_horse(horse, HORSE_RIDE_COMBAT_CHASE)


func _allows_combat_horse_remount() -> bool:
	return true


func _resume_foot_combat_after_dismount() -> void:
	if not _combat_active:
		return

	_horse_mount_target = null

	if _weapon_rig != null:
		_weapon_rig.set_prep_aim(false)
		if not _weapon_rig.is_aiming():
			_weapon_rig.begin_draw()

	if _aim_target != null:
		_sync_combat_nav_target_to(_aim_target)

	if _weapon_rig != null and _weapon_rig.is_aiming() and _can_begin_combat_aiming():
		_begin_combat_aiming()
	elif _can_begin_combat_aiming():
		_ai_state = AiState.COMBAT_DRAWING
	else:
		_begin_combat_approach()


func _begin_approach_horse(horse: StupidHorse, purpose: int) -> void:
	if horse == null or not _is_horse_available(horse):
		return

	_horse_mount_target = horse
	_horse_ride_purpose = purpose
	_saved_ai_state = _ai_state
	_ai_state = AiState.APPROACHING_HORSE
	_velocity_zero()


func _process_approach_horse(delta: float) -> void:
	if _horse_mount_target == null or not is_instance_valid(_horse_mount_target):
		_cancel_horse_approach()
		return

	if not _is_horse_available(_horse_mount_target):
		_cancel_horse_approach()
		return

	var to_horse := _horse_mount_target.global_position - global_position
	to_horse.y = 0.0
	if to_horse.length_squared() <= HORSE_MOUNT_RANGE * HORSE_MOUNT_RANGE:
		_horse_mount_target.mount_rider(self)
		return

	var move_dir := to_horse.normalized()
	velocity.x = move_dir.x * RUN_SPEED
	velocity.z = move_dir.z * RUN_SPEED
	_face_position(global_position + move_dir, delta)


func _cancel_horse_approach() -> void:
	_horse_mount_target = null
	if _horse_ride_purpose != HORSE_RIDE_NONE and _mounted_horse == null:
		_horse_ride_purpose = HORSE_RIDE_NONE

	if _combat_active:
		if _ai_state == AiState.APPROACHING_HORSE:
			_ai_state = AiState.COMBAT_MOVING
		return

	if _ai_state == AiState.APPROACHING_HORSE:
		_ai_state = _saved_ai_state
		if _ai_state == AiState.IDLE:
			_begin_idle()


func _should_stay_mounted_during_threat() -> bool:
	if _mounted_horse == null:
		return false
	if _faction_standoff_active and _faction_aggro_level < 3:
		return true
	if _ai_state == AiState.STARING or _faction_aggro_level <= 1:
		return true
	if _player_weapon_threat_active:
		return true
	return false


func _request_horse_dismount() -> void:
	if _mounted_horse == null:
		return
	if _should_stay_mounted_during_threat():
		return
	if _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE and not _combat_active:
		_horse_ride_purpose = HORSE_RIDE_NONE
		return
	_mounted_horse.dismount_rider()


func _pick_horse_patrol_target() -> void:
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(HORSE_PATROL_WANDER_MIN, HORSE_PATROL_WANDER_MAX)
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * distance
	_horse_ride_target = global_position + offset
	_horse_ride_target.y = global_position.y


func _find_nearest_available_horse(max_range: float) -> StupidHorse:
	var nearest: StupidHorse = null
	var nearest_dist_sq := max_range * max_range

	for node in get_tree().get_nodes_in_group("stupid_horse"):
		var horse := node as StupidHorse
		if not _is_horse_available(horse):
			continue
		var dist_sq := global_position.distance_squared_to(horse.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = horse

	return nearest


func _is_horse_available(horse: StupidHorse) -> bool:
	if horse == null or not is_instance_valid(horse):
		return false
	if horse.has_method("is_horse_defeated") and horse.is_horse_defeated():
		return false
	if horse.is_mounted():
		return false
	if horse.has_method("is_lassoable") and not horse.is_lassoable():
		return false
	return true


func _force_detach_model_to_player() -> void:
	GroyperBodyUtils.detach_model_to_actor(_model, self)


func _ensure_model_detached_for_horse_dismount() -> void:
	if _model == null:
		return
	if _model.get_parent() != self:
		_force_detach_model_to_player()
	if _model.get_parent() == self:
		GroyperBodyUtils.apply_model_baseline(_model)


func _rebind_animation_tree() -> void:
	if _animation_tree == null or _animation_player == null:
		return
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)


func _update_mounted_saddle_gun_arm() -> void:
	if _mounted_horse == null or _saddle_blend_node == null or _weapon_rig == null:
		return
	var saddle_owns_gun_arm: bool = _weapon_rig.is_holstered()
	if _weapon_rig.is_overworld_reloading():
		saddle_owns_gun_arm = false
	SaddlePoseConfig.set_gun_arm_blend_filtered(_saddle_blend_node, saddle_owns_gun_arm)


func _update_mounted_aim_spine(delta: float) -> void:
	if _weapon_rig == null:
		return

	var target := 0.0
	if (
		_mounted_horse != null
		and _weapon_rig.is_aiming()
		and _aim_target != null
	):
		var rider_forward := -_model.global_transform.basis.z
		rider_forward.y = 0.0
		if rider_forward.length_squared() > 0.0001:
			rider_forward = rider_forward.normalized()
			var to_target := _aim_target.global_position - global_position
			to_target.y = 0.0
			if to_target.length_squared() > 0.0001:
				var aim_dir := to_target.normalized()
				var relative_yaw := atan2(
					rider_forward.cross(aim_dir).y,
					rider_forward.dot(aim_dir)
				)
				var abs_yaw := absf(relative_yaw)
				if abs_yaw > MOUNT_AIM_SPINE_DEAD_ZONE:
					target = signf(relative_yaw) * (abs_yaw - MOUNT_AIM_SPINE_DEAD_ZONE)

	var step := 1.0 - exp(-MOUNT_AIM_SPINE_SMOOTH * delta)
	_mount_spine_yaw = lerpf(_mount_spine_yaw, target, step)
	_weapon_rig.set_mount_aim_spine_yaw(_mount_spine_yaw)


func _dismount_for_defeat(hit_info: Dictionary) -> void:
	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	if horse == null:
		return
	_mounted_horse = horse
	var spawn_pos := _get_defeat_dismount_position(hit_info)
	hit_info["mounted_launch_velocity"] = _get_defeat_launch_velocity(hit_info)
	if horse.has_method("release_rider"):
		horse.release_rider()
	dismount_from_horse(spawn_pos, true)


func _find_horse_from_model_parent() -> Node:
	if _model == null:
		return null
	var node := _model.get_parent()
	while node != null:
		if node.is_in_group("stupid_horse"):
			return node
		node = node.get_parent()
	return null


func _is_model_parented_to_horse() -> bool:
	return _find_horse_from_model_parent() != null


func _sync_mounted_actor_position() -> void:
	if _horse_dismount_active:
		return
	var horse: StupidHorse = _mounted_horse
	if horse == null:
		horse = _find_horse_from_model_parent() as StupidHorse
	if horse != null and horse.has_method("is_horse_defeated") and horse.is_horse_defeated():
		if not _defeated:
			_fall_off_dead_horse({})
		return
	if horse != null and _mounted_horse == null and _is_model_parented_to_horse() and not _defeated:
		_mounted_horse = horse

	var mount: Node3D = null
	if _mounted_horse != null:
		mount = _mounted_horse.get_rider_mount_node()
	elif horse != null and horse.has_method("get_rider_mount_node"):
		mount = horse.get_rider_mount_node()
	if mount == null:
		return

	global_position = mount.global_position
	velocity = Vector3.ZERO
	if _horse_dismount_active:
		return
	GroyperBodyUtils.sync_model_to_rider_mount(_model, mount, _mounted_model_mount_offset)


func _force_mounted_hitbox_transforms() -> void:
	if not is_mounted_on_horse() and not _is_model_parented_to_horse():
		return
	if _model != null:
		_model.force_update_transform()
	if _skeleton != null:
		_skeleton.force_update_transform()


func _get_rider_mount_anchor() -> Vector3:
	if _mounted_horse != null:
		var mount := _mounted_horse.get_rider_mount_node()
		if mount != null:
			return mount.global_position
	var horse := _find_horse_from_model_parent()
	if horse != null and horse.has_method("get_rider_mount_node"):
		var mount: Node3D = horse.get_rider_mount_node()
		if mount != null:
			return mount.global_position
	return global_position


func _get_mounted_bullet_capsule() -> Dictionary:
	var anchor := _get_rider_mount_anchor()
	var torso := _get_torso_transform()
	var center := torso.origin
	if center.y < anchor.y + MOUNTED_HITBOX_MIN_Y_ABOVE_MOUNT:
		center = anchor + MOUNTED_CHEST_OFFSET
	var half_height := (
		MOUNTED_HITBOX_HALF_HEIGHT if not _roll_active else ROLL_HITBOX_HALF_HEIGHT + 0.18
	)
	var radius := MOUNTED_HITBOX_RADIUS if not _roll_active else ROLL_HITBOX_RADIUS + 0.12
	return {
		"center": center,
		"half_height": half_height,
		"radius": radius,
		"axis": Vector3.UP,
	}


func _get_mounted_head_hit_sphere() -> Dictionary:
	var anchor := _get_rider_mount_anchor()
	var head := GroyperBodyUtils.get_head_hit_sphere(
		_skeleton,
		anchor + MOUNTED_CHEST_OFFSET,
		MOUNTED_HEAD_RADIUS
	)
	if head.center.y < anchor.y + 0.62:
		head.center = anchor + MOUNTED_HEAD_OFFSET
	return head


func _knock_off_horse_from_hit(hit_info: Dictionary) -> void:
	if _mounted_horse == null:
		_mounted_horse = _find_horse_from_model_parent() as StupidHorse
	if _mounted_horse == null:
		return
	var horse := _mounted_horse
	var spawn_pos := _get_defeat_dismount_position(hit_info)
	var launch := _get_defeat_launch_velocity(hit_info) * 0.72
	if horse.has_method("release_rider"):
		horse.release_rider()
	_horse_dismount_launch_velocity = launch
	dismount_from_horse(spawn_pos, false)


func _get_defeat_launch_velocity(hit_info: Dictionary) -> Vector3:
	var shot_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001 and _mounted_horse != null:
		shot_dir = -_mounted_horse.get_facing_direction()
	shot_dir = shot_dir.normalized() if shot_dir.length_squared() > 0.0001 else Vector3.FORWARD
	return shot_dir * MOUNT_DEFEAT_LAUNCH_SPEED + Vector3.UP * MOUNT_DEFEAT_LAUNCH_UP


func _get_defeat_dismount_position(hit_info: Dictionary) -> Vector3:
	var mount: Node3D = null
	if _mounted_horse != null:
		mount = _mounted_horse.get_rider_mount_node()
	var base_pos := mount.global_position if mount != null else global_position
	var launch_vel := _get_defeat_launch_velocity(hit_info)
	var horizontal := Vector3(launch_vel.x, 0.0, launch_vel.z)
	if horizontal.length_squared() > 0.0001:
		return base_pos + horizontal.normalized() * 0.35 + Vector3(0.0, 0.2, 0.0)
	if _mounted_horse != null:
		var side := _mounted_horse.get_facing_direction().cross(Vector3.UP)
		if side.length_squared() < 0.0001:
			side = Vector3.RIGHT
		return base_pos + side.normalized() * 0.9 + Vector3(0.0, 0.15, 0.0)
	return base_pos + Vector3(0.0, 0.15, 0.0)


func _face_position(target_pos: Vector3, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	var target_yaw := GroyperBodyUtils.facing_yaw_for_direction(to_target.normalized())
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _snap_face_toward_target() -> void:
	if _aim_target == null:
		return
	var flat_target := Vector3(
		_aim_target.global_position.x,
		global_position.y,
		_aim_target.global_position.z
	)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	_model.rotation.y = GroyperBodyUtils.facing_yaw_for_direction(to_target.normalized())


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	var target := 0.0
	if speed > 0.05:
		target = 1.0 if sprinting else 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)


func _get_torso_transform() -> Transform3D:
	if _skeleton == null:
		var no_skeleton := global_transform
		no_skeleton.origin = global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
		return no_skeleton

	for bone_name in ["Spine02", "Spine01", "Spine"]:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
		return Transform3D(
			bone_global.basis,
			bone_global.origin + bone_global.basis * Vector3(0.0, 0.04, 0.02)
		)

	var fallback := global_transform
	fallback.origin = global_position + Vector3(0.0, CHEST_AIM_HEIGHT, 0.0)
	return fallback


func _get_alert_world_position() -> Vector3:
	if _skeleton != null:
		var head_id := _skeleton.find_bone("Head")
		if head_id >= 0:
			var head_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)
			return head_global.origin + Vector3(0.0, ALERT_HEAD_BONE_OFFSET, 0.0)
	return global_position + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0)


func _show_alert_fx() -> void:
	AlertSymbolFX.spawn_above(self, _get_alert_world_position())

