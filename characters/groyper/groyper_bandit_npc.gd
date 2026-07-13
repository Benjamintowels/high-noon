extends GroyperTownNpc
class_name GroyperBanditNpc

const BANDIT_HAT_COLOR := Color(0.72, 0.18, 0.14)

enum BanditAggroMode {
	HARASS,
	WARN,
	MELEE,
	GUN,
}

const MELEE_DECISION_MIN := 0.5
const MELEE_DECISION_MAX := 1.5
const MELEE_ATTACK_CHANCE := 0.42
const MELEE_BLOCK_CHANCE := 0.22
const MELEE_ROLL_CHANCE := 0.28
const MELEE_BLOCK_MIN := 0.9
const MELEE_BLOCK_MAX := 1.8
const MELEE_PUNCH_TELEGRAPH_TIME := 1.0
const PUNCHED_BLOCK_CHANCE := 0.65
const PUNCHED_BLOCK_MIN := 1.5
const PUNCHED_BLOCK_MAX := 3.0
const MELEE_COMBO_CHANCE := 0.55
const MELEE_PURSUE_STOP_RANGE := 1.35
const HARASS_TAUNT_INTERVAL_MIN := 2.2
const HARASS_TAUNT_INTERVAL_MAX := 4.0

# Softer tuning for melee_only brawlers (the tutorial fight): slower
# decisions, more blocking/dodging, occasional retreats, spaced-out punches.
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

@export var aggro_range := 18.0
@export var bandit_hat_color := BANDIT_HAT_COLOR
## When true this NPC can never draw a gun or rally its faction: every
## escalation path (on-sight, getting hit, scenario calls) stays unarmed melee.
@export var melee_only := false

var _bandit_aggro_mode := BanditAggroMode.HARASS
var _harass_target: Node3D
var _harass_taunt_timer := 0.0
var _melee_decision_timer := 0.0
var _melee_punch_telegraph_timer := 0.0
var _melee_blocking := false
var _melee_block_timer := 0.0
var _punch_combo_step := MeleePunch.ComboStep.HOOK
var _punch_combo_pending := false
var _last_stand_triggered := false
var _melee_opening_rush := false
var _melee_retreat_timer := 0.0
var _torch_hand_visual: Node3D


func _ready() -> void:
	random_hat_color = false
	hat_color = bandit_hat_color
	faction_on_sight_aggro_range = aggro_range
	# Melee-only brawlers are Top Ranch hands, not bandits — the bandit
	# faction would make every BECKER_BOYS NPC in sight open fire on them.
	if not melee_only:
		add_to_group("bandit")
	super._ready()
	if melee_only and _weapon_rig != null:
		_weapon_rig.call_deferred("clear_weapon_visual")


## Canyon spawns stamp shard min/max via meta. Armed bandits default higher.
func get_kill_loot_soul_shards() -> int:
	var shard_min := int(get_meta(&"canyon_soul_shard_min", -1))
	var shard_max := int(get_meta(&"canyon_soul_shard_max", -1))
	if shard_min >= 0 and shard_max >= shard_min:
		return randi_range(shard_min, shard_max)
	if melee_only:
		return randi_range(1, 2)
	return -1


func get_faction_id() -> StringName:
	# Hotel brawl melee_only uses Top Ranch so bandits don't gun them down.
	# Canyon raiders stay Bandits even when unarmed so they don't murder each other.
	if melee_only and not bool(get_meta(&"canyon_raider", false)):
		return FactionIds.TOP_RANCH
	return FactionIds.BANDITS


## Mark as canyon raider so on-sight aggro works (town HARASS/WARN blocks do not).
func prepare_canyon_raider() -> void:
	set_meta(&"canyon_raider", true)
	_harass_target = null


## Attach a lit torch to the right hand (visual + light only — combat stays unarmed).
func equip_handheld_torch() -> void:
	call_deferred("_attach_torch_hand_visual")


func _attach_torch_hand_visual() -> void:
	if _defeated or _skeleton == null:
		return
	GroyperBodyUtils.ensure_melee_mounts(_skeleton)
	var hand_mount := _skeleton.get_node_or_null("HandTorchMount") as Node3D
	if hand_mount == null:
		return
	_torch_hand_visual = hand_mount.get_node_or_null("GripOffset/TorchGrip") as Node3D
	if _torch_hand_visual == null:
		_torch_hand_visual = hand_mount.get_node_or_null("TorchGrip") as Node3D
	if _torch_hand_visual != null:
		_torch_hand_visual.visible = true


