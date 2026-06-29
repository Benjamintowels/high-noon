@tool
extends Node3D

enum CropType { WHEAT, SUNFLOWER }

const FARM_CROP_SCENE := preload("res://gameplay/world/farms/farm_crop.tscn")
const WHEAT_TEXTURE := preload("res://Assets/World/Crops/Wheat.png")
const SUNFLOWER_TEXTURE := preload("res://Assets/World/Crops/Sunflower.png")
const SUNFLOWER2_TEXTURE := preload("res://Assets/World/Crops/Sunflower2.png")

const DIRT_COLOR := Color(0.56, 0.39, 0.24)
const ROW_COLOR := Color(0.34, 0.21, 0.11)

@export var crop_type: CropType = CropType.WHEAT:
	set(value):
		crop_type = value
		_request_rebuild()

@export_range(1, 24, 1) var plot_columns: int = 5:
	set(value):
		plot_columns = maxi(value, 1)
		_request_rebuild()

@export_range(1, 24, 1) var plot_rows: int = 4:
	set(value):
		plot_rows = maxi(value, 1)
		_request_rebuild()

@export var plot_size: float = 1.25:
	set(value):
		plot_size = maxf(value, 0.5)
		_request_rebuild()

@export var row_width: float = 0.18:
	set(value):
		row_width = maxf(value, 0.05)
		_request_rebuild()

@export var ground_thickness: float = 0.06:
	set(value):
		ground_thickness = maxf(value, 0.02)
		_request_rebuild()

@export var crop_pixel_size: float = 0.0075:
	set(value):
		crop_pixel_size = maxf(value, 0.001)
		_request_rebuild()

@export var randomize_crop_yaw := true

var _rebuild_queued := false


func _ready() -> void:
	call_deferred("_rebuild_field")


func _request_rebuild() -> void:
	if not is_inside_tree():
		return
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_field")


func _edited_scene_root() -> Node:
	if Engine.is_editor_hint() and is_inside_tree():
		return get_tree().edited_scene_root
	return null


func _set_owner_if_editing(node: Node) -> void:
	var root := _edited_scene_root()
	if root != null:
		node.owner = root


func _rebuild_field() -> void:
	_rebuild_queued = false
	_clear_generated()

	var ground := _make_ground()
	add_child(ground)
	_set_owner_if_editing(ground)

	_add_row_dividers()
	_add_crops()


func _clear_generated() -> void:
	for child in get_children():
		child.free()


func _field_width() -> float:
	return plot_columns * plot_size


func _field_depth() -> float:
	if plot_rows <= 1:
		return plot_size
	return plot_rows * plot_size + (plot_rows - 1) * row_width


func _crop_surface_y() -> float:
	return ground_thickness


func _make_ground() -> MeshInstance3D:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"

	var mesh := BoxMesh.new()
	mesh.size = Vector3(_field_width(), ground_thickness, _field_depth())
	ground.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = DIRT_COLOR
	material.roughness = 0.95
	ground.material_override = material
	ground.position = Vector3(0.0, ground_thickness * 0.5, 0.0)

	return ground


func _add_row_dividers() -> void:
	if plot_rows <= 1:
		return

	var rows_root := Node3D.new()
	rows_root.name = "Rows"
	add_child(rows_root)
	_set_owner_if_editing(rows_root)

	var field_depth := _field_depth()
	var start_z := -field_depth * 0.5

	for row_index in plot_rows - 1:
		var row_z := start_z + (row_index + 1) * plot_size + row_index * row_width + row_width * 0.5
		var row_mesh := MeshInstance3D.new()
		row_mesh.name = "Row_%02d" % (row_index + 1)

		var mesh := BoxMesh.new()
		mesh.size = Vector3(_field_width(), ground_thickness + 0.01, row_width)
		row_mesh.mesh = mesh

		var material := StandardMaterial3D.new()
		material.albedo_color = ROW_COLOR
		material.roughness = 0.98
		row_mesh.material_override = material
		row_mesh.position = Vector3(0.0, ground_thickness * 0.5 + 0.005, row_z)

		rows_root.add_child(row_mesh)
		_set_owner_if_editing(row_mesh)


func _add_crops() -> void:
	var crops_root := Node3D.new()
	crops_root.name = "Crops"
	add_child(crops_root)
	_set_owner_if_editing(crops_root)

	var field_width := _field_width()
	var field_depth := _field_depth()
	var start_x := -field_width * 0.5 + plot_size * 0.5
	var start_z := -field_depth * 0.5 + plot_size * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%d_%d" % [name, plot_columns, plot_rows])

	for row in plot_rows:
		for column in plot_columns:
			var crop: Node3D = FARM_CROP_SCENE.instantiate()
			crop.name = "Crop_%02d_%02d" % [row + 1, column + 1]

			var local_x := start_x + column * plot_size
			var local_z := start_z + row * (plot_size + row_width)
			crop.position = Vector3(local_x, _crop_surface_y(), local_z)

			var texture := _pick_crop_texture(rng)
			var yaw := rng.randf_range(0.0, TAU) if randomize_crop_yaw else 0.0
			crop.set("crop_texture", texture)
			crop.set("crop_pixel_size", crop_pixel_size)
			crop.set("crop_yaw", yaw)

			crops_root.add_child(crop)
			_set_owner_if_editing(crop)


func _pick_crop_texture(rng: RandomNumberGenerator) -> Texture2D:
	match crop_type:
		CropType.WHEAT:
			return WHEAT_TEXTURE
		CropType.SUNFLOWER:
			if rng.randf() < 0.5:
				return SUNFLOWER_TEXTURE
			return SUNFLOWER2_TEXTURE
	return WHEAT_TEXTURE
