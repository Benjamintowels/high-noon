extends Control

const MARKER_COLOR := Color(0.42, 0.42, 0.46, 1.0)

@export var radius := 9.0


func _draw() -> void:
	draw_circle(size * 0.5, radius, MARKER_COLOR)
