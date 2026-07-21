extends RefCounted

## Large dynamite blast: layered FX, camera shake, AOE damage/knockback,
## crater decal, and breakable prop destruction.

const BlastRadiusFXScript := preload("res://gameplay/fx/blast_radius_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const DirtBurstFXScript := preload("res://gameplay/fx/dirt_burst_fx.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ExplosionCraterFXScript := preload("res://gameplay/fx/explosion_crater_fx.gd")
const ExplosionCameraShakeScript := preload("res://gameplay/fx/explosion_camera_shake.gd")
const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const HitchProfiler := preload("res://gameplay/debug/run_hitch_profiler.gd")

const DEFAULT_RADIUS := 7.5
const DEFAULT_BLAST_FORCE := 48.0
const DEFAULT_DAMAGE := 3
const CAMERA_SHAKE := 1.35
const FIREBALL_PIXEL_SIZE := 0.04
const SMOKE_PIXEL_SIZE := 0.032


static func detonate(
	parent: Node,
	center: Vector3,
	shooter: Node3D,
	radius: float = DEFAULT_RADIUS,
	blast_force: float = DEFAULT_BLAST_FORCE,
	damage: int = DEFAULT_DAMAGE
) -> void:
	if parent == null:
		return
	var tree := parent.get_tree()
	if tree == null and shooter != null:
		tree = shooter.get_tree()
	if tree == null:
		return

	var hitch_t := HitchProfiler.begin()
	_detonate_body(parent, tree, center, shooter, radius, blast_force, damage)
	HitchProfiler.end(
		HitchProfiler.LABEL_DYNAMITE_EXPLODE,
		hitch_t,
		"r=%.1f" % radius
	)


static func _detonate_body(
	parent: Node,
	tree: SceneTree,
	center: Vector3,
	shooter: Node3D,
	radius: float,
	blast_force: float,
	damage: int
) -> void:
	GameAudioScript.play_explosion(parent, center)
	GameAudioScript.notify_birds_of_explosion(parent, center)
	_spawn_fireball(parent, center, radius)
	BlastRadiusFXScript.spawn(parent, center, radius * 1.15)
	MuzzleFlashFXScript.spawn(parent, center, &"epic_explosion", 0.13)
	MuzzleFlashFXScript.spawn(parent, center + Vector3(0.0, 0.45, 0.0), &"epic_explosion", 0.095)
	MuzzleFlashFXScript.spawn(parent, center, &"symmetrical", 0.06)
	MuzzleFlashFXScript.spawn(parent, center + Vector3(0.0, 0.2, 0.0), &"symmetrical_large", 0.1)

	for i in 8:
		var angle := TAU * float(i) / 8.0 + randf_range(-0.15, 0.15)
		var offset := Vector3(cos(angle), randf_range(0.08, 0.4), sin(angle)) * radius * 0.24
		MuzzleFlashFXScript.spawn(parent, center + offset, &"epic_explosion", randf_range(0.04, 0.06))
		_spawn_directional_smoke(parent, center, Vector3(cos(angle), randf_range(0.25, 0.6), sin(angle)))

	SmokePuffFXScript.spawn_burst(parent, center, 12)
	# Soft lingering haze — few large budgeted puffs, long fade.
	SmokePuffFXScript.spawn_lingering_cloud(parent, center, 6, radius * 0.22)
	DirtBurstFXScript.spawn_burst(parent, center, 16)
	ExplosionCraterFXScript.spawn(parent, center, radius)

	ExplosionCameraShakeScript.shake_nearby(parent, center, radius, CAMERA_SHAKE)
	_damage_targets(tree, center, radius, blast_force, damage, shooter)
	_break_props(tree, center, radius, blast_force, shooter)
	_detonate_oil_drums(tree, center, radius, shooter)
	_push_physics_bodies(parent, center, radius, blast_force, shooter)


static func _spawn_fireball(parent: Node, center: Vector3, radius: float) -> void:
	var frames := FxCatalogScript.epic_explosion_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = FIREBALL_PIXEL_SIZE
	sprite.modulate = Color(1.0, 0.72, 0.28, 0.96)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, radius * 0.32, 0.0)
	sprite.scale = Vector3.ZERO
	sprite.play()
	var target_scale := maxf(radius / 1.9, 1.1)
	var tween := sprite.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector3.ONE * target_scale, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5).set_delay(0.12)
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
	sprite.modulate = Color(0.95, 0.95, 0.98, 0.9)
	parent.add_child(sprite)
	sprite.global_position = center + Vector3(0.0, 0.25, 0.0)
	sprite.rotation.y = atan2(flat_dir.x, flat_dir.z)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)


