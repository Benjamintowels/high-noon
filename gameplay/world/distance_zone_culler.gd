extends Node
class_name DistanceZoneCuller

const StageZoneCuller := preload("res://gameplay/world/stage_zone_culler.gd")

signal zone_activated
signal zone_deactivated

@export var target: Node3D
@export var player_path: NodePath
@export var activate_distance := 90.0
@export var deactivate_distance := 110.0
@export var check_interval := 0.35
@export var start_active := false

var _player: Node3D
var _active := false
var _timer := 0.0
var _suspended := false


func _ready() -> void:
	_active = start_active
	if target != null:
		StageZoneCuller.set_zone_active(target, _active)
	if not player_path.is_empty():
		call_deferred("_refresh_player")
		call_deferred("_evaluate_zone", true)


func bind_player(player: Node3D) -> void:
	_player = player
	player_path = NodePath()
	if not _suspended:
		_evaluate_zone(true)


## When true, distance checks pause — an external system (canyon gates) owns
## the target zone's active state until unsuspended.
func set_suspended(suspended: bool) -> void:
	_suspended = suspended
	if not _suspended:
		_evaluate_zone(true)


func is_suspended() -> bool:
	return _suspended


func force_set_active(active: bool) -> void:
	if target == null:
		return
	var was_active := _active
	_active = active
	StageZoneCuller.set_zone_active(target, _active)
	if _active == was_active:
		return
	if _active:
		zone_activated.emit()
	else:
		zone_deactivated.emit()


func _refresh_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	if player_path.is_empty():
		return
	var stage := get_tree().current_scene
	if stage == null:
		return
	_player = stage.get_node_or_null(player_path) as Node3D


func _process(delta: float) -> void:
	if _suspended or target == null or _player == null or not is_instance_valid(_player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = check_interval
	_evaluate_zone(false)


func _evaluate_zone(force: bool) -> void:
	if _suspended or target == null or _player == null or not is_instance_valid(_player):
		return

	var distance_sq := target.global_position.distance_squared_to(_player.global_position)
	var should_activate := _active
	if _active:
		if distance_sq > deactivate_distance * deactivate_distance:
			should_activate = false
	elif distance_sq <= activate_distance * activate_distance:
		should_activate = true

	if not force and should_activate == _active:
		return

	_active = should_activate
	StageZoneCuller.set_zone_active(target, _active)
	if _active:
		zone_activated.emit()
	else:
		zone_deactivated.emit()
