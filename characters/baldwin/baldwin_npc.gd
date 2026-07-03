extends "res://characters/baldwin/baldwin_actor.gd"
class_name BaldwinNpc

const BaldwinAnimConfigScript := preload("res://characters/baldwin/baldwin_anim_config.gd")
const BaldwinAnimUtilsScript := preload("res://characters/baldwin/baldwin_anim_utils.gd")
const BaldwinShieldConfigScript := preload("res://characters/baldwin/baldwin_shield_config.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")
const SwordCrescentFXScript := preload("res://gameplay/fx/sword_crescent_fx.gd")
const NpcCombatNavigationScript := preload("res://gameplay/navigation/npc_combat_navigation.gd")
const BaldwinWeaponRigScript := preload("res://characters/baldwin/baldwin_weapon_rig.gd")

enum EncounterState {
	SITTING_LOCKED,
	SITTING_READY,
	STANDING_UP,
	NORMAL,
	COMPANION,
}

enum AiState {
	IDLE,
	WALKING,
	FOLLOWING,
	CHASING,
	COMBAT_DECIDING,
	BLOCKING,
	ATTACKING,
	DISENGAGING,
	RELOCATING,
	PARRY_STUNNED,
	BLOCK_BROKEN,
}

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const WALK_SPEED := 2.0
const RUN_SPEED := 4.6
const BLEND_SPEED := 8.0
const IDLE_MIN := 4.0
const IDLE_MAX := 9.0
const WALK_MIN := 2.0
const WALK_MAX := 5.0
const COMPANION_LEASH := 7.5
const COMPANION_FOLLOW_DISTANCE := 3.2
const COMPANION_CATCHUP_DISTANCE := 9.0
const COMPANION_COMBAT_RANGE_MULT := 2.0
const COMPANION_IDLE_FACE_SPEED := 6.0
const LOCOMOTION_STOP_SPEED := 0.08
const LOCOMOTION_RUN_SPEED := 3.4
const ENEMY_DETECT_RANGE := 12.0
const ATTACK_RANGE := MeleeSwordSlashScript.RANGE
const ATTACK_STRIKE_FRACTION := 0.35
const ATTACK_COOLDOWN := MeleeSwordSlashScript.COOLDOWN
const AGGRO_STAND_DOWN_TIME := 3.0
const DISENGAGE_MIN := 1.0
const DISENGAGE_MAX := 2.2
const MELEE_DECISION_MIN := 0.25
const MELEE_DECISION_MAX := 0.55
const MELEE_ATTACK_CHANCE := 0.34
const MELEE_BLOCK_CHANCE := 0.28
const BLOCK_DURATION_MIN := 1.2
const BLOCK_DURATION_MAX := 2.4
const PARRY_FOLLOWUP_ATTACK_CHANCE := 0.60
const PARRY_FOLLOWUP_REBLOCK_CHANCE := 0.30
const PARRY_REBLOCK_HOLD_MIN := 1.0
const PARRY_REBLOCK_HOLD_MAX := 2.0
const BLOCK_FACING_DOT_MIN := 0.32
const HAMMER_BLOCK_DEFENDER_KNOCKBACK_SCALE := 1.45
const POST_ATTACK_DISENGAGE_CHANCE := 0.35
const RELOCATE_ARRIVE_DIST := 0.85
const MAX_HEALTH := BulletHitDamageScript.BALDWIN_MAX_HEALTH
const HEALTH_REGEN_INTERVAL := 3.0
const BODY_HIT_RADIUS := 0.4
const BODY_HIT_HALF_HEIGHT := 1.0

var _attack_elapsed := 0.0

@export var speaker_name := "Baldwin"
@export var idle_duration_min := IDLE_MIN
@export var idle_duration_max := IDLE_MAX
@export var walk_duration_min := WALK_MIN
@export var walk_duration_max := WALK_MAX
@export_group("Shield Block Animations")
@export var shield_block_break_damage := BaldwinShieldConfigScript.DEFAULT_BLOCK_BREAK_DAMAGE
@export var shield_block_enter_meshy_clip: StringName = (
	BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_ENTER
)
@export var shield_block_hold_meshy_clip: StringName = (
	BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_HOLD
)
@export var shield_block_clash_meshy_clip: StringName = (
	BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_CLASH
)
@export var shield_block_break_meshy_clip: StringName = (
	BaldwinAnimConfigScript.MESHY_SHIELD_BLOCK_BREAK
)
@export_group("Legacy Parry Clips")
@export var parry_hold_meshy_clip: StringName = BaldwinAnimConfigScript.MESHY_SWORD_PARRY
@export var parry_clash_meshy_clip: StringName = BaldwinAnimConfigScript.MESHY_SWORD_PARRY_BACKWARD

@onready var _interact_area: Area3D = $InteractArea

var _encounter_state := EncounterState.SITTING_LOCKED
var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _walk_direction := Vector3.ZERO
var _locomotion_blend := 0.0
var _roam_center := Vector3.ZERO
var _roam_half_extents := Vector2(4.0, 4.0)
var _player_in_range: Node3D
var _talking := false
var _busy := false
var _companion_player: Node3D
var _combat_target: Node3D
var _attack_timer := 0.0
var _attack_cooldown := 0.0
var _attack_struck := false
var _attack_direction := Vector3.FORWARD
var _combat_nav
var _stance_anim_name := StringName()
var _stance_reverse_anim_name := StringName()
var _sitting_pose_anim_name := StringName()
var _attack_anim_name := StringName()
var _parry_pose_anim_name := StringName()
var _parry_clash_anim_name := StringName()
var _shield_block_hold_path := StringName()
var _shield_block_enter_path := StringName()
var _shield_block_clash_path := StringName()
var _shield_block_break_path := StringName()
var _has_shield_block_anims := false
var _has_block_clash_one_shot := false
var _block_hold_blend_tween: Tween
var _weapon_rig: Node
var _no_enemy_timer := 0.0
var _peaceful_idle_path := StringName()
var _aggro_idle_path := StringName()
var _using_aggro_idle := false
var _idle_anim_node: AnimationNodeAnimation
var _voice_player: AudioStreamPlayer3D
var _health := MAX_HEALTH
var _health_regen_timer := 0.0
var _defeated := false
var _disengage_timer := 0.0
var _disengage_direction := Vector3.ZERO
var _blocking := false
var _melee_hit_absorbed := false
var _decision_timer := 0.0
var _combat_state_timer := 0.0
var _relocate_target := Vector3.ZERO
var _companion_combat_active := false


