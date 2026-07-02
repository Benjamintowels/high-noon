extends FastTownNpc
class_name EnginesNpc

const ENGINES_AGGRO_VOICE_SCRIPT := preload("res://characters/fast/engines_aggro_voice.gd")
const DEBUG_ENGINES_RAID := true
const DEBUG_ENGINES_RAID_INTERVAL := 1.5

var _raid_charge_point := Vector3.ZERO
var _engines_raid_debug_timer := 0.0


func _ready() -> void:
	wear_hat = false
	random_hat_color = false
	equipped_weapon_id = GroyperWeapons.Id.BOW
	faction_max_engage_range = 100.0
	add_to_group("engines_npc")
	add_to_group("faction_npc")
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not DEBUG_ENGINES_RAID:
		return
	_engines_raid_debug_timer -= delta
	if _engines_raid_debug_timer > 0.0:
		return
	_engines_raid_debug_timer = DEBUG_ENGINES_RAID_INTERVAL

	var horse_mounted := false
	var horse_speed := 0.0
	if _mounted_horse != null:
		if _mounted_horse.has_method("is_mounted"):
			horse_mounted = _mounted_horse.is_mounted()
		horse_speed = Vector2(_mounted_horse.velocity.x, _mounted_horse.velocity.z).length()

	var target_name := "null"
	if _aim_target != null and is_instance_valid(_aim_target):
		target_name = _aim_target.name

	var ride_input := get_ride_move_input()
	_engines_raid_debug(
		(
			"state mounted_horse=%s horse_mounted=%s purpose=%d combat=%s aggro=%d ai=%d"
			+ " target=%s in_range=%s ride_in=%s horse_spd=%.2f"
		)
		% [
			_mounted_horse.name if _mounted_horse != null else "null",
			horse_mounted,
			_horse_ride_purpose,
			_combat_active,
			_faction_aggro_level,
			_ai_state,
			target_name,
			_is_target_in_weapon_range() if _aim_target != null else "no_target",
			ride_input,
			horse_speed,
		]
	)


func _engines_raid_debug(msg: String) -> void:
	if DEBUG_ENGINES_RAID:
		print("[EnginesRaid][%s] %s" % [name, msg])


func get_town_character_group() -> StringName:
	return &"engines_npc"


func get_faction_id() -> StringName:
	return FactionIds.ENGINES


func _create_aggro_voice() -> Node:
	var voice := ENGINES_AGGRO_VOICE_SCRIPT.new()
	voice.name = "AggroVoice"
	add_child(voice)
	voice.setup(self)
	return voice


func mount_and_begin_raid_assault(horse: StupidHorse, scenario: Node) -> void:
	if horse == null or scenario == null:
		_engines_raid_debug(
			"assault aborted horse=%s scenario=%s"
			% [horse, scenario]
		)
		return

	horse.mount_rider(self)
	if _mounted_horse == null:
		_engines_raid_debug(
			"mount failed horse.mounted=%s horse.defeated=%s saddle_node=%s"
			% [
				horse.is_mounted() if horse.has_method("is_mounted") else "?",
				horse.is_horse_defeated() if horse.has_method("is_horse_defeated") else "?",
				_saddle_blend_node != null,
			]
		)
		return

	var target: Node3D = scenario.call("pick_attack_target", global_position)
	var charge_point: Vector3 = scenario.call("get_town_charge_point")
	_engines_raid_debug(
		"mounted on %s target=%s charge=%s"
		% [
			horse.name,
			target.name if target != null else "null",
			charge_point,
		]
	)
	begin_raid_charge(target, charge_point, scenario)


func begin_raid_charge(target: Node3D, charge_point: Vector3, scenario: Node = null) -> void:
	if _defeated:
		return

	_raid_charge_point = charge_point
	_horse_ride_purpose = HORSE_RIDE_COMBAT_CHASE
	_combat_active = true
	_combat_move_pursue = true

	if target != null and is_instance_valid(target):
		_aim_target = target
		if scenario != null:
			scenario.call("rally_defenders_against", self)
		set_faction_aggro_level(3, target)
		if not _combat_active:
			enter_combat(target)
		elif _ai_state == AiState.IDLE:
			_ai_state = AiState.COMBAT_MOVING
	elif _aim_target == null or not is_instance_valid(_aim_target):
		_ai_state = AiState.COMBAT_MOVING

	if _aggro_voice != null and _aggro_voice.has_method("play_woah_now"):
		_aggro_voice.play_woah_now()

	_engines_raid_debug(
		"charge active purpose=%d combat=%s pursue=%s ai=%d target=%s"
		% [
			_horse_ride_purpose,
			_combat_active,
			_combat_move_pursue,
			_ai_state,
			_aim_target.name if _aim_target != null and is_instance_valid(_aim_target) else "null",
		]
	)


func get_ride_move_input() -> Vector3:
	if _horse_ride_purpose != HORSE_RIDE_COMBAT_CHASE or not _combat_active:
		return super.get_ride_move_input()

	if _aim_target != null and is_instance_valid(_aim_target):
		return _get_mounted_combat_chase_input(_raid_charge_point)

	var to_dest := _raid_charge_point - global_position
	to_dest.y = 0.0
	if to_dest.length_squared() < 0.0001:
		return Vector3.ZERO
	return to_dest.normalized()


func is_ride_sprinting() -> bool:
	if _horse_ride_purpose == HORSE_RIDE_COMBAT_CHASE and _combat_active:
		return true
	return super.is_ride_sprinting()


func _allows_combat_horse_remount() -> bool:
	return false
