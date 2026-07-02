class_name QuiverAmmoDisplay
extends Control

const MAX_VISIBLE := 5
const QUIVER_COLOR := Color(0.42, 0.28, 0.14, 1.0)
const QUIVER_DARK := Color(0.28, 0.17, 0.09, 1.0)
const QUIVER_EDGE := Color(0.52, 0.36, 0.2, 1.0)
const ARROW_SHAFT := Color(0.58, 0.48, 0.34, 1.0)
const ARROW_FEATHER := Color(0.72, 0.24, 0.18, 1.0)

@export var display_size := Vector2(56.0, 72.0)

var _rounds := MAX_VISIBLE


func _ready() -> void:
	custom_minimum_size = display_size
	size = display_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sync_rounds(MAX_VISIBLE)


func sync_rounds(count: int, _animate_shot: bool = false, _reset_display: bool = false) -> void:
	_rounds = clampi(count, 0, 999)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var quiver_w := 34.0
	var quiver_h := 44.0
	var quiver_rect := Rect2(
		center.x - quiver_w * 0.5,
		center.y - quiver_h * 0.42,
		quiver_w,
		quiver_h
	)

	draw_rect(quiver_rect, QUIVER_DARK, true, -1.0, true)
	draw_rect(quiver_rect.grow(-2.0), QUIVER_COLOR, true, -1.0, true)
	draw_rect(quiver_rect, QUIVER_EDGE, false, 2.0, true)

	var arrow_count := mini(_rounds, MAX_VISIBLE)
	var top_y := quiver_rect.position.y + 4.0
	var spread := 7.0
	var start_x := center.x - spread * (arrow_count - 1) * 0.5

	for i in arrow_count:
		var shaft_x := start_x + spread * i
		var shaft_top := top_y - 18.0
		var shaft_bottom := top_y + 2.0
		draw_line(Vector2(shaft_x, shaft_top), Vector2(shaft_x, shaft_bottom), ARROW_SHAFT, 2.5, true)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(shaft_x - 2.0, shaft_top - 1.0),
				Vector2(shaft_x + 2.0, shaft_top - 1.0),
				Vector2(shaft_x, shaft_top - 7.0),
			]),
			ARROW_SHAFT
		)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(shaft_x - 3.0, shaft_bottom),
				Vector2(shaft_x + 3.0, shaft_bottom),
				Vector2(shaft_x, shaft_bottom + 5.0),
			]),
			ARROW_FEATHER
		)
