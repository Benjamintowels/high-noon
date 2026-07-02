extends Node3D
class_name Bonfire

const INTERACT_APPROACH_TIME := 0.85
const LIGHT_TIME := 1.1

@onready var _interact_area: Area3D = $InteractArea

var _fire_visual: Node3D

var _lit := false
var _busy := false
var _menu_done := false
var _player_in_range: Node3D


func _ready() -> void:
	_interact_area.monitoring = true
	_interact_area.monitorable = false
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)
	_fire_visual = get_node_or_null("AltarFire/Fire")
	_set_fire_visible(_lit)


func get_interact_hint() -> String:
	return "Rest at Bonfire" if _lit else "Light Bonfire"


func interact(player: Node3D) -> void:
	if _busy or player == null:
		return
	_busy = true
	await _perform_bonfire_sequence(player)
	_busy = false


func respawn_cave_enemies() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("respawn_enemy"):
			node.respawn_enemy()


func _perform_bonfire_sequence(player: Node3D) -> void:
	if player.has_method("begin_bonfire_interaction"):
		player.begin_bonfire_interaction(self)

	await get_tree().create_timer(INTERACT_APPROACH_TIME).timeout

	if not _lit:
		if player.has_method("begin_bonfire_cinematic_camera"):
			player.begin_bonfire_cinematic_camera(self)
		_lit = true
		_set_fire_visible(true)
		await get_tree().create_timer(LIGHT_TIME).timeout
	elif player.has_method("begin_bonfire_cinematic_camera"):
		player.begin_bonfire_cinematic_camera(self)

	BonfireMenuManager.show_menu(
		Callable(self, "_on_rest_selected").bind(player),
		Callable(self, "_on_menu_closed").bind(player)
	)
	_menu_done = false
	while not _menu_done:
		await get_tree().process_frame


func _on_rest_selected(player: Node3D) -> void:
	if player != null and player.has_method("rest_at_bonfire"):
		player.rest_at_bonfire()
	respawn_cave_enemies()
	var stage := get_tree().current_scene
	AdventureSave.sync_runtime_state(player, stage)
	_finish_bonfire_menu(player)


func _on_menu_closed(player: Node3D) -> void:
	_finish_bonfire_menu(player)


func _finish_bonfire_menu(player: Node3D) -> void:
	BonfireMenuManager.hide_menu()
	if player != null:
		if player.has_method("begin_bonfire_cinematic_camera_exit"):
			player.begin_bonfire_cinematic_camera_exit()
		if player.has_method("end_bonfire_interaction"):
			player.end_bonfire_interaction()
	_menu_done = true


func _set_fire_visible(active: bool) -> void:
	if _fire_visual != null:
		_fire_visual.visible = active


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
