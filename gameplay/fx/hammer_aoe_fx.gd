extends RefCounted
class_name HammerAoeFX

const BlastRadiusFXScript := preload("res://gameplay/fx/blast_radius_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")

const SMOKE_PIXEL_SIZE := 0.028


static func spawn(parent: Node, center: Vector3, radius: float) -> void:
	if parent == null:
		return

	BlastRadiusFXScript.spawn(parent, center, radius)
	MuzzleFlashFXScript.spawn(parent, center, &"symmetrical_large", radius * 0.02)
	MuzzleFlashFXScript.spawn(
		parent,
		center + Vector3(0.0, radius * 0.18, 0.0),
		&"epic_explosion",
		radius * 0.016
	)

	for i in 6:
		var angle := TAU * float(i) / 6.0 + randf_range(-0.15, 0.15)
		var smoke_dir := Vector3(cos(angle), randf_range(0.2, 0.45), sin(angle))
		_spawn_directional_smoke(parent, center, smoke_dir)

	SmokePuffFXScript.spawn_burst(parent, center, maxi(6, int(radius * 2.5)))


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
	sprite.modulate = Color(0.94, 0.94, 0.98, 0.9)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, 0.18, 0.0)
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)
