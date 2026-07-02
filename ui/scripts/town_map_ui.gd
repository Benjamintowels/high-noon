extends Control
class_name TownMapPanel

const WORLD_MIN := Vector2(-18.0, -55.0)
const WORLD_MAX := Vector2(72.0, 78.0)

const LANDMARKS: Array[Dictionary] = [
	{"label": "Shop", "world": Vector2(58.0, 64.0), "color": Color(0.72, 0.48, 0.22)},
	{"label": "Sheriff", "world": Vector2(4.0, -28.0), "color": Color(0.82, 0.78, 0.62)},
	{"label": "Town", "world": Vector2(0.0, -10.0), "color": Color(0.55, 0.42, 0.24)},
	{"label": "Pink Tree", "world": Vector2(40.0, -60.0), "color": Color(0.95, 0.45, 0.72)},
	{"label": "Farm", "world": Vector2(13.5, -20.5), "color": Color(0.42, 0.62, 0.28)},
]

@onready var _map_canvas: Control = $Panel/MarginContainer/VBoxContainer/MapFrame/MapCanvas


func _ready() -> void:
	call_deferred("_build_map")


func _build_map() -> void:
	if _map_canvas == null:
		return

	for child in _map_canvas.get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.78, 0.68, 0.46, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(bg)

	var road := ColorRect.new()
	road.color = Color(0.62, 0.5, 0.32, 1.0)
	road.position = _world_to_map(Vector2(-8.0, -40.0))
	road.size = _world_to_map(Vector2(52.0, 70.0)) - _world_to_map(Vector2(-8.0, -40.0))
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(road)

	var north := Label.new()
	north.text = "N"
	north.position = Vector2(_map_canvas.size.x * 0.5 - 6.0, 4.0)
	north.add_theme_font_size_override("font_size", 12)
	_map_canvas.add_child(north)

	for landmark: Dictionary in LANDMARKS:
		_add_landmark(landmark)

	var treasure := ColorRect.new()
	treasure.color = Color(0.95, 0.82, 0.2, 1.0)
	var treasure_pos := _world_to_map(Vector2(40.0, -60.0))
	treasure.position = treasure_pos - Vector2(5.0, 5.0)
	treasure.size = Vector2(10.0, 10.0)
	treasure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(treasure)

	var treasure_label := Label.new()
	treasure_label.text = "X"
	treasure_label.position = treasure_pos - Vector2(4.0, 8.0)
	treasure_label.add_theme_font_size_override("font_size", 12)
	_map_canvas.add_child(treasure_label)


func _add_landmark(landmark: Dictionary) -> void:
	var world_pos: Vector2 = landmark.get("world", Vector2.ZERO)
	var map_pos := _world_to_map(world_pos)
	var color: Color = landmark.get("color", Color.WHITE)
	var label_text: String = landmark.get("label", "")

	var dot := ColorRect.new()
	dot.color = color
	dot.position = map_pos - Vector2(4.0, 4.0)
	dot.size = Vector2(8.0, 8.0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(dot)

	var label := Label.new()
	label.text = label_text
	label.position = map_pos + Vector2(6.0, -6.0)
	label.add_theme_font_size_override("font_size", 10)
	_map_canvas.add_child(label)


func _world_to_map(world_pos: Vector2) -> Vector2:
	var canvas_size := _map_canvas.size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		canvas_size = Vector2(280.0, 280.0)

	var normalized := Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_pos.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_pos.y)
	)
	return Vector2(
		normalized.x * canvas_size.x,
		normalized.y * canvas_size.y
	)
