extends Control

const TIP_COLOR := Color(0.95, 0.76, 0.18, 1.0)
const HULL_COLOR := Color(0.78, 0.14, 0.12, 1.0)
const HULL_DARK := Color(0.55, 0.08, 0.08, 1.0)

@export var tip_width := 5.0
@export var hull_width := 11.0
@export var shell_height := 5.0


func _draw() -> void:
	var tip_rect := Rect2(Vector2.ZERO, Vector2(tip_width, shell_height))
	var hull_rect := Rect2(Vector2(tip_width - 0.5, 0.0), Vector2(hull_width, shell_height))
	draw_rect(tip_rect, TIP_COLOR, true)
	draw_rect(hull_rect, HULL_COLOR, true)
	draw_rect(hull_rect.grow_individual(0.0, -1.0, 0.0, -1.0), HULL_DARK, false, 0.8)
