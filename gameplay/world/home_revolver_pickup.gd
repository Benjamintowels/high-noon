extends Area3D

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const PLAYER_SPEAKER := "Groyper"

var _dialog_lines := PackedStringArray([
	"its loaded",
	"pick it up",
])

var display_node: Node3D

var _picked_up := false
var _interacting := false
var _player_in_range: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.35
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 0.45, 0.0)
	add_child(shape_node)


func get_interact_hint() -> String:
	if _picked_up or _interacting:
		return ""
	return "Inspect Revolver"


func interact(player: Node3D) -> void:
	if _picked_up or _interacting or player == null:
		return

	_interacting = true
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog_sequence(
		_dialog_lines,
		func() -> void:
			_complete_pickup(player),
		PLAYER_SPEAKER,
		func(line_index: int) -> void:
			if line_index == 1:
				GameAudio.play_weapon_reload_grab(self, GroyperWeapons.Id.REVOLVER, global_position)
	)


func _complete_pickup(player: Node3D) -> void:
	_interacting = false
	if _picked_up:
		_end_dialog(player)
		return

	if not PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER):
		PlayerInventory.add_weapon(GroyperWeapons.Id.REVOLVER)

	if player.has_method("equip_weapon"):
		player.equip_weapon(GroyperWeapons.Id.REVOLVER, true)
	if player.has_method("refresh_stowed_weapon_visuals"):
		player.refresh_stowed_weapon_visuals()
	if player.has_method("notify_weapon_inventory_changed"):
		player.notify_weapon_inventory_changed()

	_picked_up = true
	_hide_display()
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	_end_dialog(player)


func _hide_display() -> void:
	if display_node != null and is_instance_valid(display_node):
		display_node.queue_free()
		display_node = null
	monitoring = false
	visible = false


func _end_dialog(player: Node3D) -> void:
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if not InventoryMenuManager.is_open() and not TownMapManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
