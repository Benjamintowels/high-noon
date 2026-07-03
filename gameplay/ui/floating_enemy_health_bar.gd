extends Node3D
class_name FloatingEnemyHealthBar

const CombatHealthReadoutScript := preload("res://gameplay/ui/combat_health_readout.gd")

const VIEWPORT_SIZE := Vector2i(52, 7)
const PIXEL_SIZE := 0.00165
const HEAD_CLEARANCE := 0.16
const SHORT_HEAD_HEIGHT := 1.08
const TALL_HEAD_HEIGHT := 1.48

var _target: Node3D
var _sprite: Sprite3D
var _viewport: SubViewport
var _fill: ColorRect
var _last_ratio := -1.0


static func attach_to(target: Node3D) -> FloatingEnemyHealthBar:
	if target == null or not is_instance_valid(target):
		return null
	if not target.is_in_group("cave_enemy"):
		return null

	var existing := target.get_node_or_null("FloatingHealthBar") as FloatingEnemyHealthBar
	if existing != null:
		return existing

	var bar := FloatingEnemyHealthBar.new()
	bar.name = "FloatingHealthBar"
	target.add_child(bar)
	bar.setup(target)
	return bar


func setup(target: Node3D) -> void:
	_target = target


func _ready() -> void:
	if _target == null:
		_target = get_parent() as Node3D
	_build_visuals()


func _build_visuals() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.transparent_bg = true
	_viewport.size = VIEWPORT_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(root)

	var border := ColorRect.new()
	border.color = Color(0.22, 0.16, 0.1, 0.95)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(border)

	var background := ColorRect.new()
	background.color = Color(0.08, 0.06, 0.05, 0.92)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 1.0
	background.offset_top = 1.0
	background.offset_right = -1.0
	background.offset_bottom = -1.0
	root.add_child(background)

	_fill = ColorRect.new()
	_fill.color = Color(0.82, 0.2, 0.14, 1.0)
	_fill.position = Vector2(1.0, 1.0)
	_fill.size = Vector2(float(VIEWPORT_SIZE.x) - 2.0, float(VIEWPORT_SIZE.y) - 2.0)
	root.add_child(_fill)

	_sprite = Sprite3D.new()
	_sprite.name = "Billboard"
	_sprite.texture = _viewport.get_texture()
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = PIXEL_SIZE
	_sprite.centered = true
	add_child(_sprite)


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return

	if _target.has_method("is_defeated") and _target.is_defeated():
		visible = false
		return

	var health := CombatHealthReadoutScript.read(_target)
	if health.max <= 0:
		visible = false
		return

	var ratio := clampf(float(health.current) / float(health.max), 0.0, 1.0)
	visible = true
	global_position = _resolve_anchor()

	if absf(ratio - _last_ratio) > 0.001:
		_last_ratio = ratio
		_fill.size.x = maxf(1.0, (float(VIEWPORT_SIZE.x) - 2.0) * ratio)
		_fill.color = _color_for_ratio(ratio)
		_sprite.modulate = Color(1.0, 1.0, 1.0, 0.72 if ratio >= 1.0 else 1.0)


func _resolve_anchor() -> Vector3:
	if _target.has_method("get_threat_aim_point"):
		return _target.get_threat_aim_point() + Vector3(0.0, HEAD_CLEARANCE, 0.0)
	if _uses_short_offset():
		return _target.global_position + Vector3(0.0, SHORT_HEAD_HEIGHT, 0.0)
	return _target.global_position + Vector3(0.0, TALL_HEAD_HEIGHT, 0.0)


func _uses_short_offset() -> bool:
	var script := _target.get_script() as Script
	if script == null:
		return false
	return str(script.resource_path).contains("skeleton_enemy")


func _color_for_ratio(ratio: float) -> Color:
	if ratio > 0.55:
		return Color(0.82, 0.2, 0.14, 1.0)
	if ratio > 0.3:
		return Color(0.9, 0.45, 0.1, 1.0)
	return Color(0.95, 0.12, 0.08, 1.0)
