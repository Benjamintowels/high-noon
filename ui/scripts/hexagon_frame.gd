extends Control

@export var hex_radius := 50.0
@export var fill_color := Color(0.34, 0.34, 0.38, 0.95)
@export var border_color := Color(0.52, 0.52, 0.58, 1.0)
@export var border_width := 2.0


func _draw() -> void:
	var center := size * 0.5
	var points := PackedVector2Array()
	for i in 6:
		var angle := deg_to_rad(60.0 * float(i) - 90.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * hex_radius)

	draw_colored_polygon(points, fill_color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, border_color, border_width, true)
