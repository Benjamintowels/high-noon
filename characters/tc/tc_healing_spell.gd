extends RefCounted
class_name TcHealingSpell

const HEAL_AMOUNT := 3
const COOLDOWN := 15.0
const AURA_DURATION := 2.2
const AURA_RADIUS := 4.5


static func can_cast(boss: Node, current_health: int, max_health: int, cooldown: float) -> bool:
	if boss == null:
		return false
	if cooldown > 0.0:
		return false
	return current_health < max_health


static func apply_heal(current_health: int, max_health: int) -> int:
	return mini(current_health + HEAL_AMOUNT, max_health)


static func spawn_aura(boss: Node) -> void:
	var actor := boss as Node3D
	if actor == null:
		return

	var aura := Node3D.new()
	aura.name = "TcHealingAura"
	actor.add_child(aura)
	aura.position = Vector3(0.0, 0.5, 0.0)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = AURA_RADIUS * 0.82
	torus.outer_radius = AURA_RADIUS
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.25, 0.95, 0.35, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.85, 0.25)
	mat.emission_energy_multiplier = 1.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	aura.add_child(ring)

	var pillar := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = AURA_RADIUS
	cylinder.bottom_radius = AURA_RADIUS
	cylinder.height = 0.08
	pillar.mesh = cylinder
	pillar.position.y = 0.04
	var pillar_mat := mat.duplicate() as StandardMaterial3D
	pillar_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.35)
	pillar.material_override = pillar_mat
	aura.add_child(pillar)

	var tween := aura.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.25, 1.25, 1.25), AURA_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pillar_mat, "albedo_color:a", 0.0, AURA_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(mat, "albedo_color:a", 0.0, AURA_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(aura.queue_free)
