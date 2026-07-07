extends Area3D
class_name CaveEntranceDoor

var _transitioning := false
var _player_in_range: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	return "Enter Caves"


func interact(player: Node3D) -> void:
	if _transitioning or player == null:
		return

	_transitioning = true
	var stage := get_tree().current_scene
	var return_marker := _find_return_marker(stage)
	await AdventureSave.transition_to_caves(player, stage, return_marker)
	_transitioning = false


func _find_return_marker(stage: Node) -> Marker3D:
	if stage == null:
		return null
	var cave_spawn := stage.get_node_or_null("CavePuzzle/CaveEntrance") as Marker3D
	if cave_spawn != null:
		return cave_spawn
	return stage.get_node_or_null("cliff_base/RuinsStart") as Marker3D


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
