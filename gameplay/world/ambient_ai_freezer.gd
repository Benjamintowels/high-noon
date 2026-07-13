extends Node
class_name AmbientAiFreezer

## Soft-freezes ambient NPCs and animals far from the player: only their own
## _process/_physics_process stop, so child nodes (ragdolls, audio, fires)
## keep running and method calls (bullet hits, dialog) still work. Anything
## whose is_ambient_freezable() flips false — combat, lasso, a sniper hit —
## is unfrozen on the next poll.

const CHECK_INTERVAL := 0.5
const FREEZE_DISTANCE := 115.0
## Hysteresis so actors near the boundary don't flap between states.
const UNFREEZE_DISTANCE := 100.0

const MANAGED_GROUPS: Array[StringName] = [
	&"town_npc",
	&"stupid_horse",
	&"cow",
	&"ground_bird",
]

var _frozen: Dictionary = {}
var _check_accum := 0.0


func _process(delta: float) -> void:
	_check_accum += delta
	if _check_accum < CHECK_INTERVAL:
		return
	_check_accum = 0.0

	_prune_frozen()

	var player := _find_player()
	if player == null:
		_unfreeze_all()
		return

	var player_pos := player.global_position
	var freeze_sq := FREEZE_DISTANCE * FREEZE_DISTANCE
	var unfreeze_sq := UNFREEZE_DISTANCE * UNFREEZE_DISTANCE

	for group_name in MANAGED_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			var body := node as Node3D
			if body == null or not is_instance_valid(body):
				continue

			var dist_sq := body.global_position.distance_squared_to(player_pos)
			if _frozen.has(body.get_instance_id()):
				if dist_sq <= unfreeze_sq or not _is_freezable(body):
					_unfreeze(body)
			elif dist_sq >= freeze_sq and _is_freezable(body):
				_freeze(body)


func _is_freezable(body: Node3D) -> bool:
	# Only actors that explicitly opt in are ever frozen — anything without
	# the method (bosses, quest NPCs, companions) is left alone.
	if not body.has_method("is_ambient_freezable"):
		return false
	return bool(body.call("is_ambient_freezable"))


func _freeze(body: Node3D) -> void:
	body.set_physics_process(false)
	body.set_process(false)
	_frozen[body.get_instance_id()] = body


func _unfreeze(body: Node3D) -> void:
	_frozen.erase(body.get_instance_id())
	body.set_physics_process(true)
	body.set_process(true)


func _unfreeze_all() -> void:
	for id in _frozen.keys():
		# Untyped on purpose: assigning a freed instance to a typed var
		# raises "Trying to assign invalid previously freed instance"
		# BEFORE is_instance_valid can run.
		var body = _frozen[id]
		if is_instance_valid(body):
			body.set_physics_process(true)
			body.set_process(true)
	_frozen.clear()


func _prune_frozen() -> void:
	for id in _frozen.keys():
		var body = _frozen[id]  # untyped: may hold a freed instance
		if not is_instance_valid(body) or not body.is_inside_tree():
			_frozen.erase(id)


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D