func is_ambient_freezable() -> bool:
	# Canyon spawns often start above Terrain3D with no nearby prop collision.
	# Freezing them mid-air stops gravity, so they never fall onto the ground.
	if bool(get_meta(&"canyon_raider", false)):
		return false
	return super.is_ambient_freezable()


var _canyon_terrain: Terrain3D


## Terrain3D Dynamic collision is camera-local. Canyon raiders outside that
## radius fall through the world unless we clamp to the heightmap.
func _clamp_canyon_raider_to_terrain() -> void:
	if not bool(get_meta(&"canyon_raider", false)) or _defeated:
		return
	if is_on_floor():
		return
	if _canyon_terrain == null or not is_instance_valid(_canyon_terrain):
		_canyon_terrain = _find_stage_terrain3d()
	if _canyon_terrain == null or _canyon_terrain.data == null:
		return
	var height: float = _canyon_terrain.data.get_height(global_position)
	if is_nan(height):
		return
	var floor_y := height - GroyperBodyUtils.get_collision_feet_offset(self)
	if global_position.y <= floor_y:
		global_position.y = floor_y
		velocity.y = 0.0


func _find_stage_terrain3d() -> Terrain3D:
	var node: Node = self
	while node != null:
		var direct := node.get_node_or_null("Terrain/Terrain3D")
		if direct is Terrain3D:
			return direct as Terrain3D
		node = node.get_parent()
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.find_child("Terrain3D", true, false) as Terrain3D


## Immediate player hostility for canyon encounters (no harass/warn warmup).
func arm_canyon_hostility(player: Node3D = null) -> void:
	if _defeated:
		return
	if player == null or not is_instance_valid(player):
		player = _find_player()
	if player == null or not is_instance_valid(player):
		return
	prepare_canyon_raider()
	if melee_only or (
		_weapon_rig != null
		and GroyperWeapons.is_melee(_weapon_rig.get_equipped_weapon_id())
	):
		enter_melee_aggro(player)
		begin_melee_opening_rush()
	else:
		escalate_to_gun_aggro(player)


func begin_harass_groypette(groypette: Node3D) -> void:
	_bandit_aggro_mode = BanditAggroMode.HARASS
	_harass_target = groypette
	_harass_taunt_timer = randf_range(HARASS_TAUNT_INTERVAL_MIN, HARASS_TAUNT_INTERVAL_MAX)
	_aim_target = groypette
	_ai_state = AiState.STARING
	_velocity_zero()
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.begin_holster()


func resume_harass_groypette(groypette: Node3D) -> void:
	_combat_active = false
	_faction_aggro_level = 0
	_faction_provoker = null
	_has_locked_aim = false
	_player_weapon_threat_active = false
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.begin_holster()
	begin_harass_groypette(groypette)


func begin_warn_player(player: Node3D) -> void:
	_bandit_aggro_mode = BanditAggroMode.WARN
	_harass_target = null
	_aim_target = player
	_ai_state = AiState.STARING
	_velocity_zero()
	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.begin_holster()


func end_warn_player(groypette: Node3D) -> void:
	if _defeated:
		return
	resume_harass_groypette(groypette)


func _exit_combat_peaceful() -> void:
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		return
	super._exit_combat_peaceful()


func _is_combat_target_out_of_engagement_range() -> bool:
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		if _aim_target == null or not is_instance_valid(_aim_target):
			return true
		return _get_horizontal_distance_to(_aim_target) > aggro_range * 1.75
	return super._is_combat_target_out_of_engagement_range()


func _begin_combat_approach() -> void:
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		if _aim_target == null:
			return
		_combat_move_pursue = true
		_ai_state = AiState.COMBAT_MOVING
		_sync_combat_nav_target_to(_aim_target)
		return
	super._begin_combat_approach()


func _can_begin_combat_aiming() -> bool:
	# Fists don't aim: without this, pursue movement flips into the gun
	# COMBAT_AIMING stance whenever the target has line of sight, so melee
	# brawlers stand off at range instead of charging in.
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		return false
	return super._can_begin_combat_aiming()


