extends Node3D
## Physical door on the Hotel ↔ Uncle's Ranch gate. Blocks the hotel side until
## unlocked (ranch key, or opening from the ranch / "back" side). Once open it
## stays open for the rest of the save.

const OPEN_YAW := deg_to_rad(-95.0)
const OPEN_DURATION := 0.55
const INTERACT_HALF_EXTENTS := Vector3(1.4, 1.6, 1.1)
const BODY_HALF_EXTENTS := Vector3(0.12, 1.35, 0.85)

## Local +Z faces the hotel (front). Ranch / unlock-without-key is local -Z.
@export var hotel_side_is_local_plus_z := true

var _opened := false
var _busy := false
var _player_in_range: Node3D
var _body: StaticBody3D
var _interact: Area3D
var _open_yaw_applied := 0.0


func _ready() -> void:
	_build_collision()
	_build_interact_zone()
	if HotelRanchDoorProgress.unlocked or PlayerInventory.has_ranch_key:
		_apply_opened(true)


func get_interact_hint() -> String:
	if _opened or _busy:
		return ""
	if _player_can_open_from_here():
		return "Open Door"
	return "Locked (Need Key)"


func interact(player: Node3D) -> void:
	if _opened or _busy or player == null:
		return
	if not _player_can_open_from_here():
		return
	_open_door()


func is_opened() -> bool:
	return _opened


func open_from_ranch_crossing() -> void:
	if _opened or _busy:
		return
	_open_door()


func _player_can_open_from_here() -> bool:
	if HotelRanchDoorProgress.unlocked or PlayerInventory.has_ranch_key:
		return true
	if _player_in_range != null and _is_on_ranch_side(_player_in_range):
		return true
	return false


func _is_on_ranch_side(player: Node3D) -> bool:
	var local := to_local(player.global_position)
	if hotel_side_is_local_plus_z:
		return local.z < 0.0
	return local.z > 0.0


func _open_door() -> void:
	_busy = true
	HotelRanchDoorProgress.mark_unlocked()
	await _tween_open()
	_apply_opened(false)
	_busy = false


func _tween_open() -> void:
	var remaining := OPEN_YAW - _open_yaw_applied
	if absf(remaining) < 0.001:
		return
	var start := _open_yaw_applied
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_open_yaw, start, OPEN_YAW, OPEN_DURATION)
	await tween.finished


func _set_open_yaw(yaw: float) -> void:
	var delta := yaw - _open_yaw_applied
	if absf(delta) < 0.0001:
		return
	rotate_object_local(Vector3.UP, delta)
	_open_yaw_applied = yaw


func _apply_opened(instant: bool) -> void:
	_opened = true
	if instant:
		_set_open_yaw(OPEN_YAW)
	if _body != null:
		_body.collision_layer = 0
		_body.collision_mask = 0
		for child in _body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = true
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
		_player_in_range = null


func _build_collision() -> void:
	_body = StaticBody3D.new()
	_body.name = "DoorBody"
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = BODY_HALF_EXTENTS * 2.0
	shape.shape = box
	shape.position = Vector3(0.0, BODY_HALF_EXTENTS.y, 0.0)
	_body.add_child(shape)


func _build_interact_zone() -> void:
	_interact = Area3D.new()
	_interact.name = "DoorInteract"
	_interact.collision_layer = 0
	_interact.collision_mask = 1
	_interact.monitoring = true
	_interact.monitorable = false
	add_child(_interact)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = INTERACT_HALF_EXTENTS * 2.0
	shape.shape = box
	shape.position = Vector3(0.0, INTERACT_HALF_EXTENTS.y, 0.0)
	_interact.add_child(shape)
	_interact.body_entered.connect(_on_body_entered)
	_interact.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player_in_range = body
	# Auto-open when approaching from the ranch side — that crossing is the
	# unlock quest; hotel side still needs the key / prior unlock.
	if not _opened and _is_on_ranch_side(body):
		_open_door()
		return
	if body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body != _player_in_range:
		return
	_player_in_range = null
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
