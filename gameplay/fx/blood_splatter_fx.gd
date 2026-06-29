extends RefCounted
class_name BloodSplatterFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const PIXEL_SIZE := 0.013


static func spawn_for_hit(target: Node, hit_info: Dictionary) -> void:
	if target == null:
		return

	var position: Vector3 = hit_info.get("position", Vector3.ZERO)
	if position == Vector3.ZERO and target is Node3D:
		position = (target as Node3D).global_position

	var direction: Vector3 = hit_info.get("direction", Vector3.ZERO)
	if direction.length_squared() > 0.0001:
		position += direction.normalized() * 0.03

	var parent := ImpactFXScript.parent_for(target)
	spawn(parent, position)


static func spawn(parent: Node, global_position: Vector3) -> void:
	if parent == null:
		return

	var frames := FxCatalogScript.random_splatter_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = PIXEL_SIZE
	sprite.modulate = Color(1.0, 0.92, 0.92, 1.0)
	parent.add_child(sprite)
	sprite.global_position = global_position
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
