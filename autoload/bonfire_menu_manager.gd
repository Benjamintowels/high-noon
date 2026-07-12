extends Node

const BONFIRE_MENU_SCENE := preload("res://ui/scenes/bonfire_menu.tscn")

var _layer: CanvasLayer
var _menu: BonfireMenuPanel
var _active := false
var _on_rest: Callable = Callable()
var _on_close: Callable = Callable()
var _on_travel: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 105
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_menu = BONFIRE_MENU_SCENE.instantiate() as BonfireMenuPanel
	_layer.add_child(_menu)
	_menu.hide()
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu.rest_selected.connect(_on_rest_selected)
	_menu.menu_closed.connect(_on_menu_closed)
	_menu.travel_selected.connect(_on_travel_destination_selected)


func is_showing() -> bool:
	return _active


func show_menu(
	on_rest: Callable = Callable(),
	on_close: Callable = Callable(),
	on_travel: Callable = Callable(),
	current_bonfire_id: String = ""
) -> void:
	_on_rest = on_rest
	_on_close = on_close
	_on_travel = on_travel
	_active = true
	_menu.show_menu(current_bonfire_id)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_menu() -> void:
	_active = false
	_menu.hide_menu()
	_clear_callbacks()
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _clear_callbacks() -> void:
	_on_rest = Callable()
	_on_close = Callable()
	_on_travel = Callable()


func _on_rest_selected() -> void:
	_active = false
	var callback := _on_rest
	_clear_callbacks()
	if callback.is_valid():
		callback.call()


func _on_menu_closed() -> void:
	_active = false
	var callback := _on_close
	_clear_callbacks()
	if callback.is_valid():
		callback.call()
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_travel_destination_selected(entry: Dictionary) -> void:
	_active = false
	var callback := _on_travel
	_clear_callbacks()
	if callback.is_valid():
		callback.call(entry)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
