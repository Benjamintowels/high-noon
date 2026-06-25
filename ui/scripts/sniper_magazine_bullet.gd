extends Control

const GOLD := Color(0.95, 0.76, 0.18, 1.0)
const GOLD_HIGHLIGHT := Color(1.0, 0.88, 0.42, 1.0)
const TIP := Color(0.82, 0.62, 0.12, 1.0)


func _draw() -> void:
	var radius := size.y * 0.5
	var center_y := size.y * 0.5
	var body := Rect2(Vector2(radius, 0.0), Vector2(maxf(size.x - size.y, 0.0), size.y))
	draw_rect(body, GOLD, true)
	draw_circle(Vector2(radius, center_y), radius, GOLD)
	draw_circle(Vector2(size.x - radius, center_y), radius, TIP)
	draw_line(
		Vector2(radius * 0.5, center_y - radius * 0.4),
		Vector2(size.x - radius * 0.7, center_y - radius * 0.4),
		GOLD_HIGHLIGHT,
		1.2,
		true
	)
