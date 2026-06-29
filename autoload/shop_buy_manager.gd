extends Node

const SHOP_BUY_DIALOG_SCENE := preload("res://ui/scenes/shop_buy_dialog.tscn")

var _layer: CanvasLayer
var _dialog: ShopBuyDialogPanel
var _active := false
var _on_confirm: Callable = Callable()
var _on_cancel: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 105
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_dialog = SHOP_BUY_DIALOG_SCENE.instantiate() as ShopBuyDialogPanel
	_layer.add_child(_dialog)
	_dialog.hide()
	_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	_dialog.purchase_confirmed.connect(_on_purchase_confirmed)
	_dialog.purchase_cancelled.connect(_on_purchase_cancelled)


func is_showing() -> bool:
	return _active


func show_purchase(
	item_name: String,
	price_gram: int,
	on_confirm: Callable = Callable(),
	on_cancel: Callable = Callable()
) -> void:
	_on_confirm = on_confirm
	_on_cancel = on_cancel
	_active = true
	_dialog.show_purchase(item_name, price_gram, PlayerInventory.can_afford(price_gram))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_dialog() -> void:
	_active = false
	_dialog.hide_dialog()
	_on_confirm = Callable()
	_on_cancel = Callable()


func cancel_dialog() -> void:
	if not _active:
		return
	_on_purchase_cancelled()


func _on_purchase_confirmed() -> void:
	_active = false
	var callback := _on_confirm
	_on_confirm = Callable()
	_on_cancel = Callable()
	if callback.is_valid():
		callback.call()


func _on_purchase_cancelled() -> void:
	_active = false
	var callback := _on_cancel
	_on_confirm = Callable()
	_on_cancel = Callable()
	if callback.is_valid():
		callback.call()
