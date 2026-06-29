extends Control
class_name ShopBuyDialogPanel

signal purchase_confirmed
signal purchase_cancelled

@onready var _title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var _price_label: Label = $Panel/MarginContainer/VBoxContainer/PriceLabel
@onready var _buy_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/BuyButton
@onready var _cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/CancelButton


func _ready() -> void:
	hide()
	_buy_button.pressed.connect(_on_buy_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func show_purchase(item_name: String, price_gram: int, can_afford: bool) -> void:
	_title_label.text = item_name
	_price_label.text = "%d Gram" % price_gram
	_buy_button.disabled = not can_afford
	if can_afford:
		_buy_button.text = "Buy"
	else:
		_buy_button.text = "Not enough Gram"
	show()


func hide_dialog() -> void:
	hide()


func _on_buy_pressed() -> void:
	hide_dialog()
	purchase_confirmed.emit()


func _on_cancel_pressed() -> void:
	hide_dialog()
	purchase_cancelled.emit()
