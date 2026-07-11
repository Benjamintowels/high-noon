extends RefCounted
class_name FlyingKickFX
## One-shot pixel-sprite FX for the rising flying kick: a directional launch
## burst at takeoff, streak puffs during flight, a big impact flash on a clean
## hit, and a smaller clang burst when the kick is blocked.

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")

const LAUNCH_PIXEL_SIZE := 0.022
const TRAIL_PIXEL_SIZE := 0.011
const IMPACT_PIXEL_SIZE := 0.024
const IMPACT_BURST_PIXEL_SIZE := 0.018
const BLOCK_PIXEL_SIZE := 0.015
const IMPACT_LIGHT_ENERGY := 5.5
const IMPACT_LIGHT_RANGE := 3.4
const BLOCK_LIGHT_ENERGY := 3.2
const BLOCK_LIGHT_RANGE := 2.4


static func spawn_launch_burst(parent: Node, position: Vector3, direction: Vector3) -> void:
	var sprite := _spawn_frames(
		parent,
		FxCatalogScript.directional_smoke_frames(),
		position,
		LAUNCH_PIXEL_SIZE
	)
	if sprite == null:
		return
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() > 0.0001:
		sprite.rotation.y = atan2(flat.x, flat.z)


static func spawn_trail_puff(parent: Node, position: Vector3) -> void:
	var sprite := _spawn_frames(
		parent,
		FxCatalogScript.directional_smoke_frames(),
		position,
		TRAIL_PIXEL_SIZE
	)
	if sprite != null:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.65)


static func spawn_impact(parent: Node, position: Vector3, direction: Vector3) -> void:
	_spawn_frames(parent, FxCatalogScript.epic_explosion_frames(), position, IMPACT_PIXEL_SIZE)
	DirectionalImpactFXScript.spawn(parent, position, direction, IMPACT_BURST_PIXEL_SIZE)
	_spawn_light_flash(parent, position, Color(1.0, 0.78, 0.45), IMPACT_LIGHT_ENERGY, IMPACT_LIGHT_RANGE)


static func spawn_blocked(parent: Node, position: Vector3) -> void:
	_spawn_frames(parent, FxCatalogScript.muzzle_frames(), position, BLOCK_PIXEL_SIZE)
	_spawn_light_flash(parent, position, Color(1.0, 0.92, 0.7), BLOCK_LIGHT_ENERGY, BLOCK_LIGHT_RANGE)


static func _spawn_light_flash(
	parent: Node,
	position: Vector3,
	color: Color,
	energy: float,
	light_range: float
) -> void:
	if parent == null:
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = position
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.2)\
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
