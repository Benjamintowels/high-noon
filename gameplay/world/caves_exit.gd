extends Area3D

const INTERACT_RANGE := 2.75

var _transitioning := false
var _player_in_range: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	return "Return to Town"


func interact(player: Node3D) -> void:
	if _transitioning or player == null:
		return

	_transitioning = true
	await AdventureSave.transition_to_town(player, get_tree().current_scene)
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
