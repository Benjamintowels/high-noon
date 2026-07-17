extends RefCounted
class_name SmokePuffFX

const FxNodeBudget := preload("res://gameplay/fx/fx_node_budget.gd")

const PUFFS_NAME := &"SmokePuffs"
const MAX_PUFFS := 32
const META_TWEEN := &"smoke_puff_tween"

const LIFETIME := 1.35
const RISE_DISTANCE := 1.1
const LINGERING_LIFETIME := 3.4
const LINGERING_RISE := 1.75


static func spawn_trail(parent: Node, global_position: Vector3, puff_scale: float = 0.22) -> void:
	_spawn_puff(parent, global_position, puff_scale, 0.42, LIFETIME, RISE_DISTANCE)


static func spawn_burst(parent: Node, global_position: Vector3, count: int = 6) -> void:
	for i in count:
		var offset := Vector3(
			randf_range(-0.65, 0.65),
			randf_range(0.0, 0.35),
			randf_range(-0.65, 0.65)
		)
		_spawn_puff(
			parent,
			global_position + offset,
			randf_range(0.28, 0.5),
			randf_range(0.55, 0.85),
			LIFETIME,
			RISE_DISTANCE
		)


## Fewer larger puffs that hang and fade slowly. Budgeted so blasts stay cheap.
static func spawn_lingering_cloud(
	parent: Node,
	global_position: Vector3,
	count: int = 6,
	spread: float = 1.15
) -> void:
	var n := maxi(count, 1)
	for i in n:
		var angle := TAU * float(i) / float(n) + randf_range(-0.25, 0.25)
		var radial := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(spread * 0.25, spread)
		var pos := global_position + radial + Vector3(0.0, randf_range(0.08, 0.55), 0.0)
		_spawn_puff(
			parent,
			pos,
			randf_range(0.62, 1.05),
			randf_range(0.28, 0.48),
			LINGERING_LIFETIME * randf_range(0.85, 1.1),
			LINGERING_RISE * randf_range(0.75, 1.15),
			true
		)


static func _spawn_puff(
	parent: Node,
	global_position: Vector3,
	puff_scale: float,
	start_alpha: float,
	lifetime: float = LIFETIME,
	rise_distance: float = RISE_DISTANCE,
	soft_fade: bool = false
) -> void:
	if parent == null:
		return

	var container := FxNodeBudget.ensure_container(parent, PUFFS_NAME)
	if container == null:
		return

	var puff := FxNodeBudget.acquire_or_recycle(
		container,
		MAX_PUFFS,
		func() -> Node:
			return _make_puff_node()
	) as MeshInstance3D
	if puff == null:
		return

	_kill_puff_tween(puff)
	puff.visible = true

	var mesh := puff.mesh as SphereMesh
	if mesh == null:
		mesh = SphereMesh.new()
		puff.mesh = mesh
	mesh.radius = puff_scale
	mesh.height = puff_scale * 2.2

	var material := puff.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		puff.material_override = material
	material.albedo_color = Color(0.96, 0.97, 0.99, start_alpha)

	puff.scale = Vector3.ONE
	puff.global_position = global_position + Vector3(
		randf_range(-0.08, 0.08),
		randf_range(-0.04, 0.06),
		randf_range(-0.08, 0.08)
	)

	var end_scale := puff_scale * randf_range(2.0, 2.8) if not soft_fade else puff_scale * randf_range(2.4, 3.4)
	var rise := Vector3(
		randf_range(-0.18, 0.18) if soft_fade else randf_range(-0.12, 0.12),
		rise_distance + randf_range(0.0, 0.45),
		randf_range(-0.18, 0.18) if soft_fade else randf_range(-0.12, 0.12)
	)
	var life := maxf(lifetime, 0.2)

	var tween := puff.create_tween().set_parallel(true)
	puff.set_meta(META_TWEEN, tween)
	tween.tween_property(puff, "global_position", puff.global_position + rise, life) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(puff, "scale", Vector3.ONE * end_scale, life) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if soft_fade:
		# Hold opacity, then ease out — reads as lingering haze.
		tween.tween_method(
			func(t: float) -> void:
				if not is_instance_valid(material):
					return
				var alpha := start_alpha
				if t > 0.45:
					var fade_t := (t - 0.45) / 0.55
					alpha = lerpf(start_alpha, 0.0, fade_t)
				material.albedo_color.a = alpha,
			0.0,
			1.0,
			life
		).set_trans(Tween.TRANS_LINEAR)
	else:
		tween.tween_method(
			func(alpha: float) -> void:
				if is_instance_valid(material):
					material.albedo_color.a = alpha,
			start_alpha,
			0.0,
			life
		)

	tween.chain().tween_callback(func() -> void:
		_retire_puff(puff)
	)


static func _make_puff_node() -> MeshInstance3D:
	var puff := MeshInstance3D.new()
	puff.name = "SmokePuff"
	puff.mesh = SphereMesh.new()
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	puff.material_override = material
	return puff


static func _kill_puff_tween(puff: MeshInstance3D) -> void:
	if puff == null or not puff.has_meta(META_TWEEN):
		return
	var tween: Tween = puff.get_meta(META_TWEEN)
	if tween != null and is_instance_valid(tween):
		tween.kill()
	puff.remove_meta(META_TWEEN)


static func _retire_puff(puff: MeshInstance3D) -> void:
	if puff == null or not is_instance_valid(puff):
		return
	_kill_puff_tween(puff)
	puff.visible = false
