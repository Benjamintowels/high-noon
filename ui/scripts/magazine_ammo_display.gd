class_name MagazineAmmoDisplay
extends Control

const BULLET_SCENE := preload("res://ui/scenes/magazine_bullet.tscn")

const MAX_ROUNDS := 30
const MAG_BODY_COLOR := Color(0.2, 0.21, 0.24, 1.0)
const MAG_EDGE_COLOR := Color(0.48, 0.5, 0.54, 1.0)
const MAG_INSET_COLOR := Color(0.1, 0.1, 0.12, 1.0)
const BULLET_SIZE := Vector2(14.0, 3.5)
const BULLET_SLOT_STEP := 4.0
const EJECT_DURATION := 0.2
const SLIDE_DURATION := 0.07

@export var magazine_size := Vector2(40.0, 128.0)
@export var window_inset := Vector2(10.0, 8.0)

@onready var _bullets_root: Control = $Bullets

var _bullets: Array[Control] = []
var _rounds := MAX_ROUNDS
var _slide_tween: Tween


func _ready() -> void:
	custom_minimum_size = magazine_size
	size = magazine_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_bullets()
	_layout_stack(false)


func sync_rounds(count: int, animate_shot: bool = false, reset_magazine: bool = false) -> void:
	var previous := _rounds
	_rounds = clampi(count, 0, MAX_ROUNDS)

	if reset_magazine:
		_kill_slide_tween()
		_layout_stack(false)
		return

	if animate_shot and _rounds < previous:
		_eject_top_bullet(previous)
	else:
		_layout_stack(false)


func _build_bullets() -> void:
	_bullets.clear()
	for child in _bullets_root.get_children():
		child.queue_free()

	for i in MAX_ROUNDS:
		var bullet: Control = BULLET_SCENE.instantiate()
		bullet.custom_minimum_size = BULLET_SIZE
		bullet.size = BULLET_SIZE
		bullet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bullets_root.add_child(bullet)
		_bullets.append(bullet)


func _window_rect() -> Rect2:
	var window_width := magazine_size.x - window_inset.x - 6.0
	var window_height := magazine_size.y - window_inset.y * 2.0
	return Rect2(
		Vector2(window_inset.x, window_inset.y),
		Vector2(window_width, window_height)
	)


func _slot_position(index: int, round_count: int) -> Vector2:
	var window := _window_rect()
	var stack_height := round_count * BULLET_SLOT_STEP
	var base_y := window.position.y + window.size.y - stack_height
	return Vector2(
		window.position.x + (window.size.x - BULLET_SIZE.x) * 0.5,
		base_y + float(index) * BULLET_SLOT_STEP
	)


func _layout_stack(animate_slide: bool) -> void:
	_kill_slide_tween()

	for i in _bullets.size():
		var bullet := _bullets[i]
		var show_bullet := i < _rounds
		bullet.visible = show_bullet
		if not show_bullet:
			continue

		var target := _slot_position(i, _rounds)
		if animate_slide:
			if _slide_tween == null or not _slide_tween.is_valid():
				_slide_tween = create_tween().set_parallel(true)
			_slide_tween.tween_property(
				bullet,
				"position",
				target,
				SLIDE_DURATION
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			bullet.position = target


func _eject_top_bullet(previous_rounds: int) -> void:
	if previous_rounds <= 0:
		return

	var top_index := previous_rounds - 1
	var source := _bullets[top_index]
	source.visible = false

	var flying: Control = BULLET_SCENE.instantiate()
	flying.custom_minimum_size = BULLET_SIZE
	flying.size = BULLET_SIZE
	flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying.position = source.position
	flying.rotation_degrees = randf_range(-8.0, 8.0)
	add_child(flying)

	var start := flying.position
	var end := start + Vector2(34.0, -26.0)
	var control := start + Vector2(18.0, -8.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_method(
		func(t: float) -> void:
			if not is_instance_valid(flying):
				return
			var u := 1.0 - t
			flying.position = (
				u * u * start
				+ 2.0 * u * t * control
				+ t * t * end
			),
		0.0,
		1.0,
		EJECT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(flying, "rotation_degrees", flying.rotation_degrees + randf_range(140.0, 220.0), EJECT_DURATION)
	tween.tween_property(flying, "modulate:a", 0.0, EJECT_DURATION * 0.85).set_delay(EJECT_DURATION * 0.15)
	tween.chain().tween_callback(flying.queue_free)

	_layout_stack(true)


func _kill_slide_tween() -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = null


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, magazine_size)
	draw_rect(body, MAG_BODY_COLOR, true)
	draw_rect(body, MAG_EDGE_COLOR, false, 2.0)

	var window := _window_rect()
	draw_rect(window.grow(1.5), MAG_INSET_COLOR, true)
	draw_rect(window, Color(0.04, 0.04, 0.05, 0.35), true)

	var lip_start := Vector2(window.position.x + window.size.x, window.position.y + 4.0)
	var lip_end := Vector2(window.position.x + window.size.x, window.position.y + window.size.y - 4.0)
	draw_line(lip_start, lip_end, MAG_EDGE_COLOR.lightened(0.2), 2.0, true)
