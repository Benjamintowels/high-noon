extends Node

const INVENTORY_MENU_SCENE := preload("res://ui/scenes/inventory_menu.tscn")

var _layer: CanvasLayer
var _menu: InventoryMenuPanel
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 110
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_menu = INVENTORY_MENU_SCENE.instantiate() as InventoryMenuPanel
	_layer.add_child(_menu)
	_menu.hide()
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS

	PlayerInventory.inventory_changed.connect(_on_inventory_changed)


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	_menu.refresh()
	_menu.show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	if not _open:
		return
	_open = false
	_menu.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _on_inventory_changed() -> void:
	if _open and _menu != null:
		_menu.refresh()


func _input(event: InputEvent) -> void:
	if not _is_escape_pressed(event):
		return

	if _open:
		close()
		get_viewport().set_input_as_handled()
		return

	if ShopBuyManager.is_showing():
		ShopBuyManager.cancel_dialog()
		_set_overworld_player_dialog_active(false)
		get_viewport().set_input_as_handled()
		return

	if not _can_open_inventory():
		return

	open()
	get_viewport().set_input_as_handled()


func _is_escape_pressed(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	return event.keycode == KEY_ESCAPE or event.is_action("ui_cancel")


func _can_open_inventory() -> bool:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return false
	var player: Node = players[0]
	if player.has_method("is_inventory_menu_blocked"):
		return not player.is_inventory_menu_blocked()
	return true


func _set_overworld_player_dialog_active(active: bool) -> void:
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return
	var player: Node = players[0]
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(active)