func _on_actor_ready() -> void:
	add_to_group("baldwin_npc")
	add_to_group("crusader_npc")
	add_to_group("faction_npc")
	_setup_animations()
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	call_deferred("_finalize_spawn")


func _finalize_spawn() -> void:
	snap_to_floor()
	_roam_center = global_position

	if CompanionManager.is_recruited(CompanionManager.COMPANION_BALDWIN):
		_begin_companion_mode(_find_player())
		return

	if CompanionManager.has_baldwin_hopeless_shown():
		_encounter_state = EncounterState.SITTING_READY

	_lock_sitting_pose()


func _physics_process(delta: float) -> void:
	tick_melee_stun(delta)
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if _encounter_state == EncounterState.SITTING_LOCKED \
			or _encounter_state == EncounterState.SITTING_READY:
		velocity = Vector3.ZERO
		if _talking and _player_in_range != null:
			_face_position(_player_in_range.global_position, delta)
		move_and_slide()
		return

	if _encounter_state == EncounterState.STANDING_UP:
		move_and_slide()
		return

	if _weapon_rig != null:
		_weapon_rig.update(delta)
		_weapon_rig.apply_pose_overrides(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _defeated:
		if not should_preserve_knockback_velocity():
			velocity.x = 0.0
			velocity.z = 0.0
		_update_companion_health(delta)
		move_and_slide()
		return

	if (
		is_melee_stunned()
		and _ai_state not in [AiState.PARRY_STUNNED, AiState.BLOCK_BROKEN]
	):
		if not should_preserve_knockback_velocity():
			velocity.x = 0.0
			velocity.z = 0.0
		_update_companion_health(delta)
		move_and_slide()
		return

	match _encounter_state:
		EncounterState.NORMAL:
			_process_normal_ai(delta)
		EncounterState.COMPANION:
			_process_companion_ai(delta)
			_update_companion_health(delta)

	match _ai_state:
		AiState.ATTACKING:
			_process_attack(delta)
		AiState.BLOCKING:
			_process_blocking(delta)
		AiState.BLOCK_BROKEN:
			_process_block_broken(delta)
		AiState.PARRY_STUNNED:
			_process_parry_stunned(delta)
		AiState.COMBAT_DECIDING:
			_process_combat_deciding(delta)
		AiState.RELOCATING:
			_process_relocating(delta)

	if _ai_state not in [
		AiState.ATTACKING,
		AiState.BLOCKING,
		AiState.BLOCK_BROKEN,
		AiState.PARRY_STUNNED,
		AiState.COMBAT_DECIDING,
	]:
		_update_locomotion_blend(delta)

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	update_npc_locomotion_audio(
		delta,
		horizontal_speed,
		horizontal_speed > LOCOMOTION_STOP_SPEED,
		horizontal_speed >= LOCOMOTION_RUN_SPEED
	)


func _process(_delta: float) -> void:
	if _voice_player == null or not is_instance_valid(_voice_player) or not _voice_player.playing:
		return
	_voice_player.global_position = get_voice_world_position()


func interact(player: Node3D) -> void:
	if _busy or _talking or player == null:
		return
	if _encounter_state == EncounterState.COMPANION:
		return

	match _encounter_state:
		EncounterState.SITTING_LOCKED:
			_show_hopeless_dialog(player)
		EncounterState.SITTING_READY:
			_begin_stand_up_sequence(player)
		EncounterState.NORMAL:
			_show_recruit_dialog(player)


func get_interact_hint() -> String:
	if _encounter_state == EncounterState.COMPANION:
		return ""
	return "Talk"


func get_voice_world_position() -> Vector3:
	return global_position + Vector3(0.0, 1.6, 0.0)


func get_faction_id() -> StringName:
	if _encounter_state == EncounterState.COMPANION:
		return FactionIdsScript.PLAYER
	return FactionIdsScript.CRUSADERS


func get_punch_facing_direction() -> Vector3:
	if _attack_direction.length_squared() > 0.0001 and _ai_state == AiState.ATTACKING:
		return _attack_direction
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func receive_bullet_hit(hit_info: Dictionary) -> void:
	if _defeated:
		return

	_melee_hit_absorbed = false

	if _can_block_melee(hit_info):
		var damage := int(hit_info.get("damage", 1))
		if damage >= shield_block_break_damage:
			_melee_hit_absorbed = true
			_on_shield_block_broken(hit_info)
			return
		_melee_hit_absorbed = true
		_on_attack_blocked(hit_info)
		return

	_focus_attacker_from_hit(hit_info)

	var result := BulletHitDamageScript.process_hit(self, hit_info, _health, MAX_HEALTH)
	_health = result.health
	CombatHitFlashScript.flash_damage(self)
	if result.knockback_applied:
		hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	if result.killed:
		_on_defeated(hit_info)
		return

	if bool(hit_info.get("melee", false)) and hit_info.has("melee_stun_duration"):
		apply_melee_stun(float(hit_info.get("melee_stun_duration", 0.55)))


func is_blocking() -> bool:
	return _blocking and _ai_state == AiState.BLOCKING


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func on_melee_clash_blocked(
	attacker: Node,
	hit_info: Dictionary,
	stun_duration: float
) -> void:
	CombatHitFlashScript.flash_block(self)
	_blocking = false
	_tween_block_hold_blend(0.0, CombatAnimTransitionsScript.CLASH_BLOCK_BLEND_OUT)
	_play_block_clash_animation()
	_enter_parry_stun(stun_duration)
	call_deferred("_finish_shield_clash_knockback", attacker, hit_info, stun_duration)


func _finish_shield_clash_knockback(
	attacker: Node,
	hit_info: Dictionary,
	stun_duration: float
) -> void:
	if not is_instance_valid(self):
		return
	var clash_hit_info := hit_info
	if bool(hit_info.get("hammer_hit", false)):
		clash_hit_info = hit_info.duplicate()
		clash_hit_info["knockback_speed"] = (
			float(hit_info.get("knockback_speed", 6.5)) * HAMMER_BLOCK_DEFENDER_KNOCKBACK_SCALE
		)
	MeleeClashScript.apply_defender_clash_knockback(self, attacker, clash_hit_info)
	hold_knockback_velocity(stun_duration)


func get_bullet_capsule() -> Dictionary:
	return {
		"center": global_position + Vector3(0.0, 0.95, 0.0),
		"half_height": BODY_HIT_HALF_HEIGHT,
		"radius": BODY_HIT_RADIUS,
		"axis": Vector3.UP,
	}


func get_threat_aim_point() -> Vector3:
	return global_position + Vector3(0.0, 1.1, 0.0)


func is_defeated() -> bool:
	return _defeated


func apply_melee_stun(duration: float) -> void:
	if _ai_state in [AiState.PARRY_STUNNED, AiState.BLOCK_BROKEN]:
		return
	_melee_stun_timer = maxf(_melee_stun_timer, duration)


func on_melee_clash_attacker(
	_defender: Node,
	hit_info: Dictionary,
	stun_duration: float
) -> void:
	if _ai_state == AiState.ATTACKING:
		_attack_struck = true
		_attack_timer = 0.0
	CombatHitFlashScript.flash_block(self)
	_tween_block_hold_blend(0.0, CombatAnimTransitionsScript.CLASH_BLOCK_BLEND_OUT)
	_play_block_clash_animation()
	_enter_parry_stun(stun_duration)
	call_deferred("_finish_shield_clash_knockback", _defender, hit_info, stun_duration)


func _play_block_clash_animation() -> void:
	if _animation_tree == null or not _animation_tree.active or not _has_block_clash_one_shot:
		return
	if (
		not _animation_player.has_animation(_shield_block_clash_path)
		and not _animation_player.has_animation(_parry_clash_anim_name)
	):
		return
	_animation_tree.set(
		"parameters/%s/request" % BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _play_block_break_animation() -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	if not _animation_player.has_animation(_shield_block_break_path):
		return
	_tween_block_hold_blend(0.0, CombatAnimTransitionsScript.CLASH_BLOCK_BLEND_OUT)
	_animation_tree.set(
		"parameters/%s/request" % BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


func _process_normal_ai(delta: float) -> void:
	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer <= 0.0:
				_begin_walk()
		AiState.WALKING:
			_move_in_direction(_walk_direction, WALK_SPEED, delta)
			if _state_timer <= 0.0:
				_begin_idle()


func _process_companion_ai(delta: float) -> void:
	if _defeated:
		_velocity_stop_horizontal()
		return

	if _ai_state in [
		AiState.ATTACKING,
		AiState.BLOCKING,
		AiState.BLOCK_BROKEN,
		AiState.PARRY_STUNNED,
		AiState.COMBAT_DECIDING,
		AiState.RELOCATING,
	]:
		return

	if _ai_state == AiState.DISENGAGING:
		_process_disengage(delta)
		return

	var draw_state: BaldwinWeaponRigScript.DrawState = (
		_weapon_rig.get_draw_state()
		if _weapon_rig != null
		else BaldwinWeaponRigScript.DrawState.EQUIPPED
	)
	if _weapon_rig != null and _weapon_rig.is_transitioning():
		_velocity_stop_horizontal()
		var focus := _combat_target if _combat_target != null else _find_nearest_enemy()
		if focus != null:
			_face_position(focus.global_position, delta)
		_update_combat_idle_blend(delta, draw_state)
		return

	var enemy := _find_nearest_enemy()
	if _weapon_rig != null and _weapon_rig.is_holstered():
		_set_combat_idle(false)
		if enemy != null:
			_enter_companion_combat()
			_weapon_rig.begin_draw()
			_face_position(enemy.global_position, delta)
			_velocity_stop_horizontal()
			return
		_process_companion_peaceful(delta)
		return

	if _weapon_rig != null and _weapon_rig.is_equipped():
		_update_combat_idle_blend(delta, draw_state)
		if enemy == null:
			_no_enemy_timer += delta
			if _no_enemy_timer >= AGGRO_STAND_DOWN_TIME:
				_exit_companion_combat()
				_weapon_rig.begin_holster()
				_velocity_stop_horizontal()
				return
		else:
			_no_enemy_timer = 0.0
			_combat_target = enemy
			var to_enemy := enemy.global_position - global_position
			to_enemy.y = 0.0
			var distance := to_enemy.length()
			if distance <= ATTACK_RANGE + 0.35:
				_begin_combat_deciding()
				return
			_move_toward(enemy.global_position, RUN_SPEED, delta)
			_ai_state = AiState.CHASING
			return

	_process_companion_peaceful(delta)


func _process_companion_peaceful(delta: float) -> void:
	var player := _companion_player
	if player == null or not is_instance_valid(player):
		player = _find_player()
		_companion_player = player

	_combat_target = null
	if player == null:
		_velocity_stop_horizontal()
		_ai_state = AiState.IDLE
		return

	var offset := global_position - player.global_position
	offset.y = 0.0
	var distance_to_player := offset.length()

	if distance_to_player > _get_companion_catchup_distance():
		_move_toward(player.global_position, RUN_SPEED, delta)
		_ai_state = AiState.CHASING
		return

	if distance_to_player > _get_companion_follow_distance():
		_move_toward(player.global_position, WALK_SPEED, delta)
		_ai_state = AiState.FOLLOWING
		return

	if _ai_state == AiState.FOLLOWING or _ai_state == AiState.CHASING:
		_begin_companion_idle()

	_roam_center = player.global_position
	_state_timer -= delta
	match _ai_state:
		AiState.IDLE:
			_velocity_stop_horizontal()
			_face_position(player.global_position, delta, COMPANION_IDLE_FACE_SPEED)
			if _state_timer <= 0.0:
				_begin_companion_walk()
		AiState.WALKING:
			_move_in_direction(_walk_direction, WALK_SPEED, delta)
			_clamp_walk_to_leash(player.global_position)
			if _state_timer <= 0.0:
				_begin_companion_idle()


func _process_disengage(delta: float) -> void:
	_disengage_timer -= delta
	_move_in_direction(_disengage_direction, RUN_SPEED, delta)
	if _disengage_timer > 0.0:
		return

	if randf() < 0.45:
		_combat_target = _find_nearest_enemy()
	elif _combat_target == null or not is_instance_valid(_combat_target):
		_combat_target = _find_nearest_enemy()

	_ai_state = AiState.CHASING


func _process_attack(delta: float) -> void:
	_attack_elapsed += delta
	_attack_timer -= delta
	_velocity_stop_horizontal()

	if _combat_target != null and is_instance_valid(_combat_target):
		_face_position(_combat_target.global_position, delta)
		_attack_direction = MeleeSwordSlashScript.get_strike_direction(self, _combat_target)
	else:
		_attack_direction = MeleeSwordSlashScript.get_strike_direction(self)

	var strike_time := _get_attack_length() * ATTACK_STRIKE_FRACTION
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		var strike_target: Node3D = _combat_target
		if strike_target == null or not is_instance_valid(strike_target):
			strike_target = MeleeSwordSlashScript.find_strike_target(
				self,
				_attack_direction
			) as Node3D
		MeleeSwordSlashScript.apply_strike(self, _attack_direction, strike_target)
		SwordCrescentFXScript.spawn_preview(self, _attack_direction, ATTACK_RANGE)

	if _attack_timer <= 0.0:
		_end_attack()


func _begin_attack(target: Node3D) -> void:
	_ai_state = AiState.ATTACKING
	_attack_elapsed = 0.0
	_attack_timer = _get_attack_length()
	_attack_struck = false
	_attack_cooldown = ATTACK_COOLDOWN
	_combat_target = target
	_locomotion_blend = 0.0
	_set_locomotion_blend(0.0)
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.set("parameters/%s/request" % BaldwinAnimConfigScript.ATTACK_ONE_SHOT, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _end_attack() -> void:
	_attack_timer = 0.0
	_attack_struck = false
	_choose_post_attack_action()


func _choose_post_attack_action() -> void:
	if _combat_target == null:
		_ai_state = AiState.CHASING
		return

	var roll := randf()
	if roll < POST_ATTACK_DISENGAGE_CHANCE:
		_begin_disengage()
		return
	if roll < POST_ATTACK_DISENGAGE_CHANCE + MELEE_BLOCK_CHANCE:
		_begin_blocking()
		return
	_begin_combat_deciding()


func _begin_disengage() -> void:
	_ai_state = AiState.DISENGAGING
	_disengage_timer = randf_range(DISENGAGE_MIN, DISENGAGE_MAX)
	_end_blocking()

	var away_from := _combat_target
	if away_from == null or not is_instance_valid(away_from):
		away_from = _find_nearest_enemy()

	if away_from != null:
		var away := global_position - away_from.global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			_disengage_direction = away.normalized()
		else:
			var angle := randf_range(0.0, TAU)
			_disengage_direction = Vector3(sin(angle), 0.0, cos(angle))
	else:
		var angle := randf_range(0.0, TAU)
		_disengage_direction = Vector3(sin(angle), 0.0, cos(angle))


func _begin_combat_deciding() -> void:
	_ai_state = AiState.COMBAT_DECIDING
	_decision_timer = randf_range(MELEE_DECISION_MIN, MELEE_DECISION_MAX)
	_end_blocking()


func _process_combat_deciding(delta: float) -> void:
	_velocity_stop_horizontal()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)

	_decision_timer -= delta
	if _decision_timer > 0.0:
		return

	if _combat_target == null or not is_instance_valid(_combat_target):
		_combat_target = _find_nearest_enemy()
	if _combat_target == null:
		_ai_state = AiState.IDLE
		return

	var to_target := _combat_target.global_position - global_position
	to_target.y = 0.0
	var in_range := to_target.length() <= ATTACK_RANGE + 0.35
	if not in_range:
		_ai_state = AiState.CHASING
		return

	var roll := randf()
	if _attack_cooldown <= 0.0 and roll < MELEE_ATTACK_CHANCE:
		_begin_attack(_combat_target)
	elif roll < MELEE_ATTACK_CHANCE + MELEE_BLOCK_CHANCE:
		_begin_blocking()
	else:
		_choose_post_attack_action()


func _begin_blocking(hold_duration := -1.0) -> void:
	if _weapon_rig != null and not _weapon_rig.is_equipped():
		_begin_combat_deciding()
		return

	_ai_state = AiState.BLOCKING
	_blocking = true
	if hold_duration > 0.0:
		_combat_state_timer = hold_duration
	else:
		_combat_state_timer = randf_range(BLOCK_DURATION_MIN, BLOCK_DURATION_MAX)
	_locomotion_blend = 0.0
	_set_locomotion_blend(0.0)
	_tween_block_hold_blend(1.0, CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_IN)
	if (
		_animation_tree != null
		and _animation_tree.active
		and _animation_player.has_animation(_shield_block_enter_path)
	):
		_animation_tree.set(
			"parameters/%s/request" % BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT,
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)


func _end_blocking(fade_duration := CombatAnimTransitionsScript.BLOCK_HOLD_BLEND_OUT) -> void:
	_blocking = false
	if fade_duration > 0.0:
		_tween_block_hold_blend(0.0, fade_duration)
	else:
		_set_block_hold_blend(0.0)


func _process_blocking(delta: float) -> void:
	_blocking = true
	_velocity_stop_horizontal()
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)

	_combat_state_timer -= delta
	if _combat_state_timer <= 0.0:
		_end_blocking()
		_begin_combat_deciding()


func _process_block_broken(delta: float) -> void:
	_velocity_stop_horizontal()
	_combat_state_timer -= delta
	if _combat_state_timer > 0.0:
		return
	_end_blocking()
	_begin_combat_deciding()


func _process_parry_stunned(delta: float) -> void:
	_velocity_stop_horizontal()
	_combat_state_timer -= delta
	if _combat_state_timer > 0.0:
		return
	_melee_stun_timer = 0.0
	_finish_parry_followup()


func _enter_parry_stun(stun_duration: float) -> void:
	_ai_state = AiState.PARRY_STUNNED
	_combat_state_timer = stun_duration
	_melee_stun_timer = stun_duration
	_blocking = false


func _finish_parry_followup() -> void:
	if _combat_target == null:
		_ai_state = AiState.CHASING
		return

	var roll := randf()
	if roll < PARRY_FOLLOWUP_ATTACK_CHANCE:
		var to_target := _combat_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > ATTACK_RANGE + 0.35:
			_ai_state = AiState.CHASING
		elif _attack_cooldown <= 0.0:
			_begin_attack(_combat_target)
		else:
			_ai_state = AiState.CHASING
		return

	if roll < PARRY_FOLLOWUP_ATTACK_CHANCE + PARRY_FOLLOWUP_REBLOCK_CHANCE:
		_begin_blocking(randf_range(PARRY_REBLOCK_HOLD_MIN, PARRY_REBLOCK_HOLD_MAX))
		return

	_begin_post_block_reposition()


func _begin_post_block_reposition() -> void:
	if _combat_target == null:
		_begin_combat_deciding()
		return

	if randf() < 0.5:
		_combat_target = _find_nearest_enemy()

	if randf() < 0.5:
		_begin_disengage()
	else:
		_begin_relocate()


func _begin_relocate() -> void:
	_ai_state = AiState.RELOCATING
	_relocate_target = _pick_relocate_point()
	if _relocate_target.distance_squared_to(global_position) < 0.25:
		_begin_combat_deciding()


func _process_relocating(delta: float) -> void:
	var to_target := _relocate_target - global_position
	to_target.y = 0.0
	if to_target.length() <= RELOCATE_ARRIVE_DIST:
		_begin_combat_deciding()
		return
	_move_toward(_relocate_target, RUN_SPEED, delta)


func _pick_relocate_point() -> Vector3:
	var center := global_position
	if _combat_target != null:
		center = _combat_target.global_position
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(3.0, 6.5)
	return center + Vector3(sin(angle), 0.0, cos(angle)) * distance


func _can_block_melee(hit_info: Dictionary) -> bool:
	return (
		_blocking
		and _ai_state == AiState.BLOCKING
		and bool(hit_info.get("melee", false))
		and _is_facing_attack(hit_info)
	)


func _on_attack_blocked(hit_info: Dictionary) -> void:
	_focus_attacker_from_hit(hit_info)
	var attacker: Node = hit_info.get("shooter")
	MeleeClashScript.resolve(self, attacker, hit_info)


func _on_shield_block_broken(hit_info: Dictionary) -> void:
	_focus_attacker_from_hit(hit_info)
	_end_blocking(0.0)
	_ai_state = AiState.BLOCK_BROKEN
	_combat_state_timer = _get_clip_length(
		BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK,
		0.85
	)
	_melee_stun_timer = _combat_state_timer
	hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
	CombatHitFlashScript.flash_damage(self)
	_play_block_break_animation()


func _focus_attacker_from_hit(hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D and is_instance_valid(attacker):
		_combat_target = attacker as Node3D


func _is_facing_attack(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return _get_flat_forward().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN

	var attack_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	attack_dir.y = 0.0
	if attack_dir.length_squared() < 0.0001:
		attack_dir = _get_flat_forward()
	return _get_flat_forward().dot(attack_dir.normalized()) <= -BLOCK_FACING_DOT_MIN


func _get_flat_forward() -> Vector3:
	var forward := -_model.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _set_block_hold_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set(
		"parameters/%s/blend_amount" % BaldwinAnimConfigScript.BLOCK_HOLD_BLEND,
		clampf(value, 0.0, 1.0)
	)


func _tween_block_hold_blend(target: float, duration: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	if _block_hold_blend_tween != null and _block_hold_blend_tween.is_valid():
		_block_hold_blend_tween.kill()
	if duration <= 0.0:
		_set_block_hold_blend(target)
		return
	_block_hold_blend_tween = CombatAnimTransitionsScript.tween_tree_float(
		self,
		_animation_tree,
		"%s/blend_amount" % BaldwinAnimConfigScript.BLOCK_HOLD_BLEND,
		target,
		duration
	)


func _get_clip_length(clip_name: StringName, fallback: float) -> float:
	var clip_path := BaldwinAnimUtilsScript.clip_path(clip_name)
	if _animation_player != null and _animation_player.has_animation(clip_path):
		return _animation_player.get_animation(clip_path).length
	return fallback


func _show_hopeless_dialog(player: Node3D) -> void:
	_talking = true
	_player_in_range = player
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		PackedStringArray(["it's all hopeless..."]),
		func() -> void:
			CompanionManager.set_baldwin_hopeless_shown(true)
			_encounter_state = EncounterState.SITTING_READY
			_end_dialog(player),
		speaker_name,
		func(_line_index: int) -> void:
			_play_baldwin_talk()
	)


func _begin_stand_up_sequence(player: Node3D) -> void:
	_busy = true
	_encounter_state = EncounterState.STANDING_UP
	_player_in_range = player
	await _play_forward_stance()
	_encounter_state = EncounterState.NORMAL
	_begin_idle()
	setup_npc_locomotion_audio()
	_show_recruit_dialog(player)
	_busy = false


func _show_recruit_dialog(player: Node3D) -> void:
	_talking = true
	_player_in_range = player
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)
	_face_position(player.global_position, 0.0)

	DialogManager.show_dialog_sequence(
		PackedStringArray([
			"But maybe it's not if someone else is also here",
			"May I join you?",
		]),
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Yes", "No"]),
				func(choice_index: int) -> void:
					if choice_index == 0:
						_on_player_accepted_companion(player)
					else:
						_on_player_declined_companion(player)
			),
		speaker_name,
		func(_line_index: int) -> void:
			_play_baldwin_talk()
	)


func _on_player_accepted_companion(player: Node3D) -> void:
	DialogManager.hide_dialog()
	_end_dialog(player)
	CompanionManager.set_recruited(CompanionManager.COMPANION_BALDWIN, true)
	var player_ref := player
	if player_ref != null:
		var stage := get_tree().current_scene
		AdventureSave.sync_runtime_state(player_ref, stage)
	_begin_companion_mode(player)


func _on_player_declined_companion(player: Node3D) -> void:
	DialogManager.hide_dialog()
	_end_dialog(player)
	_busy = true
	await _play_reverse_stance()
	CompanionManager.reset_baldwin_encounter()
	_encounter_state = EncounterState.SITTING_LOCKED
	_interact_area.monitoring = true
	_lock_sitting_pose()
	_busy = false


func _begin_companion_mode(player: Node3D) -> void:
	_encounter_state = EncounterState.COMPANION
	_companion_player = player
	_health = MAX_HEALTH
	_health_regen_timer = 0.0
	_defeated = false
	add_to_group("duel_target")
	_roam_center = player.global_position if player != null else global_position
	_roam_half_extents = Vector2(COMPANION_LEASH, COMPANION_LEASH)
	_interact_area.monitoring = false
	_setup_weapon_rig()
	_no_enemy_timer = 0.0
	_begin_companion_idle()
	setup_npc_locomotion_audio()
	if _animation_tree != null:
		_animation_tree.active = true


func _setup_weapon_rig() -> void:
	if _weapon_rig != null:
		return
	if _skeleton == null:
		return
	_weapon_rig = BaldwinWeaponRigScript.new()
	_weapon_rig.name = "BaldwinWeaponRig"
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton)


func _lock_sitting_pose() -> void:
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.active = false
	if _animation_player == null:
		return
	if _sitting_pose_anim_name.is_empty():
		return
	_animation_player.play(_sitting_pose_anim_name)
	_animation_player.seek(0.0, true)
	_animation_player.pause()


func _play_forward_stance() -> void:
	if _animation_player == null or _stance_anim_name.is_empty():
		return
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.active = false
	_animation_player.play(_stance_anim_name)
	_animation_player.speed_scale = 1.0
	await _animation_player.animation_finished
	if _animation_tree != null:
		_animation_tree.active = true


func _play_reverse_stance() -> void:
	if _animation_player == null or _stance_reverse_anim_name.is_empty():
		return
	if _animation_tree != null and _animation_tree.active:
		_animation_tree.active = false
	_animation_player.play(_stance_reverse_anim_name)
	_animation_player.speed_scale = 1.0
	await _animation_player.animation_finished
	_animation_player.stop()


func _play_baldwin_talk() -> void:
	_stop_voice()
	var stream := GameAudio.pick_baldwin_talk_voice()
	if stream == null:
		return

	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "BaldwinVoice"
	_voice_player.stream = stream
	_voice_player.max_distance = 48.0
	_voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_voice_player.unit_size = 2.0
	_voice_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
	_voice_player.volume_db = randf_range(
		-GameAudio.VOLUME_JITTER_DB * 0.5,
		GameAudio.VOLUME_JITTER_DB * 0.5
	)
	add_child(_voice_player)
	_voice_player.global_position = get_voice_world_position()
	_voice_player.finished.connect(_on_voice_finished)
	_voice_player.play()


func _stop_voice() -> void:
	if _voice_player != null and is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.queue_free()
	_voice_player = null


func _on_voice_finished() -> void:
	_stop_voice()


func _end_dialog(player: Node3D) -> void:
	_talking = false
	_stop_voice()
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)


