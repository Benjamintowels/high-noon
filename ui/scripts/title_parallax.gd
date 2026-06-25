extends Control

const LAYER_SPEEDS: Array[float] = [0.14, 0.17, 0.21, 0.25, 0.29]
const LAYER_X_AMPLITUDE: Array[float] = [12.0, 18.0, 24.0, 30.0, 36.0]
const LAYER_Y_AMPLITUDE: Array[float] = [2.0, 3.0, 4.0, 5.0, 6.0]

const STAR_SPEED := 0.18
const STAR_X_AMPLITUDE := 10.0
const STAR_BLEND_SPEED := 0.38

const CLOUD_SPEED := 0.2
const CLOUD_X_AMPLITUDE := 18.0
const CLOUD_BLEND_SPEED := 0.26

const SUN_SPEED := 0.15
const SUN_X_AMPLITUDE := 5.0
const SUN_Y_AMPLITUDE := 2.5
const SUN_GLOW_SPEED := 0.32

const TURN_SCROLL_DISTANCE := 1400.0
const TURN_LAYER_MULTIPLIERS: Array[float] = [0.18, 0.22, 0.28, 0.34, 0.42, 0.58, 0.72, 0.86, 1.0]

class TiledLayer:
	var wrapper: Control
	var texture: Texture2D
	var tiles: Array[TextureRect] = []
	var tile_width: float = 0.0
	var tile_height: float = 0.0


var _terrain_layers: Array[TiledLayer] = []
var _stars_a: TiledLayer
var _stars_b: TiledLayer
var _clouds_a: TiledLayer
var _clouds_b: TiledLayer
var _sun: TiledLayer
var _time: float = 0.0
var _idle_enabled: bool = true
var _turn_scroll: float = 0.0


func _ready() -> void:
	await get_tree().process_frame
	_stars_a = _make_tiled_layer($LayerStarsA)
	_stars_b = _make_tiled_layer($LayerStarsB)
	_sun = _make_tiled_layer($LayerSun)
	_clouds_a = _make_tiled_layer($LayerCloudsA)
	_clouds_b = _make_tiled_layer($LayerCloudsB)
	_terrain_layers = [
		_make_tiled_layer($LayerMountains),
		_make_tiled_layer($Layer4),
		_make_tiled_layer($Layer3),
		_make_tiled_layer($Layer2),
		_make_tiled_layer($Layer1),
	]


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not _terrain_layers.is_empty():
		call_deferred("_rebuild_all_layers")


func _rebuild_all_layers() -> void:
	for layer in _collect_all_layers():
		_rebuild_tiled_layer(layer)


func _collect_all_layers() -> Array[TiledLayer]:
	var layers: Array[TiledLayer] = [_stars_a, _stars_b, _sun, _clouds_a, _clouds_b]
	layers.append_array(_terrain_layers)
	return layers


func _make_tiled_layer(source: TextureRect) -> TiledLayer:
	var layer := TiledLayer.new()
	layer.texture = source.texture
	layer.wrapper = Control.new()
	layer.wrapper.name = source.name
	layer.wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.wrapper.clip_contents = true
	layer.wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.wrapper.modulate = source.modulate

	var parent := source.get_parent()
	var index := source.get_index()
	parent.remove_child(source)
	parent.add_child(layer.wrapper)
	parent.move_child(layer.wrapper, index)
	source.queue_free()

	_rebuild_tiled_layer(layer)
	return layer


func _rebuild_tiled_layer(layer: TiledLayer) -> void:
	for tile in layer.tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	layer.tiles.clear()

	if layer.texture == null or size.x <= 0.0 or size.y <= 0.0:
		return

	var dimensions := _calc_cover_dimensions(layer.texture)
	layer.tile_width = dimensions.x
	layer.tile_height = dimensions.y

	for i in 2:
		var tile := _create_tile(layer.texture, dimensions)
		tile.position = Vector2(i * layer.tile_width, size.y - layer.tile_height)
		layer.wrapper.add_child(tile)
		layer.tiles.append(tile)


