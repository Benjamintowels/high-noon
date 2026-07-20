extends RefCounted
class_name DirectionalImpactFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE := 0.02
const POP_START_SCALE := 1.35
const POP_END_SCALE := 0.85
const POP_DURATION := 0.1
const POP_MODULATE := Color(1.15, 1.05, 0.78, 1.0)


static func spawn(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size: float = PIXEL_SIZE
) -> void:
	_spawn_sprite(parent, global_position, direction, pixel_size, false)


## Melee connect pop: starts oversized/bright, then shrinks+fades for a punchy frame.
static func spawn_pop(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size: float = PIXEL_SIZE
) -> void:
	_spawn_sprite(parent, global_position, direction, pixel_size, true)


static func _spawn_sprite(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size: float,
	pop: bool
) -> void:
	if parent == null:
		return

	var frames := FxCatalogScript.directional_impact_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	else:
		flat_dir = flat_dir.normalized()

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size * (POP_START_SCALE if pop else 1.0)
	sprite.modulate = POP_MODULATE if pop else Color(1.0, 0.95, 0.72, 1.0)
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()

	if pop:
		var end_size := pixel_size * POP_END_SCALE
		var tween := sprite.create_tween()
		tween.set_parallel(true)
		tween.set_ignore_time_scale(true)
		tween.tween_property(sprite, "pixel_size", end_size, POP_DURATION)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "modulate:a", 0.0, POP_DURATION)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)

	sprite.animation_finished.connect(sprite.queue_free)
