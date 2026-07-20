extends RefCounted
class_name OilDrumExplosionFX

const BlastDamageScript := preload("res://gameplay/shooting/blast_damage.gd")
const BlastRadiusFXScript := preload("res://gameplay/fx/blast_radius_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const FIREBALL_PIXEL_SIZE := 0.034
const SMOKE_PIXEL_SIZE := 0.028


static func detonate(
	parent: Node,
	center: Vector3,
	shooter: Node3D,
	radius: float,
	blast_force: float,
	damage: int = BlastDamageScript.DEFAULT_DAMAGE
) -> void:
	if parent == null:
		return

	GameAudioScript.play_explosion(parent, center)
	GameAudioScript.notify_birds_of_explosion(parent, center)
	_spawn_fireball_aoe(parent, center, radius)
	BlastRadiusFXScript.spawn(parent, center, radius)

	MuzzleFlashFXScript.spawn(parent, center, &"epic_explosion", 0.12)
	MuzzleFlashFXScript.spawn(parent, center + Vector3(0.0, 0.35, 0.0), &"epic_explosion", 0.085)
	MuzzleFlashFXScript.spawn(parent, center, &"symmetrical", 0.055)
	MuzzleFlashFXScript.spawn(parent, center + Vector3(0.0, 0.15, 0.0), &"symmetrical_large", 0.09)

	for i in 6:
		var angle := TAU * float(i) / 6.0 + randf_range(-0.18, 0.18)
		var offset := Vector3(cos(angle), randf_range(0.08, 0.35), sin(angle)) * radius * 0.22
		MuzzleFlashFXScript.spawn(parent, center + offset, &"symmetrical", randf_range(0.035, 0.05))
		_spawn_directional_smoke(parent, center, Vector3(cos(angle), randf_range(0.25, 0.55), sin(angle)))

	SmokePuffFXScript.spawn_burst(parent, center, 14)
	BlastDamageScript.explode(center, shooter, radius, blast_force, true, damage)


static func _spawn_fireball_aoe(parent: Node, center: Vector3, radius: float) -> void:
	var frames := FxCatalogScript.epic_explosion_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = FIREBALL_PIXEL_SIZE
	sprite.modulate = Color(1.0, 0.78, 0.32, 0.95)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, radius * 0.35, 0.0)
	sprite.scale = Vector3.ZERO
	sprite.play()

	var target_scale := maxf(radius / 2.2, 0.85)
	var tween := sprite.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3.ONE * target_scale, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.42).set_delay(0.12)
	tween.chain().tween_callback(sprite.queue_free)


static func _spawn_directional_smoke(parent: Node, center: Vector3, direction: Vector3) -> void:
	var frames := FxCatalogScript.directional_smoke_frames()
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
	sprite.pixel_size = SMOKE_PIXEL_SIZE
	sprite.modulate = Color(0.98, 0.98, 1.0, 0.92)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, 0.2, 0.0)
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
