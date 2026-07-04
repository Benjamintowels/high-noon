extends RefCounted
class_name CompanionTeleportFX

const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const FX_HEIGHT := 0.9
const RING_LIFETIME := 0.45


static func spawn(source: Node, global_position: Vector3) -> void:
	var parent := ImpactFXScript.parent_for(source)
	if parent == null:
		return

	var fx_pos := global_position + Vector3(0.0, FX_HEIGHT, 0.0)
	SmokePuffFXScript.spawn_burst(parent, fx_pos, 5)
	MuzzleFlashFXScript.spawn(parent, fx_pos, &"symmetrical_large", 0.016)
	_spawn_rings(parent, fx_pos)


static func _spawn_rings(parent: Node, center: Vector3) -> void:
	for ring_index in 3:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.08 + ring_index * 0.04
		mesh.outer_radius = 0.18 + ring_index * 0.07
		ring.mesh = mesh

		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.72, 0.88, 1.0, 0.72 - ring_index * 0.12)
		material.emission_enabled = true
		material.emission = Color(0.45, 0.72, 1.0)
		material.emission_energy_multiplier = 1.35
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		ring.material_override = material

		parent.add_child(ring)
		ring.global_position = center
		ring.rotation.x = PI * 0.5

		var end_scale := Vector3.ONE * (1.8 + ring_index * 0.55)
		var tween := ring.create_tween().set_parallel(true)
		tween.tween_property(ring, "scale", end_scale, RING_LIFETIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_method(
			func(alpha: float) -> void:
				if is_instance_valid(material):
					material.albedo_color.a = alpha,
			material.albedo_color.a,
			0.0,
			RING_LIFETIME
		)
		tween.chain().tween_callback(ring.queue_free)