func _apply_combat_pursue_movement(delta: float) -> void:
	if _bandit_aggro_mode != BanditAggroMode.MELEE:
		super._apply_combat_pursue_movement(delta)
		return

	# Direct chase for fist fights. The nav-based pursue assumes a baked
	# navmesh; without one its stuck-recovery issues flank relocations that
	# send brawlers sprinting away (interiors have no navmesh at all).
	if _aim_target == null or not is_instance_valid(_aim_target):
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if _is_combat_target_out_of_engagement_range():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if _melee_retreat_timer > 0.0:
		_melee_retreat_timer -= delta
		var away := global_position - _aim_target.global_position
		away.y = 0.0
		if away.length() >= BRAWL_RETREAT_RANGE or away.length_squared() < 0.0001:
			_melee_retreat_timer = 0.0
		else:
			var back := away.normalized()
			velocity.x = back.x * RUN_SPEED * 0.85
			velocity.z = back.z * RUN_SPEED * 0.85
			_face_position(global_position + back, delta)
			return

	if _should_try_combat_punch() and _try_start_combat_punch():
		return

	var to_target := _aim_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var stop_range := BRAWL_PURSUE_STOP_RANGE if melee_only else MELEE_PURSUE_STOP_RANGE
	if distance <= stop_range or distance < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		if _aim_target != null:
			_face_position(_aim_target.global_position, delta)
		return

	var dir := to_target.normalized()
	velocity.x = dir.x * RUN_SPEED
	velocity.z = dir.z * RUN_SPEED
	_face_position(global_position + dir, delta)


func enter_melee_aggro(player: Node3D) -> void:
	_bandit_aggro_mode = BanditAggroMode.MELEE
	_harass_target = null
	_enter_unarmed_combat(player)
	_melee_opening_rush = false
	_roll_melee_decision_timer()


func on_hostage_released_by_player(player: Node3D) -> void:
	if _defeated or player == null or not is_instance_valid(player):
		return
	enter_melee_aggro(player)
	if _aggro_voice != null and _aggro_voice.has_method("play_gropyptalk_now"):
		_aggro_voice.play_gropyptalk_now()


func begin_melee_opening_rush() -> void:
	if _defeated or _bandit_aggro_mode != BanditAggroMode.MELEE:
		return
	_melee_opening_rush = true
	_melee_decision_timer = 0.0


func escalate_to_gun_aggro(player: Node3D) -> void:
	if _defeated or _bandit_aggro_mode == BanditAggroMode.GUN:
		return
	if melee_only:
		if _bandit_aggro_mode != BanditAggroMode.MELEE and player != null:
			enter_melee_aggro(player)
		return
	_end_melee_block()
	_melee_punch_telegraph_timer = 0.0
	if _weapon_rig != null:
		_weapon_rig.set_gun_arm_released_for_pose(false)
	_bandit_aggro_mode = BanditAggroMode.GUN
	release_ambush_hold()
	set_faction_aggro_level(3, player)


func try_last_stand_gun_aggro(player: Node3D) -> void:
	if _last_stand_triggered or _defeated or melee_only:
		return
	_last_stand_triggered = true
	if _aggro_voice != null and _aggro_voice.has_method("play_woah_now"):
		_aggro_voice.play_woah_now()
	escalate_to_gun_aggro(player)


func is_in_melee_aggro() -> bool:
	return _bandit_aggro_mode == BanditAggroMode.MELEE


func is_unarmed_blocking() -> bool:
	return super.is_unarmed_blocking() and _bandit_aggro_mode == BanditAggroMode.MELEE