func _setup_animations() -> void:
	if _animation_player == null:
		push_error("BaldwinNpc: missing AnimationPlayer.")
		return

	var library := AnimationLibrary.new()
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_AXE_STANCE, BaldwinAnimConfigScript.MESHY_AXE_STANCE, Animation.LOOP_NONE)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_IDLE, BaldwinAnimConfigScript.MESHY_IDLE, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_AGGRO_IDLE, BaldwinAnimConfigScript.MESHY_AGGRO_IDLE, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_WALK, BaldwinAnimConfigScript.MESHY_WALK, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_RUN, BaldwinAnimConfigScript.MESHY_RUN, Animation.LOOP_LINEAR)
	_add_merged_clip(library, BaldwinAnimConfigScript.CLIP_SWORD_SLASH, BaldwinAnimConfigScript.MESHY_SWORD_SLASH, Animation.LOOP_NONE)
	_add_shield_block_clips(library)

	var stance_path := _clip_path(BaldwinAnimConfigScript.CLIP_AXE_STANCE)
	var stance_anim := _animation_player.get_animation(stance_path)
	if stance_anim != null:
		var pose := RigAnimUtils.extract_pose_at_time(stance_anim, 0.0)
		pose.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(BaldwinAnimConfigScript.CLIP_AXE_STANCE_POSE, pose)
		var reversed := RigAnimUtils.make_reversed_animation(stance_anim)
		reversed.loop_mode = Animation.LOOP_NONE
		library.add_animation(BaldwinAnimConfigScript.CLIP_AXE_STANCE_REVERSE, reversed)

	if _animation_player.has_animation_library(BaldwinAnimConfigScript.LIBRARY):
		_animation_player.remove_animation_library(BaldwinAnimConfigScript.LIBRARY)
	_animation_player.add_animation_library(BaldwinAnimConfigScript.LIBRARY, library)

	_stance_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_AXE_STANCE)
	_stance_reverse_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_AXE_STANCE_REVERSE)
	_sitting_pose_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_AXE_STANCE_POSE)
	_attack_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_SWORD_SLASH)
	_parry_pose_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_PARRY_POSE)
	_parry_clash_anim_name = _clip_path(BaldwinAnimConfigScript.CLIP_PARRY_BACKWARD)
	_shield_block_hold_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD)
	_shield_block_enter_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER)
	_shield_block_clash_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH)
	_shield_block_break_path = _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK)
	_has_shield_block_anims = _animation_player.has_animation(_shield_block_hold_path)
	_setup_animation_tree()


