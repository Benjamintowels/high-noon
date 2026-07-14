extends RefCounted
class_name MuzzleFlashFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const PIXEL_SIZE := 0.014
const EPIC_EXPLOSION_PIXEL_SIZE := 0.022
const NIGHT_FLASH_DURATION := 0.09
const NIGHT_FLASH_ENERGY := 2.6
const NIGHT_FLASH_RANGE := 3.8


static func spawn(
	parent: Node,
	global_position: Vector3,
	style: StringName = &"default",
	pixel_size_override: float = -1.0,
	gun_muzzle: bool = false,
	modulate_override: Color = Color(0, 0, 0, 0)
) -> void:
	if parent == null:
		return

	if gun_muzzle:
		_spawn_night_light_flash(parent, global_position)

	var frames: SpriteFrames = null
	var pixel_size := PIXEL_SIZE
	var modulate := Color(1.0, 0.92, 0.78, 1.0)

	match style:
		&"epic_explosion":
			frames = FxCatalogScript.epic_explosion_frames()
			pixel_size = EPIC_EXPLOSION_PIXEL_SIZE
			modulate = Color(1.0, 0.95, 0.82, 1.0)
		&"symmetrical_large":
			frames = FxCatalogScript.symmetrical_explosion_large_frames()
			pixel_size = EPIC_EXPLOSION_PIXEL_SIZE
			modulate = Color(1.0, 0.88, 0.62, 1.0)
		&"symmetrical", &"default":
			frames = FxCatalogScript.muzzle_frames()
		_:
			frames = FxCatalogScript.muzzle_frames()

	if pixel_size_override > 0.0:
		pixel_size = pixel_size_override
	if modulate_override.a > 0.001:
		modulate = modulate_override

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


static func _spawn_night_light_flash(parent: Node, global_position: Vector3) -> void:
	if not DayNightCycle.is_outdoor_night():
		return

	var holder := Node3D.new()
	holder.name = "MuzzleNightFlash"
	parent.add_child(holder)
	holder.global_position = global_position

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.84, 0.48)
	light.light_energy = NIGHT_FLASH_ENERGY
	light.omni_range = NIGHT_FLASH_RANGE
	light.shadow_enabled = false
	holder.add_child(light)

	var tween := holder.create_tween()
	tween.tween_property(light, "light_energy", 0.0, NIGHT_FLASH_DURATION)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(holder.queue_free)
