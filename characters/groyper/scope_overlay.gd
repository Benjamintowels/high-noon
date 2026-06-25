extends Control

const RING_COLOR := Color(0.1, 0.1, 0.1, 0.95)
const RING_WIDTH := 3.0
const VIGNETTE_COLOR := Color(0.0, 0.0, 0.0, 0.9)
const APERTURE_FRACTION := 0.38
const CROSSHAIR_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const CROSSHAIR_GAP := 10.0
const CROSSHAIR_ARM := 20.0

var scope_blend: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func set_scope_blend(blend: float) -> void:
	var next := clampf(blend, 0.0, 1.0)
	if is_equal_approx(scope_blend, next):
		return
	scope_blend = next
	visible = scope_blend > 0.01
	queue_redraw()


func _draw() -> void:
	if scope_blend <= 0.01:
		return

	var center := size * 0.5
	var viewport_min := minf(size.x, size.y)
	var inner_radius := viewport_min * APERTURE_FRACTION
	var alpha := scope_blend
	var shade := Color(VIGNETTE_COLOR, VIGNETTE_COLOR.a * alpha)

	draw_rect(Rect2(0.0, 0.0, size.x, center.y - inner_radius), shade)
	draw_rect(Rect2(0.0, center.y + inner_radius, size.x, size.y - center.y - inner_radius), shade)
	draw_rect(
		Rect2(0.0, center.y - inner_radius, center.x - inner_radius, inner_radius * 2.0),
		shade
	)
	draw_rect(
		Rect2(
			center.x + inner_radius,
			center.y - inner_radius,
			size.x - center.x - inner_radius,
			inner_radius * 2.0
		),
		shade
	)
	_fill_square_corners_outside_circle(center, inner_radius, shade)

	draw_arc(center, inner_radius, 0.0, TAU, 96, Color(RING_COLOR, alpha), RING_WIDTH, true)
	draw_arc(
		center,
		inner_radius - 5.0,
		0.0,
		TAU,
		96,
		Color(0.18, 0.18, 0.18, alpha * 0.55),
		1.0,
		true
	)

	_draw_crosshair(center, alpha)


func _fill_square_corners_outside_circle(center: Vector2, radius: float, color: Color) -> void:
	const SEGMENTS := 14
	# Each patch fills one square corner between the circle edge and its bounding box.
	_draw_corner_patch(center, radius, color, Vector2(-1.0, -1.0), PI, PI * 1.5, SEGMENTS)
	_draw_corner_patch(center, radius, color, Vector2(1.0, -1.0), PI * 1.5, TAU, SEGMENTS)
	_draw_corner_patch(center, radius, color, Vector2(1.0, 1.0), 0.0, PI * 0.5, SEGMENTS)
	_draw_corner_patch(center, radius, color, Vector2(-1.0, 1.0), PI * 0.5, PI, SEGMENTS)


func _draw_corner_patch(
	center: Vector2,
	radius: float,
	color: Color,
	corner_sign: Vector2,
	start_angle: float,
	end_angle: float,
	segments: int
) -> void:
	var points := PackedVector2Array()
	points.append(center + Vector2(corner_sign.x, corner_sign.y) * radius)
	for i in segments + 1:
		var t := float(i) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)


func _draw_crosshair(center: Vector2, alpha: float) -> void:
	var color := Color(CROSSHAIR_COLOR, CROSSHAIR_COLOR.a * alpha)
	var width := 1.5
	draw_line(center + Vector2(CROSSHAIR_GAP, 0.0), center + Vector2(CROSSHAIR_GAP + CROSSHAIR_ARM, 0.0), color, width, true)
	draw_line(center - Vector2(CROSSHAIR_GAP, 0.0), center - Vector2(CROSSHAIR_GAP + CROSSHAIR_ARM, 0.0), color, width, true)
	draw_line(center + Vector2(0.0, CROSSHAIR_GAP), center + Vector2(0.0, CROSSHAIR_GAP + CROSSHAIR_ARM), color, width, true)
	draw_line(center - Vector2(0.0, CROSSHAIR_GAP), center - Vector2(0.0, CROSSHAIR_GAP + CROSSHAIR_ARM), color, width, true)
	draw_circle(center, 1.5, color)
