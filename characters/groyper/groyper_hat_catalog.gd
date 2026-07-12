extends RefCounted
class_name GroyperHatCatalog

## Collectible hat ids: tintable cowboy hats keyed to the town NPC color
## palette, plus unique civil-war hats that carry their own mount scene.

const COWBOY_HAT_ID := &"cowboy"
const HAT_BASE_MATERIAL := preload("res://characters/groyper/cowboy_hat_material.tres")

const COWBOY_MOUNT_SCENE_PATH := "res://characters/groyper/cowboy_hat_mount.tscn"

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

## Hats with their own model + mount scene. Not tintable — their FBX materials
## carry the real textures. "visual_offset"/"visual_scale" normalize the raw
## model (authored floating at reference-head height) for ground pickups.
const UNIQUE_HATS: Array[Dictionary] = [
	{
		"id": &"civil_war_cap",
		"color": Color(0.2, 0.26, 0.42),
		"name": "Civil War Cap",
		"mount_scene": "res://characters/groyper/civil_war_cap_mount.tscn",
		"model_scene": "res://Assets/CharacterModels/Hats/source/civil_war_hat.fbx",
		"visual_offset": Vector3(0.0005, -1.889317, -0.006369),
		"visual_scale": 1.1318,
	},
	{
		"id": &"cavalry",
		"color": Color(0.42, 0.36, 0.26),
		"name": "Cavalry Slouch Hat",
		"mount_scene": "res://characters/groyper/cavalry_hat_mount.tscn",
		"model_scene": "res://Assets/CharacterModels/Hats/source/civil_war_cavalry_hats.fbx",
		"visual_offset": Vector3(0.0, -1.855728, 0.014372),
		"visual_scale": 1.1318,
	},
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


static func get_all_hat_ids() -> Array[StringName]:
	var ids: Array[StringName] = [COWBOY_HAT_ID]
	for entry in HATS:
		ids.append(entry["id"])
	for entry in UNIQUE_HATS:
		ids.append(entry["id"])
	return ids


static func _find_unique_entry(hat_id: StringName) -> Dictionary:
	for entry in UNIQUE_HATS:
		if entry["id"] == hat_id:
			return entry
	return {}


static func is_unique_hat(hat_id: StringName) -> bool:
	return not _find_unique_entry(hat_id).is_empty()


## Tintable hats reuse the shared cowboy hat mesh with a solid albedo color.
static func is_tintable(hat_id: StringName) -> bool:
	return hat_id != COWBOY_HAT_ID and not is_unique_hat(hat_id)


static func get_mount_scene_path(hat_id: StringName) -> String:
	var entry := _find_unique_entry(hat_id)
	if entry.is_empty():
		return COWBOY_MOUNT_SCENE_PATH
	return entry["mount_scene"]


static func get_display_name(hat_id: StringName) -> String:
	if hat_id == COWBOY_HAT_ID:
		return "Cowboy Hat"
	for entry in HATS:
		if entry["id"] == hat_id:
			return entry["name"]
	var unique := _find_unique_entry(hat_id)
	if not unique.is_empty():
		return unique["name"]
	return str(hat_id).capitalize()


static func get_color(hat_id: StringName) -> Color:
	if hat_id == COWBOY_HAT_ID:
		return Color(0.52, 0.28, 0.16)
	for entry in HATS:
		if entry["id"] == hat_id:
			return entry["color"]
	var unique := _find_unique_entry(hat_id)
	if not unique.is_empty():
		return unique["color"]
	return Color(0.72, 0.18, 0.14)


static func create_tinted_material(color: Color) -> StandardMaterial3D:
	var mat := HAT_BASE_MATERIAL.duplicate() as StandardMaterial3D
	# Drop the shared hat texture so albedo_color reads as a solid hat tint.
	mat.albedo_texture = null
	mat.albedo_color = color
	return mat


## Material the worn hat should be overridden with, or null to keep the
## model's own imported materials (unique hats).
static func create_worn_material(hat_id: StringName) -> Material:
	if is_unique_hat(hat_id):
		return null
	if hat_id == COWBOY_HAT_ID:
		return HAT_BASE_MATERIAL
	return create_tinted_material(get_color(hat_id))


## Standalone hat visual for world pickups/displays, normalized so the hat
## rests centered on the node origin at ground scale.
static func create_hat_visual(hat_id: StringName) -> Node3D:
	var entry := _find_unique_entry(hat_id)
	var root := Node3D.new()
	root.name = "CowboyHat"
	var model_path: String = entry.get(
		"model_scene",
		"res://Assets/CharacterModels/Hats/source/hat01.fbx"
	)
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("GroyperHatCatalog: missing hat model %s" % model_path)
		return root
	var model := packed.instantiate() as Node3D
	if model == null:
		return root
	var offset: Vector3 = entry.get("visual_offset", Vector3.ZERO)
	var vis_scale: float = entry.get("visual_scale", 1.0)
	model.transform = Transform3D(
		Basis.IDENTITY.scaled(Vector3.ONE * vis_scale),
		offset * vis_scale
	)
	root.add_child(model)

	var override := create_worn_material(hat_id)
	if override != null:
		for mesh in root.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := mesh as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			mesh_instance.material_override = override
	return root
