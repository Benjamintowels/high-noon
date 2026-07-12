extends Control
class_name BonfireMenuPanel

signal rest_selected
signal menu_closed
signal travel_selected(entry: Dictionary)

@onready var _rest_button: Button = $Panel/MarginContainer/VBoxContainer/RestButton
@onready var _soul_shards_label: Label = $Panel/MarginContainer/VBoxContainer/SoulShardsLabel
@onready var _vitality_button: Button = $Panel/MarginContainer/VBoxContainer/VitalityUpgradeButton
@onready var _strength_button: Button = $Panel/MarginContainer/VBoxContainer/StrengthUpgradeButton
@onready var _travel_button: Button = $Panel/MarginContainer/VBoxContainer/TravelButton
@onready var _leave_button: Button = $Panel/MarginContainer/VBoxContainer/LeaveButton
@onready var _travel_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/TravelContainer
@onready var _travel_back_button: Button = $Panel/MarginContainer/VBoxContainer/TravelContainer/BackButton

var _current_bonfire_id := ""
var _destinations: Array[Dictionary] = []
var _travel_open := false


func _ready() -> void:
	hide()
	_rest_button.pressed.connect(_on_rest_pressed)
	_vitality_button.pressed.connect(_on_vitality_pressed)
	_strength_button.pressed.connect(_on_strength_pressed)
	_travel_button.pressed.connect(_on_travel_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)
	_travel_back_button.pressed.connect(_on_travel_back_pressed)


func show_menu(current_bonfire_id: String = "") -> void:
	_current_bonfire_id = current_bonfire_id
	_destinations = _collect_destinations()
	_close_travel_list()
	var soul_shards := PlayerInventory.get_soul_shards()
	_soul_shards_label.text = "Soul Shards: %d" % soul_shards
	_vitality_button.disabled = true
	_vitality_button.text = "Vitality (Coming Soon)"
	_strength_button.disabled = true
	_strength_button.text = "Strength (Coming Soon)"
	_travel_button.disabled = _destinations.is_empty()
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_rest_button.grab_focus()


func hide_menu() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _collect_destinations() -> Array[Dictionary]:
	var entries := AdventureSave.get_lit_bonfires()
	# Home base is always a destination, even on saves recorded before it
	# was written into lit_bonfires at new-game spawn.
	entries.push_front(BonfireTravelManager.HOTEL_TRAVEL_ENTRY.duplicate(true))
	var result: Array[Dictionary] = []
	var seen := {}
	for entry in entries:
		var id := str(entry.get("id", ""))
		if id == "" or seen.has(id):
			continue
		if not bool(entry.get("travelable", false)):
			continue
		if id == _current_bonfire_id:
			continue
		if str(entry.get("stage_path", "")) == "":
			continue
		seen[id] = true
		result.append(entry)
	return result


func _open_travel_list() -> void:
	_travel_open = true
	_set_main_buttons_visible(false)
	_rebuild_travel_destinations()
	_travel_container.show()
	var first := _travel_container.get_child(0) as Button
	if first != null:
		first.grab_focus()


func _close_travel_list() -> void:
	_travel_open = false
	_travel_container.hide()
	_set_main_buttons_visible(true)


func _set_main_buttons_visible(main_visible: bool) -> void:
	_rest_button.visible = main_visible
	_vitality_button.visible = main_visible
	_strength_button.visible = main_visible
	_travel_button.visible = main_visible
	_leave_button.visible = main_visible


func _rebuild_travel_destinations() -> void:
	for child in _travel_container.get_children():
		if child != _travel_back_button:
			_travel_container.remove_child(child)
			child.queue_free()
	for entry in _destinations:
		var button := Button.new()
		button.text = str(entry.get("name", "Bonfire"))
		button.pressed.connect(_on_destination_pressed.bind(entry))
		_travel_container.add_child(button)
		_travel_container.move_child(button, _travel_container.get_child_count() - 2)


func _on_travel_pressed() -> void:
	_open_travel_list()


func _on_travel_back_pressed() -> void:
	_close_travel_list()
	_travel_button.grab_focus()


func _on_destination_pressed(entry: Dictionary) -> void:
	hide_menu()
	travel_selected.emit(entry)


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
		if _travel_open:
			_on_travel_back_pressed()
		else:
			_on_leave_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not _travel_open:
		_on_rest_pressed()
		get_viewport().set_input_as_handled()
