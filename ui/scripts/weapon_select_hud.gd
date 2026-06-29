extends CanvasLayer
class_name WeaponSelectHud

const SHOW_DURATION := 2.0
const FADE_DURATION := 0.6
const ICON_SIZE := 52
const ACTIVE_SCALE := 1.15

@onready var _root: Control = $MarginContainer
@onready var _panel: HBoxContainer = $MarginContainer/Panel

var _fade_timer := 0.0


func _ready() -> void:
	_root.visible = false
	_root.modulate.a = 0.0


func show_weapons(weapon_ids: Array[int], active_weapon_id: int) -> void:
	_rebuild_icons(weapon_ids, active_weapon_id)
	_root.modulate.a = 1.0
	_fade_timer = SHOW_DURATION
	_root.visible = true


func _process(delta: float) -> void:
	if not _root.visible:
		return
	if _fade_timer > 0.0:
		_fade_timer = maxf(_fade_timer - delta, 0.0)
		return
	_root.modulate.a = maxf(_root.modulate.a - delta / FADE_DURATION, 0.0)
	if _root.modulate.a <= 0.0:
		_root.visible = false


func _rebuild_icons(weapon_ids: Array[int], active_weapon_id: int) -> void:
	for child in _panel.get_children():
		child.queue_free()

	for weapon_id: int in weapon_ids:
		var slot := VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_theme_constant_override("separation", 4)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = GroyperWeapons.get_icon(weapon_id)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var is_active := weapon_id == active_weapon_id
		icon_rect.scale = Vector2.ONE * (ACTIVE_SCALE if is_active else 1.0)
		icon_rect.modulate = Color(1.0, 0.95, 0.72, 1.0) if is_active else Color(0.72, 0.68, 0.58, 0.9)
		slot.add_child(icon_rect)

		var label := Label.new()
		label.text = PlayerInventory.get_weapon_display_name(weapon_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.modulate = Color(1.0, 0.95, 0.72, 1.0) if is_active else Color(0.8, 0.76, 0.68, 0.85)
		slot.add_child(label)

		_panel.add_child(slot)