func _calc_cover_dimensions(texture: Texture2D) -> Vector2:
	var tex_size := texture.get_size()
	var cover_scale := maxf(size.x / tex_size.x, size.y / tex_size.y)
	return Vector2(tex_size.x * cover_scale, tex_size.y * cover_scale)


func _create_tile(texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var tile := TextureRect.new()
	tile.texture = texture
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tile.custom_minimum_size = dimensions
	tile.size = dimensions
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


func _set_tiled_offset(layer: TiledLayer, offset_x: float, offset_y: float) -> void:
	if layer.tiles.size() < 2:
		return

	var wrapped := fposmod(offset_x, layer.tile_width)
	var base_y := size.y - layer.tile_height + offset_y
	layer.tiles[0].position = Vector2(-wrapped, base_y)
	layer.tiles[1].position = Vector2(-wrapped + layer.tile_width, base_y)


func play_turn_transition(duration: float = 0.9) -> void:
	_idle_enabled = false
	var tween := create_tween()
	tween.tween_method(_set_turn_scroll, _turn_scroll, TURN_SCROLL_DISTANCE, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func resume_idle_after_turn() -> void:
	_idle_enabled = true


func _set_turn_scroll(value: float) -> void:
	_turn_scroll = value
	_apply_all_layer_positions()


func _process(delta: float) -> void:
	if not _idle_enabled:
		return
	_time += delta
	_apply_all_layer_positions()


func _apply_all_layer_positions() -> void:
	_animate_terrain_layers()
	_animate_stars()
	_animate_clouds()
	_animate_sun()


func _turn_offset(multiplier_index: int) -> float:
	return _turn_scroll * TURN_LAYER_MULTIPLIERS[multiplier_index]


func _animate_terrain_layers() -> void:
	for i in _terrain_layers.size():
		var offset_x: float = 0.0
		var offset_y: float = 0.0
		if _idle_enabled:
			offset_x = sin(_time * LAYER_SPEEDS[i]) * LAYER_X_AMPLITUDE[i]
			offset_y = cos(_time * LAYER_SPEEDS[i] * 0.7) * LAYER_Y_AMPLITUDE[i]
		offset_x += _turn_offset(4 + i)
		_set_tiled_offset(_terrain_layers[i], offset_x, offset_y)


func _animate_stars() -> void:
	if _idle_enabled:
		var blend := 0.5 + 0.5 * sin(_time * STAR_BLEND_SPEED)
		_stars_a.wrapper.modulate.a = 1.0 - blend * 0.3
		_stars_b.wrapper.modulate.a = 0.7 + blend * 0.3

	var drift: float = 0.0
	if _idle_enabled:
		drift = sin(_time * STAR_SPEED) * STAR_X_AMPLITUDE
	drift += _turn_offset(0)
	_set_tiled_offset(_stars_a, drift, 0.0)
	_set_tiled_offset(_stars_b, drift * 1.08, 0.0)


func _animate_clouds() -> void:
	if _idle_enabled:
		var blend := 0.5 + 0.5 * sin(_time * CLOUD_BLEND_SPEED)
		_clouds_a.wrapper.modulate.a = 1.0 - blend * 0.35
		_clouds_b.wrapper.modulate.a = 0.65 + blend * 0.35

	var drift: float = 0.0
	if _idle_enabled:
		drift = sin(_time * CLOUD_SPEED) * CLOUD_X_AMPLITUDE
	drift += _turn_offset(2)
	_set_tiled_offset(_clouds_a, drift, 0.0)
	_set_tiled_offset(_clouds_b, drift + 3.0, 0.0)


func _animate_sun() -> void:
	var offset_x: float = _turn_offset(1)
	var offset_y: float = 0.0
	if _idle_enabled:
		offset_x += sin(_time * SUN_SPEED) * SUN_X_AMPLITUDE
		offset_y = sin(_time * SUN_SPEED * 1.4) * SUN_Y_AMPLITUDE
		var glow := 1.0 + sin(_time * SUN_GLOW_SPEED) * 0.06
		_sun.wrapper.modulate = Color(glow, glow * 0.95, glow * 0.82, 1.0)
	_set_tiled_offset(_sun, offset_x, offset_y)
