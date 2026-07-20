extends Control
class_name BossHealthBar

const CombatHealthReadoutScript := preload("res://gameplay/ui/combat_health_readout.gd")
const BlockPoiseScript := preload("res://gameplay/combat/block_poise.gd")

const BAR_WIDTH := 520.0
const BAR_HEIGHT := 18.0
const BLOCK_BAR_HEIGHT := 12.0
const NAME_FONT_SIZE := 22
const BLOCK_GAP := 4.0

var _target: Node
var _display_health := 0.0
var _display_block := 0.0
var _name_label: Label
var _fill: ColorRect
var _background: ColorRect
var _border: ColorRect
var _block_fill: ColorRect
var _block_background: ColorRect
var _block_border: ColorRect
var _block_row: Control


static func attach_to(target: Node, boss_name: String = "TC") -> BossHealthBar:
	if target == null:
		return null

	var existing := target.get_node_or_null("BossHealthBar") as BossHealthBar
	if existing != null:
		return existing

	var layer := CanvasLayer.new()
	layer.name = "BossHealthLayer"
	layer.layer = 90
	target.get_tree().current_scene.add_child(layer)

	var bar := BossHealthBar.new()
	bar.name = "BossHealthBar"
	bar._target = target
	bar._build_ui(boss_name)
	var health_data := CombatHealthReadoutScript.read(target)
	bar._display_health = float(health_data.current)
	bar._display_block = BlockPoiseScript.get_current(target)
	layer.add_child(bar)
	target.tree_exiting.connect(bar._on_target_exiting.bind(layer))
	return bar


func _build_ui(boss_name: String) -> void:
	var block_row_h := BLOCK_BAR_HEIGHT + 4.0
	var health_row_h := BAR_HEIGHT + 4.0
	var stack_h := 28.0 + block_row_h + BLOCK_GAP + health_row_h
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -BAR_WIDTH * 0.5
	offset_right = BAR_WIDTH * 0.5
	offset_top = -48.0 - stack_h
	offset_bottom = -48.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_name_label = Label.new()
	_name_label.text = boss_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_name_label.position = Vector2(0.0, 0.0)
	_name_label.size = Vector2(BAR_WIDTH, 28.0)
	add_child(_name_label)

	var block_y := 30.0
	_block_row = Control.new()
	_block_row.name = "BlockRow"
	_block_row.position = Vector2(0.0, block_y)
	_block_row.size = Vector2(BAR_WIDTH, block_row_h)
	_block_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_block_row)

	_block_border = ColorRect.new()
	_block_border.color = Color(0.06, 0.1, 0.16, 0.95)
	_block_border.position = Vector2(0.0, 0.0)
	_block_border.size = Vector2(BAR_WIDTH, block_row_h)
	_block_row.add_child(_block_border)

	_block_background = ColorRect.new()
	_block_background.color = Color(0.08, 0.12, 0.2, 0.92)
	_block_background.position = Vector2(2.0, 2.0)
	_block_background.size = Vector2(BAR_WIDTH - 4.0, BLOCK_BAR_HEIGHT)
	_block_row.add_child(_block_background)

	_block_fill = ColorRect.new()
	_block_fill.color = Color(0.45, 0.82, 1.0, 1.0)
	_block_fill.position = Vector2(2.0, 2.0)
	_block_fill.size = Vector2(BAR_WIDTH - 4.0, BLOCK_BAR_HEIGHT)
	_block_row.add_child(_block_fill)

	var health_y := block_y + block_row_h + BLOCK_GAP
	_border = ColorRect.new()
	_border.color = Color(0.08, 0.06, 0.06, 0.95)
	_border.position = Vector2(0.0, health_y)
	_border.size = Vector2(BAR_WIDTH, health_row_h)
	add_child(_border)

	_background = ColorRect.new()
	_background.color = Color(0.18, 0.12, 0.12, 0.92)
	_background.position = Vector2(2.0, health_y + 2.0)
	_background.size = Vector2(BAR_WIDTH - 4.0, BAR_HEIGHT)
	add_child(_background)

	_fill = ColorRect.new()
	_fill.color = Color(0.72, 0.12, 0.1, 1.0)
	_fill.position = Vector2(2.0, health_y + 2.0)
	_fill.size = Vector2(BAR_WIDTH - 4.0, BAR_HEIGHT)
	add_child(_fill)


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return

	if _target.has_method("is_defeated") and _target.is_defeated():
		visible = false
		return

	visible = true
	var health_data := CombatHealthReadoutScript.read(_target)
	var max_health := maxf(float(health_data.max), 1.0)
	var current := float(health_data.current)
	_display_health = lerpf(_display_health, current, delta * 6.0)

	var ratio := clampf(_display_health / max_health, 0.0, 1.0)
	_fill.size.x = (BAR_WIDTH - 4.0) * ratio

	if ratio > 0.5:
		_fill.color = Color(0.72, 0.12, 0.1, 1.0)
	elif ratio > 0.25:
		_fill.color = Color(0.78, 0.28, 0.08, 1.0)
	else:
		_fill.color = Color(0.55, 0.08, 0.06, 1.0)

	_update_block_meter(delta)


func _update_block_meter(delta: float) -> void:
	var blocking := _is_target_blocking()
	var damaged := BlockPoiseScript.is_damaged(_target)
	var poise_max := BlockPoiseScript.get_max(_target)
	if poise_max <= 0.0 or (not blocking and not damaged):
		_block_row.visible = false
		return

	_block_row.visible = true
	var current_poise := BlockPoiseScript.get_current(_target)
	_display_block = lerpf(_display_block, current_poise, delta * 8.0)
	var block_ratio := clampf(_display_block / poise_max, 0.0, 1.0)
	_block_fill.size.x = maxf(0.0, (BAR_WIDTH - 4.0) * block_ratio)
	_block_fill.color = _block_color_for_ratio(block_ratio)
	_block_row.modulate = Color(1.0, 1.0, 1.0, 1.0 if blocking else 0.85)


func _is_target_blocking() -> bool:
	if _target.has_method("is_unarmed_blocking") and _target.is_unarmed_blocking():
		return true
	if _target.has_method("is_blocking") and _target.is_blocking():
		return true
	if "_blocking" in _target and bool(_target.get("_blocking")):
		return true
	return false


func _block_color_for_ratio(ratio: float) -> Color:
	if ratio > 0.55:
		return Color(0.4, 0.85, 1.15, 1.0)
	if ratio > 0.3:
		return Color(0.55, 0.88, 1.1, 1.0)
	return Color(1.0, 0.55, 0.25, 1.0)


func _on_target_exiting(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
