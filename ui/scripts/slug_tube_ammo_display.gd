class_name SlugTubeAmmoDisplay
extends Control

const SLUG_SCENE := preload("res://ui/scenes/slug_shell.tscn")

const MAX_ROUNDS := 4
const TUBE_BODY_COLOR := Color(0.2, 0.21, 0.24, 1.0)
const TUBE_EDGE_COLOR := Color(0.48, 0.5, 0.54, 1.0)
const TUBE_INSET_COLOR := Color(0.1, 0.1, 0.12, 1.0)
const SLUG_SIZE := Vector2(16.0, 5.0)
const SLUG_SLOT_STEP := 7.0
const EJECT_DURATION := 0.24
const SLIDE_DURATION := 0.12

@export var tube_size := Vector2(40.0, 52.0)
@export var window_inset := Vector2(10.0, 8.0)

@onready var _slugs_root: Control = $Slugs

var _slugs: Array[Control] = []
var _rounds := MAX_ROUNDS
var _slide_tween: Tween


func _ready() -> void:
	custom_minimum_size = tube_size
	size = tube_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_slugs()
	_layout_stack(false)


func sync_rounds(count: int, animate_shot: bool = false, reset_tube: bool = false) -> void:
	var previous := _rounds
	_rounds = clampi(count, 0, MAX_ROUNDS)

	if reset_tube:
		_kill_slide_tween()
		_layout_stack(false)
		return

	if animate_shot and _rounds < previous:
		_eject_top_slug(previous)
	else:
		_layout_stack(false)


func _build_slugs() -> void:
	_slugs.clear()
	for child in _slugs_root.get_children():
		child.queue_free()

	for i in MAX_ROUNDS:
		var slug: Control = SLUG_SCENE.instantiate()
		slug.custom_minimum_size = SLUG_SIZE
		slug.size = SLUG_SIZE
		slug.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slugs_root.add_child(slug)
		_slugs.append(slug)


func _window_rect() -> Rect2:
	var window_width := tube_size.x - window_inset.x - 6.0
	var window_height := tube_size.y - window_inset.y * 2.0
	return Rect2(
		Vector2(window_inset.x, window_inset.y),
		Vector2(window_width, window_height)
	)


func _slot_position(index: int, round_count: int) -> Vector2:
	var window := _window_rect()
	var stack_height := round_count * SLUG_SLOT_STEP
	var base_y := window.position.y + window.size.y - stack_height
	return Vector2(
		window.position.x + (window.size.x - SLUG_SIZE.x) * 0.5,
		base_y + float(index) * SLUG_SLOT_STEP
	)


func _layout_stack(animate_slide: bool) -> void:
	_kill_slide_tween()

	for i in _slugs.size():
		var slug := _slugs[i]
		var show_slug := i < _rounds
		slug.visible = show_slug
		if not show_slug:
			continue

		var target := _slot_position(i, _rounds)
		if animate_slide:
			if _slide_tween == null or not _slide_tween.is_valid():
				_slide_tween = create_tween().set_parallel(true)
			_slide_tween.tween_property(
				slug,
				"position",
				target,
				SLIDE_DURATION
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			slug.position = target


func _eject_top_slug(previous_rounds: int) -> void:
	if previous_rounds <= 0:
		return

	var top_index := previous_rounds - 1
	var source := _slugs[top_index]
	source.visible = false

	var flying: Control = SLUG_SCENE.instantiate()
	flying.custom_minimum_size = SLUG_SIZE
	flying.size = SLUG_SIZE
	flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying.position = source.position
	flying.rotation_degrees = randf_range(-12.0, 12.0)
	add_child(flying)

	var start := flying.position
	var end := start + Vector2(36.0, -22.0)
	var control := start + Vector2(20.0, -6.0)

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
	tween.tween_property(flying, "rotation_degrees", flying.rotation_degrees + randf_range(120.0, 200.0), EJECT_DURATION)
	tween.tween_property(flying, "modulate:a", 0.0, EJECT_DURATION * 0.85).set_delay(EJECT_DURATION * 0.15)
	tween.chain().tween_callback(flying.queue_free)

	_layout_stack(true)


const RELOAD_EJECT_STAGGER := 0.035
const LOAD_POP_SCALE := 2.2
const LOAD_POP_DURATION := 0.1


func eject_all_casings() -> void:
	var count := _rounds
	_rounds = 0
	_kill_slide_tween()
	for i in count:
		var previous := count - i
		var delay := float(i) * RELOAD_EJECT_STAGGER
		if delay <= 0.0:
			_eject_top_slug(previous)
		else:
			var timer := get_tree().create_timer(delay)
			timer.timeout.connect(
				func() -> void:
					if is_instance_valid(self):
						_eject_top_slug(previous)
			)


func animate_load_round(round_count: int) -> void:
	var previous := _rounds
	_rounds = clampi(round_count, 0, MAX_ROUNDS)
	if _rounds <= previous:
		_layout_stack(false)
		return

	var slug := _slugs[_rounds - 1]
	slug.visible = true
	slug.pivot_offset = slug.size * 0.5
	slug.scale = Vector2.ONE * LOAD_POP_SCALE
	_layout_stack(false)

	var tween := create_tween()
	tween.tween_property(
		slug,
		"scale",
		Vector2.ONE,
		LOAD_POP_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_slide_tween() -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = null


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, tube_size)
	draw_rect(body, TUBE_BODY_COLOR, true)
	draw_rect(body, TUBE_EDGE_COLOR, false, 2.0)

	var window := _window_rect()
	draw_rect(window.grow(1.5), TUBE_INSET_COLOR, true)
	draw_rect(window, Color(0.04, 0.04, 0.05, 0.35), true)

	var lip_start := Vector2(window.position.x + window.size.x, window.position.y + 3.0)
	var lip_end := Vector2(window.position.x + window.size.x, window.position.y + window.size.y - 3.0)
	draw_line(lip_start, lip_end, TUBE_EDGE_COLOR.lightened(0.2), 2.0, true)
