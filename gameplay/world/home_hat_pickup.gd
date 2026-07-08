extends Area3D

const PLAYER_SPEAKER := "Groyper"
const DIALOG_LINE := "What's a Cowboy without his hat?"

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
	shape_node.position = Vector3(0.0, 0.35, 0.0)
	add_child(shape_node)


func get_interact_hint() -> String:
	if _picked_up or _interacting:
		return ""
	return "Inspect Hat"


func interact(player: Node3D) -> void:
	if _picked_up or _interacting or player == null:
		return

	_interacting = true
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	DialogManager.show_dialog(
		PLAYER_SPEAKER,
		DIALOG_LINE,
		func() -> void:
			_complete_pickup(player)
	)


func _complete_pickup(player: Node3D) -> void:
	_interacting = false
	if _picked_up:
		_end_dialog(player)
		return

	PlayerInventory.add_hat(PlayerInventory.COWBOY_HAT_ID)

	if player.has_method("get_duel_hat"):
		var duel_hat: GroyperDuelHat = player.get_duel_hat()
		if duel_hat != null:
			duel_hat.prepare_for_round(false, true)

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