func is_facing_punch_block(hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	var facing := get_punch_facing_direction()
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001 and facing.length_squared() > 0.0001:
			return facing.normalized().dot(to_attacker.normalized()) >= 0.32
	return true


func receive_bullet_hit(hit_info: Dictionary) -> void:
	var consider_reactive_block := (
		is_in_melee_aggro()
		and bool(hit_info.get("punch_hit", false))
		and not _melee_blocking
		and not _defeated
	)
	super.receive_bullet_hit(hit_info)
	if consider_reactive_block and not _defeated and randf() < PUNCHED_BLOCK_CHANCE:
		_begin_melee_block(randf_range(PUNCHED_BLOCK_MIN, PUNCHED_BLOCK_MAX))


func is_in_harass_mode() -> bool:
	return _bandit_aggro_mode == BanditAggroMode.HARASS


func _physics_process(delta: float) -> void:
	if _bandit_aggro_mode == BanditAggroMode.HARASS and not _defeated:
		_process_harass_mode(delta)
	if _melee_blocking:
		_update_melee_block(delta)
	super._physics_process(delta)
	_clamp_canyon_raider_to_terrain()


func _process(delta: float) -> void:
	if _bandit_aggro_mode in [BanditAggroMode.MELEE, BanditAggroMode.GUN] and not _defeated:
		_check_gun_escalation()
	super._process(delta)


func _update_combat_ai(delta: float) -> void:
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		_update_melee_aggro_ai(delta)
		return
	if _bandit_aggro_mode == BanditAggroMode.HARASS or _bandit_aggro_mode == BanditAggroMode.WARN:
		return
	super._update_combat_ai(delta)


func _check_outsider_player_threat() -> void:
	if _ambush_hold_active and _bandit_aggro_mode != BanditAggroMode.GUN:
		return
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		var player := _find_player()
		if player != null and _is_player_weapon_threatening_target(player, self):
			escalate_to_gun_aggro(player)
		return
	super._check_outsider_player_threat()


func _try_aggro_hostile_on_sight() -> bool:
	# Canyon raiders: town HARASS/WARN + melee_only blocks are for the hotel
	# brawl / groypette hostage flow. Canyon bandits should open on the player
	# the moment they enter aggro range.
	if bool(get_meta(&"canyon_raider", false)):
		if _defeated or _combat_active or _ambush_hold_active:
			return false
		var target := _pick_nearest_hostile_faction_member(faction_on_sight_aggro_range)
		if target == null:
			return false
		arm_canyon_hostility(target)
		return true
	if melee_only:
		return false
	if _ambush_hold_active or _bandit_aggro_mode in [BanditAggroMode.HARASS, BanditAggroMode.WARN]:
		return false
	return super._try_aggro_hostile_on_sight()


func set_faction_aggro_level(level: int, target: Node3D = null, play_alert_voice := true) -> void:
	if melee_only and level >= 2:
		if _bandit_aggro_mode != BanditAggroMode.MELEE and target != null and not _defeated:
			enter_melee_aggro(target)
		return
	super.set_faction_aggro_level(level, target, play_alert_voice)


func _react_to_hostile_shooter(
	shooter: Node3D,
	killed: bool,
	hit_info: Dictionary = {}
) -> void:
	if melee_only:
		if killed or shooter == null or not is_instance_valid(shooter):
			return
		if _bandit_aggro_mode != BanditAggroMode.MELEE:
			enter_melee_aggro(shooter)
		return
	super._react_to_hostile_shooter(shooter, killed, hit_info)


func is_unarmed_melee_attacking() -> bool:
	if super.is_unarmed_melee_attacking():
		return true
	return _melee_punch_telegraph_timer > 0.0


func _should_try_combat_punch() -> bool:
	if _bandit_aggro_mode != BanditAggroMode.MELEE:
		return false
	if _melee_blocking or _unarmed_block_blend > 0.35 or _face_punch_reaction_active:
		return false
	if _melee_punch_telegraph_timer > 0.0:
		return false
	return super._should_try_combat_punch()


func _start_combat_punch() -> bool:
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		_punch_combo_step = MeleePunch.ComboStep.HOOK
		_punch_combo_pending = false
	var started := super._start_combat_punch()
	if started and melee_only:
		# Space brawl punches out so three brawlers don't all swing at once.
		_punch_cooldown = MeleePunch.COOLDOWN * randf_range(
			BRAWL_PUNCH_COOLDOWN_MULT_MIN,
			BRAWL_PUNCH_COOLDOWN_MULT_MAX
		)
	return started


func _apply_punch_strike_if_ready() -> void:
	if not _punch_active or _punch_exit_active or _punch_strike_applied:
		return
	if _punch_timer < MeleePunchScript.get_windup_duration():
		return

	_punch_strike_applied = true
	var knockdown := _punch_combo_step == MeleePunch.ComboStep.ELBOW_FIRST
	MeleePunchScript.apply_strike(
		self,
		_punch_direction,
		_aim_target,
		{
			"damage": MeleePunchScript.BANDIT_PUNCH_DAMAGE,
			"knockdown": knockdown,
			"face_punch_reaction": not knockdown,
		}
	)
	velocity.x += _punch_direction.x * MeleePunchScript.LUNGE_SPEED
	velocity.z += _punch_direction.z * MeleePunchScript.LUNGE_SPEED

	if (
		_bandit_aggro_mode == BanditAggroMode.MELEE
		and _punch_combo_step == MeleePunch.ComboStep.HOOK
		and randf() < MELEE_COMBO_CHANCE
	):
		_punch_combo_pending = true


func _finish_punch() -> void:
	if _punch_combo_pending and _bandit_aggro_mode == BanditAggroMode.MELEE:
		_punch_combo_pending = false
		_begin_melee_combo_punch()
		return
	super._finish_punch()
	if _bandit_aggro_mode == BanditAggroMode.MELEE:
		_roll_melee_decision_timer()


func _update_punch_overlay(delta: float) -> void:
	super._update_punch_overlay(delta)


func _begin_melee_combo_punch() -> bool:
	_punch_combo_step = MeleePunch.ComboStep.ELBOW_FIRST
	var anim_path := PunchPoseConfig.get_elbow_strike_path()
	if _animation_player == null or not _animation_player.has_animation(anim_path):
		return false

	var animation := _animation_player.get_animation(anim_path)
	_punch_duration = MeleePunchScript.get_attack_duration_for_step(
		_punch_combo_step,
		animation.length
	)
	_punch_timer = 0.0
	_punch_active = true
	_punch_strike_applied = false
	_punch_direction = get_punch_facing_direction()
	_punch_cooldown = MeleePunchScript.COOLDOWN
	_punch_blend = 0.0
	_punch_exit_active = false

	if _punch_anim_node != null:
		_punch_anim_node.animation = anim_path
	_init_punch_animation_tree_state()
	return true


func _process_harass_mode(delta: float) -> void:
	if _harass_target == null or not is_instance_valid(_harass_target):
		return
	_aim_target = _harass_target
	_ai_state = AiState.STARING
	_face_position(_harass_target.global_position, delta)
	_harass_taunt_timer -= delta
	if _harass_taunt_timer <= 0.0:
		_harass_taunt_timer = randf_range(HARASS_TAUNT_INTERVAL_MIN, HARASS_TAUNT_INTERVAL_MAX)
		_play_harass_taunt()


func _play_harass_taunt() -> void:
	if _punch_active or _defeated:
		return
	_start_combat_punch()
	_punch_strike_applied = true


func _update_melee_aggro_ai(delta: float) -> void:
	if not _combat_active:
		_enter_unarmed_combat(_aim_target)
	_refresh_combat_target_if_needed()
	if _aim_target == null:
		return

	if _melee_punch_telegraph_timer > 0.0:
		_update_melee_punch_telegraph(delta)
		return

	if _melee_blocking:
		return

	_melee_decision_timer -= delta
	if _melee_decision_timer > 0.0:
		return

	if _melee_opening_rush:
		_melee_opening_rush = false
		_roll_melee_decision_timer()
		_combat_move_pursue = true
		_ai_state = AiState.COMBAT_MOVING
		_sync_combat_nav_target_to(_aim_target)
		_begin_melee_punch_telegraph()
		return

	_roll_melee_decision_timer()
	_combat_move_pursue = true
	_ai_state = AiState.COMBAT_MOVING
	_sync_combat_nav_target_to(_aim_target)
	if melee_only:
		_decide_brawl_action()
		return
	if _should_try_combat_punch():
		_begin_melee_punch_telegraph()
		return
	if randf() < MELEE_BLOCK_CHANCE:
		_begin_melee_block()
		return
	if randf() < MELEE_ROLL_CHANCE:
		_try_combat_roll_away_from(_aim_target.global_position, 1.0)
		return
	_begin_combat_approach()


## Brawl tutorial pacing: defensive options roll first, so most decision
## ticks end in a block, dodge, or retreat rather than another rush.
func _decide_brawl_action() -> void:
	if randf() < BRAWL_BLOCK_CHANCE:
		_begin_melee_block(randf_range(BRAWL_BLOCK_MIN, BRAWL_BLOCK_MAX))
		return
	if randf() < BRAWL_ROLL_CHANCE:
		_try_combat_roll_away_from(_aim_target.global_position, 1.0)
		return
	if randf() < BRAWL_RETREAT_CHANCE:
		_melee_retreat_timer = BRAWL_RETREAT_DURATION
		return
	if _should_try_combat_punch():
		_begin_melee_punch_telegraph()
		return
	_begin_combat_approach()


func _begin_melee_punch_telegraph() -> void:
	if not _should_try_combat_punch():
		_begin_combat_approach()
		return
	_velocity_zero()
	_combat_move_pursue = false
	_ai_state = AiState.STARING
	if _aim_target != null:
		_face_position(_aim_target.global_position, get_physics_process_delta_time())
	_show_alert_fx()
	_melee_punch_telegraph_timer = MELEE_PUNCH_TELEGRAPH_TIME


func _update_melee_punch_telegraph(delta: float) -> void:
	_velocity_zero()
	_combat_move_pursue = false
	_ai_state = AiState.STARING
	if _aim_target != null:
		_face_position(_aim_target.global_position, delta)
	_melee_punch_telegraph_timer = maxf(_melee_punch_telegraph_timer - delta, 0.0)
	if _melee_punch_telegraph_timer > 0.0:
		return
	if not _try_start_combat_punch():
		_begin_combat_approach()


func _roll_melee_decision_timer() -> void:
	if melee_only:
		_melee_decision_timer = randf_range(BRAWL_DECISION_MIN, BRAWL_DECISION_MAX)
		return
	_melee_decision_timer = randf_range(MELEE_DECISION_MIN, MELEE_DECISION_MAX)


func _enter_unarmed_combat(player: Node3D) -> void:
	if _defeated or player == null:
		return
	release_ambush_hold()
	_ensure_overworld_combat_for_target(player)
	_combat_active = true
	_aim_target = player
	_combat_move_pursue = true
	_saved_ai_state = _ai_state
	_ai_state = AiState.COMBAT_MOVING
	_velocity_zero()
	_committed_aim_zone = _pick_body_aim_zone()
	_roll_mounted_fire_target()
	_refresh_aim_spread()
	_has_locked_aim = true
	_smoothed_aim_point = _sample_body_aim_point(_committed_aim_zone) + _aim_spread_offset
	_sync_combat_nav_target_to(player)
	_roll_melee_decision_timer()
	if _weapon_rig != null:
		_weapon_rig.set_prep_aim(false)
		_weapon_rig.set_gun_arm_released_for_pose(true)
		if not _weapon_rig.is_holstered():
			_weapon_rig.begin_holster()


func _begin_melee_block(duration: float = -1.0) -> void:
	if _melee_blocking:
		return
	_melee_punch_telegraph_timer = 0.0
	_melee_blocking = true
	if duration < 0.0:
		_melee_block_timer = randf_range(MELEE_BLOCK_MIN, MELEE_BLOCK_MAX)
	else:
		_melee_block_timer = duration
	_velocity_zero()
	_ai_state = AiState.STARING
	if _aim_target != null:
		_face_position(_aim_target.global_position, get_physics_process_delta_time())
	_begin_unarmed_block_hold()


func _update_melee_block(delta: float) -> void:
	if not _melee_blocking:
		return
	velocity.x = 0.0
	velocity.z = 0.0
	_melee_block_timer -= delta
	if _aim_target != null:
		_face_position(_aim_target.global_position, delta)
	if _melee_block_timer <= 0.0:
		_end_melee_block()


func _end_melee_block() -> void:
	if not _melee_blocking:
		return
	_melee_blocking = false
	_melee_block_timer = 0.0
	_end_unarmed_block_hold()
	_roll_melee_decision_timer()


func _check_gun_escalation() -> void:
	var player := _find_player()
	if player == null:
		return
	if not _is_player_weapon_threatening_target(player, self):
		return
	if player.has_method("is_weapon_raised") and player.is_weapon_raised():
		escalate_to_gun_aggro(player)