func _add_shield_block_clips(library: AnimationLibrary) -> void:
	var hold := BaldwinAnimUtilsScript.load_merged_clip(
		shield_block_hold_meshy_clip,
		Animation.LOOP_LINEAR
	)
	if hold != null:
		hold.resource_name = "shield_block_hold"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD, hold)
	else:
		_add_legacy_parry_hold_clip(library)

	var enter := BaldwinAnimUtilsScript.load_merged_clip(
		shield_block_enter_meshy_clip,
		Animation.LOOP_NONE
	)
	if enter != null:
		enter.resource_name = "shield_block_enter"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER, enter)

	var clash := BaldwinAnimUtilsScript.load_merged_clip(
		shield_block_clash_meshy_clip,
		Animation.LOOP_NONE
	)
	if clash != null:
		clash.resource_name = "shield_block_clash"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH, clash)
	else:
		_add_legacy_parry_clash_clip(library)

	var block_break := BaldwinAnimUtilsScript.load_merged_clip(
		shield_block_break_meshy_clip,
		Animation.LOOP_NONE
	)
	if block_break != null:
		block_break.resource_name = "shield_block_break"
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK, block_break)


func _add_legacy_parry_hold_clip(library: AnimationLibrary) -> void:
	var parry_source := RigAnimUtils.load_skeleton_animation(
		BaldwinAnimConfigScript.MERGED_SCENE,
		parry_hold_meshy_clip
	)
	if parry_source != null:
		var hold_pose := RigAnimUtils.extract_pose_at_time(parry_source, 0.0)
		hold_pose.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD, hold_pose)
		library.add_animation(BaldwinAnimConfigScript.CLIP_PARRY_POSE, hold_pose)


