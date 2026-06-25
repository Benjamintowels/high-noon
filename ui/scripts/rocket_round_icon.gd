extends Control

const BODY_COLOR := Color(0.72, 0.16, 0.14, 1.0)
const NOSE_COLOR := Color(0.95, 0.76, 0.18, 1.0)
const FIN_COLOR := Color(0.35, 0.36, 0.4, 1.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var nose_w := w * 0.28
	var body_rect := Rect2(Vector2(nose_w - 1.0, h * 0.22), Vector2(w - nose_w - w * 0.12, h * 0.56))
	var fin_h := h * 0.18

	draw_rect(body_rect, BODY_COLOR, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0.0, h * 0.5),
			Vector2(nose_w, h * 0.18),
			Vector2(nose_w, h * 0.82),
		]),
		NOSE_COLOR
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(w * 0.78, h * 0.5),
			Vector2(w, h * 0.5 - fin_h),
			Vector2(w, h * 0.5 + fin_h),
		]),
		FIN_COLOR
	)
	draw_rect(Rect2(nose_w + 2.0, h * 0.34, w * 0.16, h * 0.32), NOSE_COLOR.lightened(0.12), true)
