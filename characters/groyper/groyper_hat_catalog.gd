extends RefCounted
class_name GroyperHatCatalog

## Collectible cowboy hat ids keyed to the town NPC color palette.

const HATS: Array[Dictionary] = [
	{"id": &"red", "color": Color(0.72, 0.18, 0.14), "name": "Red Cowboy Hat"},
	{"id": &"blue", "color": Color(0.15, 0.35, 0.75), "name": "Blue Cowboy Hat"},
	{"id": &"green", "color": Color(0.2, 0.6, 0.25), "name": "Green Cowboy Hat"},
	{"id": &"gold", "color": Color(0.94, 0.82, 0.2), "name": "Gold Cowboy Hat"},
	{"id": &"white", "color": Color(0.94, 0.94, 0.92), "name": "White Cowboy Hat"},
	{"id": &"purple", "color": Color(0.55, 0.28, 0.62), "name": "Purple Cowboy Hat"},
	{"id": &"brown", "color": Color(0.35, 0.22, 0.14), "name": "Brown Cowboy Hat"},
	{"id": &"black", "color": Color(0.08, 0.08, 0.1), "name": "Black Cowboy Hat"},
]


static func id_for_color(color: Color) -> StringName:
	var best_id := &"red"
	var best_dist := INF
	for entry in HATS:
		var dist := _color_distance(color, entry["color"] as Color)
		if dist < best_dist:
			best_dist = dist
			best_id = entry["id"]
	return best_id


static func _color_distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


static func get_display_name(hat_id: StringName) -> String:
	for entry in HATS:
		if entry["id"] == hat_id:
			return entry["name"]
	return str(hat_id).capitalize()


static func get_color(hat_id: StringName) -> Color:
	for entry in HATS:
		if entry["id"] == hat_id:
			return entry["color"]
	return Color(0.72, 0.18, 0.14)
