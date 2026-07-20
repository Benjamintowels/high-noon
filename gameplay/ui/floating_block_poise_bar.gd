extends Node3D
class_name FloatingBlockPoiseBar

## World-space guard meter. Visible while blocking or when poise is damaged
## (persists after releasing block until a break refills it).

const BlockPoiseScript := preload("res://gameplay/combat/block_poise.gd")
const RunEnemyArmorScript := preload("res://gameplay/runs/run_enemy_armor.gd")

const VIEWPORT_SIZE := Vector2i(48, 5)
const PIXEL_SIZE := 0.00155
const HEAD_CLEARANCE := 0.08
const HEALTH_BAR_GAP := 0.11
const SHORT_HEAD_HEIGHT := 1.0
const TALL_HEAD_HEIGHT := 1.4

var _target: Node3D
var _sprite: Sprite3D
var _viewport: SubViewport
var _fill: ColorRect
var _last_ratio := -1.0


static func attach_to(target: Node3D) -> FloatingBlockPoiseBar:
	if target == null or not is_instance_valid(target):
		return null

	var existing := target.get_node_or_null("FloatingBlockPoiseBar") as FloatingBlockPoiseBar
	if existing != null:
		return existing

	var bar := FloatingBlockPoiseBar.new()
	bar.name = "FloatingBlockPoiseBar"
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
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(root)

	var border := ColorRect.new()
	border.color = Color(0.12, 0.2, 0.32, 0.95)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(border)

	var background := ColorRect.new()
	background.color = Color(0.04, 0.07, 0.12, 0.92)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 1.0
	background.offset_top = 1.0
	background.offset_right = -1.0
	background.offset_bottom = -1.0
	root.add_child(background)

	_fill = ColorRect.new()
	_fill.color = Color(0.45, 0.82, 1.0, 1.0)
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
		# Free the SubViewport render target — hiding leaves GPU textures alive
		# on every corpse and exhausts VRAM in long roguelike farms.
		queue_free()
		return

	var blocking := _is_blocking()
	var use_run_armor := (
		RunEnemyArmorScript.has_armor(_target) and not RunEnemyArmorScript.is_broken(_target)
	)
	var damaged := (
		RunEnemyArmorScript.get_current(_target) + 0.001 < RunEnemyArmorScript.get_max(_target)
		if use_run_armor
		else BlockPoiseScript.is_damaged(_target)
	)
	# Run gun-shield stays visible while intact; melee poise only while blocking/damaged.
	if not use_run_armor and not blocking and not damaged:
		visible = false
		return

	var poise_max := (
		RunEnemyArmorScript.get_max(_target)
		if use_run_armor
		else BlockPoiseScript.get_max(_target)
	)
	if poise_max <= 0.0:
		visible = false
		return

	var ratio := (
		RunEnemyArmorScript.get_ratio(_target)
		if use_run_armor
		else BlockPoiseScript.get_ratio(_target)
	)
	visible = true
	global_position = _resolve_anchor()

	if absf(ratio - _last_ratio) > 0.001:
		_last_ratio = ratio
		_fill.size.x = maxf(1.0, (float(VIEWPORT_SIZE.x) - 2.0) * ratio)
		_fill.color = _color_for_ratio(ratio)
		_sprite.modulate = Color(1.0, 1.0, 1.0, 0.85 if (blocking or use_run_armor) else 0.7)
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _is_blocking() -> bool:
	if _target.has_method("is_unarmed_blocking") and _target.is_unarmed_blocking():
		return true
	if _target.has_method("is_blocking") and _target.is_blocking():
		return true
	if "_combat_blocking" in _target and bool(_target.get("_combat_blocking")):
		return true
	if "_melee_blocking" in _target and bool(_target.get("_melee_blocking")):
		return true
	if "_unarmed_blocking" in _target and bool(_target.get("_unarmed_blocking")):
		return true
	return false


func _resolve_anchor() -> Vector3:
	var base := _target.global_position + Vector3(0.0, TALL_HEAD_HEIGHT, 0.0)
	if _target.has_method("get_threat_aim_point"):
		base = _target.get_threat_aim_point() + Vector3(0.0, HEAD_CLEARANCE, 0.0)
	elif _uses_short_offset():
		base = _target.global_position + Vector3(0.0, SHORT_HEAD_HEIGHT, 0.0)

	# Sit just below the floating health bar when one is present.
	if _target.get_node_or_null("FloatingHealthBar") != null:
		base += Vector3(0.0, -HEALTH_BAR_GAP, 0.0)
	return base


func _uses_short_offset() -> bool:
	var script := _target.get_script() as Script
	if script == null:
		return false
	return str(script.resource_path).contains("skeleton_enemy")


func _color_for_ratio(ratio: float) -> Color:
	if ratio > 0.55:
		return Color(0.4, 0.85, 1.15, 1.0)
	if ratio > 0.3:
		return Color(0.85, 0.9, 1.2, 1.0)
	return Color(1.15, 0.55, 0.2, 1.0)
