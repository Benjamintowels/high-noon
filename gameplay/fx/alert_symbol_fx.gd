extends RefCounted
class_name AlertSymbolFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE := 0.010
const FADE_DURATION := 0.35


static func spawn_above(parent: Node, world_position: Vector3) -> void:
	if parent == null:
		return

	var frames := FxCatalogScript.alert_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = PIXEL_SIZE
	parent.add_child(sprite)
	sprite.global_position = world_position
	sprite.play()

	sprite.animation_finished.connect(
		func() -> void:
			if not is_instance_valid(sprite):
				return
			var tween := sprite.create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.finished.connect(sprite.queue_free),
		CONNECT_ONE_SHOT
	)
