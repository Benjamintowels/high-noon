extends Node3D
class_name EnginesFireballToss

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const AttackTelegraphScript := preload("res://gameplay/fx/attack_telegraph.gd")

const FLIGHT_TIME := 0.85
const ARC_HEIGHT := 5.5
const FIREBALL_PIXEL_SIZE := 0.028
const TOWN_CENTER_DAMAGE := 10
const IMPACT_TELEGRAPH_RADIUS := 2.4


static func launch(
	parent: Node,
	origin: Vector3,
	target: Node3D,
	attacker: Node3D = null
) -> void:
	if parent == null or target == null or not is_instance_valid(target):
		return

	var impact := target.global_position
	var telegraph_source: Node = attacker if attacker != null else parent
	var telegraph := AttackTelegraphScript.begin(
		telegraph_source,
		impact,
		IMPACT_TELEGRAPH_RADIUS,
		FLIGHT_TIME
	)
	if telegraph != null:
		telegraph.set_world_point(impact)
		telegraph.lock()

	var projectile := EnginesFireballToss.new()
	projectile.name = "EnginesFireball"
	parent.add_child(projectile)
	projectile._telegraph = telegraph
	projectile._begin_flight(origin, impact, target, attacker)


var _telegraph: Node3D


func _begin_flight(
	origin: Vector3,
	impact_point: Vector3,
	target: Node3D,
	attacker: Node3D
) -> void:
	global_position = origin
	_spawn_visual()
	GameAudioScript.play_explosion(get_parent(), origin)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(
		func(t: float) -> void:
			_update_arc_position(origin, impact_point, t),
		0.0,
		1.0,
		FLIGHT_TIME
	)
	tween.finished.connect(func() -> void:
		_on_impact(impact_point, target, attacker)
	)


func _spawn_visual() -> void:
	var frames := FxCatalogScript.epic_explosion_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = FIREBALL_PIXEL_SIZE
	sprite.modulate = Color(1.0, 0.72, 0.28, 0.95)
	sprite.scale = Vector3(0.35, 0.35, 0.35)
	add_child(sprite)
	sprite.play()


func _update_arc_position(origin: Vector3, impact_point: Vector3, t: float) -> void:
	var flat := origin.lerp(impact_point, t)
	var arc := sin(t * PI) * ARC_HEIGHT
	global_position = Vector3(flat.x, flat.y + arc, flat.z)


func _on_impact(impact_point: Vector3, target: Node3D, attacker: Node3D) -> void:
	if _telegraph != null and is_instance_valid(_telegraph):
		_telegraph.complete()
		_telegraph = null
	_spawn_impact_fx(impact_point)

	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		target.call("take_damage", TOWN_CENTER_DAMAGE)

	queue_free()


func _spawn_impact_fx(center: Vector3) -> void:
	var frames := FxCatalogScript.epic_explosion_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var parent := get_parent()
	if parent == null:
		return

	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.034
	sprite.modulate = Color(1.0, 0.78, 0.32, 0.95)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, 0.6, 0.0)
	sprite.scale = Vector3.ZERO
	sprite.play()

	var target_scale := 0.75
	var tween := sprite.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3.ONE * target_scale, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.38).set_delay(0.1)
	tween.chain().tween_callback(sprite.queue_free)
