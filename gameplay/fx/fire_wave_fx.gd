extends RefCounted
class_name FireWaveFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")

const SEGMENT_PIXEL_SIZE := 0.032
const LAUNCH_PIXEL_SIZE := 0.038


static func spawn_launch(parent: Node, origin: Vector3, direction: Vector3) -> void:
	if parent == null:
		return

	MuzzleFlashFXScript.spawn(parent, origin, &"epic_explosion", LAUNCH_PIXEL_SIZE)
	DirectionalImpactFXScript.spawn(parent, origin, direction, SEGMENT_PIXEL_SIZE)


static func spawn_segment(parent: Node, origin: Vector3, direction: Vector3) -> void:
	if parent == null:
		return

	var frames := FxCatalogScript.epic_explosion_frames()
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
	sprite.pixel_size = SEGMENT_PIXEL_SIZE
	sprite.modulate = Color(1.0, 0.72, 0.28, 0.92)
	parent.add_child(sprite)
	sprite.global_position = origin + Vector3(0.0, 0.55, 0.0)
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
