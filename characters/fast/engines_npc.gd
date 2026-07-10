extends FastTownNpc
class_name EnginesNpc

const ENGINES_AGGRO_VOICE_SCRIPT := preload("res://characters/fast/engines_aggro_voice.gd")
const EnginesFireballTossScript := preload("res://gameplay/combat/engines_fireball_toss.gd")
const RAID_ENGAGE_RANGE := 180.0
const RAID_CHASE_RANGE := 280.0
const RAID_FIREBALL_RANGE := 14.0
const RAID_MODE_SWITCH_MIN := 7.0
const RAID_MODE_SWITCH_MAX := 14.0
const RAID_RELOCATE_MIN := 1.5
const RAID_RELOCATE_MAX := 4.5
const RAID_FIRE_DELAY_MIN := 1.0
const RAID_FIRE_DELAY_MAX := 2.2
const RAID_BARK_INTERVAL_MIN := 2.5
const RAID_BARK_INTERVAL_MAX := 5.5
const RAID_OPENING_CHARGE_DURATION := 5.0
const RAID_OPENING_CHARGE_SPEED := 7.25

enum RaidAiMode {
	OPENING_CHARGE,
	CHASE_TOWNSPERSON,
	ASSAULT_TOWN_CENTER,
}

var _raid_charge_point := Vector3.ZERO
var _raid_ignore_player := false
var _raid_bark_timer := 0.0
var _raid_active := false
var _raid_scenario: Node = null
var _raid_town_center: Node3D = null
var _raid_ai_mode := RaidAiMode.CHASE_TOWNSPERSON
var _raid_mode_timer := 0.0
var _opening_charge_timer := 0.0
var _opening_charge_target: Node3D
var _fireball_toss_cooldown := 0.0
var _raid_reposition_timer := 0.0


func _ready() -> void:
	wear_hat = false
	random_hat_color = false
	equipped_weapon_id = GroyperWeapons.Id.BOW
	faction_max_engage_range = 100.0
	add_to_group("engines_npc")
	add_to_group("faction_npc")
	super._ready()


func _physics_process(delta: float) -> void:
	if _raid_active and not _defeated:
		_update_raid_ai(delta)
	super._physics_process(delta)
	if (
		_raid_active
		and _raid_ai_mode == RaidAiMode.OPENING_CHARGE
		and _mounted_horse == null
		and not _defeated
	):
		_apply_opening_charge_foot_sprint(delta)
	_update_raid_combat_barks(delta)


func get_town_character_group() -> StringName:
	return &"engines_npc"


func get_faction_id() -> StringName:
	return FactionIds.ENGINES


func set_raid_ignore_player(ignore: bool) -> void:
	_raid_ignore_player = ignore


func set_raid_town_center(center: Node3D) -> void:
	_raid_town_center = center


func _is_valid_combat_target(target: Node3D) -> bool:
	if _should_ignore_player_target(target):
		return false
	return super._is_valid_combat_target(target)


func _pick_nearest_hostile_faction_member(max_range: float = -1.0) -> Node3D:
	var target := super._pick_nearest_hostile_faction_member(max_range)
	if _should_ignore_player_target(target):
		return _pick_nearest_hostile_excluding_player(max_range)
	return target


func _should_ignore_player_target(target: Node3D) -> bool:
	return (
		_raid_ignore_player
		and target != null
		and target.is_in_group("overworld_player")
		and not TownShootout.player_harmed_becker_boys(get_tree())
	)


func _pick_nearest_hostile_excluding_player(max_range: float = -1.0) -> Node3D:
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

	for group_name: StringName in [&"engines_npc", &"bandit", &"becker_boys", &"town_groyper", &"town_fast", &"town_sheriff"]:
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

	return nearest


func _create_aggro_voice() -> Node:
	var voice := ENGINES_AGGRO_VOICE_SCRIPT.new()
	voice.name = "AggroVoice"
	add_child(voice)
	voice.setup(self)
	return voice


func mount_and_begin_raid_assault(horse: StupidHorse, scenario: Node) -> void:
	if horse == null or scenario == null:
		return

	horse.mount_rider(self)
	if _mounted_horse == null:
		begin_foot_raid_assault(scenario)
		return

	var target: Node3D = scenario.call("pick_attack_target", global_position)
	var charge_point: Vector3 = scenario.call("get_town_charge_point")
	begin_raid_charge(target, charge_point, scenario)