func _add_legacy_parry_clash_clip(library: AnimationLibrary) -> void:
	var clash_raw := RigAnimUtils.load_skeleton_animation(
		BaldwinAnimConfigScript.MERGED_SCENE,
		parry_clash_meshy_clip
	)
	if clash_raw != null:
		var clash := RigAnimUtils.prepare_meshy_merged_clip(clash_raw, false)
		clash.loop_mode = Animation.LOOP_NONE
		library.add_animation(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH, clash)
		library.add_animation(BaldwinAnimConfigScript.CLIP_PARRY_BACKWARD, clash)
	else:
		push_warning(
			"BaldwinNpc: shield clash clip '%s' missing from merged FBX."
			% shield_block_clash_meshy_clip
		)


func _setup_animation_tree() -> void:
	var idle_path := _clip_path(BaldwinAnimConfigScript.CLIP_IDLE)
	var aggro_idle_path := _clip_path(BaldwinAnimConfigScript.CLIP_AGGRO_IDLE)
	var walk_path := _clip_path(BaldwinAnimConfigScript.CLIP_WALK)
	var run_path := _clip_path(BaldwinAnimConfigScript.CLIP_RUN)
	var attack_path := _clip_path(BaldwinAnimConfigScript.CLIP_SWORD_SLASH)
	var block_hold_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_HOLD)
	var block_enter_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_ENTER)
	var block_clash_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_CLASH)
	var block_break_path := _clip_path(BaldwinAnimConfigScript.CLIP_SHIELD_BLOCK_BREAK)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(aggro_idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
		or not _animation_player.has_animation(attack_path)
	):
		push_error("BaldwinNpc: locomotion clips missing.")
		return

	var peaceful_idle_node := AnimationNodeAnimation.new()
	peaceful_idle_node.animation = idle_path
	_idle_anim_node = peaceful_idle_node
	_peaceful_idle_path = idle_path
	_aggro_idle_path = aggro_idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(peaceful_idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 0.5)
	blend_space.add_blend_point(run_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0

	var attack_node := AnimationNodeAnimation.new()
	attack_node.animation = attack_path
	var attack_shot := AnimationNodeOneShot.new()
	CombatAnimTransitionsScript.configure_one_shot(
		attack_shot,
		CombatAnimTransitionsScript.ATTACK_FADEIN,
		CombatAnimTransitionsScript.ATTACK_FADEOUT
	)

	var block_hold_node := AnimationNodeAnimation.new()
	if _animation_player.has_animation(block_hold_path):
		block_hold_node.animation = block_hold_path
	elif _animation_player.has_animation(_parry_pose_anim_name):
		block_hold_node.animation = _parry_pose_anim_name
	var block_hold_blend := AnimationNodeBlend2.new()
	BaldwinAnimUtilsScript.configure_block_hold_blend(block_hold_blend)

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(BaldwinAnimConfigScript.LOCOMOTION_BLEND, blend_space)
	blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, block_hold_blend)
	blend_tree.add_node(&"ShieldBlockHoldAnim", block_hold_node)
	blend_tree.add_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(&"AttackAnim", attack_node)
	blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, 0, BaldwinAnimConfigScript.LOCOMOTION_BLEND)
	blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_HOLD_BLEND, 1, &"ShieldBlockHoldAnim")
	blend_tree.connect_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, 0, BaldwinAnimConfigScript.BLOCK_HOLD_BLEND)
	blend_tree.connect_node(BaldwinAnimConfigScript.ATTACK_ONE_SHOT, 1, &"AttackAnim")

	var output_node := BaldwinAnimConfigScript.ATTACK_ONE_SHOT
	if _animation_player.has_animation(block_enter_path):
		var block_enter_node := AnimationNodeAnimation.new()
		block_enter_node.animation = block_enter_path
		var block_enter_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_enter_shot,
			CombatAnimTransitionsScript.BLOCK_ENTER_FADEIN,
			CombatAnimTransitionsScript.BLOCK_ENTER_FADEOUT
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, block_enter_shot)
		blend_tree.add_node(&"ShieldBlockEnterAnim", block_enter_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, 0, BaldwinAnimConfigScript.ATTACK_ONE_SHOT)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT, 1, &"ShieldBlockEnterAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_ENTER_ONE_SHOT

	var clash_anim_path := block_clash_path
	if not _animation_player.has_animation(clash_anim_path):
		var parry_backward_path := _clip_path(BaldwinAnimConfigScript.CLIP_PARRY_BACKWARD)
		if _animation_player.has_animation(parry_backward_path):
			clash_anim_path = parry_backward_path

	if _animation_player.has_animation(clash_anim_path):
		var block_clash_node := AnimationNodeAnimation.new()
		block_clash_node.animation = clash_anim_path
		var block_clash_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_clash_shot,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEIN,
			CombatAnimTransitionsScript.PARRY_CLASH_FADEOUT,
			true
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, block_clash_shot)
		blend_tree.add_node(&"ShieldBlockClashAnim", block_clash_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT, 1, &"ShieldBlockClashAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_CLASH_ONE_SHOT
		_has_block_clash_one_shot = true

	if _animation_player.has_animation(block_break_path):
		var block_break_node := AnimationNodeAnimation.new()
		block_break_node.animation = block_break_path
		var block_break_shot := AnimationNodeOneShot.new()
		CombatAnimTransitionsScript.configure_one_shot(
			block_break_shot,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEIN,
			CombatAnimTransitionsScript.BLOCK_BREAK_FADEOUT,
			true
		)
		blend_tree.add_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, block_break_shot)
		blend_tree.add_node(&"ShieldBlockBreakAnim", block_break_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, 0, output_node)
		blend_tree.connect_node(BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT, 1, &"ShieldBlockBreakAnim")
		output_node = BaldwinAnimConfigScript.BLOCK_BREAK_ONE_SHOT

	blend_tree.connect_node(&"output", 0, output_node)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = false
	_animation_tree.set("parameters/LocomotionBlend/blend_position", 0.0)
	_animation_tree.set("parameters/BlockHoldBlend/blend_amount", 0.0)


