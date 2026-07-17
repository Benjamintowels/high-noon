extends Control

@export var reticle_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var circle_radius: float = 10.0
@export var circle_width: float = 2.0
@export var dot_radius: float = 2.5
@export var aim_urgency_orange: Color = Color(1.0, 0.58, 0.1, 0.9)
@export var aim_urgency_red: Color = Color(1.0, 0.1, 0.06, 0.98)
@export_range(1.0, 24.0, 0.5) var urgency_color_smooth: float = 10.0
@export_range(4.0, 32.0, 0.5) var screen_position_smooth: float = 7.0
## Spread-crosshair (run-and-gun) tuning: four ticks whose gap tracks bloom.
@export var spread_tick_length: float = 9.0
@export var spread_tick_width: float = 2.0
@export var spread_min_gap: float = 6.0
## Shotgun circle outline: bloom radius is the arc radius in px.
@export var spread_circle_width: float = 2.25
@export var spread_circle_min_radius: float = 18.0

var screen_offset: Vector2 = Vector2.ZERO

var _display_color: Color
var _urgency_target: float = 0.0
var _urgency_display: float = 0.0
var _screen_offset_target := Vector2.ZERO
var _uses_aim_urgency := false
var _spread_mode := false
var _spread_px := 0.0
## `ticks` = four-arm crosshair; `circle` = white bloom ring (shotgun).
var _spread_style: StringName = &"ticks"


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


## Run-and-gun crosshair: screen-centered, expanding with bloom.
## `style`: &"ticks" (default) or &"circle" (shotgun outline).
func set_spread_px(spread: float, style: StringName = &"") -> void:
	var next_style := style if style != &"" else _spread_style
	var style_changed := next_style != _spread_style
	_spread_style = next_style
	if not _spread_mode:
		_spread_mode = true
		queue_redraw()
	elif style_changed:
		queue_redraw()
	if is_equal_approx(_spread_px, spread):
		return
	_spread_px = spread
	queue_redraw()


func set_spread_style(style: StringName) -> void:
	if _spread_style == style:
		return
	_spread_style = style
	if _spread_mode:
		queue_redraw()


func clear_spread_mode() -> void:
	if not _spread_mode:
		return
	_spread_mode = false
	queue_redraw()


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

	if _spread_mode:
		if _spread_style == &"circle":
			var radius := maxf(spread_circle_min_radius, _spread_px)
			draw_arc(center, radius, 0.0, TAU, 64, color, spread_circle_width, true)
			return

		var gap := spread_min_gap + _spread_px
		draw_circle(center, dot_radius, color)
		for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var from := center + dir * gap
			var to := center + dir * (gap + spread_tick_length)
			draw_line(from, to, color, spread_tick_width, true)
		return

	draw_circle(center, dot_radius, color)
	draw_arc(center, circle_radius, 0.0, TAU, 48, color, circle_width, true)
