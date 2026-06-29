extends Area3D
class_name ShopItemDisplay

@export var weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.REVOLVER
@export var price_gram := 15
@export var display_name := "Revolver"

var _sold := false
var _player_in_range: Node3D
var _display_root: Node3D
var _sold_label: Label3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_display_mesh()


func get_interact_hint() -> String:
	if _sold:
		return ""
	return "Buy %s" % display_name


func interact(player: Node3D) -> void:
	if _sold or player == null or ShopBuyManager.is_showing():
		return

	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)

	ShopBuyManager.show_purchase(
		display_name,
		price_gram,
		func() -> void:
			_complete_purchase(player),
		func() -> void:
			_cancel_purchase(player)
	)


func _spawn_display_mesh() -> void:
	_display_root = Node3D.new()
	_display_root.name = "DisplayMesh"
	add_child(_display_root)

	var grip_scene := GroyperWeapons.get_grip_scene(weapon_id)
	var grip: Node3D = grip_scene.instantiate()
	_display_root.add_child(grip)
	grip.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	grip.scale = _get_display_scale()

	_sold_label = Label3D.new()
	_sold_label.text = "SOLD"
	_sold_label.font_size = 28
	_sold_label.modulate = Color(0.9, 0.25, 0.2, 1.0)
	_sold_label.position = Vector3(0.0, 0.15, 0.0)
	_sold_label.visible = false
	_display_root.add_child(_sold_label)


func _get_display_scale() -> Vector3:
	match weapon_id:
		GroyperWeapons.Id.SHOTGUN:
			return Vector3(1.1, 1.1, 1.1)
		_:
			return Vector3(1.35, 1.35, 1.35)


func _complete_purchase(player: Node3D) -> void:
	if _sold:
		_finish_purchase_ui(player)
		return

	if not PlayerInventory.can_afford(price_gram):
		_finish_purchase_ui(player)
		return

	if not PlayerInventory.spend_gram(price_gram):
		_finish_purchase_ui(player)
		return

	PlayerInventory.add_weapon(weapon_id)

	_sold = true
	if _display_root != null:
		for child in _display_root.get_children():
			if child == _sold_label:
				continue
			if child is Node3D:
				child.visible = false
	if _sold_label != null:
		_sold_label.visible = true

	_finish_purchase_ui(player)


func _cancel_purchase(player: Node3D) -> void:
	_finish_purchase_ui(player)


func _finish_purchase_ui(player: Node3D) -> void:
	if player != null and player.has_method("set_dialog_active"):
		player.set_dialog_active(false)
	if not InventoryMenuManager.is_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_body_entered(body: Node3D) -> void:
	if _sold:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
