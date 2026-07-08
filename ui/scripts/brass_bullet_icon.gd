extends Control

const BRASS := Color(0.78, 0.58, 0.28, 1.0)
const BRASS_HIGHLIGHT := Color(0.95, 0.78, 0.42, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(26, 12)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Keep footprint fixed so container stretch can't balloon the glyph.
		if size != custom_minimum_size:
			size = custom_minimum_size
		queue_redraw()


func _draw() -> void:
	var w := custom_minimum_size.x
	var h := custom_minimum_size.y
	if w <= 0.0 or h <= 0.0:
		return

	var radius := h * 0.5
	var center_y := h * 0.5
	var body := Rect2(Vector2(radius, 1.0), Vector2(maxf(w - h, 0.0), h - 2.0))
	draw_rect(body, BRASS, true)
	draw_circle(Vector2(radius, center_y), radius, BRASS)
	draw_circle(Vector2(w - radius * 0.7, center_y), radius * 0.68, BRASS.darkened(0.12))
	draw_line(
		Vector2(radius * 0.55, center_y - radius * 0.32),
		Vector2(w - radius * 1.15, center_y - radius * 0.32),
		BRASS_HIGHLIGHT,
		1.0,
		true
	)
