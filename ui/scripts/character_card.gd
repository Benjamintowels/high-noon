extends PanelContainer
class_name CharacterCard

signal card_selected(card: CharacterCard)

@export var character_id: String = ""
@export var display_name: String = "Cowboy"
@export var portrait: Texture2D
@export var locked: bool = false

const SELECTED_BORDER := Color(0.98, 0.82, 0.28, 1.0)
const NORMAL_BORDER := Color(0.45, 0.32, 0.14, 0.0)

@onready var _select_border: Panel = $SelectBorder
@onready var _portrait: TextureRect = $MarginContainer/VBox/PortraitFrame/Portrait
@onready var _name_label: Label = $MarginContainer/VBox/NameLabel
@onready var _lock_overlay: Control = $LockOverlay

var is_selected: bool = false


func _ready() -> void:
	theme_type_variation = &"CharacterCard"
	if _name_label:
		_name_label.text = display_name
	if _portrait:
		_portrait.texture = portrait
		_portrait.visible = portrait != null
	if _lock_overlay:
		_lock_overlay.visible = locked
	_update_selection_visual()
	_update_interaction()


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit(self)


func _notification(what: int) -> void:
	if locked:
		return
	if what == NOTIFICATION_MOUSE_ENTER:
		if not is_selected:
			modulate = Color(1.06, 1.03, 0.94, 1.0)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_update_selection_visual()


func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_selection_visual()


func _update_selection_visual() -> void:
	if is_node_ready() and _select_border:
		_select_border.visible = is_selected and not locked
	if is_selected and not locked:
		modulate = Color(1.05, 1.02, 0.92, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_interaction() -> void:
	if locked:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(0.55, 0.52, 0.48, 1.0)
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