func begin_foot_raid_assault(scenario: Node) -> void:
	if scenario == null:
		return

	var target: Node3D = scenario.call("pick_attack_target", global_position)
	var charge_point: Vector3 = scenario.call("get_town_charge_point")
	begin_raid_charge(target, charge_point, scenario)


func begin_raid_charge(target: Node3D, charge_point: Vector3, scenario: Node = null) -> void:
	if _defeated:
		return

	_raid_active = true
	_raid_scenario = scenario
	if _raid_town_center == null and scenario != null and scenario.has_method("get_town_center"):
		_raid_town_center = scenario.call("get_town_center")

	_raid_charge_point = charge_point
	faction_max_engage_range = RAID_CHASE_RANGE
	_opening_charge_target = target

	if _raid_town_center != null and is_instance_valid(_raid_town_center):
		_begin_opening_charge()
		return

	_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE if _mounted_horse != null else HORSE_RIDE_NONE
	_combat_active = true
	_combat_move_pursue = true
	_ai_state = AiState.COMBAT_MOVING
	_raid_ai_mode = (
		RaidAiMode.ASSAULT_TOWN_CENTER
		if randf() < 0.5
		else RaidAiMode.CHASE_TOWNSPERSON
	)
	_raid_mode_timer = randf_range(RAID_MODE_SWITCH_MIN, RAID_MODE_SWITCH_MAX)
	_raid_reposition_timer = randf_range(0.4, 1.2)
	_begin_raid_mode_behavior(target)

	if _weapon_rig != null and _weapon_rig.is_holstered():
		_weapon_rig.set_prep_aim(false)
		_weapon_rig.begin_draw()

	if _aggro_voice != null:
		if _aggro_voice.has_method("set_raid_mode"):
			_aggro_voice.set_raid_mode(true)
		if _aggro_voice.has_method("play_woah_now"):
			_aggro_voice.play_woah_now()
		if _aggro_voice.has_method("schedule_raid_bark"):
			_aggro_voice.schedule_raid_bark()
	_raid_bark_timer = randf_range(1.0, 2.5)


func _begin_opening_charge() -> void:
	_raid_ai_mode = RaidAiMode.OPENING_CHARGE
	_opening_charge_timer = RAID_OPENING_CHARGE_DURATION
	_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE if _mounted_horse != null else HORSE_RIDE_NONE
	_combat_active = true
	_combat_move_pursue = false
	_aim_target = null
	_ai_state = AiState.COMBAT_MOVING
	_combat_move_target = _get_opening_charge_destination()
	if _combat_nav != null:
		_combat_nav.set_target(_combat_move_target)

	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.reset_to_holster()

	if _aggro_voice != null:
		if _aggro_voice.has_method("set_raid_mode"):
			_aggro_voice.set_raid_mode(true)
		if _aggro_voice.has_method("play_woah_now"):
			_aggro_voice.play_woah_now()
	_raid_bark_timer = randf_range(1.0, 2.5)


func _end_opening_charge() -> void:
	if not _raid_active or _defeated:
		return
	if _raid_ai_mode != RaidAiMode.OPENING_CHARGE:
		return

	_raid_ai_mode = (
		RaidAiMode.ASSAULT_TOWN_CENTER
		if randf() < 0.5
		else RaidAiMode.CHASE_TOWNSPERSON
	)
	_raid_mode_timer = randf_range(RAID_MODE_SWITCH_MIN, RAID_MODE_SWITCH_MAX)
	_raid_reposition_timer = randf_range(0.4, 1.2)

	if _weapon_rig != null and _weapon_rig.is_holstered():
		_weapon_rig.set_prep_aim(false)
		_weapon_rig.begin_draw()

	if _aggro_voice != null and _aggro_voice.has_method("schedule_raid_bark"):
		_aggro_voice.schedule_raid_bark()

	var target := _opening_charge_target
	if target == null or not is_instance_valid(target):
		if _raid_scenario != null:
			target = _raid_scenario.call("pick_attack_target", global_position)
	_begin_raid_mode_behavior(target)


func _get_opening_charge_destination() -> Vector3:
	if _raid_town_center != null and is_instance_valid(_raid_town_center):
		return _raid_town_center.global_position
	return _raid_charge_point


