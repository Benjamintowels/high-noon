extends Area3D

var _transitioning := false
var _player_in_range: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	return "Return to Caves"


func interact(player: Node3D) -> void:
	if _transitioning or player == null:
		return

	_transitioning = true
	var stage := get_tree().current_scene
	await AdventureSave.transition_from_boss_room(player, stage)
	_transitioning = false


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
