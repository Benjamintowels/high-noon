extends RefCounted

## Performative pixel dust for weapons with an active embedded elemental gem.
## Visual-only — combat side effects live in lightning/fire combat modules.

const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const ElementalGemStamina := preload("res://gameplay/combat/elemental_gem_stamina.gd")
const FxNodeBudget := preload("res://gameplay/fx/fx_node_budget.gd")

const CONTAINER_NAME := &"ElementalAttackFx"
const MAX_EMITTERS := 24
const LIGHTNING_COLOR := Color(1.0, 0.92, 0.22, 1.0)
const LIGHTNING_SPARK := Color(1.0, 0.98, 0.65, 1.0)


static func get_active_trail_gem(weapon_id: int) -> StringName:
	if not ElementalGemStamina.is_effect_active(weapon_id):
		return &""
	for gem_id in PlayerInventory.get_embedded_gems(weapon_id):
		if ElementalGems.is_active(gem_id):
			return gem_id
	return &""


static func weapon_has_elemental_trail(weapon_id: int) -> bool:
	return get_active_trail_gem(weapon_id) != &""


static func get_trail_color(weapon_id: int) -> Color:
	var gem_id := get_active_trail_gem(weapon_id)
	if gem_id == &"":
		return LIGHTNING_COLOR
	return ElementalGems.get_color(gem_id)


## Kept for call sites that still ask specifically about lightning trails.
static func weapon_has_lightning(weapon_id: int) -> bool:
	return (
		PlayerInventory.weapon_has_gem(weapon_id, ElementalGems.LIGHTNING)
		and ElementalGemStamina.is_effect_active(weapon_id)
	)


## Dust streak along a bullet / shot beam path.
static func spawn_trail_dust(parent: Node, from: Vector3, to: Vector3, color: Color = LIGHTNING_COLOR) -> void:
	if parent == null:
		return
	var delta := to - from
	var length := delta.length()
	if length < 0.05:
		return

	var container := FxNodeBudget.ensure_container(parent, CONTAINER_NAME)
	if container == null or FxNodeBudget.is_at_budget(container, MAX_EMITTERS):
		return

	var direction := delta / length
	var mid := from + direction * (length * 0.5)
	var spark := color.lerp(Color.WHITE, 0.35)

	var particles := _make_pixel_particles(
		clampi(int(length * 10.0), 8, 28),
		0.28,
		spark,
		color
	)
	# Emit in local space so the oriented emission box matches the beam.
	particles.local_coords = true
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(0.03, 0.03, length * 0.5)
	particles.direction = Vector3(0.0, 1.0, 0.0)
	particles.spread = 48.0
	particles.initial_velocity_min = 0.12
	particles.initial_velocity_max = 0.7
	particles.gravity = Vector3(0.0, -1.0, 0.0)

	container.add_child(particles)
	_orient_along(particles, mid, direction)
	_start_emitting(particles)


## Burst near a melee swing origin (hands / blade).
static func spawn_swing_dust(
	parent: Node,
	origin: Vector3,
	direction: Vector3 = Vector3.FORWARD,
	color: Color = LIGHTNING_COLOR
) -> void:
	if parent == null:
		return

	var container := FxNodeBudget.ensure_container(parent, CONTAINER_NAME)
	if container == null or FxNodeBudget.is_at_budget(container, MAX_EMITTERS):
		return

	var dir := direction
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	else:
		dir = dir.normalized()

	var spawn_pos := origin + Vector3(0.0, 1.05, 0.0) + dir * 0.45
	var spark := color.lerp(Color.WHITE, 0.25)

	var particles := _make_pixel_particles(
		18,
		0.32,
		spark,
		color
	)
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.12
	particles.direction = (dir + Vector3.UP * 0.35).normalized()
	particles.spread = 55.0
	particles.initial_velocity_min = 0.9
	particles.initial_velocity_max = 2.6
	particles.gravity = Vector3(0.0, -2.5, 0.0)

	container.add_child(particles)
	particles.global_position = spawn_pos
	_start_emitting(particles)

	# Secondary puffs along the swing arc so it reads in aim space, not just at feet.
	var arc_count := 3
	for i in arc_count:
		if FxNodeBudget.is_at_budget(container, MAX_EMITTERS):
			break
		var t := (float(i) + 1.0) / float(arc_count + 1)
		var arc_pos := origin + Vector3(0.0, 1.0 + t * 0.35, 0.0) + dir * (0.55 + t * 0.85)
		var puff := _make_pixel_particles(8, 0.22, color, color)
		puff.local_coords = false
		puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		puff.emission_sphere_radius = 0.08
		puff.direction = dir
		puff.spread = 40.0
		puff.initial_velocity_min = 0.4
		puff.initial_velocity_max = 1.4
		puff.gravity = Vector3(0.0, -1.5, 0.0)
		container.add_child(puff)
		puff.global_position = arc_pos
		_start_emitting(puff)


static func _make_pixel_particles(
	amount: int,
	lifetime: float,
	particle_color: Color,
	mat_color: Color
) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	# Critical: stay off until the node is parented and placed in world space.
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = 0.9
	particles.scale_amount_min = 0.018
	particles.scale_amount_max = 0.04
	particles.color = particle_color

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = mat_color
	mat.emission_enabled = true
	mat.emission = mat_color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.mesh = _pixel_quad_mesh()
	particles.material_override = mat
	return particles


static func _orient_along(node: Node3D, mid: Vector3, direction: Vector3) -> void:
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.95:
		up = Vector3.FORWARD
	node.global_basis = Basis.looking_at(direction, up)
	node.global_position = mid


static func _start_emitting(particles: CPUParticles3D) -> void:
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func _pixel_quad_mesh() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.04)
	return quad