func _set_combat_idle(active: bool) -> void:
	if _using_aggro_idle == active or _idle_anim_node == null:
		return
	_using_aggro_idle = active
	_idle_anim_node.animation = _aggro_idle_path if active else _peaceful_idle_path


func _update_combat_idle_blend(_delta: float, draw_state: BaldwinWeaponRigScript.DrawState) -> void:
	var use_aggro := draw_state == BaldwinWeaponRigScript.DrawState.EQUIPPED
	if use_aggro:
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		use_aggro = horizontal_speed <= LOCOMOTION_STOP_SPEED
	_set_combat_idle(use_aggro)


func _add_merged_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	meshy_clip: StringName,
	loop_mode: Animation.LoopMode
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(BaldwinAnimConfigScript.MERGED_SCENE, meshy_clip)
	if raw == null:
		push_error("BaldwinNpc: failed to load clip '%s'." % meshy_clip)
		return
	var animation := RigAnimUtils.prepare_meshy_merged_clip(raw, false)
	animation.loop_mode = loop_mode
	library.add_animation(clip_name, animation)


func _clip_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [BaldwinAnimConfigScript.LIBRARY, clip_name])


func _get_attack_length() -> float:
	if _animation_player == null or _attack_anim_name.is_empty():
		return 0.8
	if _animation_player.has_animation(_attack_anim_name):
		return _animation_player.get_animation(_attack_anim_name).length
	return 0.8


