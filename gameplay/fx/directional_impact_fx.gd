extends RefCounted
class_name DirectionalImpactFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE := 0.02


static func spawn(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size: float = PIXEL_SIZE
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
	sprite.pixel_size = pixel_size
	sprite.modulate = Color(1.0, 0.95, 0.72, 1.0)
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
