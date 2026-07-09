extends RefCounted
class_name ParryTossFX
## One-shot sprite FX for the unarmed parry throw: launch burst, smoke trail
## puffs behind the flying body, and a small AoE flash on ground bounces.

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const TOSS_PIXEL_SIZE := 0.026
const TRAIL_PIXEL_SIZE := 0.012
const BOUNCE_PIXEL_SIZE := 0.02
const BOUNCE_LIGHT_ENERGY := 4.5
const BOUNCE_LIGHT_RANGE := 3.2


static func spawn_toss_burst(parent: Node, position: Vector3, direction: Vector3) -> void:
	var sprite := _spawn_frames(parent, FxCatalogScript.directional_smoke_frames(), position, TOSS_PIXEL_SIZE)
	if sprite == null:
		return
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() > 0.0001:
		sprite.rotation.y = atan2(flat.x, flat.z)


static func spawn_trail_puff(parent: Node, position: Vector3) -> void:
	var sprite := _spawn_frames(parent, FxCatalogScript.directional_smoke_frames(), position, TRAIL_PIXEL_SIZE)
	if sprite != null:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.7)


static func spawn_bounce_flash(parent: Node, position: Vector3) -> void:
	_spawn_frames(parent, FxCatalogScript.epic_explosion_frames(), position, BOUNCE_PIXEL_SIZE)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.5)
	light.light_energy = BOUNCE_LIGHT_ENERGY
	light.omni_range = BOUNCE_LIGHT_RANGE
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = position
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(light.queue_free)


static func _spawn_frames(
	parent: Node,
	frames: SpriteFrames,
	position: Vector3,
	pixel_size: float
) -> AnimatedSprite3D:
	if parent == null or frames == null:
		return null
	if frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return null

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	parent.add_child(sprite)
	sprite.global_position = position
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
	return sprite
