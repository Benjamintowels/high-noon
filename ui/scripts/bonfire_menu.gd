extends Control
class_name BonfireMenuPanel

signal rest_selected
signal menu_closed

@onready var _rest_button: Button = $Panel/MarginContainer/VBoxContainer/RestButton
@onready var _level_up_button: Button = $Panel/MarginContainer/VBoxContainer/LevelUpButton
@onready var _leave_button: Button = $Panel/MarginContainer/VBoxContainer/LeaveButton


func _ready() -> void:
	hide()
	_rest_button.pressed.connect(_on_rest_pressed)
	_level_up_button.pressed.connect(_on_level_up_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)


func show_menu() -> void:
	_level_up_button.disabled = true
	_level_up_button.text = "Level Up (Coming Soon)"
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_rest_button.grab_focus()


func hide_menu() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_rest_pressed() -> void:
	hide_menu()
	rest_selected.emit()


func _on_level_up_pressed() -> void:
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
