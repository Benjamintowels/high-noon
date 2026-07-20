extends RefCounted
class_name BossShieldBreakFX

## Flashy shatter burst when a boss block/poise meter breaks.

const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const RING_RADIUS := 2.4
const FADE_DURATION := 0.7
const SHARD_COUNT := 14
const SHARD_SPEED := 6.5


static func spawn(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss) or not (boss is Node3D):
		return

	var body := boss as Node3D
	var center := body.global_position + Vector3(0.0, 1.15, 0.0)
	if boss.has_method("get_threat_aim_point"):
		center = boss.call("get_threat_aim_point")

	var fx_parent := ImpactFXScript.parent_for(boss)
	if fx_parent == null:
		return

	CombatHitFlashScript.flash_block_break(boss)
	MuzzleFlashFXScript.spawn(
		fx_parent,
		center,
		&"symmetrical_large",
		0.034,
		false,
		Color(0.55, 0.9, 1.6, 1.0)
	)
	SmokePuffFXScript.spawn_burst(fx_parent, center, 10)
	GameAudioScript.play_punch(boss, center)

	var root := Node3D.new()
	root.name = "BossShieldBreakFX"
	fx_parent.add_child(root)
	root.global_position = center

	_add_shock_ring(root)
	_add_shock_sphere(root)
	_spawn_shards(root)

	if boss.has_method("apply_camera_shake"):
		boss.call("apply_camera_shake", 0.55)
	var tree := boss.get_tree()
	if tree != null:
		for player in tree.get_nodes_in_group("overworld_player"):
			if player != null and player.has_method("apply_camera_shake"):
				player.call("apply_camera_shake", 0.45)

	var tween := root.create_tween()
	tween.tween_interval(FADE_DURATION)
	tween.tween_callback(root.queue_free)


static func _add_shock_ring(root: Node3D) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS - 0.22
	torus.outer_radius = RING_RADIUS
	torus.rings = 16
	torus.ring_segments = 48
	ring.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.85, 1.5, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.75, 1.6)
	mat.emission_energy_multiplier = 3.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	ring.scale = Vector3(0.15, 0.15, 0.15)
	root.add_child(ring)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.35, 0.35, 1.35), 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(mat):
				mat.albedo_color.a = alpha,
		0.75,
		0.0,
		FADE_DURATION
	).set_delay(0.05)


static func _add_shock_sphere(root: Node3D) -> void:
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	mesh.radial_segments = 20
	mesh.rings = 12
	sphere.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.6, 1.7, 2.0, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 1.2, 1.8)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material_override = mat
	sphere.scale = Vector3.ONE * 0.2
	root.add_child(sphere)

	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(sphere, "scale", Vector3.ONE * 2.8, 0.32) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(mat):
				mat.albedo_color.a = alpha,
		0.55,
		0.0,
		0.35
	)


static func _spawn_shards(root: Node3D) -> void:
	for i in SHARD_COUNT:
		var shard := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(
			randf_range(0.08, 0.16),
			randf_range(0.04, 0.1),
			randf_range(0.18, 0.32)
		)
		shard.mesh = box

		var mat := StandardMaterial3D.new()
		var tint := Color(0.4, 0.85, 1.5, 0.95) if i % 2 == 0 else Color(1.7, 1.8, 2.0, 0.9)
		mat.albedo_color = tint
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = 2.8
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shard.material_override = mat
		root.add_child(shard)

		var angle := TAU * float(i) / float(SHARD_COUNT) + randf_range(-0.15, 0.15)
		var dir := Vector3(cos(angle), randf_range(0.35, 0.95), sin(angle)).normalized()
		var end_pos := dir * randf_range(SHARD_SPEED * 0.35, SHARD_SPEED * 0.65)
		shard.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)

		var tween := root.create_tween().set_parallel(true)
		tween.tween_property(shard, "position", end_pos, FADE_DURATION * 0.85) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(
			shard,
			"rotation",
			shard.rotation + Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)),
			FADE_DURATION
		)
		tween.tween_method(
			func(alpha: float) -> void:
				if is_instance_valid(mat):
					mat.albedo_color.a = alpha,
			0.95,
			0.0,
			FADE_DURATION
		).set_delay(0.12)
