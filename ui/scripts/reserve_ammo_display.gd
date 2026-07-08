class_name ReserveAmmoDisplay
extends HBoxContainer

const LABEL_COLOR := Color(0.92, 0.82, 0.58, 1.0)
const ICON_SIZE := Vector2(26, 12)

var _icon: Control
var _count_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(56, 28)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_END
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_icon = Control.new()
	_icon.name = "BrassBulletIcon"
	_icon.custom_minimum_size = ICON_SIZE
	_icon.size = ICON_SIZE
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_script(preload("res://ui/scripts/brass_bullet_icon.gd"))
	add_child(_icon)

	_count_label = Label.new()
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_count_label.add_theme_color_override("font_color", LABEL_COLOR)
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_count_label)

	sync_count(0)


func sync_count(count: int) -> void:
	var clamped := maxi(count, 0)
	_count_label.text = "x%d" % clamped
	modulate = Color(1.0, 1.0, 1.0, 1.0) if clamped > 0 else Color(0.65, 0.65, 0.65, 0.75)
