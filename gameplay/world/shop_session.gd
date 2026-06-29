extends Node

var _active := false
var _player_snapshot: Dictionary = {}
var _world_snapshot: Dictionary = {}


func is_inside_shop() -> bool:
	return _active


func save_before_enter(player: Node, stage: Node) -> void:
	if player.has_method("capture_overworld_snapshot"):
		_player_snapshot = player.capture_overworld_snapshot()
	else:
		_player_snapshot = {}
	_world_snapshot = _capture_world_snapshot(stage)
	_active = true


func enter_interior(player: Node, interior_marker: Marker3D) -> void:
	if interior_marker == null:
		return
	if player.has_method("teleport_to_position_only"):
		player.teleport_to_position_only(interior_marker.global_position, false)


func restore_after_exit(player: Node, stage: Node, fallback_marker: Marker3D = null) -> void:
	if _active and not _player_snapshot.is_empty():
		if player.has_method("apply_overworld_transform_snapshot"):
			player.apply_overworld_transform_snapshot(_player_snapshot.get("transform", {}))
		elif player.has_method("apply_overworld_snapshot"):
			player.apply_overworld_snapshot(_player_snapshot)
	elif fallback_marker != null and player.has_method("teleport_to_position_only"):
		player.teleport_to_position_only(fallback_marker.global_position)

	_restore_world_snapshot(stage, _world_snapshot)
	_player_snapshot = {}
	_world_snapshot = {}
	_active = false


func _capture_world_snapshot(stage: Node) -> Dictionary:
	if stage == null:
		return {}

	return {
		"stage_path": stage.scene_file_path,
	}


func _restore_world_snapshot(_stage: Node, _snapshot: Dictionary) -> void:
	pass
