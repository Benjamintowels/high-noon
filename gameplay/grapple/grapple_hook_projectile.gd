extends Node3D
class_name GrappleHookProjectile

signal arrived
signal retract_finished

const HOOK_RADIUS := 0.18

var _flight_active := false
var _flight_timer := 0.0
var _flight_duration := 0.18
var _flight_start := Vector3.ZERO
var _flight_end := Vector3.ZERO
var _retract_active := false
var _retract_timer := 0.0
var _retract_duration := 0.22
var _retract_start := Vector3.ZERO
var _retract_target := Vector3.ZERO
var _attached := false


func _ready() -> void:
	set_physics_process(false)


func is_attached() -> bool:
	return _attached


func get_hook_point() -> Vector3:
	return global_position


func launch(from: Vector3, to: Vector3, duration: float) -> void:
	_flight_active = true
	_flight_timer = 0.0
	_flight_duration = maxf(duration, 0.05)
	_flight_start = from
	_flight_end = to
	_retract_active = false
	_attached = false
	global_position = from
	visible = true
	set_physics_process(true)


func begin_retract(target: Vector3, duration: float) -> void:
	_retract_active = true
	_retract_timer = 0.0
	_retract_duration = maxf(duration, 0.05)
	_retract_start = global_position
	_retract_target = target
	_flight_active = false
	_attached = false
	set_physics_process(true)


func snap_hidden() -> void:
	_flight_active = false
	_retract_active = false
	_attached = false
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _flight_active:
		_process_flight(delta)
	elif _retract_active:
		_process_retract(delta)


func _process_flight(delta: float) -> void:
	_flight_timer += delta
	var t := clampf(_flight_timer / _flight_duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 2.4)
	var pos := _flight_start.lerp(_flight_end, eased)
	var span := _flight_start.distance_to(_flight_end)
	pos.y += sin(t * PI) * clampf(span * 0.08, 0.15, 1.2)
	global_position = pos

	if t >= 1.0:
		_flight_active = false
		_attached = true
		global_position = _flight_end
		arrived.emit()


func _process_retract(delta: float) -> void:
	_retract_timer += delta
	var t := clampf(_retract_timer / _retract_duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _retract_start.lerp(_retract_target, eased)
	if t >= 1.0:
		snap_hidden()
		retract_finished.emit()