func _apply_opening_charge_foot_sprint(delta: float) -> void:
	var to_dest := _get_opening_charge_destination() - global_position
	to_dest.y = 0.0
	if to_dest.length_squared() < 0.0001:
		return

	var move_dir := to_dest.normalized()
	velocity.x = move_dir.x * RAID_OPENING_CHARGE_SPEED
	velocity.z = move_dir.z * RAID_OPENING_CHARGE_SPEED
	_face_position(global_position + move_dir, delta)


func get_ride_move_input() -> Vector3:
	if _raid_active and _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		var to_center := _get_opening_charge_destination() - global_position
		to_center.y = 0.0
		if to_center.length_squared() > 0.0001:
			return to_center.normalized()

	if _raid_active and _combat_active:
		if _raid_ai_mode == RaidAiMode.ASSAULT_TOWN_CENTER and _raid_town_center != null:
			var to_center := _raid_town_center.global_position - global_position
			to_center.y = 0.0
			if to_center.length_squared() > 0.0001:
				return to_center.normalized()

	if _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE and _combat_active and _mounted_horse != null:
		if _aim_target != null and is_instance_valid(_aim_target):
			return super.get_ride_move_input()

		var to_dest := _raid_charge_point - global_position
		to_dest.y = 0.0
		if to_dest.length_squared() < 0.0001:
			return Vector3.ZERO
		return to_dest.normalized()

	return super.get_ride_move_input()


func is_ride_sprinting() -> bool:
	if _raid_active and _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		return true
	if _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE and _combat_active:
		return true
	return super.is_ride_sprinting()


func _allows_combat_horse_remount() -> bool:
	return false


func _update_raid_combat_barks(delta: float) -> void:
	if _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		return
	if not _combat_active or _defeated:
		return
	if _aggro_voice == null:
		return

	_raid_bark_timer -= delta
	if _raid_bark_timer > 0.0:
		return

	_raid_bark_timer = randf_range(RAID_BARK_INTERVAL_MIN, RAID_BARK_INTERVAL_MAX)
	if _aggro_voice.has_method("schedule_raid_bark"):
		_aggro_voice.schedule_raid_bark()


func _update_combat_ai(delta: float) -> void:
	if _raid_active:
		_update_raid_combat_ai(delta)
		return
	super._update_combat_ai(delta)


func _update_raid_ai(delta: float) -> void:
	if _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		_opening_charge_timer -= delta
		if _opening_charge_timer <= 0.0:
			_end_opening_charge()
		return

	_fireball_toss_cooldown = maxf(_fireball_toss_cooldown - delta, 0.0)
	_raid_mode_timer -= delta
	if _raid_mode_timer <= 0.0:
		_cycle_raid_ai_mode()


func _update_raid_combat_ai(delta: float) -> void:
	if (
		not _combat_active
		or _defeated
		or _roll_active
		or _punch_active
		or is_melee_stunned()
	):
		return

	if _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		_update_opening_charge(delta)
		return

	if _raid_ai_mode == RaidAiMode.ASSAULT_TOWN_CENTER:
		_update_raid_town_center_assault(delta)
		return

	_refresh_raid_chase_target()
	_refresh_combat_target_if_needed()
	_raid_reposition_timer -= delta

	match _ai_state:
		AiState.COMBAT_DRAWING:
			if _weapon_rig.is_aiming():
				if _can_begin_combat_aiming():
					_begin_combat_aiming()
				else:
					_begin_combat_approach()
		AiState.COMBAT_AIMING:
			if not _is_target_in_weapon_range() or not _has_combat_line_of_sight_to(_aim_target):
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
			elif _can_begin_combat_aiming() and _raid_reposition_timer > 0.0:
				_begin_combat_aiming()
			elif _raid_reposition_timer <= 0.0:
				_begin_raid_relocate()
			elif _should_try_combat_punch():
				_try_start_combat_punch()


func _update_opening_charge(_delta: float) -> void:
	_combat_move_target = _get_opening_charge_destination()
	if _combat_nav != null:
		_combat_nav.set_target_if_needed(_combat_move_target)

	if _weapon_rig != null and not _weapon_rig.is_holstered():
		_weapon_rig.reset_to_holster()


