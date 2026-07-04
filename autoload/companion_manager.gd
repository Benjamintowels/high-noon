extends Node

const COMPANION_BALDWIN := &"baldwin"

var _recruited: Dictionary = {}
var _baldwin_hopeless_shown := false


func is_recruited(companion_id: StringName = COMPANION_BALDWIN) -> bool:
	return bool(_recruited.get(companion_id, false))


func set_recruited(companion_id: StringName, recruited: bool) -> void:
	_recruited[companion_id] = recruited


func has_baldwin_hopeless_shown() -> bool:
	return _baldwin_hopeless_shown


func set_baldwin_hopeless_shown(shown: bool) -> void:
	_baldwin_hopeless_shown = shown


func reset_baldwin_encounter() -> void:
	_baldwin_hopeless_shown = false
	set_recruited(COMPANION_BALDWIN, false)


func capture_snapshot() -> Dictionary:
	return {
		"recruited": _recruited.duplicate(true),
		"baldwin_hopeless_shown": _baldwin_hopeless_shown,
	}


func apply_snapshot(data: Dictionary) -> void:
	_recruited = data.get("recruited", {}).duplicate(true)
	_baldwin_hopeless_shown = bool(data.get("baldwin_hopeless_shown", false))


func request_companion_teleport(player: Node3D) -> void:
	if not is_recruited(COMPANION_BALDWIN):
		return
	if player == null or not is_instance_valid(player):
		return
	var tree := player.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"baldwin_npc"):
		if node.has_method(&"teleport_to_player_on_request"):
			node.call(&"teleport_to_player_on_request", player)
			return
