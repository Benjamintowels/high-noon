extends Terrain3D

## Runtime-only bootstrap. Intentionally not @tool — editor attach + file deletion caused save crashes.

const ASSETS := preload("res://stages/stage1/terrain/stage1_terrain_assets.tres")
const MATERIAL := preload("res://stages/stage1/terrain/stage1_terrain_material.tres")

const DATA_DIR := "res://stages/stage1/terrain/data"
const REGION_ORIGIN := Vector3(-128.0, 0.0, -128.0)
const HEIGHT_SCALE := 3.5
const MAP_SIZE := 512
const TOWN_FLATTEN_RADIUS := 0.28


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_configure_defaults()
	if data.get_region_count() == 0:
		_generate_initial_terrain()


func _configure_defaults() -> void:
	if assets == null:
		assets = ASSETS
	if material == null:
		material = MATERIAL
	if data_directory.is_empty():
		data_directory = DATA_DIR
	collision_mask = 1


func _generate_initial_terrain() -> void:
	var height_img := _build_height_image()
	data.import_images([height_img, null, null], REGION_ORIGIN, 0.0, HEIGHT_SCALE)


func _build_height_image() -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = 61042
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.0075

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = 9137
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.035

	var img := Image.create_empty(MAP_SIZE, MAP_SIZE, false, Image.FORMAT_RF)
	var center := Vector2(MAP_SIZE * 0.5, MAP_SIZE * 0.5)
	var flatten_radius := MAP_SIZE * TOWN_FLATTEN_RADIUS

	for x in MAP_SIZE:
		for y in MAP_SIZE:
			var base_noise := noise.get_noise_2d(float(x), float(y))
			var detail := detail_noise.get_noise_2d(float(x), float(y)) * 0.25
			var combined := base_noise + detail

			var dist := Vector2(x, y).distance_to(center) / flatten_radius
			var town_flat := clampf(1.0 - dist, 0.0, 1.0)
			town_flat *= town_flat
			combined *= lerpf(1.0, 0.0, town_flat)

			var height_value := clampf(maxf(combined, 0.0) * 0.22, 0.0, 1.0)
			img.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))

	return img
