extends Node
class_name UnarmedHostageTake
## Holds an NPC in front of the player as a human shield. The hostage absorbs
## incoming damage, can be released with Q, shoved with LMB, or may break free
## while the player stands still.

const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")
const UnarmedParryThrowScript := preload("res://gameplay/combat/unarmed_parry_throw.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const HOSTAGE_FORWARD_OFFSET := 1.05
const HOSTAGE_SETUP_DURATION := 0.38
const HOSTAGE_FACING_SPEED := 14.0
const HOSTAGE_POSITION_LERP_SPEED := 12.0
const STRUGGLE_INTERVAL := 2.5
const STRUGGLE_CHANCE := 0.5
const STAND_STILL_SPEED := 0.18

enum Phase { SETUP, HOLD, DONE }

var _player: Node3D
var _victim: CharacterBody3D
var _phase := Phase.SETUP
var _setup_timer := 0.0
var _setup_from := Vector3.ZERO
var _setup_from_yaw := 0.0
var _struggle_timer := STRUGGLE_INTERVAL


static func is_grab_parry_throw_target(target: Node) -> bool:
	return (
		target != null
		and target.has_method("is_unarmed_blocking")
		and target.is_unarmed_blocking()
	)


func get_victim() -> CharacterBody3D:
	return _victim


func begin(player: Node3D, victim: CharacterBody3D) -> void:
	_player = player
	_victim = victim
	_phase = Phase.SETUP
	_setup_timer = HOSTAGE_SETUP_DURATION
	_setup_from = victim.global_position
	_setup_from_yaw = _get_victim_model_yaw()
	_struggle_timer = STRUGGLE_INTERVAL

	if victim.has_method("begin_hostage_capture"):
		victim.begin_hostage_capture(player)


func release(enter_aggro := false) -> void:
	if _phase == Phase.DONE:
		return
	_finish(enter_aggro)


func shove() -> void:
	if _phase != Phase.HOLD or _victim == null or not is_instance_valid(_victim):
		return
	if _player == null or not is_instance_valid(_player):
		release()
		return

	var direction := Vector3.FORWARD
	if _player.has_method("get_punch_facing_direction"):
		direction = _player.get_punch_facing_direction()
	elif _player.has_method("get_parry_throw_direction"):
		direction = _player.get_parry_throw_direction()
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	direction = direction.normalized()

	if _victim.has_method("end_hostage_capture"):
		_victim.end_hostage_capture()

	var controller := UnarmedParryThrowScript.new()
	controller.name = "UnarmedParryThrow"
	_player.get_parent().add_child(controller)
	controller.begin_shove(_player, _victim, direction)

	_victim = null
	_phase = Phase.DONE
	if _player.has_method("notify_hostage_take_ended"):
		_player.notify_hostage_take_ended()


func _physics_process(delta: float) -> void:
	if _victim == null or not is_instance_valid(_victim):
		_finish(false)
		return

	if _victim.has_method("is_defeated") and _victim.is_defeated():
		_finish(false)
		return

	match _phase:
		Phase.SETUP:
			_update_setup(delta)
		Phase.HOLD:
			_update_hold(delta)
		Phase.DONE:
			queue_free()


func _update_setup(delta: float) -> void:
	_setup_timer -= delta
	var progress := 1.0 - clampf(_setup_timer / HOSTAGE_SETUP_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, progress)
	var target_pos := _get_hostage_world_position()
	_victim.global_position = _setup_from.lerp(target_pos, eased)
	_apply_victim_facing(delta, _get_player_facing(), eased)
	_victim.velocity = Vector3.ZERO

	if _setup_timer <= 0.0:
		_phase = Phase.HOLD
		_victim.global_position = target_pos
		_apply_victim_facing(delta, _get_player_facing(), 1.0)


func _update_hold(delta: float) -> void:
	var target_pos := _get_hostage_world_position()
	_victim.global_position = _victim.global_position.lerp(
		target_pos,
		1.0 - exp(-HOSTAGE_POSITION_LERP_SPEED * delta)
	)
	_apply_victim_facing(delta, _get_player_facing(), 1.0)
	_victim.velocity = Vector3.ZERO
	_update_struggle(delta)


func _update_struggle(delta: float) -> void:
	var player_speed := _get_player_horizontal_speed()
	if player_speed > STAND_STILL_SPEED:
		_struggle_timer = STRUGGLE_INTERVAL
		return

	_struggle_timer -= delta
	if _struggle_timer > 0.0:
		return

	_struggle_timer = STRUGGLE_INTERVAL
	if randf() >= STRUGGLE_CHANCE:
		return
	if _get_player_horizontal_speed() > STAND_STILL_SPEED:
		return

	CombatHitFlashScript.flash_block(_victim)
	GameAudioScript.play_punch(_victim, _victim.global_position)
	release(true)


func _get_hostage_world_position() -> Vector3:
	var facing := _get_player_facing()
	return _player.global_position + facing * HOSTAGE_FORWARD_OFFSET


func _get_player_facing() -> Vector3:
	if _player != null and _player.has_method("get_punch_facing_direction"):
		var facing: Vector3 = _player.get_punch_facing_direction()
		facing.y = 0.0
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	return Vector3.FORWARD


func _get_player_horizontal_speed() -> float:
	if _player == null:
		return 0.0
	if "velocity" in _player:
		var vel: Vector3 = _player.velocity
		return Vector2(vel.x, vel.z).length()
	return 0.0


func _get_victim_model() -> Node3D:
	if _victim == null:
		return null
	var model := _victim.get_node_or_null("Model") as Node3D
	if model != null:
		return model
	for child in _victim.get_children():
		if child is Node3D and child.name == &"Model":
			return child as Node3D
	return null


func _get_victim_model_yaw() -> float:
	var model := _get_victim_model()
	if model == null:
		return GroyperBodyUtilsScript.MODEL_YAW_OFFSET
	return model.rotation.y


func _apply_victim_facing(delta: float, direction: Vector3, blend_weight: float) -> void:
	if _victim.has_method("apply_hostage_facing"):
		_victim.apply_hostage_facing(direction)
		return

	var model := _get_victim_model()
	if model == null:
		return
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var target_yaw := GroyperBodyUtilsScript.facing_yaw_for_direction(direction.normalized())
	if blend_weight >= 0.999:
		model.rotation.y = target_yaw
	else:
		model.rotation.y = lerp_angle(
			_setup_from_yaw,
			target_yaw,
			blend_weight * (1.0 - exp(-HOSTAGE_FACING_SPEED * delta))
		)


func _finish(enter_aggro: bool) -> void:
	if _phase == Phase.DONE:
		return
	_phase = Phase.DONE

	if _victim != null and is_instance_valid(_victim):
		if _victim.has_method("end_hostage_capture"):
			_victim.end_hostage_capture()
	if (
		enter_aggro
		and not (_victim.has_method("is_defeated") and _victim.is_defeated())
		and _player != null
		and is_instance_valid(_player)
	):
		if _victim.has_method("on_hostage_released_by_player"):
			_victim.on_hostage_released_by_player(_player)
		elif _victim.has_method("enter_melee_aggro"):
			_victim.enter_melee_aggro(_player)

	_victim = null
	if _player != null and is_instance_valid(_player) and _player.has_method("notify_hostage_take_ended"):
		_player.notify_hostage_take_ended()
	queue_free()