func _update_locomotion_blend(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var target := 0.0
	if horizontal_speed > LOCOMOTION_STOP_SPEED:
		target = 1.0 if horizontal_speed >= LOCOMOTION_RUN_SPEED else 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_set_locomotion_blend(_locomotion_blend)


func _set_locomotion_blend(value: float) -> void:
	if _animation_tree == null or not _animation_tree.active:
		return
	_animation_tree.set("parameters/LocomotionBlend/blend_position", value)


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


func _begin_companion_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_walk_direction = Vector3.ZERO
	_velocity_stop_horizontal()


func _begin_companion_walk() -> void:
	_ai_state = AiState.WALKING
	_state_timer = randf_range(walk_duration_min, walk_duration_max)
	var angle := randf_range(0.0, TAU)
	_walk_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	if _companion_player != null:
		_clamp_walk_to_leash(_companion_player.global_position)


func _move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		_velocity_stop_horizontal()
		return
	var flat_dir := direction.normalized()
	velocity.x = flat_dir.x * speed
	velocity.z = flat_dir.z * speed
	_face_direction(flat_dir, delta)


func _move_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		_velocity_stop_horizontal()
		return
	_move_in_direction(to_target.normalized(), speed, delta)


func _velocity_stop_horizontal() -> void:
	if should_preserve_knockback_velocity():
		return
	velocity.x = 0.0
	velocity.z = 0.0


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


func _enter_companion_combat() -> void:
	if _companion_combat_active:
		return
	_companion_combat_active = true
	_roam_half_extents = Vector2(
		COMPANION_LEASH * COMPANION_COMBAT_RANGE_MULT,
		COMPANION_LEASH * COMPANION_COMBAT_RANGE_MULT
	)


func _exit_companion_combat() -> void:
	if not _companion_combat_active:
		return
	_companion_combat_active = false
	_roam_half_extents = Vector2(COMPANION_LEASH, COMPANION_LEASH)


func _get_companion_leash() -> float:
	if _companion_combat_active:
		return COMPANION_LEASH * COMPANION_COMBAT_RANGE_MULT
	return COMPANION_LEASH


func _get_companion_follow_distance() -> float:
	if _companion_combat_active:
		return COMPANION_FOLLOW_DISTANCE * COMPANION_COMBAT_RANGE_MULT
	return COMPANION_FOLLOW_DISTANCE


func _get_companion_catchup_distance() -> float:
	if _companion_combat_active:
		return COMPANION_CATCHUP_DISTANCE * COMPANION_COMBAT_RANGE_MULT
	return COMPANION_CATCHUP_DISTANCE


func _get_enemy_detect_range() -> float:
	if _companion_combat_active:
		return ENEMY_DETECT_RANGE * COMPANION_COMBAT_RANGE_MULT
	return ENEMY_DETECT_RANGE


func _get_enemy_search_origin() -> Vector3:
	if (
		_companion_combat_active
		and _companion_player != null
		and is_instance_valid(_companion_player)
	):
		return _companion_player.global_position
	return global_position


func _clamp_walk_to_leash(player_pos: Vector3) -> void:
	var offset := global_position - player_pos
	offset.y = 0.0
	if offset.length() > _get_companion_leash():
		_walk_direction = (player_pos - global_position).normalized()
		_walk_direction.y = 0.0


func _face_position(target_pos: Vector3, delta: float, turn_speed: float = FACING_SPEED) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var to_target := flat_target - global_position
	if to_target.length_squared() < 0.0001:
		return
	_face_direction(to_target.normalized(), delta, turn_speed)


func _face_direction(direction: Vector3, delta: float, turn_speed: float = FACING_SPEED) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw := get_model_facing_yaw_for_direction(direction)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, turn_speed * delta)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _find_nearest_enemy() -> Node3D:
	var best: Node3D = null
	var detect_range := _get_enemy_detect_range()
	var best_dist_sq := detect_range * detect_range
	var search_origin := _get_enemy_search_origin()
	for node in get_tree().get_nodes_in_group("cave_enemy"):
		if not (node is Node3D):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		var enemy := node as Node3D
		if FactionAffinityScript.are_allies(self, enemy):
			continue
		var offset := enemy.global_position - search_origin
		offset.y = 0.0
		var dist_sq := offset.length_squared()
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = enemy
	return best


