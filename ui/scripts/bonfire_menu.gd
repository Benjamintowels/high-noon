extends Control
class_name BonfireMenuPanel

signal rest_selected
signal menu_closed

@onready var _rest_button: Button = $Panel/MarginContainer/VBoxContainer/RestButton
@onready var _soul_shards_label: Label = $Panel/MarginContainer/VBoxContainer/SoulShardsLabel
@onready var _vitality_button: Button = $Panel/MarginContainer/VBoxContainer/VitalityUpgradeButton
@onready var _strength_button: Button = $Panel/MarginContainer/VBoxContainer/StrengthUpgradeButton
@onready var _leave_button: Button = $Panel/MarginContainer/VBoxContainer/LeaveButton


func _ready() -> void:
	hide()
	_rest_button.pressed.connect(_on_rest_pressed)
	_vitality_button.pressed.connect(_on_vitality_pressed)
	_strength_button.pressed.connect(_on_strength_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)


func show_menu() -> void:
	var soul_shards := PlayerInventory.get_soul_shards()
	_soul_shards_label.text = "Soul Shards: %d" % soul_shards
	_vitality_button.disabled = true
	_vitality_button.text = "Vitality (Coming Soon)"
	_strength_button.disabled = true
	_strength_button.text = "Strength (Coming Soon)"
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_rest_button.grab_focus()


func hide_menu() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_rest_pressed() -> void:
	hide_menu()
	rest_selected.emit()


func _on_vitality_pressed() -> void:
	pass


func _on_strength_pressed() -> void:
	pass


func _on_leave_pressed() -> void:
	hide_menu()
	menu_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		_on_leave_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_rest_pressed()
		get_viewport().set_input_as_handled()
