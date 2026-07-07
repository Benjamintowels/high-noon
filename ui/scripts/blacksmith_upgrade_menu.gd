extends Control
class_name BlacksmithUpgradeMenuPanel

signal menu_closed

@onready var _revolver_button: Button = $Panel/MarginContainer/VBoxContainer/RevolverButton
@onready var _armor_button: Button = $Panel/MarginContainer/VBoxContainer/ArmorButton
@onready var _blade_button: Button = $Panel/MarginContainer/VBoxContainer/BladeButton
@onready var _leave_button: Button = $Panel/MarginContainer/VBoxContainer/LeaveButton


func _ready() -> void:
	hide()
	_revolver_button.pressed.connect(_on_revolver_pressed)
	_armor_button.pressed.connect(_on_armor_pressed)
	_blade_button.pressed.connect(_on_blade_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)


func show_menu() -> void:
	_revolver_button.disabled = true
	_armor_button.disabled = true
	_blade_button.disabled = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_leave_button.grab_focus()


func hide_menu() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_revolver_pressed() -> void:
	pass


func _on_armor_pressed() -> void:
	pass


func _on_blade_pressed() -> void:
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