static func _damage_targets(
	tree: SceneTree,
	center: Vector3,
	radius: float,
	blast_force: float,
	damage: int,
	shooter: Node3D
) -> void:
	for group_name: StringName in [&"duel_target", &"target_scorable"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if node.has_method("is_defeated") and node.is_defeated():
				continue
			if node.has_method("is_duel_defeated") and node.is_duel_defeated():
				continue
			if not (node is Node3D):
				continue

			var target := node as Node3D
			var target_point := target.global_position
			if target.has_method("get_bullet_capsule"):
				var capsule: Dictionary = target.get_bullet_capsule()
				target_point = capsule.get("center", target_point)
			var distance := target_point.distance_to(center)
			if distance > radius:
				continue

			var falloff := 1.0 - pow(distance / radius, 1.2)
			var blast_dir := (target_point - center).normalized()
			if blast_dir.length_squared() < 0.0001:
				blast_dir = Vector3.UP
			var is_player := (
				target.is_in_group("overworld_player")
				or target.is_in_group("player")
			)
			var hit_info := BossGunResilienceScript.build_explosive_hit_info(
				target_point,
				blast_dir,
				shooter,
				is_player,
				damage,
				{
					"impulse_scale": clampf(falloff * 1.5, 0.2, 1.6),
					"dynamite": true,
					"blast_force": blast_force * falloff,
				}
			)

			if target is CharacterBody3D and not is_player:
				var body := target as CharacterBody3D
				body.velocity += blast_dir * BossGunResilienceScript.EXPLOSIVE_KNOCKBACK_SPEED * 0.55
				body.velocity.y = maxf(
					body.velocity.y,
					BossGunResilienceScript.EXPLOSIVE_KNOCKBACK_UP
				)

			if target.has_method("receive_bullet_hit"):
				target.receive_bullet_hit(hit_info)
			elif target.has_method("apply_bullet_hit"):
				target.apply_bullet_hit(hit_info)


static func _break_props(
	tree: SceneTree,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	for group_name: StringName in [&"breakable_prop", &"punchable_prop", &"sit_chair"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node) or not (node is Node3D):
				continue
			var prop := node as Node3D
			var prop_center := prop.global_position
			if prop.has_method("get_prop_center"):
				prop_center = prop.get_prop_center()
			var distance := prop_center.distance_to(center)
			if distance > radius:
				continue
			var away := prop_center - center
			away.y = 0.0
			if away.length_squared() < 0.0001:
				away = Vector3.FORWARD
			else:
				away = away.normalized()
			var hit_info := {
				"position": prop_center,
				"direction": away + Vector3.UP * 0.35,
				"explosion": true,
				"dynamite": true,
				"blast_force": blast_force * (1.0 - distance / radius),
				"shooter": shooter,
				"thrown_body": true,
			}
			if prop.has_method("break_from_explosion"):
				prop.break_from_explosion(hit_info)
			elif prop.has_method("break_apart"):
				prop.break_apart()
			elif prop.has_method("receive_punch"):
				prop.receive_punch(hit_info)
			elif prop.has_method("apply_bullet_hit"):
				prop.apply_bullet_hit(hit_info)


static func _detonate_oil_drums(
	tree: SceneTree,
	center: Vector3,
	radius: float,
	shooter: Node3D
) -> void:
	for node in tree.get_nodes_in_group(&"oil_drum"):
		if node == null or not is_instance_valid(node) or not (node is Node3D):
			continue
		var drum := node as Node3D
		if drum.global_position.distance_to(center) > radius:
			continue
		if node.has_method("_detonate"):
			node.call("_detonate", shooter, drum.global_position)
		elif node.has_method("receive_bullet_hit"):
			# 4th hit is a guaranteed explode in oil_drum.gd.
			for i in 4:
				node.receive_bullet_hit({
					"position": drum.global_position,
					"direction": (drum.global_position - center).normalized(),
					"explosion": true,
					"dynamite": true,
					"damage": 99,
					"shooter": shooter,
				})



static func _push_physics_bodies(
	parent: Node,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	_push_physics_node(parent, center, radius, blast_force, shooter)


static func _push_physics_node(
	node: Node,
	center: Vector3,
	radius: float,
	blast_force: float,
	shooter: Node3D
) -> void:
	if node is RigidBody3D and node != shooter:
		var body := node as RigidBody3D
		var distance := body.global_position.distance_to(center)
		if distance <= radius:
			var falloff := 1.0 - distance / radius
			var push_dir := (body.global_position - center).normalized()
			if push_dir.length_squared() < 0.0001:
				push_dir = Vector3.UP
			var offset := body.global_position - center
			body.apply_impulse(
				push_dir * blast_force * falloff + Vector3.UP * blast_force * 0.28 * falloff,
				offset
			)
	for child in node.get_children():
		_push_physics_node(child, center, radius, blast_force, shooter)
