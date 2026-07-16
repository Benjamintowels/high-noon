extends Area3D

## Interactable run prop. Player summons the stage boss through the RunDirector.

@export var interact_hint := "Summon the Chief"

var _director: Node
var _used := false
var _player_in_range: Node3D


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func bind_director(director: Node) -> void:
	_director = director


func mark_used() -> void:
	_used = true
	monitoring = false
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	_player_in_range = null


func get_interact_hint() -> String:
	if _used:
		return ""
	return interact_hint


func interact(player: Node3D) -> void:
	if _used or player == null:
		return
	if _director == null:
		_director = _find_director()
	if _director == null or not _director.has_method("request_summon_boss"):
		push_warning("BossTower: no RunDirector bound.")
		return
	_director.request_summon_boss(self, player)


func _find_director() -> Node:
	var stage := get_tree().current_scene
	if stage != null:
		var director := stage.get_node_or_null("RunDirector")
		if director != null:
			return director
	for node in get_tree().get_nodes_in_group("run_director"):
		if is_instance_valid(node):
			return node
	return null


func _on_body_entered(body: Node3D) -> void:
	if _used:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
