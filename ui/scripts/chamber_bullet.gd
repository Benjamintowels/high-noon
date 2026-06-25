extends Control

const LOADED_COLOR := Color(0.95, 0.76, 0.18, 1.0)
const SPENT_COLOR := Color(0.08, 0.08, 0.08, 1.0)

@export var radius := 7.0

var loaded := true:
	set(value):
		if loaded == value:
			return
		loaded = value
		queue_redraw()


func set_loaded(is_loaded: bool) -> void:
	loaded = is_loaded


func _draw() -> void:
	var bullet_color := LOADED_COLOR if loaded else SPENT_COLOR
	draw_circle(size * 0.5, radius, bullet_color)
	draw_arc(size * 0.5, radius * 0.55, 0.0, TAU, 16, bullet_color.lightened(0.18), 1.5, true)
