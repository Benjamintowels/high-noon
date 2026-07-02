extends Node

const TOWN_MAP_SCENE := preload("res://ui/scenes/town_map_ui.tscn")

var _layer: CanvasLayer
var _map: TownMapPanel
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 115
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_map = TOWN_MAP_SCENE.instantiate() as TownMapPanel
	_layer.add_child(_map)
	_map.hide()
	_map.process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _open


func open() -> void:
	if _open or not PlayerInventory.has_treasure_map:
		return
	if not _can_open_map():
		return
	_open = true
	_map.show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close() -> void:
	if not _open:
		return
	_open = false
	_map.hide()
	get_tree().paused = false
	if not InventoryMenuManager.is_open() and not DialogManager.is_showing() and not ShopBuyManager.is_showing():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _input(event: InputEvent) -> void:
	if _is_map_key_pressed(event):
		if PlayerInventory.has_treasure_map and _can_open_map():
			toggle()
			get_viewport().set_input_as_handled()
		return

	if not _is_escape_pressed(event):
		return

	if _open:
		close()
		get_viewport().set_input_as_handled()


func _is_map_key_pressed(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	return event.keycode == KEY_M


func _is_escape_pressed(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	return event.keycode == KEY_ESCAPE or event.is_action("ui_cancel")


func _can_open_map() -> bool:
	if DialogManager.is_showing() or ShopBuyManager.is_showing():
		return false
	var players := get_tree().get_nodes_in_group("overworld_player")
	if players.is_empty():
		return false
	var player: Node = players[0]
	if player.has_method("is_inventory_menu_blocked"):
		return not player.is_inventory_menu_blocked()
	return true
