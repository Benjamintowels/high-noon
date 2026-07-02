extends RefCounted
class_name BloodSplatterFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const PIXEL_SIZE := 0.013
const BIG_PIXEL_SIZE := 0.028


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


static func spawn_big_for_hit(target: Node, hit_info: Dictionary) -> void:
	var position: Vector3 = hit_info.get("position", Vector3.ZERO)
	if position == Vector3.ZERO and target is Node3D:
		position = (target as Node3D).global_position

	var direction: Vector3 = hit_info.get("direction", Vector3.ZERO)
	if direction.length_squared() > 0.0001:
		position += direction.normalized() * 0.05

	var parent := ImpactFXScript.parent_for(target) if target != null else null
	if parent == null:
		parent = target
	spawn_big(parent, position, direction)


static func spawn(parent: Node, global_position: Vector3) -> void:
	spawn_scaled(parent, global_position, Vector3.ZERO, PIXEL_SIZE, FxCatalogScript.random_splatter_frames())


static func spawn_big(parent: Node, global_position: Vector3, direction: Vector3 = Vector3.ZERO) -> void:
	spawn_scaled(
		parent,
		global_position,
		direction,
		BIG_PIXEL_SIZE,
		FxCatalogScript.random_large_splatter_frames()
	)


static func spawn_scaled(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size: float,
	frames: SpriteFrames
) -> void:
	if parent == null:
		return

	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.modulate = Color(1.0, 0.92, 0.92, 1.0)
	parent.add_child(sprite)
	sprite.global_position = global_position
	if direction.length_squared() > 0.0001:
		var flat_dir := Vector3(direction.x, 0.0, direction.z)
		if flat_dir.length_squared() > 0.0001:
			sprite.rotation.y = atan2(flat_dir.normalized().x, flat_dir.normalized().z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
