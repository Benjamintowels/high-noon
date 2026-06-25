class_name SingleRocketAmmoDisplay
extends Control

const ROCKET_SCENE := preload("res://ui/scenes/rocket_round_icon.tscn")

const PANEL_COLOR := Color(0.2, 0.21, 0.24, 1.0)
const PANEL_EDGE := Color(0.48, 0.5, 0.54, 1.0)
const ROCKET_SIZE := Vector2(34.0, 10.0)
const FLY_DURATION := 0.34

@export var panel_size := Vector2(88.0, 36.0)

var _loaded := true
var _rocket: Control
var _fly_tween: Tween


func _ready() -> void:
	custom_minimum_size = panel_size
	size = panel_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_rocket()
	_set_loaded(true)


func sync_rounds(count: int, animate_shot: bool = false, reset_display: bool = false) -> void:
	var was_loaded := _loaded
	_loaded = count > 0

	if reset_display:
		_kill_fly_tween()
		_set_loaded(_loaded)
		return

	if animate_shot and was_loaded and not _loaded:
		_launch_rocket()
	else:
		_set_loaded(_loaded)


func _build_rocket() -> void:
	if _rocket != null:
		_rocket.queue_free()

	_rocket = ROCKET_SCENE.instantiate() as Control
	_rocket.custom_minimum_size = ROCKET_SIZE
	_rocket.size = ROCKET_SIZE
	_rocket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rocket)
	_layout_rocket_rest()


func _layout_rocket_rest() -> void:
	if _rocket == null:
		return
	_rocket.modulate = Color.WHITE
	_rocket.rotation_degrees = 0.0
	_rocket.position = Vector2(
		(panel_size.x - ROCKET_SIZE.x) * 0.5,
		(panel_size.y - ROCKET_SIZE.y) * 0.5
	)


func _set_loaded(loaded: bool) -> void:
	_kill_fly_tween()
	if _rocket == null:
		return
	_rocket.visible = loaded
	if loaded:
		_layout_rocket_rest()


func _launch_rocket() -> void:
	if _rocket == null:
		return

	_kill_fly_tween()
	_rocket.visible = true
	_layout_rocket_rest()

	_fly_tween = create_tween().set_parallel(true)
	_fly_tween.tween_property(
		_rocket,
		"position",
		_rocket.position + Vector2(72.0, -4.0),
		FLY_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fly_tween.tween_property(_rocket, "rotation_degrees", -18.0, FLY_DURATION)
	_fly_tween.tween_property(_rocket, "modulate:a", 0.0, FLY_DURATION * 0.75).set_delay(FLY_DURATION * 0.2)
	_fly_tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_rocket):
			_rocket.visible = false
	)


func _kill_fly_tween() -> void:
	if _fly_tween != null and _fly_tween.is_valid():
		_fly_tween.kill()
	_fly_tween = null


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, panel_size)
	draw_rect(body, PANEL_COLOR, true)
	draw_rect(body, PANEL_EDGE, false, 2.0)