func _on_interact_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)


func _update_companion_health(delta: float) -> void:
	if _encounter_state != EncounterState.COMPANION or not _is_in_companion_combat():
		_health_regen_timer = 0.0
		return
	if _health >= MAX_HEALTH:
		_health_regen_timer = 0.0
		if _defeated:
			_recover_from_defeat()
		return

	_health_regen_timer += delta
	while _health_regen_timer >= HEALTH_REGEN_INTERVAL and _health < MAX_HEALTH:
		_health_regen_timer -= HEALTH_REGEN_INTERVAL
		_health += 1
		if _defeated and _health > 0:
			_recover_from_defeat()


func _is_in_companion_combat() -> bool:
	if _companion_combat_active:
		return true
	if _weapon_rig != null and _weapon_rig.is_equipped():
		return true
	return _find_nearest_enemy() != null


func _on_defeated(_hit_info: Dictionary) -> void:
	_defeated = true
	_combat_target = null
	_ai_state = AiState.IDLE
	_velocity_stop_horizontal()
	if _weapon_rig != null and _weapon_rig.is_equipped():
		_exit_companion_combat()
		_weapon_rig.begin_holster()
	apply_melee_stun(2.5)


func _recover_from_defeat() -> void:
	_defeated = false
	_melee_stun_timer = 0.0
