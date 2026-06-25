extends Control

@export var reticle_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var circle_radius: float = 10.0
@export var circle_width: float = 2.0
@export var dot_radius: float = 2.5
@export var aim_urgency_orange: Color = Color(1.0, 0.58, 0.1, 0.9)
@export var aim_urgency_red: Color = Color(1.0, 0.1, 0.06, 0.98)
@export_range(1.0, 24.0, 0.5) var urgency_color_smooth: float = 10.0
@export_range(4.0, 32.0, 0.5) var screen_position_smooth: float = 7.0

var screen_offset: Vector2 = Vector2.ZERO

var _display_color: Color
var _urgency_target: float = 0.0
var _urgency_display: float = 0.0
var _screen_offset_target := Vector2.ZERO
var _uses_aim_urgency := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display_color = reticle_color
	set_process(false)


func set_screen_offset(offset: Vector2) -> void:
	_screen_offset_target = offset
	_uses_aim_urgency = false
	set_process(false)
	if screen_offset.is_equal_approx(offset):
		return
	screen_offset = offset
	queue_redraw()


func set_world_aim_screen_position(screen_pos: Vector2) -> void:
	_screen_offset_target = screen_pos - size * 0.5
	if _uses_aim_urgency:
		set_process(true)
		return
	set_screen_offset(_screen_offset_target)


func set_aim_urgency(urgency: float) -> void:
	_uses_aim_urgency = true
	_urgency_target = clampf(urgency, 0.0, 1.0)
	if not is_processing():
		set_process(true)


func _process(delta: float) -> void:
	var changed := false

	if _uses_aim_urgency:
		var urgency_step := 1.0 - exp(-urgency_color_smooth * delta)
		var prev_urgency := _urgency_display
		_urgency_display = lerpf(_urgency_display, _urgency_target, urgency_step)
		_display_color = aim_urgency_orange.lerp(aim_urgency_red, _urgency_display)
		if not is_equal_approx(prev_urgency, _urgency_display):
			changed = true

	var pos_step := 1.0 - exp(-screen_position_smooth * delta)
	var next_offset := screen_offset.lerp(_screen_offset_target, pos_step)
	if not screen_offset.is_equal_approx(next_offset):
		screen_offset = next_offset
		changed = true

	if changed:
		queue_redraw()

	if screen_offset.is_equal_approx(_screen_offset_target) \
			and is_equal_approx(_urgency_display, _urgency_target):
		set_process(_uses_aim_urgency)


func _draw() -> void:
	var center := size * 0.5 + screen_offset
	var color := _display_color if _uses_aim_urgency else reticle_color
	draw_circle(center, dot_radius, color)
	draw_arc(center, circle_radius, 0.0, TAU, 48, color, circle_width, true)
