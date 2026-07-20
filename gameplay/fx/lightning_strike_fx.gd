extends RefCounted

## Nearest-filtered lightning_strike sprite with yellow tint for gem electrify hits.

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE_LARGE := 0.028
const PIXEL_SIZE_SMALL := 0.018
const YELLOW_TINT := Color(1.15, 1.0, 0.35, 1.0)


static func spawn(
	parent: Node,
	global_position: Vector3,
	small: bool = false,
	modulate_override: Color = YELLOW_TINT
) -> void:
	if parent == null:
		return

	var frames := (
		FxCatalogScript.lightning_strike_small_frames()
		if small
		else FxCatalogScript.lightning_strike_frames()
	)
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = PIXEL_SIZE_SMALL if small else PIXEL_SIZE_LARGE
	sprite.modulate = modulate_override
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
