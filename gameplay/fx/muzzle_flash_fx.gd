extends RefCounted
class_name MuzzleFlashFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE := 0.014
const EPIC_EXPLOSION_PIXEL_SIZE := 0.022


static func spawn(
	parent: Node,
	global_position: Vector3,
	style: StringName = &"default",
	pixel_size_override: float = -1.0
) -> void:
	if parent == null:
		return

	var frames: SpriteFrames = null
	var pixel_size := PIXEL_SIZE
	var modulate := Color(1.0, 0.92, 0.78, 1.0)

	match style:
		&"epic_explosion":
			frames = FxCatalogScript.epic_explosion_frames()
			pixel_size = EPIC_EXPLOSION_PIXEL_SIZE
			modulate = Color(1.0, 0.95, 0.82, 1.0)
		&"symmetrical", &"default":
			frames = FxCatalogScript.muzzle_frames()
		_:
			frames = FxCatalogScript.muzzle_frames()

	if pixel_size_override > 0.0:
		pixel_size = pixel_size_override

	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.modulate = modulate
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
