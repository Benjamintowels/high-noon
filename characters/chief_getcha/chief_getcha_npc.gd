extends "res://characters/chief_getcha/chief_getcha_actor.gd"
class_name ChiefGetchaNpc

const ChiefGetchaAnimConfigScript := preload("res://characters/chief_getcha/chief_getcha_anim_config.gd")
const MeleePunchScript := preload("res://gameplay/combat/melee_punch.gd")
const TcChargeRunScript := preload("res://characters/tc/tc_charge_run.gd")
const CombatAnimTransitionsScript := preload("res://gameplay/combat/combat_anim_transitions.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")
const AlertSymbolFXScript := preload("res://gameplay/fx/alert_symbol_fx.gd")
const BossHealthBarScript := preload("res://gameplay/ui/boss_health_bar.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const RAGDOLL_SCRIPT := preload("res://characters/groyper/groyper_ragdoll.gd")

enum Phase {
	SITTING,
	STANDING_UP,
	FIGHTING,
	DEFEATED,
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
}

enum AttackKind {
	PUNCH,
	COMBO,
	KICK,
}

const GRAVITY := 22.0
const FACING_SPEED := 10.0
const WALK_SPEED := 3.8
const RUN_SPEED := 5.5
const BLEND_SPEED := 8.0
const MAX_HEALTH := 15
const ATTACK_RANGE := 2.1
const DETECT_RANGE := 28.0
const PUNCH_DAMAGE := 0.75
const KICK_DAMAGE := 1.0

const BRAWL_DECISION_MIN := 0.5
const BRAWL_DECISION_MAX := 1.5
const BRAWL_BLOCK_CHANCE := 0.38
const BRAWL_BLOCK_MIN := 1.4
const BRAWL_BLOCK_MAX := 2.6
const BRAWL_ROLL_CHANCE := 0.35
const BRAWL_RETREAT_CHANCE := 0.3
const BRAWL_RETREAT_DURATION := 1.6
const BRAWL_RETREAT_RANGE := 4.5
const BRAWL_PURSUE_STOP_RANGE := 1.7
const BRAWL_PUNCH_COOLDOWN_MULT_MIN := 1.7
const BRAWL_PUNCH_COOLDOWN_MULT_MAX := 2.8
const PUNCH_TELEGRAPH_TIME := 1.0
const PUNCHED_BLOCK_CHANCE := 0.65
const PUNCHED_BLOCK_MIN := 1.5
const PUNCHED_BLOCK_MAX := 3.0
const MELEE_COMBO_CHANCE := 0.55
const CHARGE_RUN_CHANCE := 0.16
const ROLL_SPEED := 6.2
const BLOCK_FACING_DOT_MIN := 0.32
const ALERT_HEAD_OFFSET := 2.1

const FIGHT_LINES: PackedStringArray = [
	"You dare disturb my prayer?",
	"Then let us settle this the old way.",
]

@export var speaker_name := "Chief Getcha"

@onready var _interact_area: Area3D = $InteractArea

var _phase := Phase.SITTING
var _ai_state := AiState.CHASE
var _combat_target: Node3D
var _health := MAX_HEALTH
var _defeated := false
var _blocking := false
var _attack_kind := AttackKind.PUNCH
var _attack_elapsed := 0.0
var _attack_timer := 0.0
var _attack_struck := false
var _attack_direction := Vector3.FORWARD
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
var _combo_pending := false
var _move_blend := 0.0
var _walk_run_blend := 0.0
var _block_blend := 0.0
var _sit_hold_position := Vector3.ZERO
var _player_in_range: Node3D
var _talking := false
var _fight_started := false
var _boss_health_bar
var _ragdoll
var _voice_player: AudioStreamPlayer3D
var _melee_hit_absorbed := false


func _on_actor_ready() -> void:
	add_to_group("chief_getcha_boss")
	add_to_group("cave_enemy")
	add_to_group("duel_target")
	add_to_group("faction_npc")
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
	if _defeated:
		return

	tick_melee_stun(delta)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_charge_cooldown = maxf(_charge_cooldown - delta, 0.0)

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

	move_and_slide()

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var sprinting := _ai_state in [AiState.CHASE, AiState.CHARGE_RUN] and horizontal_speed > WALK_SPEED * 0.9
	var moving := horizontal_speed > 0.05 and _phase == Phase.FIGHTING
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


func is_defeated() -> bool:
	return _defeated


func get_combat_health() -> int:
	return _health


func get_combat_max_health() -> int:
	return MAX_HEALTH


func was_melee_hit_absorbed() -> bool:
	return _melee_hit_absorbed


func is_unarmed_blocking() -> bool:
	return _blocking and _block_blend > 0.35


func is_facing_punch_block(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	var facing := get_punch_facing_direction()
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001 and facing.length_squared() > 0.0001:
			return facing.normalized().dot(to_attacker.normalized()) >= BLOCK_FACING_DOT_MIN
	return true


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

	_melee_hit_absorbed = false
	var consider_reactive_block := (
		bool(hit_info.get("punch_hit", false))
		and not _blocking
		and not _defeated
	)

	if _can_block_hit(hit_info):
		_melee_hit_absorbed = true
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

	if consider_reactive_block and not _defeated and randf() < PUNCHED_BLOCK_CHANCE:
		_begin_blocking(randf_range(PUNCHED_BLOCK_MIN, PUNCHED_BLOCK_MAX))


func get_bullet_capsule() -> Dictionary:
	return GroyperBodyUtils.get_town_bullet_capsule(_skeleton, global_position, 1.8, 2.4)


func get_head_hit_sphere() -> Dictionary:
	return GroyperBodyUtils.get_town_head_hit_sphere(_skeleton, global_position, 0.9)


func get_threat_aim_point() -> Vector3:
	return GroyperBodyUtils.get_threat_aim_point(_skeleton, global_position)


func reset_for_bonfire_rest() -> void:
	if _fight_started and not _defeated:
		return
	_reset_boss_state()


func _reset_boss_state() -> void:
	_defeated = false
	_fight_started = false
	_talking = false
	_phase = Phase.SITTING
	_ai_state = AiState.CHASE
	_health = MAX_HEALTH
	_blocking = false
	_attack_cooldown = 0.0
	_charge_cooldown = 0.0
	_punch_telegraph_timer = 0.0
	_retreat_timer = 0.0
	velocity = Vector3.ZERO
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
	if _player_in_range != null and is_instance_valid(_player_in_range):
		_face_position(_player_in_range.global_position, delta)


func _process_standing_up(delta: float) -> void:
	velocity = Vector3.ZERO
	if _combat_target != null:
		_face_position(_combat_target.global_position, delta)
	_state_timer -= delta
	if _state_timer > 0.0:
		return
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


func _begin_boss_fight(player: Node3D) -> void:
	if _fight_started or _defeated or player == null:
		return

	_fight_started = true
	_combat_target = player
	_interact_area.monitoring = false
	if player.has_method("enter_overworld_combat"):
		player.enter_overworld_combat()
	_boss_health_bar = BossHealthBarScript.attach_to(self, speaker_name)
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


func _play_stand_up() -> void:
	if _animation_player == null:
		_phase = Phase.FIGHTING
		_setup_combat_animation_tree()
		return
	_setup_stand_up_clip()
	var stand_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_STAND_UP)
	if not _animation_player.has_animation(stand_path):
		_phase = Phase.FIGHTING
		_setup_combat_animation_tree()
		return
	var anim := _animation_player.get_animation(stand_path)
	_state_timer = maxf(anim.length * 0.5, 0.8)
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
	if to_target.length() > ATTACK_RANGE + 0.5:
		_ai_state = AiState.CHASE
		return

	_decide_brawl_action()


func _decide_brawl_action() -> void:
	if (
		_charge_cooldown <= 0.0
		and TcChargeRunScript.can_cast(_charge_cooldown)
		and _combat_target != null
		and TcChargeRunScript.is_in_range(self, _combat_target)
		and randf() < CHARGE_RUN_CHANCE
	):
		_begin_charge_windup()
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
	if _attack_cooldown <= 0.0:
		_begin_punch_telegraph()
		return
	_ai_state = AiState.CHASE


func _process_blocking(delta: float) -> void:
	_blocking = true
	_block_blend = lerpf(_block_blend, 1.0, BLEND_SPEED * delta)
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

	var strike_fraction := _get_attack_strike_fraction()
	var strike_time := _get_attack_length() * strike_fraction
	if not _attack_struck and _attack_elapsed >= strike_time:
		_attack_struck = true
		_apply_attack_strike()

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
	_begin_attack_windup(AttackKind.PUNCH)


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
	_attack_direction = _flat_direction_to(
		_combat_target.global_position if _combat_target != null else global_position + Vector3.FORWARD
	)
	var anim_name := _attack_anim_name(_attack_kind)
	var anim_path := _clip_path(anim_name)
	var length := 1.0
	if _animation_player != null and _animation_player.has_animation(anim_path):
		length = _animation_player.get_animation(anim_path).length
	_attack_timer = maxf(length * 0.5, 0.55)
	_fire_attack_one_shot(anim_path)


func _end_attacking() -> void:
	if _combo_pending and _attack_kind == AttackKind.PUNCH:
		_combo_pending = false
		_begin_attack_windup(AttackKind.COMBO)
		return
	_attack_struck = false
	_attack_cooldown = MeleePunchScript.COOLDOWN * randf_range(
		BRAWL_PUNCH_COOLDOWN_MULT_MIN,
		BRAWL_PUNCH_COOLDOWN_MULT_MAX
	)
	_ai_state = AiState.DECIDING
	_roll_decision_timer()


func _apply_attack_strike() -> void:
	var damage := PUNCH_DAMAGE
	if _attack_kind == AttackKind.KICK:
		damage = KICK_DAMAGE
	elif _attack_kind == AttackKind.COMBO:
		damage = PUNCH_DAMAGE * 1.15
	MeleePunchScript.apply_strike(
		self,
		_attack_direction,
		_combat_target,
		{
			"damage": damage,
			"knockdown": _attack_kind == AttackKind.KICK,
			"face_punch_reaction": _attack_kind == AttackKind.PUNCH,
		}
	)
	velocity.x += _attack_direction.x * MeleePunchScript.LUNGE_SPEED * 0.65
	velocity.z += _attack_direction.z * MeleePunchScript.LUNGE_SPEED * 0.65
	if _attack_kind == AttackKind.PUNCH and randf() < MELEE_COMBO_CHANCE:
		_combo_pending = true


func _begin_blocking(duration: float = -1.0) -> void:
	_ai_state = AiState.BLOCKING
	_blocking = true
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
	if not _blocking:
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
	if _defeated:
		return
	_defeated = true
	_phase = Phase.DEFEATED
	_velocity_zero()
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudioScript.play_death_sound(self, hit_position)
	_activate_defeat_ragdoll(hit_info)


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
		_suspend_locomotion_animations()
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
	_ensure_clip_library()
	for clip_name: StringName in [
		ChiefGetchaAnimConfigScript.CLIP_IDLE,
		ChiefGetchaAnimConfigScript.CLIP_WALK,
		ChiefGetchaAnimConfigScript.CLIP_RUN,
		ChiefGetchaAnimConfigScript.CLIP_BLOCK,
		ChiefGetchaAnimConfigScript.CLIP_PUNCH,
		ChiefGetchaAnimConfigScript.CLIP_COMBO,
		ChiefGetchaAnimConfigScript.CLIP_KICK,
		ChiefGetchaAnimConfigScript.CLIP_CHARGE,
		ChiefGetchaAnimConfigScript.CLIP_ROLL,
		ChiefGetchaAnimConfigScript.CLIP_HIT,
	]:
		_add_runtime_clip(clip_name, _meshy_for_clip(clip_name), clip_name != ChiefGetchaAnimConfigScript.CLIP_HIT)

	var idle_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_IDLE)
	var walk_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_WALK)
	var run_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_RUN)
	var block_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_BLOCK)
	var punch_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_PUNCH)
	var roll_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_ROLL)
	var hit_path := _clip_path(ChiefGetchaAnimConfigScript.CLIP_HIT)

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path
	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path
	var block_pose_node := AnimationNodeAnimation.new()
	block_pose_node.animation = block_path
	var punch_node := AnimationNodeAnimation.new()
	punch_node.animation = punch_path
	var roll_node := AnimationNodeAnimation.new()
	roll_node.animation = roll_path
	var hit_node := AnimationNodeAnimation.new()
	hit_node.animation = hit_path

	var walk_run_space := AnimationNodeBlendSpace1D.new()
	walk_run_space.add_blend_point(walk_node, 0.0)
	walk_run_space.add_blend_point(run_node, 1.0)
	walk_run_space.min_space = 0.0
	walk_run_space.max_space = 1.0

	var move_blend := AnimationNodeBlend2.new()
	move_blend.sync = true
	var block_blend := AnimationNodeBlend2.new()
	block_blend.sync = true

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
	blend_tree.add_node(&"IdleAnim", idle_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.BLOCK_BLEND_NODE, block_blend)
	blend_tree.add_node(&"BlockPoseAnim", block_pose_node)
	blend_tree.add_node(ChiefGetchaAnimConfigScript.ATTACK_ONE_SHOT, attack_shot)
	blend_tree.add_node(&"AttackAnim", punch_node)
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

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_animation_player.stop()
	_set_move_blend(0.0)
	_set_walk_run_blend(0.0)
	_set_block_blend(0.0)


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
		ChiefGetchaAnimConfigScript.CLIP_BLOCK:
			return ChiefGetchaAnimConfigScript.MESHY_BLOCK
		ChiefGetchaAnimConfigScript.CLIP_PUNCH:
			return ChiefGetchaAnimConfigScript.MESHY_PUNCH
		ChiefGetchaAnimConfigScript.CLIP_COMBO:
			return ChiefGetchaAnimConfigScript.MESHY_COMBO
		ChiefGetchaAnimConfigScript.CLIP_KICK:
			return ChiefGetchaAnimConfigScript.MESHY_KICK
		ChiefGetchaAnimConfigScript.CLIP_CHARGE:
			return ChiefGetchaAnimConfigScript.MESHY_CHARGE
		ChiefGetchaAnimConfigScript.CLIP_ROLL:
			return ChiefGetchaAnimConfigScript.MESHY_ROLL
		ChiefGetchaAnimConfigScript.CLIP_HIT:
			return ChiefGetchaAnimConfigScript.MESHY_HIT
		_:
			return ChiefGetchaAnimConfigScript.MESHY_IDLE


func _attack_anim_name(kind: AttackKind) -> StringName:
	match kind:
		AttackKind.COMBO:
			return ChiefGetchaAnimConfigScript.CLIP_COMBO
		AttackKind.KICK:
			return ChiefGetchaAnimConfigScript.CLIP_KICK
		_:
			return ChiefGetchaAnimConfigScript.CLIP_PUNCH


func _get_attack_strike_fraction() -> float:
	match _attack_kind:
		AttackKind.COMBO:
			return ChiefGetchaAnimConfigScript.COMBO_STRIKE_FRACTION
		AttackKind.KICK:
			return ChiefGetchaAnimConfigScript.KICK_STRIKE_FRACTION
		_:
			return ChiefGetchaAnimConfigScript.PUNCH_STRIKE_FRACTION


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
	_animation_tree.set(&"parameters/AttackAnim/animation", anim_path)
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
	if _animation_tree != null:
		_animation_tree.active = true
	if _animation_player != null:
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
