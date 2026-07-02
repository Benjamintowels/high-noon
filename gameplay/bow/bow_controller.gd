extends Node
class_name BowController

const ArrowScene := preload("res://gameplay/shooting/arrow_projectile.tscn")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const MIN_CHARGE := 0.03
const FULL_CHARGE := 1.8
const MIN_SPEED := 1.5
const MAX_SPEED := 23.0

var _owner: Node3D
var _weapon_rig: GroyperWeaponRig
var _get_origin: Callable
var _get_direction: Callable
var _on_fired: Callable

var _charging := false
var _charge := 0.0
var _drawback_player: AudioStreamPlayer3D


func setup(
	owner_node: Node3D,
	weapon_rig: GroyperWeaponRig,
	get_origin: Callable,
	get_direction: Callable,
	on_fired: Callable
) -> void:
	_owner = owner_node
	_weapon_rig = weapon_rig
	_get_origin = get_origin
	_get_direction = get_direction
	_on_fired = on_fired


func is_charging() -> bool:
	return _charging


func get_charge_alpha() -> float:
	return clampf(_charge / FULL_CHARGE, 0.0, 1.0)


func reset() -> void:
	_stop_drawback_sound()
	_charging = false
	_charge = 0.0
	if _weapon_rig != null:
		_weapon_rig.set_bow_draw(0.0)


func begin_draw() -> bool:
	if _charging:
		return false
	_charging = true
	_charge = 0.0
	_start_drawback_sound()
	return true


func update(delta: float, lmb_held: bool, can_use: bool) -> void:
	if not can_use:
		if _charging:
			cancel_draw()
		return

	if lmb_held:
		if not _charging:
			begin_draw()
		_charge = minf(_charge + delta, FULL_CHARGE)
		if _weapon_rig != null:
			_weapon_rig.set_bow_draw(get_charge_alpha())
	elif _charging:
		release()


func cancel_draw() -> void:
	_stop_drawback_sound()
	_charging = false
	_charge = 0.0
	if _weapon_rig != null:
		_weapon_rig.set_bow_draw(0.0)


func release() -> void:
	if not _charging:
		return

	var held_charge := _charge
	var charge_alpha := get_charge_alpha()
	var origin: Vector3 = _get_origin.call()
	var direction: Vector3 = _get_direction.call()

	_stop_drawback_sound()
	_charging = false
	_charge = 0.0
	if _weapon_rig != null:
		_weapon_rig.set_bow_draw(0.0)

	if held_charge < MIN_CHARGE:
		return

	var scene_root := _owner.get_tree().current_scene if _owner != null else null
	if scene_root == null:
		return

	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()

	var power := charge_alpha * charge_alpha
	var speed := lerpf(MIN_SPEED, MAX_SPEED, power)
	var exclude: Array = [_owner]
	var hitbox := _owner.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)

	var arrow: Node3D = ArrowScene.instantiate()
	scene_root.add_child(arrow)
	arrow.setup(origin, direction, speed, exclude, _owner)

	GameAudio.play_bow_release(scene_root, origin)
	if _on_fired.is_valid():
		_on_fired.call()


func _start_drawback_sound() -> void:
	_stop_drawback_sound()
	if _owner == null:
		return
	var origin: Vector3 = _get_origin.call() if _get_origin.is_valid() else _owner.global_position
	_drawback_player = GameAudio.start_bow_drawback(_owner, origin)
	if _drawback_player != null:
		_drawback_player.finished.connect(_on_drawback_sound_finished, CONNECT_ONE_SHOT)


func _on_drawback_sound_finished() -> void:
	if _drawback_player == null or not is_instance_valid(_drawback_player):
		_drawback_player = null
		return
	var player := _drawback_player
	_drawback_player = null
	player.queue_free()


func _stop_drawback_sound() -> void:
	if _drawback_player != null and is_instance_valid(_drawback_player):
		if _drawback_player.finished.is_connected(_on_drawback_sound_finished):
			_drawback_player.finished.disconnect(_on_drawback_sound_finished)
		GameAudio.stop_bow_drawback(_drawback_player)
	_drawback_player = null