func _update_raid_town_center_assault(_delta: float) -> void:
	if _raid_town_center == null or not is_instance_valid(_raid_town_center):
		_cycle_raid_ai_mode()
		return

	var center_pos := _raid_town_center.global_position
	var flat_dist := Vector2(
		global_position.x - center_pos.x,
		global_position.z - center_pos.z
	).length()

	if flat_dist <= RAID_FIREBALL_RANGE and _fireball_toss_cooldown <= 0.0:
		_try_toss_fireball_at_town_center()
		return

	_aim_target = null
	_combat_move_pursue = false
	_ai_state = AiState.COMBAT_MOVING
	_combat_move_target = center_pos
	if _combat_nav != null:
		_combat_nav.set_target_if_needed(center_pos)


func _try_toss_fireball_at_town_center() -> void:
	if _raid_town_center == null or not is_instance_valid(_raid_town_center):
		return

	velocity.x = 0.0
	velocity.z = 0.0
	_face_position(_raid_town_center.global_position, get_physics_process_delta_time())

	var origin := global_position + Vector3(0.0, 1.35, 0.0)
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	EnginesFireballTossScript.launch(parent, origin, _raid_town_center, self)
	_fireball_toss_cooldown = 4.5
	_cycle_raid_ai_mode()


func _begin_raid_mode_behavior(initial_target: Node3D) -> void:
	if initial_target != null and is_instance_valid(initial_target):
		if _raid_scenario != null:
			_raid_scenario.call("rally_defenders_against", self)
		set_faction_aggro_level(3, initial_target)

	match _raid_ai_mode:
		RaidAiMode.CHASE_TOWNSPERSON:
			_refresh_raid_chase_target()
			if _aim_target != null:
				_combat_move_pursue = true
				_begin_combat_approach()
			elif _mounted_horse == null:
				_combat_move_target = _raid_charge_point
				_combat_move_pursue = false
				_ai_state = AiState.COMBAT_MOVING
				if _combat_nav != null:
					_combat_nav.set_target(_raid_charge_point)
		RaidAiMode.ASSAULT_TOWN_CENTER:
			_aim_target = null
			_combat_move_pursue = false
			_ai_state = AiState.COMBAT_MOVING


func _cycle_raid_ai_mode() -> void:
	if _raid_ai_mode == RaidAiMode.OPENING_CHARGE:
		return
	_raid_ai_mode = (
		RaidAiMode.ASSAULT_TOWN_CENTER
		if _raid_ai_mode == RaidAiMode.CHASE_TOWNSPERSON
		else RaidAiMode.CHASE_TOWNSPERSON
	)
	_raid_mode_timer = randf_range(RAID_MODE_SWITCH_MIN, RAID_MODE_SWITCH_MAX)
	_raid_reposition_timer = randf_range(0.5, 1.5)
	_begin_raid_mode_behavior(_aim_target)


func _refresh_raid_chase_target() -> void:
	var target := _pick_nearest_hostile_faction_member(RAID_CHASE_RANGE)
	if target == null and _raid_scenario != null:
		target = _raid_scenario.call("pick_attack_target", global_position)
	if target != null and is_instance_valid(target):
		_aim_target = target


func _begin_raid_relocate() -> void:
	if _mounted_horse != null:
		_ai_state = AiState.COMBAT_MOVING
		_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE
		_combat_move_pursue = false
		_pick_horse_patrol_target()
		_raid_reposition_timer = randf_range(RAID_RELOCATE_MIN, RAID_RELOCATE_MAX)
		return

	_combat_move_pursue = false
	_ai_state = AiState.COMBAT_MOVING
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(RAID_RELOCATE_MIN, RAID_RELOCATE_MAX)
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * distance
	_combat_move_target = global_position + offset
	_combat_move_target.y = global_position.y
	if _combat_nav != null:
		_combat_move_target = _combat_nav.snap_position(_combat_move_target)
		_combat_nav.set_target(_combat_move_target)
	_raid_reposition_timer = randf_range(RAID_RELOCATE_MIN, RAID_RELOCATE_MAX)


func _roll_combat_fire_delay() -> float:
	if _raid_active:
		return randf_range(RAID_FIRE_DELAY_MIN, RAID_FIRE_DELAY_MAX)
	return super._roll_combat_fire_delay()


func _fire_at_target() -> void:
	if _raid_active:
		if _weapon_rig == null or not _weapon_rig.is_aiming():
			return
		if not _is_target_in_weapon_range() or not _has_combat_line_of_sight_to(_aim_target):
			_begin_combat_approach()
			return

		_weapon_rig.fire_at(_smoothed_aim_point)
		_begin_raid_relocate()
		return
	super._fire_at_target()
