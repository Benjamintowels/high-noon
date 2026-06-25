class_name BananaClipAmmoDisplay
extends Control

const BULLET_SCENE := preload("res://ui/scenes/magazine_bullet.tscn")

const MAX_ROUNDS := 20
const MAG_BODY_COLOR := Color(0.26, 0.2, 0.14, 1.0)
const MAG_EDGE_COLOR := Color(0.44, 0.34, 0.22, 1.0)
const MAG_INSET_COLOR := Color(0.14, 0.1, 0.07, 1.0)
const BULLET_SIZE := Vector2(13.0, 3.5)
const EJECT_DURATION := 0.2
const SLIDE_DURATION := 0.07

@export var clip_size := Vector2(56.0, 120.0)
@export var arc_center := Vector2(30.0, 92.0)
@export var arc_radius := 48.0
@export var arc_start_angle := -2.05
@export var arc_end_angle := -0.62

@onready var _bullets_root: Control = $Bullets

var _bullets: Array[Control] = []
var _rounds := MAX_ROUNDS
var _slide_tween: Tween


func _ready() -> void:
	custom_minimum_size = clip_size
	size = clip_size
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


func _slot_position(index: int, round_count: int) -> Vector2:
	var stack_index := index
	var t := float(stack_index) / float(maxi(round_count - 1, 1))
	var angle := lerpf(arc_start_angle, arc_end_angle, t)
	var point := arc_center + Vector2(cos(angle), sin(angle)) * arc_radius
	var tangent := Vector2(-sin(angle), cos(angle))
	return point - BULLET_SIZE * 0.5 + tangent * 1.5


func _layout_stack(animate_slide: bool) -> void:
	_kill_slide_tween()

	for i in _bullets.size():
		var bullet := _bullets[i]
		var show_bullet := i < _rounds
		bullet.visible = show_bullet
		if not show_bullet:
			continue

		var target := _slot_position(i, _rounds)
		var angle := lerpf(arc_start_angle, arc_end_angle, float(i) / float(maxi(_rounds - 1, 1)))
		var target_rotation := angle + PI * 0.5

		if animate_slide:
			if _slide_tween == null or not _slide_tween.is_valid():
				_slide_tween = create_tween().set_parallel(true)
			_slide_tween.tween_property(bullet, "position", target, SLIDE_DURATION) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_slide_tween.tween_property(bullet, "rotation", target_rotation, SLIDE_DURATION) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			bullet.position = target
			bullet.rotation = target_rotation


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
	flying.rotation = source.rotation
	add_child(flying)

	var start := flying.position
	var end := start + Vector2(34.0, -28.0)
	var control := start + Vector2(18.0, -10.0)

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
	tween.tween_property(flying, "rotation", flying.rotation + randf_range(1.2, 2.0), EJECT_DURATION)
	tween.tween_property(flying, "modulate:a", 0.0, EJECT_DURATION * 0.85).set_delay(EJECT_DURATION * 0.15)
	tween.chain().tween_callback(flying.queue_free)

	_layout_stack(true)


func _kill_slide_tween() -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = null


func _draw() -> void:
	_draw_mag_body()
	_draw_mag_lip()


func _draw_mag_body() -> void:
	var outer := _arc_points(arc_radius + 7.0, 24)
	var inner := _arc_points(arc_radius - 7.0, 24)
	if outer.size() < 2 or inner.size() < 2:
		return

	var ring := PackedVector2Array()
	for point in outer:
		ring.append(point)
	for i in range(inner.size() - 1, -1, -1):
		ring.append(inner[i])
	draw_colored_polygon(ring, MAG_BODY_COLOR)

	for i in outer.size() - 1:
		draw_line(outer[i], outer[i + 1], MAG_EDGE_COLOR, 2.0, true)
	draw_line(outer[0], outer[-1], MAG_INSET_COLOR, 1.0, true)
	draw_line(inner[0], inner[-1], MAG_INSET_COLOR, 1.0, true)


func _draw_mag_lip() -> void:
	var lip_angle := arc_end_angle
	var lip_point := arc_center + Vector2(cos(lip_angle), sin(lip_angle)) * (arc_radius + 2.0)
	var tangent := Vector2(-sin(lip_angle), cos(lip_angle)).normalized()
	draw_line(lip_point - tangent * 8.0, lip_point + tangent * 4.0, MAG_EDGE_COLOR.lightened(0.15), 2.0, true)


func _arc_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var t := float(i) / float(segments)
		var angle := lerpf(arc_start_angle, arc_end_angle, t)
		points.append(arc_center + Vector2(cos(angle), sin(angle)) * radius)
	return points
